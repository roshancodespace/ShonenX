import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class DiscordRpcService {
  static const String applicationId = '1435544312296505394';
  static const String _gatewayUrl =
      'wss://gateway.discord.gg/?v=10&encoding=json';
  static const String _appIconUrl =
      'https://raw.githubusercontent.com/roshancodespace/ShonenX/refs/heads/main/assets/images/app_icon.png';

  final _log = AppLogger.scope(DiscordRpcService);

  bool _isDesktopInitialized = false;
  bool _hasDesktopIpcFailed = false;
  WebSocket? _gatewaySocket;
  Timer? _heartbeatTimer;
  int? _heartbeatInterval;
  int? _sequenceNumber;
  bool _heartbeatAckReceived = true;
  Completer<void>? _connectCompleter;

  String? _token;
  bool _isConnected = false;
  Map<String, dynamic>? _lastPresencePayload;
  RPCActivity? _lastDesktopActivity;

  String? _activeMediaId;
  int? _activeEpisodeNumber;
  int? _mediaStartTimeMs;
  int? _browsingStartTimeMs;
  int? _animeStartTimeMs;
  int? _animeEndTimeMs;
  final Map<String, String> _assetCache = {};

  bool get isDesktopPlatform =>
      !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

  bool get isConnected =>
      _isConnected || (isDesktopPlatform && _isDesktopInitialized);
  Map<String, dynamic>? get lastPresencePayload => _lastPresencePayload;

  Future<void> initDesktopRpc() async {
    if (!isDesktopPlatform || _isDesktopInitialized) return;
    try {
      _log.i('Initializing FlutterDiscordRPC for app $applicationId...');
      await FlutterDiscordRPC.initialize(applicationId);
      _isDesktopInitialized = true;
      _log.s('FlutterDiscordRPC initialized successfully');
    } catch (e, s) {
      _log.e('Failed to initialize FlutterDiscordRPC', e, s);
    }
  }

  Future<void> connect([String? token]) async {
    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      return _connectCompleter!.future;
    }

    _connectCompleter = Completer<void>();
    _token = token;
    _log.i(
      'Connection requested (Token provided: ${token != null && token.isNotEmpty})',
    );

    try {
      if (isDesktopPlatform) {
        await initDesktopRpc();
        if (_isDesktopInitialized && !_hasDesktopIpcFailed) {
          _log.i('Connecting Desktop Discord RPC via IPC...');
          try {
            await FlutterDiscordRPC.instance.connect();
            _isConnected = true;
            if (_lastDesktopActivity != null) {
              await FlutterDiscordRPC.instance.setActivity(
                activity: _lastDesktopActivity!,
              );
            }
          } catch (e, s) {
            _hasDesktopIpcFailed = true;
            _log.e('Failed to connect Desktop Discord RPC via IPC', e, s);
          }
        }
      }

      if (token != null && token.isNotEmpty) {
        await _connectGateway();
      }
    } catch (e, s) {
      _log.e('Discord RPC connection error', e, s);
    } finally {
      if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
        _connectCompleter!.complete();
      }
    }
  }

  Future<void> _connectGateway() async {
    _log.i('Connecting to Discord Gateway socket...');
    try {
      await _gatewaySocket?.close();
      _gatewaySocket = await WebSocket.connect(_gatewayUrl);
      _gatewaySocket!.listen(
        _handleGatewayMessage,
        onError: (error) {
          _log.e('Discord Gateway socket error', error);
          if (!isDesktopPlatform) _isConnected = false;
        },
        onDone: () {
          _log.w('Discord Gateway connection closed');
          if (!isDesktopPlatform) _isConnected = false;
          _heartbeatTimer?.cancel();
        },
      );
    } catch (e, s) {
      _log.e('Failed to connect to Discord Gateway', e, s);
    }
  }

  void _handleGatewayMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final op = data['op'] as int?;
      _sequenceNumber = data['s'] as int?;

      switch (op) {
        case 10:
          _heartbeatInterval = data['d']['heartbeat_interval'] as int?;
          _heartbeatAckReceived = true;
          _log.d('Gateway HELLO received');
          _identify();
          _startHeartbeat();
          break;
        case 0:
          final event = data['t'] as String?;
          if (event == 'READY') {
            _isConnected = true;
            _log.s('Discord Gateway Connected & READY');
            if (_lastPresencePayload != null) {
              _sendGatewayPayload(_lastPresencePayload!);
            } else {
              updateBrowsingPresence();
            }
          }
          break;
        case 11:
          _heartbeatAckReceived = true;
          break;
      }
    } catch (e, s) {
      _log.e('Error handling Gateway message', e, s);
    }
  }

  void _identify() {
    if (_token == null || _token!.isEmpty) return;
    final payload = {
      'op': 2,
      'd': {
        'token': _token,
        'properties': {
          '\$os': Platform.operatingSystem,
          '\$browser': 'ShonenX',
          '\$device': 'ShonenX Client',
        },
        'presence': {'status': 'online', 'afk': false},
      },
    };
    _gatewaySocket?.add(jsonEncode(payload));
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (_heartbeatInterval != null) {
      _heartbeatTimer = Timer.periodic(
        Duration(milliseconds: _heartbeatInterval!),
        (_) => _sendHeartbeat(),
      );
    }
  }

  void _sendHeartbeat() {
    if (!_heartbeatAckReceived) {
      _log.w('Heartbeat ACK missed! Reconnecting...');
      if (_token != null) connect(_token!);
      return;
    }
    _heartbeatAckReceived = false;
    final payload = {'op': 1, 'd': _sequenceNumber};
    _gatewaySocket?.add(jsonEncode(payload));
  }

  static const String _defaultAssetKey = 'app_icon';

  Future<String> _processImageUrl(String? url) async {
    if (url == null || url.isEmpty) return _defaultAssetKey;
    if (_token == null || _token!.isEmpty) return _defaultAssetKey;
    if (_assetCache.containsKey(url)) return _assetCache[url]!;

    try {
      final response = await http
          .post(
            Uri.parse(
              'https://discord.com/api/v9/applications/$applicationId/external-assets',
            ),
            headers: {
              'Authorization': _token!,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'urls': [url],
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['external_asset_path'] != null) {
          final assetPath = 'mp:${data[0]['external_asset_path']}';
          _assetCache[url] = assetPath;
          return assetPath;
        }
      }
    } catch (e, s) {
      _log.w('Error registering external asset: $url', e, s);
    }

    return _defaultAssetKey;
  }

  void _dispatchPresence({
    required RPCActivity desktopActivity,
    required Map<String, dynamic> gatewayPayload,
  }) {
    _lastDesktopActivity = desktopActivity;
    _lastPresencePayload = gatewayPayload;

    if (isDesktopPlatform && _isDesktopInitialized) {
      try {
        _log.d('Updating activity via FlutterDiscordRPC');
        FlutterDiscordRPC.instance.setActivity(activity: desktopActivity);
      } catch (e, s) {
        _log.e('Failed to set desktop activity', e, s);
      }
    }

    if (_gatewaySocket != null && _isConnected) {
      _sendGatewayPayload(gatewayPayload);
    }
  }

  void _sendGatewayPayload(Map<String, dynamic> payload) {
    if (_gatewaySocket != null) {
      _gatewaySocket?.add(jsonEncode(payload));
    }
  }

  Future<void> updateAnimePresence({
    required UnifiedMedia anime,
    required int episodeNumber,
    String? episodeTitle,
    int? timeStampMs,
    int? durationMs,
    int? totalEpisodes,
  }) async {
    final currentSeconds = timeStampMs != null
        ? (timeStampMs / 1000).round()
        : 0;
    final totalSeconds = durationMs != null ? (durationMs / 1000).round() : 0;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final calcStartMs = nowMs - (currentSeconds * 1000);
    final calcEndMs = (totalSeconds > 60 && totalSeconds > currentSeconds)
        ? nowMs + ((totalSeconds - currentSeconds) * 1000)
        : null;

    if (_activeMediaId != anime.id ||
        _activeEpisodeNumber != episodeNumber ||
        _animeStartTimeMs == null ||
        (_animeStartTimeMs! - calcStartMs).abs() > 3000 ||
        (_animeEndTimeMs == null && calcEndMs != null)) {
      _activeMediaId = anime.id;
      _activeEpisodeNumber = episodeNumber;
      _animeStartTimeMs = calcStartMs;
      _animeEndTimeMs = calcEndMs;
    }
    _browsingStartTimeMs = null;
    _mediaStartTimeMs = null;

    final startTimeMs = _animeStartTimeMs!;
    final endTimeMs = _animeEndTimeMs;

    final title = anime.title.availableTitle;
    final epString =
        'Episode $episodeNumber${totalEpisodes != null ? '/$totalEpisodes' : ''}';
    final stateString = episodeTitle != null && episodeTitle.isNotEmpty
        ? '$epString – $episodeTitle'
        : epString;

    final coverUrl = anime.cover ?? anime.banner;
    final mediaUrl = 'https://anilist.co/anime/${anime.id}';

    _log.i('Updating Anime presence: $title ($epString)');

    final desktopActivity = RPCActivity(
      details: title,
      state: stateString,
      timestamps: RPCTimestamps(start: startTimeMs, end: endTimeMs),
      assets: RPCAssets(
        largeImage: coverUrl ?? _appIconUrl,
        largeText: title,
        smallImage: _appIconUrl,
        smallText: 'ShonenX',
      ),
      buttons: [
        RPCButton(label: 'View Anime', url: mediaUrl),
        const RPCButton(
          label: 'Watch on ShonenX',
          url: 'https://github.com/roshancodespace/shonenx',
        ),
      ],
    );

    final gatewayPayload = {
      'op': 3,
      'd': {
        'since': null,
        'activities': [
          {
            'application_id': applicationId,
            'name': 'ShonenX',
            'type': 3,
            'details': title,
            'state': stateString,
            'timestamps': {
              'start': startTimeMs,
              if (endTimeMs != null) 'end': endTimeMs,
            },
            'assets': {
              'large_image': await _processImageUrl(coverUrl),
              'large_text': title,
              'small_image': await _processImageUrl(_appIconUrl),
              'small_text': 'ShonenX',
            },
            'buttons': ['View Anime', 'Watch on ShonenX'],
            'metadata': {
              'button_urls': [
                mediaUrl,
                'https://github.com/roshancodespace/shonenx',
              ],
            },
          },
        ],
        'status': 'online',
        'afk': false,
      },
    };

    _dispatchPresence(
      desktopActivity: desktopActivity,
      gatewayPayload: gatewayPayload,
    );
  }

  Future<void> updateAnimePresencePaused({
    required UnifiedMedia anime,
    required int episodeNumber,
    int? timeStampMs,
    int? durationMs,
  }) async {
    final currentSec = timeStampMs != null ? (timeStampMs / 1000).round() : 0;
    final totalSec = durationMs != null ? (durationMs / 1000).round() : 0;
    final timeDisplay = (currentSec > 0 && totalSec > 0)
        ? ' • ${_formatDuration(Duration(seconds: currentSec))} / ${_formatDuration(Duration(seconds: totalSec))}'
        : '';

    final title = anime.title.availableTitle;
    final coverUrl = anime.cover ?? anime.banner;
    final mediaUrl = 'https://anilist.co/anime/${anime.id}';

    _log.i('Updating Anime presence (Paused): $title');

    final desktopActivity = RPCActivity(
      details: title,
      state: 'Episode $episodeNumber$timeDisplay (Paused)',
      assets: RPCAssets(
        largeImage: coverUrl ?? _appIconUrl,
        largeText: title,
        smallImage: _appIconUrl,
        smallText: 'ShonenX',
      ),
      buttons: [
        RPCButton(label: 'View Anime', url: mediaUrl),
        const RPCButton(
          label: 'Watch on ShonenX',
          url: 'https://github.com/roshancodespace/shonenx',
        ),
      ],
    );

    final gatewayPayload = {
      'op': 3,
      'd': {
        'since': null,
        'activities': [
          {
            'application_id': applicationId,
            'name': 'ShonenX',
            'type': 3,
            'details': title,
            'state': 'Episode $episodeNumber$timeDisplay (Paused)',
            'assets': {
              'large_image': await _processImageUrl(coverUrl),
              'large_text': title,
              'small_image': await _processImageUrl(_appIconUrl),
              'small_text': 'ShonenX',
            },
            'buttons': ['View Anime', 'Watch on ShonenX'],
            'metadata': {
              'button_urls': [
                mediaUrl,
                'https://github.com/roshancodespace/shonenx',
              ],
            },
          },
        ],
        'status': 'online',
        'afk': false,
      },
    };

    _dispatchPresence(
      desktopActivity: desktopActivity,
      gatewayPayload: gatewayPayload,
    );
  }

  Future<void> updateMangaPresence({
    required UnifiedMedia manga,
    int? chapterNumber,
    String? chapterTitle,
    int? currentPage,
    int? totalPages,
    int? totalChapters,
  }) async {
    if (_activeMediaId != manga.id || _mediaStartTimeMs == null) {
      _activeMediaId = manga.id;
      _mediaStartTimeMs = DateTime.now().millisecondsSinceEpoch;
    }
    _browsingStartTimeMs = null;

    final title = manga.title.availableTitle;
    final chString = chapterNumber != null
        ? 'Chapter $chapterNumber${totalChapters != null ? '/$totalChapters' : ''}'
        : 'Reading';
    final pageString = currentPage != null && totalPages != null
        ? ' • Page $currentPage/$totalPages'
        : '';

    final coverUrl = manga.cover ?? manga.banner;
    final mediaUrl = 'https://anilist.co/manga/${manga.id}';

    _log.i('Updating Manga presence: $title ($chString)');

    final desktopActivity = RPCActivity(
      details: title,
      state: '$chString$pageString',
      timestamps: RPCTimestamps(start: _mediaStartTimeMs),
      assets: RPCAssets(
        largeImage: coverUrl ?? _appIconUrl,
        largeText: title,
        smallImage: _appIconUrl,
        smallText: 'ShonenX',
      ),
      buttons: [
        RPCButton(label: 'View Manga', url: mediaUrl),
        const RPCButton(
          label: 'Read on ShonenX',
          url: 'https://github.com/roshancodespace/shonenx',
        ),
      ],
    );

    final gatewayPayload = {
      'op': 3,
      'd': {
        'since': null,
        'activities': [
          {
            'application_id': applicationId,
            'name': 'ShonenX',
            'type': 0,
            'details': title,
            'state': '$chString$pageString',
            'timestamps': {'start': _mediaStartTimeMs},
            'assets': {
              'large_image': await _processImageUrl(coverUrl),
              'large_text': title,
              'small_image': await _processImageUrl(_appIconUrl),
              'small_text': 'ShonenX',
            },
            'buttons': ['View Manga', 'Read on ShonenX'],
            'metadata': {
              'button_urls': [
                mediaUrl,
                'https://github.com/roshancodespace/shonenx',
              ],
            },
          },
        ],
        'status': 'online',
        'afk': false,
      },
    };

    _dispatchPresence(
      desktopActivity: desktopActivity,
      gatewayPayload: gatewayPayload,
    );
  }

  Future<void> updateMediaPresence({required UnifiedMedia media}) async {
    if (_activeMediaId != media.id ||
        _mediaStartTimeMs == null ||
        _animeStartTimeMs != null) {
      _activeMediaId = media.id;
      _mediaStartTimeMs = DateTime.now().millisecondsSinceEpoch;
    }
    _browsingStartTimeMs = null;
    _animeStartTimeMs = null;
    _animeEndTimeMs = null;
    _activeEpisodeNumber = null;

    final title = media.title.availableTitle;
    final typeStr = media.type == MediaType.MANGA ? 'Manga' : 'Anime';
    final coverUrl = media.cover ?? media.banner;
    final mediaUrl = 'https://anilist.co/${media.type.id}/${media.id}';

    _log.i('Updating Media presence: $title');

    final desktopActivity = RPCActivity(
      details: 'Viewing $title',
      state: 'Inspecting $typeStr Details',
      timestamps: RPCTimestamps(start: _mediaStartTimeMs),
      assets: RPCAssets(
        largeImage: coverUrl ?? _appIconUrl,
        largeText: title,
        smallImage: _appIconUrl,
        smallText: 'ShonenX',
      ),
      buttons: [
        RPCButton(label: 'View $typeStr', url: mediaUrl),
        const RPCButton(
          label: 'Get ShonenX',
          url: 'https://github.com/roshancodespace/shonenx',
        ),
      ],
    );

    final images = await Future.wait([
      _processImageUrl(coverUrl),
      _processImageUrl(_appIconUrl),
    ]);

    final gatewayPayload = {
      'op': 3,
      'd': {
        'since': null,
        'activities': [
          {
            'application_id': applicationId,
            'name': 'ShonenX',
            'type': 0,
            'details': 'Viewing $title',
            'state': 'Inspecting $typeStr Details',
            'timestamps': {'start': _mediaStartTimeMs},
            'assets': {
              'large_image': images[0],
              'large_text': title,
              'small_image': images[1],
              'small_text': 'ShonenX',
            },
            'buttons': ['View $typeStr', 'Get ShonenX'],
            'metadata': {
              'button_urls': [
                mediaUrl,
                'https://github.com/roshancodespace/shonenx',
              ],
            },
          },
        ],
        'status': 'online',
        'afk': false,
      },
    };

    _dispatchPresence(
      desktopActivity: desktopActivity,
      gatewayPayload: gatewayPayload,
    );
  }

  Future<void> updateBrowsingPresence({
    String? activity,
    String? details,
  }) async {
    _browsingStartTimeMs ??= DateTime.now().millisecondsSinceEpoch;
    _activeMediaId = null;
    _activeEpisodeNumber = null;
    _mediaStartTimeMs = null;
    _animeStartTimeMs = null;
    _animeEndTimeMs = null;

    _log.i('Updating Browsing presence: ${activity ?? 'Glazing ShonenX'}');

    final desktopActivity = RPCActivity(
      details: activity ?? 'Glazing ShonenX',
      state: details ?? 'Browsing Catalog',
      timestamps: RPCTimestamps(start: _browsingStartTimeMs),
      assets: const RPCAssets(
        largeImage: _appIconUrl,
        largeText: 'ShonenX - Anime & Manga Client',
      ),
      buttons: const [
        RPCButton(
          label: 'Get ShonenX',
          url: 'https://github.com/roshancodespace/shonenx',
        ),
      ],
    );

    final gatewayPayload = {
      'op': 3,
      'd': {
        'since': null,
        'activities': [
          {
            'application_id': applicationId,
            'name': 'ShonenX',
            'type': 0,
            'details': activity ?? 'Glazing ShonenX',
            'state': details ?? 'Browsing Catalog',
            'timestamps': {'start': _browsingStartTimeMs},
            'assets': {
              'large_image': await _processImageUrl(_appIconUrl),
              'large_text': 'ShonenX - Anime & Manga Client',
            },
            'buttons': ['Get ShonenX'],
            'metadata': {
              'button_urls': ['https://github.com/roshancodespace/shonenx'],
            },
          },
        ],
        'status': 'online',
        'afk': false,
      },
    };

    _dispatchPresence(
      desktopActivity: desktopActivity,
      gatewayPayload: gatewayPayload,
    );
  }

  void resetPresenceState() {
    _lastPresencePayload = null;
    _lastDesktopActivity = null;
    _activeMediaId = null;
    _activeEpisodeNumber = null;
    _mediaStartTimeMs = null;
    _browsingStartTimeMs = null;
    _animeStartTimeMs = null;
    _animeEndTimeMs = null;
  }

  Future<void> clearPresence() async {
    _log.i('Clearing Discord presence');
    resetPresenceState();
    if (isDesktopPlatform && _isDesktopInitialized) {
      try {
        FlutterDiscordRPC.instance.clearActivity();
      } catch (e, s) {
        _log.e('Failed to clear desktop activity', e, s);
      }
    }

    if (_gatewaySocket != null && _isConnected) {
      final payload = {
        'op': 3,
        'd': {
          'since': null,
          'activities': [],
          'status': 'online',
          'afk': false,
        },
      };
      _gatewaySocket?.add(jsonEncode(payload));
    }
  }

  Future<void> disconnect() async {
    _log.i('Disconnecting Discord RPC...');
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    if (isDesktopPlatform && _isDesktopInitialized) {
      try {
        FlutterDiscordRPC.instance.disconnect();
      } catch (e, s) {
        _log.e('Failed to disconnect desktop RPC', e, s);
      }
    }
    await _gatewaySocket?.close();
    _gatewaySocket = null;
    _sequenceNumber = null;
    _isConnected = false;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
