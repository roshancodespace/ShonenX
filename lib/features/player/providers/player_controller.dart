import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import 'package:shonenx/core/utils/extensions.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/providers/active_engine_provider.dart';
import 'package:shonenx/features/player/providers/aniskip_prefs_provider.dart';
import 'package:shonenx/features/player/providers/aniskip_provider.dart';
import 'package:shonenx/features/player/providers/subtitle_prefs_provider.dart';
import 'package:shonenx/features/tracking/engine/sync_engine.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';

const _keepError = Object();

class PlayerState {
  final List<VideoServer> servers;
  final List<VideoStream> streams;
  final List<SubtitleTrack> subtitles;
  final VideoServer? activeServer;
  final VideoStream? activeStream;
  final SubtitleTrack? activeSubtitle;
  final UnifiedEpisode? activeEpisode;
  final bool isLoading;
  final String? error;

  const PlayerState({
    this.servers = const [],
    this.streams = const [],
    this.subtitles = const [],
    this.activeServer,
    this.activeEpisode,
    this.activeSubtitle,
    this.activeStream,
    this.isLoading = true,
    this.error,
  });

  PlayerState copyWith({
    List<VideoServer>? servers,
    List<VideoStream>? streams,
    List<SubtitleTrack>? subtitles,
    VideoServer? activeServer,
    VideoStream? activeStream,
    SubtitleTrack? activeSubtitle,
    UnifiedEpisode? activeEpisode,
    bool? isLoading,
    Object? error = _keepError,
  }) {
    return PlayerState(
      servers: servers ?? this.servers,
      streams: streams ?? this.streams,
      subtitles: subtitles ?? this.subtitles,
      activeServer: activeServer ?? this.activeServer,
      activeStream: activeStream ?? this.activeStream,
      activeSubtitle: activeSubtitle ?? this.activeSubtitle,
      activeEpisode: activeEpisode ?? this.activeEpisode,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _keepError) ? this.error : error as String?,
    );
  }
}

class PlayerController extends Notifier<PlayerState> {
  Timer? _progressTimer;
  late UnifiedMedia _media;
  late AnimeSource _source;
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
  String? _preferredSubtitleLang;

  @override
  PlayerState build() {
    ref.onDispose(() {
      _positionSubscription?.close();
      _progressTimer?.cancel();
    });

    ref.listen(subtitlePrefsProvider, (prev, current) {
      if (prev?.useCustomSubtitle != current.useCustomSubtitle) {
        _applyNativeSubtitle(state.activeSubtitle);
      }
    });

    return const PlayerState();
  }

  Future<void> _applyNativeSubtitle(SubtitleTrack? subtitle) async {
    final prefs = ref.read(subtitlePrefsProvider);
    try {
      if (prefs.useCustomSubtitle) {
        await ref.read(videoEngineProvider).setSubtitle(null);
      } else {
        await ref.read(videoEngineProvider).setSubtitle(subtitle);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to switch subtitle: $e');
    }
  }

  Future<void> initialize(
    AnimeSource source, {
    required ScreenshotController screenshot,
    required UnifiedEpisode episode,
    required UnifiedMedia media,
    Duration? startPosition,
  }) async {
    _source = source;
    _media = media;
    _screenshot = screenshot;

    // Todo: Load smart memory from player prefs

    await _loadData(episode, startPosition: startPosition);
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
    final episodes = await ref.read(
      episodesListProvider(
        _media.title.availableTitle,
      ).selectAsync((s) => s.episodes),
    );
    final targetNumber = state.activeEpisode!.number + (forward ? 1 : -1);
    if (targetNumber < 1 || targetNumber > episodes.length) return;
    await loadEpisode(episodes.firstWhere((e) => e.number == targetNumber));
  }

  Future<void> _loadData(
    UnifiedEpisode episode, {
    VideoServer? server,
    Duration? startPosition,
    bool force = false,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      activeEpisode: episode,
    );

    try {
      List<VideoServer> servers = state.servers;
      if (force || (server == null || state.activeEpisode?.id != episode.id)) {
        servers = await _source.getServers(episode.id);
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

      final streams = await _source.getSources(episode.id, activeServer);
      if (streams.isEmpty) throw Exception('No streams available.');

      // Video Stream Selection
      VideoStream activeStream = streams.first;
      if (_preferredQuality != null) {
        final qualityMatch = streams.firstWhereOrNull(
          (s) => s.quality == _preferredQuality,
        );
        if (qualityMatch != null) activeStream = qualityMatch;
      }

      final subtitles = activeStream.subtitles;

      // Subtitle Selection
      SubtitleTrack? activeSubtitle = subtitles.firstOrNull;
      if (_preferredSubtitleLang != null && subtitles.isNotEmpty) {
        final subMatch = subtitles.firstWhereOrNull(
          (s) => s.language == _preferredSubtitleLang,
        );
        if (subMatch != null) activeSubtitle = subMatch;
      }

      state = state.copyWith(
        servers: servers,
        activeServer: activeServer,
        streams: streams,
        activeStream: activeStream,
        subtitles: subtitles,
        activeSubtitle: activeSubtitle,
        isLoading: false,
      );

      await ref
          .read(videoEngineProvider)
          .initialize(
            activeStream,
            subtitle: ref.read(subtitlePrefsProvider).useCustomSubtitle
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
    _preferredQuality = newStream.quality;

    final engine = ref.read(videoEngineProvider);
    final currentPos = engine.currentPosition;

    state = state.copyWith(
      activeStream: newStream,
      subtitles: newStream.subtitles,
      activeSubtitle: newStream.subtitles.firstOrNull,
      error: null,
    );

    try {
      await engine.initialize(
        newStream,
        subtitle: ref.read(subtitlePrefsProvider).useCustomSubtitle
            ? null
            : newStream.subtitles.firstOrNull,
        startAt: currentPos,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to switch stream: $e');
    }
  }

  Future<void> changeSubtitle(SubtitleTrack? newSubtitle) async {
    if (newSubtitle != null) {
      _preferredSubtitleLang = newSubtitle.language;
    }

    state = state.copyWith(activeSubtitle: newSubtitle, error: null);
    await _applyNativeSubtitle(newSubtitle);
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
          } else {
            _alreadyAutoSkipped.remove(skip.type);
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

    // Capture thumbnail only when needed
    if (!skipCapture && _shouldCaptureThumbnail) {
      await _captureThumbnail();
      _initialCaptureDone = true;
    }

    final thumbnail = _cachedThumbnail ?? '';

    final entry = WatchHistoryEntry()
      ..episodeNumber = state.activeEpisode?.number ?? 1
      ..totalEpisodes = _media.episodes
      ..animeId = _media.id
      ..animeIdMal = _media.idMal
      ..animeTitle = _media.title.availableTitle
      ..episodeTitle = state.activeEpisode?.title
      ..cover = _media.cover
      ..banner = _media.banner
      ..thumbnailUrl = thumbnail.isNotEmpty
          ? thumbnail
          : state.activeEpisode?.thumbnailUrl
      ..positionInMilliseconds = position.inMilliseconds
      ..durationInMilliseconds = duration.inMilliseconds
      ..lastUpdated = DateTime.now();

    ref.read(watchHistoryRepositoryProvider).saveProgress(entry);

    if (state.activeEpisode != null) {
      ref
          .read(syncEngineProvider)
          .processPlayback(
            media: _media,
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
