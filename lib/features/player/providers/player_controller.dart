import 'dart:async';

import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:collection/collection.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discord/providers/discord_rpc_provider.dart';
import 'package:shonenx/features/player/data/aniskip_resolver.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/player/providers/aniskip_prefs_provider.dart';
import 'package:shonenx/features/player/providers/aniskip_provider.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';
import 'package:shonenx/features/player/providers/progress_tracker.dart';
import 'package:shonenx/features/player/providers/selection_resolver.dart';
import 'package:shonenx/features/player/providers/subtitle_prefs_provider.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/engine/media_kit/media_kit_engine.dart';
import 'package:shonenx/features/player/engine/better_player/better_player_engine.dart';
import 'package:shonenx/features/player/providers/media_kit_prefs_provider.dart';
import 'package:shonenx/features/player/providers/better_player_prefs_provider.dart';
import 'package:shonenx/features/player/utils/screenshot_helper.dart';
import 'package:shonenx/core/network/stream_server/stream_server.dart';
import 'package:shonenx/core/network/stream_server/hls/hls_stream.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

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
  final int? malId;

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
    this.malId,
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
    String? error,
    bool clearError = false,
    int? malId,
    bool clearMalId = false,
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
      error: clearError ? null : (error ?? this.error),
      malId: clearMalId ? null : (malId ?? this.malId),
    );
  }
}

class PlayerController extends Notifier<PlayerState> {
  UnifiedMedia? _media;
  UnifiedMedia? get media => _media;
  int? get malId => state.malId;
  AnimeSource? _source;
  late ScreenshotController _screenshotController;

  late final SelectionResolver _resolver;
  late final ProgressTracker _progressTracker;

  late VideoEngine _engine;
  VideoEngine get engine => _engine;

  final Set<SkipType> _alreadyAutoSkipped = {};

  List<AniSkipStamp> _currentSkips = [];

  bool _isSkipping = false;

  bool _endingSkipCooldown = false;
  Timer? _endingSkipCooldownTimer;

  bool _isDisposed = false;
  bool _isNativeSubtitleDisabled = false;

  String? _currentHlsStreamId;

  @override
  PlayerState build() {
    _isDisposed = false;

    final prefs = ref.read(playerPrefsProvider);
    _resolver = SelectionResolver(
      preferredQuality: prefs.defaultQuality,
      preferredSubtitleLang: prefs.defaultSubtitleLang,
      preferredAudioLang: prefs.defaultAudioLang,
      preferredServerType: prefs.defaultServerType == ServerType.unknown
          ? null
          : prefs.defaultServerType,
    );
    _progressTracker = ProgressTracker(ref);

    _progressTracker.start(
      () => ProgressContext(
        media: _media,
        activeEpisode: state.activeEpisode,
        activeServer: state.activeServer,
        sourceInfo: _source?.sourceInfo,
        engine: _engine,
      ),
    );

    final playerType = ref.watch(
      playerPrefsProvider.select((s) => s.playerType),
    );
    if (playerType == PlayerType.mediakit) {
      final prefs = ref.read(mediaKitPrefsProvider);
      _engine = MediaKitEngine(prefs);
      ref.listen(mediaKitPrefsProvider, (_, next) {
        (_engine as MediaKitEngine).updatePrefs(next);
      });
    } else {
      final prefs = ref.read(betterPlayerPrefsProvider);
      _engine = BetterPlayerEngine(prefs);
      ref.listen(betterPlayerPrefsProvider, (_, next) {
        (_engine as BetterPlayerEngine).updatePrefs(next);
      });
    }

    ref.onDispose(() {
      _isDisposed = true;
      WakelockPlus.disable();
      _endingSkipCooldownTimer?.cancel();
      _progressTracker.cancel();
      _engine.dispose();
      unawaited(TorrentStreamResolver.dispose());
    });

    ref.listen(subtitlePrefsProvider, (prev, current) {
      if (prev?.useCustomSubtitle != current.useCustomSubtitle) {
        _applyNativeSubtitle(state.activeSubtitle);
      }
    });

    _engine.audioTracksNotifier.addListener(() {
      if (_isDisposed) return;
      final tracks = _engine.audioTracksNotifier.value;
      if (tracks.isNotEmpty) {
        final match = _resolver.resolveAudioTrack(tracks);
        if (match != null) {
          _engine.setAudioTrack(match);
        }
      }
    });

    _engine.statusNotifier.addListener(() {
      if (_isDisposed) return;
      final status = _engine.statusNotifier.value;
      if (status == PlayerStatus.playing) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
      _updateDiscordRpc();
    });

    _engine.positionNotifier.addListener(() {
      if (_isDisposed) return;
      _onPlaybackProgress(
        _engine.positionNotifier.value,
        _engine.durationNotifier.value,
      );
    });

    _engine.durationNotifier.addListener(() {
      if (_isDisposed) return;
      final durationSec = _engine.durationNotifier.value.inSeconds;
      if (durationSec >= 50) {
        _fetchSkipsIfNeeded(durationSec: durationSec);
      }
    });

    _engine.subtitleTracksNotifier.addListener(() {
      if (_isDisposed) return;
      final nativeTracks = _engine.subtitleTracksNotifier.value;
      if (nativeTracks.isEmpty) return;

      final currentSubs = List<SubtitleTrack>.from(state.subtitles);
      bool changed = false;

      for (final nt in nativeTracks) {
        if (!currentSubs.any((s) => s.url == nt.url)) {
          currentSubs.add(nt);
          changed = true;
        }
      }

      if (changed) {
        state = state.copyWith(subtitles: currentSubs);

        if (state.activeSubtitle == SubtitleTrack.none ||
            state.activeSubtitle == null) {
          final newActive = _resolver.resolveSubtitle(currentSubs);
          if (newActive != SubtitleTrack.none) {
            changeSubtitle(newActive);
          }
        }
      }
    });

    return const PlayerState();
  }

  void triggerEndingSkipCooldown() {
    _endingSkipCooldown = true;
    _endingSkipCooldownTimer?.cancel();
    _endingSkipCooldownTimer = Timer(const Duration(seconds: 3), () {
      _endingSkipCooldown = false;
    });
  }

  void _onPlaybackProgress(Duration position, Duration duration) {
    if (_media == null || state.activeEpisode == null) return;
    if (duration.inSeconds < 30 || position.inSeconds <= 0) return;

    final seconds = position.inSeconds;

    if (_currentSkips.isNotEmpty) {
      final prefs = ref.read(aniskipPrefsProvider);
      for (final skip in _currentSkips) {
        if (prefs.mode(skip.type) != SkipMode.auto) continue;

        final isInside = seconds >= skip.startTime && seconds < skip.endTime;
        if (isInside && _alreadyAutoSkipped.add(skip.type)) {
          _engine.seekTo(Duration(seconds: skip.endTime.ceil()));

          if (skip.type == SkipType.ending ||
              skip.type == SkipType.mixedEnding) {
            triggerEndingSkipCooldown();
          }
        }
      }
    }

    final playerPrefs = ref.read(playerPrefsProvider);
    if (playerPrefs.autoNext &&
        hasNextEpisode &&
        duration.inSeconds >= 60 &&
        position.inSeconds > 30 &&
        !state.isLoading &&
        !_isSkipping &&
        !_endingSkipCooldown) {
      final remaining = duration.inSeconds - position.inSeconds;
      if (remaining <= 0 || position.inSeconds >= duration.inSeconds) {
        skipEpisode();
      }
    }
  }

  Future<void> initialize(
    PlayerMode mode, {
    required ScreenshotController screenshotController,
  }) async {
    _screenshotController = screenshotController;
    _progressTracker.setScreenshotController(screenshotController);

    if (mode is PlayerModeOnline) {
      _source = ref.read(animeSourceProvider(mode.sourceInfo));
      _media = mode.media;
      final immediateMalId =
          int.tryParse(mode.media.externalIds.mal ?? '') ??
          int.tryParse(mode.media.idMal ?? '');
      state = state.copyWith(malId: immediateMalId);
      if (immediateMalId == null) {
        unawaited(_resolveMalId(mode.media));
      }
      await _loadData(mode.episode, startPosition: mode.startPosition);
    } else if (mode is PlayerModeOffline) {
      _source = null;
      _media = null;
      state = state.copyWith(malId: null);
      await _loadOfflineData(mode);
    }
  }

  Future<void> _resolveMalId(UnifiedMedia media) async {
    try {
      final id = await ref
          .read(aniSkipResolverProvider)
          .resolveMalId(media: media);
      if (!_isDisposed && id != null) {
        state = state.copyWith(malId: id);
        _fetchSkipsIfNeeded();
      }
    } catch (_) {}
  }

  Future<void> _fetchSkipsIfNeeded({int? durationSec}) async {
    final duration = durationSec ?? _engine.durationNotifier.value.inSeconds;
    final malId = state.malId;
    final ep = state.activeEpisode;
    if (malId == null || ep == null || duration < 50 || ep.number % 1 != 0) {
      return;
    }

    final args = AniSkipArgs(
      malId: malId,
      episodeNumber: ep.number.toInt(),
      episodeLength: duration,
    );

    try {
      _currentSkips = await ref.read(aniSkipProvider(args).future);
    } catch (_) {
      _currentSkips = [];
    }
  }

  Future<void> _loadOfflineData(PlayerModeOffline mode) async {
    _engine.pause();
    state = state.copyWith(
      isLoading: true,
      error: null,
      activeEpisode: null,
      servers: [],
      activeServer: null,
      streams: [],
      activeStream: null,
      qualities: [],
      activeQuality: null,
      subtitles: [],
      activeSubtitle: null,
    );

    try {
      final localStream = VideoStream(
        url: mode.filePath,
        quality: 'Local',
        subtitles: [],
      );

      final subtitles = [SubtitleTrack.none];
      final activeSubtitle = _resolver.resolveSubtitle(subtitles);

      state = state.copyWith(
        streams: [localStream],
        activeStream: localStream,
        qualities: [localStream],
        activeQuality: localStream,
        subtitles: subtitles,
        activeSubtitle: activeSubtitle,
        isLoading: false,
      );

      await _engine.initialize(
        localStream,
        subtitle: activeSubtitle,
        startAt: Duration.zero,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadData(
    UnifiedEpisode episode, {
    VideoServer? server,
    Duration? startPosition,
    bool force = false,
  }) async {
    if (_source == null) return;

    final isNewEpisode = state.activeEpisode?.id != episode.id;

    if (isNewEpisode) {
      _alreadyAutoSkipped.clear();
      _currentSkips = [];
      _progressTracker.resetThumbnail();
      _engine.pause();
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      activeEpisode: episode,
      servers: isNewEpisode ? [] : state.servers,
      activeServer: isNewEpisode ? null : state.activeServer,
      streams: isNewEpisode ? [] : state.streams,
      activeStream: isNewEpisode ? null : state.activeStream,
      qualities: isNewEpisode ? [] : state.qualities,
      activeQuality: isNewEpisode ? null : state.activeQuality,
      subtitles: isNewEpisode ? [] : state.subtitles,
      activeSubtitle: isNewEpisode ? null : state.activeSubtitle,
    );

    try {
      List<VideoServer> servers = state.servers;
      if (force || server == null || isNewEpisode) {
        servers = await _source!.getServers(episode.id);
        if (servers.isEmpty) throw Exception('No servers available.');
      }

      final activeServer = _resolver.resolveServer(servers, explicit: server);
      state = state.copyWith(servers: servers, activeServer: activeServer);

      final streams = await _source!.getSources(episode.id, activeServer);
      if (streams.isEmpty) throw Exception('No streams available.');

      final activeStream = _resolver.resolveStream(streams);

      state = state.copyWith(
        streams: streams,
        activeStream: activeStream,
        qualities: [activeStream],
        activeQuality: activeStream,
        isLoading: false,
      );

      unawaited(
        _initVideoPlayer(
          activeStream,
          subtitle: SubtitleTrack.none,
          startAt: startPosition,
          episode: episode,
        ).then((_) => _updateDiscordRpc()),
      );

      final httpClient = ref.read(httpClientProvider);
      final qualityResult = await _resolver.resolveQualities(
        streams,
        activeStream,
        httpClient,
      );

      final subtitles = _mapSubtitles({activeServer: streams});
      final activeSubtitle = _resolver.resolveSubtitle(subtitles);

      state = state.copyWith(
        qualities: qualityResult.list,
        activeQuality: qualityResult.active,
        subtitles: subtitles,
        activeSubtitle: activeSubtitle,
      );

      if (activeSubtitle != SubtitleTrack.none) {
        _applyNativeSubtitle(activeSubtitle);
      }

      if (qualityResult.active.url != activeStream.url &&
          _resolver.preferredQuality != null &&
          _resolver.preferredQuality != 'Auto') {
        final currentPos = _engine.currentPosition;
        final finalStartAt = currentPos.inSeconds > 0
            ? currentPos
            : startPosition;

        await _initVideoPlayer(
          qualityResult.active,
          subtitle: activeSubtitle,
          startAt: finalStartAt,
          episode: episode,
        );
      }

      unawaited(_fetchAdditionalSubtitles(episode.id, activeServer, streams));
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String? _resolveSubtitleLabel(
    SubtitleTrack sub,
    VideoStream stream,
    VideoServer? server,
  ) {
    final serverName = server?.name.trim();
    final originalLabel = sub.label?.trim();
    final quality = stream.quality.trim();
    final serverLower = serverName?.toLowerCase() ?? '';
    final hasValidServer =
        serverName != null &&
        serverLower.isNotEmpty &&
        serverLower != 'default' &&
        serverLower != 'auto';
    final hasQuality = quality.isNotEmpty && quality.toLowerCase() != 'auto';

    final parts = <String>[];

    if (hasValidServer) parts.add(serverName);
    if (hasQuality) parts.add(quality);

    if (originalLabel != null &&
        originalLabel.isNotEmpty &&
        originalLabel.toLowerCase() != 'auto' &&
        originalLabel.toLowerCase() != 'default' &&
        originalLabel.toLowerCase() != sub.language.toLowerCase() &&
        (!hasValidServer ||
            !originalLabel.toLowerCase().contains(serverLower))) {
      parts.add(originalLabel);
    }

    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  List<SubtitleTrack> _mapSubtitles(
    Map<VideoServer, List<VideoStream>> serverStreams,
  ) {
    final newSubtitles = <SubtitleTrack>[SubtitleTrack.none];
    final Set<String> seenUrls = {};

    for (final entry in serverStreams.entries) {
      final server = entry.key;
      for (final stream in entry.value) {
        for (final sub in stream.subtitles) {
          if (!seenUrls.contains(sub.url) && sub.url.isNotEmpty) {
            seenUrls.add(sub.url);
            newSubtitles.add(
              sub.copyWith(label: _resolveSubtitleLabel(sub, stream, server)),
            );
          }
        }
      }
    }
    return newSubtitles;
  }

  Future<void> _fetchAdditionalSubtitles(
    String episodeId,
    VideoServer activeServer,
    List<VideoStream> activeStreams,
  ) async {
    if (_source == null) return;

    final otherServers = state.servers
        .where((s) => s.id != activeServer.id)
        .toList();
    if (otherServers.isEmpty) return;

    final streamsList = await Future.wait(
      otherServers.map((server) async {
        try {
          return await _source!.getSources(episodeId, server);
        } catch (_) {
          return <VideoStream>[];
        }
      }),
    );

    if (_isDisposed || state.activeEpisode?.id != episodeId) return;

    final allServerStreams = <VideoServer, List<VideoStream>>{
      activeServer: activeStreams,
    };

    for (int i = 0; i < otherServers.length; i++) {
      allServerStreams[otherServers[i]] = streamsList[i];
    }

    final newSubtitles = _mapSubtitles(allServerStreams);
    state = state.copyWith(subtitles: newSubtitles);
  }

  Future<void> changeServer(VideoServer newServer) async {
    final active = state.activeServer;
    if (active != null &&
        newServer.id == active.id &&
        newServer.type == active.type) {
      return; // Already on this server
    }

    _resolver.preferredServerId = newServer.id;
    _resolver.preferredServerType = newServer.type;
    ref.read(playerPrefsProvider.notifier).setDefaultServerType(newServer.type);

    final currentPos = _engine.currentPosition;
    await _loadData(
      state.activeEpisode!,
      server: newServer,
      startPosition: currentPos,
    );
  }

  // Switch between sub/dub server variants if available
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

  Future<void> changeStreamType({bool? isDub, bool toggle = true}) async {
    final currentStream = state.activeStream;
    if (currentStream == null) return;

    bool targetDub = isDub ?? false;
    if (toggle && isDub == null) {
      final q = currentStream.quality.toLowerCase();
      targetDub = !(q.contains('dub') || q.contains('english'));
    }

    _resolver.preferredServerType = targetDub ? ServerType.dub : ServerType.sub;
    ref
        .read(playerPrefsProvider.notifier)
        .setDefaultServerType(_resolver.preferredServerType!);

    VideoStream? targetStream;
    if (targetDub) {
      targetStream = state.streams.firstWhereOrNull((s) {
        final sq = s.quality.toLowerCase();
        return sq.contains('dub') || sq.contains('english');
      });
    } else {
      // Prefer explicit "sub" / "japanese", fall back to anything non-dub
      targetStream = state.streams.firstWhereOrNull((s) {
        final sq = s.quality.toLowerCase();
        return sq.contains('sub') || sq.contains('japanese');
      });
      targetStream ??= state.streams.firstWhereOrNull((s) {
        final sq = s.quality.toLowerCase();
        return !sq.contains('dub') && !sq.contains('english');
      });
    }

    if (targetStream != null && targetStream.url != currentStream.url) {
      await changeStream(targetStream);
    }
  }

  Future<void> changeStream(VideoStream newStream) async {
    final currentPos = _engine.currentPosition;

    state = state.copyWith(
      isLoading: true,
      activeStream: newStream,
      error: null,
    );

    try {
      final httpClient = ref.read(httpClientProvider);
      final qualityResult = await _resolver.resolveQualities(
        state.streams,
        newStream,
        httpClient,
      );

      state = state.copyWith(
        qualities: qualityResult.list,
        activeQuality: qualityResult.active,
        isLoading: false,
      );

      await _initVideoPlayer(
        qualityResult.active,
        subtitle: state.activeSubtitle,
        startAt: currentPos,
        episode: state.activeEpisode,
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

    _resolver.preferredQuality = newQuality.quality;
    ref
        .read(playerPrefsProvider.notifier)
        .setDefaultQuality(newQuality.quality);

    final currentPos = _engine.currentPosition;

    state = state.copyWith(
      activeQuality: newQuality,
      isLoading: true,
      error: null,
    );

    try {
      await _initVideoPlayer(
        newQuality,
        subtitle: state.activeSubtitle,
        startAt: currentPos,
        episode: state.activeEpisode,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to switch quality: $e',
      );
    }
  }

  Future<VideoStream> _resolveStream(
    VideoStream stream, {
    UnifiedEpisode? episode,
  }) async {
    VideoStream resolvedStream = stream;
    if (isTorrentUrl(stream.url)) {
      final ep = episode ?? state.activeEpisode;
      final epString = ep != null
          ? (ep.number % 1 == 0 ? '${ep.number.toInt()}' : '${ep.number}')
          : null;

      final resolved = await TorrentStreamResolver.resolve(
        stream.url,
        episode: epString,
      );

      if (resolved.streamUrl.isEmpty) {
        throw Exception('Failed to resolve torrent stream URL.');
      }

      resolvedStream = stream.copyWith(url: resolved.streamUrl);
    }

    if (resolvedStream.requiresProxy) {
      final server = ref.read(streamServerProvider);

      if (_currentHlsStreamId != null) {
        server.unregister(_currentHlsStreamId!);
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      _currentHlsStreamId = id;

      final localUrl = await server.register(
        HlsStream(
          id: id,
          upstreamUrl: resolvedStream.url,
          headers: resolvedStream.headers ?? {},
        ),
      );
      resolvedStream = resolvedStream.copyWith(url: localUrl);
    }

    return resolvedStream;
  }

  /// Resolves a video stream and initializes the video engine with subtitles and position.
  Future<void> _initVideoPlayer(
    VideoStream stream, {
    SubtitleTrack? subtitle,
    Duration? startAt,
    UnifiedEpisode? episode,
  }) async {
    final streamToPlay = await _resolveStream(stream, episode: episode);
    if (_isDisposed) return;

    final useCustomSub = ref.read(subtitlePrefsProvider).useCustomSubtitle;
    final activeSub = (useCustomSub || subtitle == null || subtitle.url.isEmpty)
        ? null
        : subtitle;

    await _engine.initialize(
      streamToPlay,
      subtitle: activeSub,
      startAt: startAt,
    );
  }

  Future<void> changeSubtitle(SubtitleTrack? newSubtitle) async {
    if (newSubtitle != null && newSubtitle.url.isNotEmpty) {
      _resolver.preferredSubtitleLang = newSubtitle.language;
      ref
          .read(playerPrefsProvider.notifier)
          .setDefaultSubtitleLang(newSubtitle.language);
    } else if (newSubtitle != null) {
      _resolver.preferredSubtitleLang = 'Off';
      ref.read(playerPrefsProvider.notifier).setDefaultSubtitleLang('Off');
    }

    state = state.copyWith(activeSubtitle: newSubtitle, error: null);
    await _applyNativeSubtitle(newSubtitle);
  }

  Future<void> loadLocalSubtitle(String path, String name) async {
    final newSub = SubtitleTrack(
      url: path,
      language: name,
      label: 'Local Files',
    );

    // Make sure we don't duplicate it if the user loads it twice
    final existingIndex = state.subtitles.indexWhere((s) => s.url == path);
    final newSubtitles = List<SubtitleTrack>.from(state.subtitles);

    if (existingIndex != -1) {
      newSubtitles[existingIndex] = newSub;
    } else {
      newSubtitles.add(newSub);
    }

    state = state.copyWith(subtitles: newSubtitles);
    await changeSubtitle(newSub);
  }

  Future<void> changeAudioTrack(AudioTrack track) async {
    if (track.language != null && track.language!.isNotEmpty) {
      _resolver.preferredAudioLang = track.language;
      ref
          .read(playerPrefsProvider.notifier)
          .setDefaultAudioLang(track.language!);
    } else if (track.id != 'auto' && track.id != 'no') {
      _resolver.preferredAudioLang = track.label;
      ref.read(playerPrefsProvider.notifier).setDefaultAudioLang(track.label);
    } else if (track.id == 'auto') {
      _resolver.preferredAudioLang = 'Auto';
      ref.read(playerPrefsProvider.notifier).setDefaultAudioLang('Auto');
    }
    await _engine.setAudioTrack(track);
  }

  // Set native subtitle track (or clear it if using custom Flutter overlay)
  Future<void> _applyNativeSubtitle(SubtitleTrack? subtitle) async {
    final useCustom = ref.read(subtitlePrefsProvider).useCustomSubtitle;
    try {
      if (useCustom || subtitle == null || subtitle.url.isEmpty) {
        if (!_isNativeSubtitleDisabled) {
          await _engine.setSubtitle(null);
          _isNativeSubtitleDisabled = true;
        }
      } else {
        await _engine.setSubtitle(subtitle);
        _isNativeSubtitleDisabled = false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to switch subtitle: $e');
    }
  }

  Future<void> changeSpeed(double speed) async {
    state = state.copyWith(playbackSpeed: speed);
    await _engine.setSpeed(speed);
  }

  Future<void> loadEpisode(
    UnifiedEpisode newEpisode, {
    bool force = false,
  }) async {
    _alreadyAutoSkipped.clear();
    _endingSkipCooldown = false;
    _endingSkipCooldownTimer?.cancel();
    _progressTracker.resetThumbnail();
    await _loadData(newEpisode, force: force);
  }

  // Skip to next/previous episode with re-entrancy protection
  Future<void> skipEpisode({bool forward = true}) async {
    if (_isSkipping) return;
    if (_media == null || state.activeEpisode == null) return;

    _isSkipping = true;
    try {
      final episodes = await ref.read(
        episodesListProvider(
          MediaArgs.fromMedia(_media!),
        ).selectAsync((s) => s.episodes),
      );

      final currentIndex = _findEpisodeIndex(episodes, state.activeEpisode!);
      if (currentIndex == -1) return;

      final targetIndex = currentIndex + (forward ? 1 : -1);
      if (targetIndex < 0 || targetIndex >= episodes.length) return;

      await saveExitProgress();
      await loadEpisode(episodes[targetIndex]);
    } finally {
      _isSkipping = false;
    }
  }

  bool get hasNextEpisode {
    if (_media == null || state.activeEpisode == null) return false;

    final episodes = _getEpisodesList();
    if (episodes != null) {
      final idx = _findEpisodeIndex(episodes, state.activeEpisode!);
      if (idx != -1) return idx < episodes.length - 1;
    }

    // Fall back to total episode count if episode list isn't loaded yet
    final total = _media!.episodes;
    if (total != null && total > 0) return state.activeEpisode!.number < total;

    return true; // Assume yes if total is unknown
  }

  bool get hasPrevEpisode {
    if (_media == null || state.activeEpisode == null) return false;

    final episodes = _getEpisodesList();
    if (episodes != null) {
      final idx = _findEpisodeIndex(episodes, state.activeEpisode!);
      if (idx != -1) return idx > 0;
    }

    return state.activeEpisode!.number > 1;
  }

  // Find episode by ID, or fallback to matching episode number (handles float numbers like 12.5)
  int _findEpisodeIndex(List<UnifiedEpisode> episodes, UnifiedEpisode target) {
    int index = episodes.indexWhere((e) => e.id == target.id);
    if (index == -1) {
      index = episodes.indexWhere(
        (e) => (e.number - target.number).abs() < 0.01,
      );
    }
    return index;
  }

  List<UnifiedEpisode>? _getEpisodesList() {
    return ref
        .read(episodesListProvider(MediaArgs.fromMedia(_media!)))
        .value
        ?.episodes;
  }

  Future<({bool success, String message})> takeAndShareScreenshot() async {
    _engine.pause();
    return ScreenshotHelper.captureAndShare(
      _screenshotController,
      mediaTitle: _media?.title.getPreferedTitle,
    );
  }

  Future<void> saveExitProgress() async {
    await _progressTracker.saveExitProgress(
      media: _media,
      activeEpisode: state.activeEpisode,
      activeServer: state.activeServer,
      sourceInfo: _source?.sourceInfo,
      engine: _engine,
    );
  }

  Future<void> captureExitThumbnail() async {
    await _progressTracker.captureExitThumbnail(
      media: _media,
      activeEpisode: state.activeEpisode,
      activeServer: state.activeServer,
      sourceInfo: _source?.sourceInfo,
      engine: _engine,
    );
  }

  void _updateDiscordRpc() {
    if (_isDisposed || _media == null) return;
    final activeEp = state.activeEpisode;
    if (activeEp == null) return;

    final isPlaying = _engine.statusNotifier.value == PlayerStatus.playing;

    ref
        .read(discordRpcProvider.notifier)
        .updateAnimePresence(
          anime: _media!,
          episodeNumber: activeEp.number.toInt(),
          episodeTitle: activeEp.title,
          positionMs: _engine.currentPosition.inMilliseconds,
          durationMs: _engine.currentDuration.inMilliseconds,
          totalEpisodes: _media!.episodes,
          isPlaying: isPlaying,
        );
  }
}

final playerControllerProvider =
    NotifierProvider.autoDispose<PlayerController, PlayerState>(
      PlayerController.new,
    );
