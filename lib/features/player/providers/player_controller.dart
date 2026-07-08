import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/http_x.dart';

import 'package:shonenx/core/utils/extensions.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/player/providers/aniskip_prefs_provider.dart';
import 'package:shonenx/features/player/providers/aniskip_provider.dart';
import 'package:shonenx/features/player/providers/subtitle_prefs_provider.dart';
import 'package:shonenx/features/tracking/engine/sync_engine.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

const _keepError = Object();

class PlayerState {
  final List<VideoServer> servers;
  final List<VideoStream> streams;
  final List<SubtitleTrack> subtitles;
  final List<VideoStream> qualities;
  final VideoServer? activeServer;
  final VideoStream? activeStream;
  final VideoStream? activeQuality;
  final SubtitleTrack? activeSubtitle;
  final UnifiedEpisode? activeEpisode;
  final double playbackSpeed;
  final bool isLoading;
  final String? error;

  const PlayerState({
    this.servers = const [],
    this.streams = const [],
    this.subtitles = const [],
    this.qualities = const [],
    this.activeServer,
    this.activeEpisode,
    this.activeSubtitle,
    this.activeStream,
    this.activeQuality,
    this.playbackSpeed = 1.0,
    this.isLoading = true,
    this.error,
  });

  PlayerState copyWith({
    List<VideoServer>? servers,
    List<VideoStream>? streams,
    List<SubtitleTrack>? subtitles,
    List<VideoStream>? qualities,
    VideoServer? activeServer,
    VideoStream? activeStream,
    VideoStream? activeQuality,
    SubtitleTrack? activeSubtitle,
    UnifiedEpisode? activeEpisode,
    double? playbackSpeed,
    bool? isLoading,
    Object? error = _keepError,
  }) {
    return PlayerState(
      servers: servers ?? this.servers,
      streams: streams ?? this.streams,
      subtitles: subtitles ?? this.subtitles,
      qualities: qualities ?? this.qualities,
      activeServer: activeServer ?? this.activeServer,
      activeStream: activeStream ?? this.activeStream,
      activeQuality: activeQuality ?? this.activeQuality,
      activeSubtitle: activeSubtitle ?? this.activeSubtitle,
      activeEpisode: activeEpisode ?? this.activeEpisode,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _keepError) ? this.error : error as String?,
    );
  }
}

class PlayerController extends Notifier<PlayerState> {
  Timer? _progressTimer;
  UnifiedMedia? _media;
  UnifiedMedia? get media => _media;
  AnimeSource? _source;
  late ScreenshotController _screenshot;

  // Thumbnail caching
  String? _cachedThumbnail;
  DateTime? _lastThumbnailTime;
  bool _initialCaptureDone = false;
  static const _thumbnailRefreshInterval = Duration(minutes: 2);

  final Set<SkipType> _alreadyAutoSkipped = {};

  // Subscriptions
  ProviderSubscription<Duration>? _positionSubscription;

  // Smart Memory
  String? _preferredServerId;
  ServerType? _preferredServerType;
  String? _preferredQuality;
  String? _preferredSubtitleLang = 'eng';
  String? _preferredAudioLang;

  @override
  PlayerState build() {
    ref.onDispose(() {
      _positionSubscription?.close();
      _progressTimer?.cancel();
    });

    final prefs = ref.read(playerPrefsProvider);
    _preferredQuality = prefs.defaultQuality;
    _preferredSubtitleLang = prefs.defaultSubtitleLang;
    _preferredAudioLang = prefs.defaultAudioLang;
    _preferredServerType = prefs.defaultServerType == ServerType.unknown
        ? null
        : prefs.defaultServerType;

    ref.listen(subtitlePrefsProvider, (prev, current) {
      if (prev?.useCustomSubtitle != current.useCustomSubtitle) {
        _applyNativeSubtitle(state.activeSubtitle);
      }
    });

    ref.listen(videoEngineStateProvider.select((s) => s.audioTracks), (
      prev,
      current,
    ) {
      if (_preferredAudioLang != null &&
          _preferredAudioLang != 'Auto' &&
          current.isNotEmpty) {
        final match = current.firstWhereOrNull(
          (t) =>
              t.language?.toLowerCase().contains(
                    _preferredAudioLang!.toLowerCase(),
                  ) ==
                  true ||
              t.label.toLowerCase().contains(
                    _preferredAudioLang!.toLowerCase(),
                  ) ==
                  true ||
              _preferredAudioLang!.toLowerCase().contains(
                    t.language?.toLowerCase() ?? '---',
                  ) ==
                  true ||
              _preferredAudioLang!.toLowerCase().contains(
                    t.label.toLowerCase(),
                  ) ==
                  true,
        );
        if (match != null) {
          ref.read(videoEngineProvider).setAudioTrack(match);
        }
      } else if (_preferredAudioLang == 'Auto') {
        ref.read(videoEngineProvider).setAudioTrack(AudioTrack.auto);
      }
    });

    return const PlayerState();
  }

  Future<void> _applyNativeSubtitle(SubtitleTrack? subtitle) async {
    final prefs = ref.read(subtitlePrefsProvider);
    try {
      if (prefs.useCustomSubtitle || subtitle?.url.isEmpty == true) {
        await ref.read(videoEngineProvider).setSubtitle(null);
      } else {
        await ref.read(videoEngineProvider).setSubtitle(subtitle);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to switch subtitle: $e');
    }
  }

  Future<void> initialize(
    PlayerMode mode, {
    required ScreenshotController screenshot,
  }) async {
    _screenshot = screenshot;

    // Todo: Load smart memory from player prefs

    if (mode is PlayerModeOnline) {
      _source = ref.read(animeSourceProvider(mode.sourceInfo));
      _media = mode.media;

      try {
        final mediaTitle = mode.media.title.availableTitle;
        if (mediaTitle.isNotEmpty) {
          ref
              .read(
                mediaPreferenceProvider(
                  MatchArgs(mediaTitle: mediaTitle, type: mode.media.type),
                ).notifier,
              )
              .saveWatchPreference(
                sourceInfo: mode.sourceInfo,
                mediaId: mode.media.providerId ?? mode.media.id,
                mediaTitle: mediaTitle,
              );
        }
      } catch (_) {}

      await _loadData(mode.episode, startPosition: mode.startPosition);
    } else if (mode is PlayerModeOffline) {
      _source = null;
      _media = null;
      await _loadOfflineData(mode);
    }
  }

  Future<void> _loadOfflineData(PlayerModeOffline mode) async {
    state = state.copyWith(isLoading: true, error: null, activeEpisode: null);

    try {
      final activeStream = VideoStream(
        url: mode.filePath,
        quality: 'Local',
        subtitles: [],
      );

      state = state.copyWith(
        servers: [],
        activeServer: null,
        streams: [activeStream],
        activeStream: activeStream,
        qualities: [activeStream],
        activeQuality: activeStream,
        subtitles: [SubtitleTrack.none],
        activeSubtitle: SubtitleTrack.none,
        isLoading: false,
      );

      await ref
          .read(videoEngineProvider)
          .initialize(activeStream, subtitle: null, startAt: Duration.zero);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> changeServer(VideoServer newServer) async {
    final active = state.activeServer;
    if (active != null &&
        newServer.id == active.id &&
        newServer.type == active.type) {
      return;
    }

    _preferredServerId = newServer.id;
    _preferredServerType = newServer.type;
    ref.read(playerPrefsProvider.notifier).setDefaultServerType(newServer.type);

    final currentPos = ref.read(videoEngineProvider).currentPosition;
    await _loadData(
      state.activeEpisode!,
      server: newServer,
      startPosition: currentPos,
    );
  }

  Future<void> changeServerType({bool? isDub, bool toggle = true}) async {
    ServerType targetType = isDub == true ? ServerType.dub : ServerType.sub;
    if (toggle && isDub == null) {
      targetType = state.activeServer?.type == ServerType.dub
          ? ServerType.sub
          : ServerType.dub;
    }
    final server = state.servers.firstWhereOrNull((s) => s.type == targetType);
    if (server == null) return;
    await changeServer(server);
  }

  Future<void> loadEpisode(
    UnifiedEpisode newEpisode, {
    bool force = false,
  }) async {
    _alreadyAutoSkipped.clear();
    _cachedThumbnail = null;
    _lastThumbnailTime = null;
    _initialCaptureDone = false;
    await _loadData(newEpisode, force: force);
  }

  Future<void> skipEpisode({bool forward = true}) async {
    if (_media == null) return;
    final episodes = await ref.read(
      episodesListProvider(
        MatchArgs.fromMedia(_media!),
      ).selectAsync((s) => s.episodes),
    );
    final targetNumber = state.activeEpisode!.number + (forward ? 1 : -1);
    if (targetNumber < 1 || targetNumber > episodes.length) return;
    await loadEpisode(episodes.firstWhere((e) => e.number == targetNumber));
  }

  bool _matchesQuality(String candidate, String target) {
    final c = candidate.toLowerCase();
    final t = target.toLowerCase();
    if (c == t) return true;
    if (t == 'auto') return c == 'auto';
    if (c == 'auto') return false;

    final cleanTarget = t.replaceAll('p', '').trim();
    if (cleanTarget.isNotEmpty && c.contains(cleanTarget)) {
      return true;
    }
    return c.contains(t) || t.contains(c);
  }

  Future<void> _loadData(
    UnifiedEpisode episode, {
    VideoServer? server,
    Duration? startPosition,
    bool force = false,
  }) async {
    if (_source == null) return;
    if (state.activeEpisode?.id != episode.id) {
      _alreadyAutoSkipped.clear();
    }
    state = state.copyWith(
      isLoading: true,
      error: null,
      activeEpisode: episode,
    );

    try {
      List<VideoServer> servers = state.servers;
      if (force || (server == null || state.activeEpisode?.id != episode.id)) {
        servers = await _source!.getServers(episode.id);
        if (servers.isEmpty) throw Exception('No servers available.');
      }

      // Video Server Selection
      VideoServer activeServer = servers.first;
      if (server != null) {
        activeServer = server;
      } else {
        // Priority 1: Exact match (Same ID and Same Type)
        final exactMatch = servers.firstWhereOrNull(
          (s) => s.id == _preferredServerId && s.type == _preferredServerType,
        );

        if (exactMatch != null) {
          activeServer = exactMatch;
        } else {
          // Priority 2: Type match (ID didn't match, but we have the preferred type e.g., Dub)
          final typeMatch = servers.firstWhereOrNull(
            (s) => s.type == _preferredServerType,
          );
          if (typeMatch != null) {
            activeServer = typeMatch;
          }
        }
      }

      final streams = await _source!.getSources(episode.id, activeServer);
      if (streams.isEmpty) throw Exception('No streams available.');

      // Video Stream (mirror) Selection
      VideoStream activeStream = streams.first;
      if (_preferredQuality != null && _preferredQuality != 'Auto') {
        final qualityMatch = streams.firstWhereOrNull(
          (s) => _matchesQuality(s.quality, _preferredQuality!),
        );
        if (qualityMatch != null) activeStream = qualityMatch;
      }

      // Fetch qualities for the activeStream
      final httpClient = ref.read(httpClientProvider);
      final qualitiesList = <VideoStream>[
        activeStream.copyWith(quality: 'Auto'),
      ];

      try {
        final parsedQualities = await httpClient.splitM3U8(
          activeStream.url,
          headers: activeStream.headers,
        );
        for (final q in parsedQualities) {
          qualitiesList.add(
            VideoStream(
              url: q.url,
              headers: activeStream.headers,
              quality: q.quality,
              subtitles: activeStream.subtitles,
            ),
          );
        }
      } catch (_) {
        // Fall back gracefully if parsing fails
      }

      // Select active quality from parsed list
      VideoStream activeQuality = qualitiesList.first;
      if (_preferredQuality != null && _preferredQuality != 'Auto') {
        final qualityMatch = qualitiesList.firstWhereOrNull(
          (s) => _matchesQuality(s.quality, _preferredQuality!),
        );
        if (qualityMatch != null) activeQuality = qualityMatch;
      }

      final subtitles = [SubtitleTrack.none, ...activeStream.subtitles];

      // Subtitle Selection
      SubtitleTrack? activeSubtitle = subtitles.first;
      if (_preferredSubtitleLang != null &&
          _preferredSubtitleLang != 'Off' &&
          subtitles.isNotEmpty) {
        final subMatch = subtitles.firstWhereOrNull(
          (s) =>
              s.language.toLowerCase().contains(
                _preferredSubtitleLang!.toLowerCase(),
              ) ||
              _preferredSubtitleLang!.toLowerCase().contains(
                s.language.toLowerCase(),
              ),
        );
        if (subMatch != null) activeSubtitle = subMatch;
      } else if (_preferredSubtitleLang == 'Off') {
        activeSubtitle = SubtitleTrack.none;
      }

      state = state.copyWith(
        servers: servers,
        activeServer: activeServer,
        streams: streams,
        activeStream: activeStream,
        qualities: qualitiesList,
        activeQuality: activeQuality,
        subtitles: subtitles,
        activeSubtitle: activeSubtitle,
        isLoading: false,
      );

      await ref
          .read(videoEngineProvider)
          .initialize(
            activeQuality,
            subtitle:
                ref.read(subtitlePrefsProvider).useCustomSubtitle ||
                    activeSubtitle.url.isEmpty == true
                ? null
                : activeSubtitle,
            startAt: startPosition,
          );

      _startProgressTracker();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> changeStream(VideoStream newStream) async {
    final engine = ref.read(videoEngineProvider);
    final currentPos = engine.currentPosition;

    state = state.copyWith(
      isLoading: true,
      activeStream: newStream,
      subtitles: [...newStream.subtitles, SubtitleTrack.none],
      activeSubtitle: newStream.subtitles.firstOrNull ?? SubtitleTrack.none,
      error: null,
    );

    try {
      final httpClient = ref.read(httpClientProvider);
      final newQualities = <VideoStream>[newStream.copyWith(quality: 'Auto')];

      try {
        final parsedQualities = await httpClient.splitM3U8(
          newStream.url,
          headers: newStream.headers,
        );
        for (final q in parsedQualities) {
          newQualities.add(
            VideoStream(
              url: q.url,
              headers: newStream.headers,
              quality: q.quality,
              subtitles: newStream.subtitles,
            ),
          );
        }
      } catch (_) {}

      VideoStream activeQuality = newQualities.first;
      if (_preferredQuality != null && _preferredQuality != 'Auto') {
        final qualityMatch = newQualities.firstWhereOrNull(
          (s) => _matchesQuality(s.quality, _preferredQuality!),
        );
        if (qualityMatch != null) activeQuality = qualityMatch;
      }

      state = state.copyWith(
        qualities: newQualities,
        activeQuality: activeQuality,
        isLoading: false,
      );

      await engine.initialize(
        activeQuality,
        subtitle: ref.read(subtitlePrefsProvider).useCustomSubtitle
            ? null
            : newStream.subtitles.firstOrNull,
        startAt: currentPos,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to switch stream: $e',
      );
    }
  }

  Future<void> changeQuality(VideoStream newQuality) async {
    if (state.activeQuality?.quality == newQuality.quality &&
        state.activeQuality?.url == newQuality.url) {
      return;
    }

    _preferredQuality = newQuality.quality;
    ref
        .read(playerPrefsProvider.notifier)
        .setDefaultQuality(newQuality.quality);

    final engine = ref.read(videoEngineProvider);
    final currentPos = engine.currentPosition;

    state = state.copyWith(
      activeQuality: newQuality,
      isLoading: true,
      error: null,
    );

    try {
      await engine.initialize(
        newQuality,
        subtitle:
            ref.read(subtitlePrefsProvider).useCustomSubtitle ||
                state.activeSubtitle?.url.isEmpty == true
            ? null
            : state.activeSubtitle,
        startAt: currentPos,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to switch quality: $e',
      );
    }
  }

  Future<void> changeSubtitle(SubtitleTrack? newSubtitle) async {
    if (newSubtitle != null && newSubtitle.url.isNotEmpty) {
      _preferredSubtitleLang = newSubtitle.language;
      ref
          .read(playerPrefsProvider.notifier)
          .setDefaultSubtitleLang(newSubtitle.language);
    } else if (newSubtitle != null) {
      _preferredSubtitleLang = 'Off';
      ref.read(playerPrefsProvider.notifier).setDefaultSubtitleLang('Off');
    }

    state = state.copyWith(activeSubtitle: newSubtitle, error: null);
    await _applyNativeSubtitle(newSubtitle);
  }

  Future<void> changeAudioTrack(AudioTrack track) async {
    if (track.language != null && track.language!.isNotEmpty) {
      _preferredAudioLang = track.language;
      ref
          .read(playerPrefsProvider.notifier)
          .setDefaultAudioLang(track.language!);
    } else if (track.id != 'auto' && track.id != 'no') {
      _preferredAudioLang = track.label;
      ref.read(playerPrefsProvider.notifier).setDefaultAudioLang(track.label);
    } else if (track.id == 'auto') {
      _preferredAudioLang = 'Auto';
      ref.read(playerPrefsProvider.notifier).setDefaultAudioLang('Auto');
    }
    await ref.read(videoEngineProvider).setAudioTrack(track);
  }

  Future<void> changeSpeed(double speed) async {
    state = state.copyWith(playbackSpeed: speed);
    await ref.read(videoEngineProvider).setSpeed(speed);
  }

  void setupAutoSkipListener(AniSkipArgs? args) {
    _positionSubscription?.close();

    final prefs = ref.read(aniskipPrefsProvider);
    final skips = ref.read(aniSkipProvider(args)).value ?? [];

    _positionSubscription = ref.listen(
      videoEngineStateProvider.select((s) => s.position),
      (previous, current) {
        final seconds = current.inSeconds;

        for (final skip in skips) {
          final mode = prefs.mode(skip.type);

          if (mode != SkipMode.auto) continue;

          final isInside = seconds >= skip.startTime && seconds < skip.endTime;

          if (isInside) {
            if (_alreadyAutoSkipped.add(skip.type)) {
              ref
                  .read(videoEngineProvider)
                  .seekTo(Duration(seconds: skip.endTime.ceil()));
            }
          }
        }
      },
    );
  }

  Future<void> _startProgressTracker() async {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async => await _saveCurrentProgress(),
    );
  }

  Future<String?> _captureThumbnail() async {
    try {
      final image = await _screenshot.capture(pixelRatio: 0.5);
      if (image != null) {
        _cachedThumbnail = base64Encode(image);
        _lastThumbnailTime = DateTime.now();
      }
    } catch (_) {}
    return _cachedThumbnail;
  }

  bool get _shouldCaptureThumbnail {
    if (!_initialCaptureDone) return true;
    if (_lastThumbnailTime == null) return true;
    return DateTime.now().difference(_lastThumbnailTime!) >=
        _thumbnailRefreshInterval;
  }

  Future<void> captureExitThumbnail() async {
    await _captureThumbnail();
    await _saveCurrentProgress(skipCapture: true);
  }

  Future<void> _saveCurrentProgress({bool skipCapture = false}) async {
    if (!ref.mounted) {
      _progressTimer?.cancel();
      return;
    }

    if (state.activeServer == null) return;

    final engine = ref.read(videoEngineProvider);
    final position = engine.currentPosition;
    final duration = engine.currentDuration;
    if (position == Duration.zero || duration == Duration.zero) return;

    if (_media == null) return;

    // Capture thumbnail only when needed
    if (!skipCapture && _shouldCaptureThumbnail) {
      await _captureThumbnail();
      _initialCaptureDone = true;
    }

    final thumbnail = _cachedThumbnail ?? '';

    final entry = WatchHistoryEntry()
      ..episodeNumber = state.activeEpisode?.number ?? 1
      ..totalEpisodes = _media!.episodes
      ..animeId = _media!.id
      ..animeIdMal = _media!.idMal
      ..animeTitle = _media!.title.availableTitle
      ..episodeTitle = state.activeEpisode?.title
      ..cover = _media!.cover
      ..banner = _media!.banner
      ..thumbnailUrl = thumbnail.isNotEmpty
          ? thumbnail
          : state.activeEpisode?.thumbnailUrl
      ..positionInMilliseconds = position.inMilliseconds
      ..durationInMilliseconds = duration.inMilliseconds
      ..sourceId = _source?.sourceInfo.id ?? _media!.sourceId
      ..sourceName = _source?.sourceInfo.name ?? _media!.sourceName
      ..providerId = _media!.providerId != _media!.id
          ? _media!.providerId
          : null
      ..lastUpdated = DateTime.now();

    ref.read(watchHistoryRepositoryProvider).saveProgress(entry);

    if (_source != null) {
      try {
        final mediaTitle = _media!.title.availableTitle;
        if (mediaTitle.isNotEmpty) {
          ref
              .read(
                mediaPreferenceProvider(
                  MatchArgs(mediaTitle: mediaTitle, type: _media!.type),
                ).notifier,
              )
              .saveWatchPreference(
                sourceInfo: _source!.sourceInfo,
                mediaId: _media!.providerId ?? _media!.id,
                mediaTitle: mediaTitle,
              );
        }
      } catch (_) {}
    }

    if (state.activeEpisode != null) {
      ref
          .read(syncEngineProvider)
          .processPlayback(
            media: _media!,
            episodeNumber: state.activeEpisode!.number,
            position: position,
            duration: duration,
          );
    }
  }
}

final playerControllerProvider =
    NotifierProvider.autoDispose<PlayerController, PlayerState>(
      PlayerController.new,
    );
