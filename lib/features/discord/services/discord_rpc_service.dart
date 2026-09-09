import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_discord_rpc_fork/flutter_discord_rpc.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/models/unified_media.dart';

/// Manages Discord presence across Desktop IPC and Gateway WebSocket.
class DiscordRpcService {
  static const String applicationId = '1435544312296505394';
  static const String _appIconUrl =
      'https://raw.githubusercontent.com/roshancodespace/ShonenX/refs/heads/main/assets/images/app_icon.png';

  final _log = AppLogger.scope(DiscordRpcService);
  final _desktop = _DesktopRpc();
  late final _gateway = _GatewayConnection(
    token: () => _token,
    onReady: _onGatewayReady,
  );

  String? _token;
  RPCActivity? _lastDesktopActivity;
  Map<String, dynamic>? _lastGatewayPayload;
  int? _browsingStartMs;
  int? _mediaStartMs;
  final Map<String, String> _imageAssetCache = {};

  bool get isDesktopPlatform =>
      !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

  bool get isConnected =>
      _gateway.isConnected || (isDesktopPlatform && _desktop.isInitialized);

  Map<String, dynamic>? get lastPresencePayload => _lastGatewayPayload;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> connect([String? token]) async {
    _token = token ?? _token;

    if (isDesktopPlatform) {
      await _desktop.init(applicationId);
      await _desktop.connect();
      if (_lastDesktopActivity != null) {
        _desktop.setActivity(_lastDesktopActivity!);
      }
    }

    if (_token != null && _token!.isNotEmpty) {
      await _gateway.connect();
    }
  }

  Future<void> disconnect() async {
    _log.i('Disconnecting Discord RPC');
    _desktop.disconnect();
    await _gateway.disconnect();
  }

  // ---------------------------------------------------------------------------
  // Presence
  // ---------------------------------------------------------------------------

  /// Updates presence for anime playback (watching or paused).
  Future<void> updateAnimePresence({
    required UnifiedMedia anime,
    required int episodeNumber,
    String? episodeTitle,
    int? positionMs,
    int? durationMs,
    int? timeStampMs,
    int? totalEpisodes,
    bool isPlaying = true,
  }) async {
    _resetTimestamps(media: true);

    final pos = positionMs ?? timeStampMs ?? 0;
    final dur = durationMs ?? 0;
    final title = anime.title.availableTitle;
    final epCount = totalEpisodes != null ? '/$totalEpisodes' : '';
    final epLabel = 'Episode $episodeNumber$epCount';

    final stateText = isPlaying
        ? _joinNonEmpty([epLabel, episodeTitle])
        : '${_joinNonEmpty([epLabel, _progressText(pos, dur)])} (Paused)';

    final coverUrl = anime.cover ?? anime.banner;
    final mediaUrl = 'https://anilist.co/anime/${anime.id}';

    final now = DateTime.now().millisecondsSinceEpoch;
    final startMs = isPlaying ? (pos > 0 ? now - pos : now) : null;
    final endMs =
        (isPlaying && dur > 0 && pos > 0 && dur > pos && startMs != null)
        ? startMs + dur
        : null;

    _log.i('Anime presence: $title ($stateText)');

    await _dispatch(
      desktop: RPCActivity(
        activityType: ActivityType.watching,
        details: title,
        state: stateText,
        timestamps: startMs != null
            ? RPCTimestamps(start: startMs, end: endMs)
            : null,
        assets: RPCAssets(
          largeImage: coverUrl ?? _appIconUrl,
          largeText: title,
          smallImage: _appIconUrl,
          smallText: 'ShonenX',
        ),
        buttons: [RPCButton(label: 'View Anime', url: mediaUrl)],
      ),
      gateway: _gatewayPresence(
        name: title,
        type: 3, // Watching
        details: title,
        state: stateText,
        timestamps: {
          if (isPlaying && startMs != null) 'start': startMs,
          if (isPlaying && endMs != null) 'end': endMs,
        },
        coverUrl: coverUrl,
        largeText: title,
        buttonLabel: 'View Anime',
        buttonUrl: mediaUrl,
      ),
    );
  }

  /// Updates presence for paused anime playback.
  Future<void> updateAnimePresencePaused({
    required UnifiedMedia anime,
    required int episodeNumber,
    int? positionMs,
    int? durationMs,
    int? timeStampMs,
  }) => updateAnimePresence(
    anime: anime,
    episodeNumber: episodeNumber,
    positionMs: positionMs ?? timeStampMs,
    durationMs: durationMs,
    isPlaying: false,
  );

  /// Updates presence for manga reading.
  Future<void> updateMangaPresence({
    required UnifiedMedia manga,
    int? chapterNumber,
    String? chapterTitle,
    int? currentPage,
    int? totalPages,
    int? totalChapters,
  }) async {
    _mediaStartMs ??= DateTime.now().millisecondsSinceEpoch;
    _browsingStartMs = null;

    final title = manga.title.availableTitle;
    final chTotal = totalChapters != null ? '/$totalChapters' : '';
    final chLabel = chapterNumber != null
        ? 'Chapter $chapterNumber$chTotal'
        : 'Reading';
    final pageLabel = (currentPage != null && totalPages != null)
        ? 'Page $currentPage/$totalPages'
        : null;
    final stateText = _joinNonEmpty([chLabel, chapterTitle, pageLabel]);

    final coverUrl = manga.cover ?? manga.banner;
    final mediaUrl = 'https://anilist.co/manga/${manga.id}';

    _log.i('Manga presence: $title ($stateText)');

    await _dispatch(
      desktop: RPCActivity(
        activityType: ActivityType.listening,
        details: title,
        state: stateText,
        timestamps: RPCTimestamps(start: _mediaStartMs),
        assets: RPCAssets(
          largeImage: coverUrl ?? _appIconUrl,
          largeText: title,
          smallImage: _appIconUrl,
          smallText: 'ShonenX',
        ),
        buttons: [RPCButton(label: 'View Manga', url: mediaUrl)],
      ),
      gateway: _gatewayPresence(
        name: title,
        type: 0,
        details: title,
        state: stateText,
        timestamps: {'start': _mediaStartMs},
        coverUrl: coverUrl,
        largeText: title,
        buttonLabel: 'View Manga',
        buttonUrl: mediaUrl,
      ),
    );
  }

  /// Updates presence when viewing media details.
  Future<void> updateMediaPresence({required UnifiedMedia media}) async {
    _mediaStartMs = DateTime.now().millisecondsSinceEpoch;
    _browsingStartMs = null;

    final title = media.title.availableTitle;
    final typeStr = media.type == MediaType.MANGA ? 'Manga' : 'Anime';
    final coverUrl = media.cover ?? media.banner;
    final mediaUrl = 'https://anilist.co/${media.type.id}/${media.id}';
    final stateText = 'Viewing $typeStr Details';

    _log.i('Media presence: $title');

    await _dispatch(
      desktop: RPCActivity(
        details: title,
        state: stateText,
        timestamps: RPCTimestamps(start: _mediaStartMs),
        assets: RPCAssets(
          largeImage: coverUrl ?? _appIconUrl,
          largeText: title,
          smallImage: _appIconUrl,
          smallText: 'ShonenX',
        ),
        buttons: [RPCButton(label: 'View $typeStr', url: mediaUrl)],
      ),
      gateway: _gatewayPresence(
        name: title,
        type: 0,
        details: title,
        state: stateText,
        timestamps: {'start': _mediaStartMs},
        coverUrl: coverUrl,
        largeText: title,
        buttonLabel: 'View $typeStr',
        buttonUrl: mediaUrl,
      ),
    );
  }

  /// Updates presence when browsing catalog or idle.
  Future<void> updateBrowsingPresence({
    String? activity,
    String? details,
  }) async {
    _browsingStartMs ??= DateTime.now().millisecondsSinceEpoch;
    _mediaStartMs = null;

    final primary = activity ?? 'Browsing Catalog';
    final secondary = details ?? 'Exploring Anime & Manga';

    _log.i('Browsing presence: $primary');

    await _dispatch(
      desktop: RPCActivity(
        details: primary,
        state: secondary,
        timestamps: RPCTimestamps(start: _browsingStartMs),
        assets: const RPCAssets(largeImage: _appIconUrl, largeText: 'ShonenX'),
      ),
      gateway: _gatewayPresence(
        name: 'ShonenX',
        type: 0,
        details: primary,
        state: secondary,
        timestamps: {'start': _browsingStartMs},
      ),
    );
  }

  /// Clears active presence on all platforms.
  Future<void> clearPresence() async {
    _log.i('Clearing presence');
    resetPresenceState();
    _desktop.clearActivity();
    _gateway.sendPresenceUpdate({'activities': [], 'status': 'online'});
  }

  /// Resets cached presence state without dispatching updates.
  void resetPresenceState() {
    _lastGatewayPayload = null;
    _lastDesktopActivity = null;
    _mediaStartMs = null;
    _browsingStartMs = null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _resetTimestamps({bool media = false}) {
    if (media) {
      _browsingStartMs = null;
      _mediaStartMs = null;
    }
  }

  void _onGatewayReady() {
    if (_lastGatewayPayload != null) {
      _gateway.send(_lastGatewayPayload!);
    } else {
      updateBrowsingPresence();
    }
  }

  Future<void> _dispatch({
    required RPCActivity desktop,
    required Future<Map<String, dynamic>> gateway,
  }) async {
    _lastDesktopActivity = desktop;

    if (isDesktopPlatform && _desktop.isInitialized) {
      _desktop.setActivity(desktop);
    }

    final payload = await gateway;
    _lastGatewayPayload = payload;

    if (_gateway.isConnected) {
      _gateway.send(payload);
    }
  }

  Future<Map<String, dynamic>> _gatewayPresence({
    required String name,
    required int type,
    required String details,
    required String state,
    required Map<String, dynamic> timestamps,
    String? coverUrl,
    String? largeText,
    String? buttonLabel,
    String? buttonUrl,
  }) async {
    final assets = <String, dynamic>{
      'large_image': await _resolveAsset(coverUrl ?? _appIconUrl),
      'large_text': largeText ?? 'ShonenX',
      'small_image': await _resolveAsset(_appIconUrl),
      'small_text': 'ShonenX',
    };

    if (coverUrl == null) {
      assets.remove('small_image');
      assets.remove('small_text');
    }

    final activity = <String, dynamic>{
      'application_id': applicationId,
      'name': name,
      'type': type,
      'details': details,
      'state': state,
      'timestamps': timestamps,
      'assets': assets,
    };

    if (buttonLabel != null && buttonUrl != null) {
      activity['buttons'] = [buttonLabel];
      activity['metadata'] = {
        'button_urls': [buttonUrl],
      };
    }

    return {
      'op': 3,
      'd': {
        'since': null,
        'activities': [activity],
        'status': 'online',
        'afk': false,
      },
    };
  }

  Future<String> _resolveAsset(String? url) async {
    if (url == null || url.isEmpty || _token == null || _token!.isEmpty) {
      return 'app_icon';
    }
    final cached = _imageAssetCache[url];
    if (cached != null) return cached;

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
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty && data[0]['external_asset_path'] != null) {
          final path = 'mp:${data[0]['external_asset_path']}';
          _imageAssetCache[url] = path;
          return path;
        }
      }
    } catch (_) {
      // Fall back to default app icon if resolution fails.
    }

    return 'app_icon';
  }

  String _joinNonEmpty(List<String?> parts) =>
      parts.where((p) => p != null && p.isNotEmpty).join(' • ');

  String? _progressText(int posMs, int durMs) {
    if (posMs <= 0 || durMs <= 0) return null;
    return '${_fmtDuration(Duration(milliseconds: posMs))} / '
        '${_fmtDuration(Duration(milliseconds: durMs))}';
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h.toString().padLeft(2, '0')}:$m:$s' : '$m:$s';
  }
}

/// Desktop IPC wrapper around FlutterDiscordRPC.
class _DesktopRpc {
  final _log = AppLogger.scope(_DesktopRpc);
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init(String appId) async {
    if (_initialized) return;
    try {
      await FlutterDiscordRPC.initialize(appId);
      _initialized = true;
      _log.s('Desktop IPC initialized');
    } catch (e, s) {
      _log.e('Failed to init Desktop IPC', e, s);
    }
  }

  Future<void> connect() async {
    if (!_initialized) return;
    try {
      await FlutterDiscordRPC.instance.connect();
    } catch (e, s) {
      _log.e('Desktop IPC connect failed', e, s);
    }
  }

  void setActivity(RPCActivity activity) {
    if (!_initialized) return;
    try {
      FlutterDiscordRPC.instance.setActivity(activity: activity);
    } catch (e, s) {
      _log.e('Failed to set desktop activity', e, s);
    }
  }

  void clearActivity() {
    if (!_initialized) return;
    try {
      FlutterDiscordRPC.instance.clearActivity();
    } catch (e, s) {
      _log.e('Failed to clear desktop activity', e, s);
    }
  }

  void disconnect() {
    if (!_initialized) return;
    try {
      FlutterDiscordRPC.instance.disconnect();
    } catch (e, s) {
      _log.e('Desktop IPC disconnect failed', e, s);
    }
  }
}

/// Manages the Discord Gateway WebSocket connection and heartbeat.
class _GatewayConnection {
  static const String _gatewayUrl =
      'wss://gateway.discord.gg/?v=10&encoding=json';

  final _log = AppLogger.scope(_GatewayConnection);
  final String? Function() token;
  final VoidCallback onReady;

  _GatewayConnection({required this.token, required this.onReady});

  WebSocket? _socket;
  Timer? _heartbeatTimer;
  int? _heartbeatInterval;
  int? _seq;
  bool _ackReceived = true;
  bool _connected = false;
  bool _connecting = false;

  bool get isConnected => _connected;

  Future<void> connect() async {
    if (_connecting) return;
    _connecting = true;

    try {
      await _close();
      _socket = await WebSocket.connect(_gatewayUrl);
      _socket!.listen(
        _onMessage,
        onError: (e) {
          _log.e('Gateway socket error', e);
          _connected = false;
        },
        onDone: () {
          _log.w('Gateway connection closed');
          _connected = false;
          _heartbeatTimer?.cancel();
        },
      );
    } catch (e, s) {
      _log.e('Failed to connect Gateway', e, s);
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _seq = null;
    _connected = false;
    await _close();
  }

  void send(Map<String, dynamic> payload) {
    try {
      _socket?.add(jsonEncode(payload));
    } catch (e, s) {
      _log.e('Failed to send Gateway payload', e, s);
      _connected = false;
    }
  }

  void sendPresenceUpdate(Map<String, dynamic> presenceData) {
    send({
      'op': 3,
      'd': {'since': null, 'afk': false, ...presenceData},
    });
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String);
      final op = data['op'] as int?;
      _seq = data['s'] as int? ?? _seq;

      switch (op) {
        case 10: // HELLO
          _heartbeatInterval = data['d']['heartbeat_interval'] as int?;
          _ackReceived = true;
          _identify();
          _startHeartbeat();
          break;
        case 0: // DISPATCH
          if (data['t'] == 'READY') {
            _connected = true;
            _log.s('Gateway READY');
            onReady();
          }
          break;
        case 11: // HEARTBEAT ACK
          _ackReceived = true;
          break;
      }
    } catch (e, s) {
      _log.e('Error handling Gateway message', e, s);
    }
  }

  void _identify() {
    final t = token();
    if (t == null || t.isEmpty) return;
    send({
      'op': 2,
      'd': {
        'token': t,
        'properties': {
          '\$os': Platform.operatingSystem,
          '\$browser': 'ShonenX',
          '\$device': 'ShonenX Client',
        },
        'presence': {'status': 'online', 'afk': false},
      },
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    final interval = _heartbeatInterval;
    if (interval == null) return;
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: interval),
      (_) => _sendHeartbeat(),
    );
  }

  void _sendHeartbeat() {
    if (!_ackReceived) {
      _log.w('Heartbeat ACK missed, reconnecting');
      connect();
      return;
    }
    _ackReceived = false;
    send({'op': 1, 'd': _seq});
  }

  Future<void> _close() async {
    try {
      await _socket?.close();
    } catch (_) {
      // Socket may already be closed.
    }
    _socket = null;
  }
}
