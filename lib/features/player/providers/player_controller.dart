import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import 'package:collection/collection.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discord/providers/discord_rpc_provider.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/player/providers/aniskip_prefs_provider.dart';
import 'package:shonenx/features/player/providers/aniskip_provider.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';
import 'package:shonenx/features/player/providers/progress_tracker.dart';
import 'package:shonenx/features/player/providers/selection_resolver.dart';
import 'package:shonenx/features/player/providers/subtitle_prefs_provider.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/player/utils/screenshot_helper.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

// Sentinel object for copyWith error handling.
// Needed because null is a valid error value (to clear error state).
const _keepError = Object();

// Holds state for the player UI.
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

// Manages playback, stream switching, episode changing, and progress tracking.
class PlayerController extends Notifier<PlayerState> {
  UnifiedMedia? _media;
  UnifiedMedia? get media => _media;
  AnimeSource? _source;
  late ScreenshotController _screenshotController;

  late final SelectionResolver _resolver;
  late final ProgressTracker _progressTracker;

  // Track auto-skipped segments to prevent repeat triggers when seeking backwards
  final Set<SkipType> _alreadyAutoSkipped = {};

  // Prevents multiple skip triggers during episode loading transitions
  bool _isSkipping = false;

  // Ending skip cooldown prevents instant auto-next when an ending is skipped
  bool _endingSkipCooldown = false;
  Timer? _endingSkipCooldownTimer;

  bool _isDisposed = false;

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

    ref.onDispose(() {
      _isDisposed = true;
      _endingSkipCooldownTimer?.cancel();
      _progressTracker.cancel();
    });

    // Re-apply native subtitle when the "use custom subtitle" pref toggles
    ref.listen(subtitlePrefsProvider, (prev, current) {
      if (prev?.useCustomSubtitle != current.useCustomSubtitle) {
        _applyNativeSubtitle(state.activeSubtitle);
      }
    });

    // Auto-select preferred audio track when tracks become available
    ref.listen(videoEngineStateProvider.select((s) => s.audioTracks), (
      _,
      tracks,
    ) {
      if (tracks.isNotEmpty) {
        final match = _resolver.resolveAudioTrack(tracks);
        if (match != null) {
          ref.read(videoEngineProvider).setAudioTrack(match);
        }
      }
    });

    // Update Discord RPC when play/pause changes
    ref.listen(videoEngineStateProvider.select((s) => s.isPlaying), (
      prev,
      current,
    ) {
      if (!_isDisposed && prev != current) _updateDiscordRpc();
    });

    // Handles auto-skip & auto-next episode
    ref.listen(
      videoEngineStateProvider.select((s) => (s.position, s.duration)),
      (prev, next) {
        if (!_isDisposed) {
          _onPlaybackProgress(next.$1, next.$2);
        }
      },
    );

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

    // 1. Auto-Skip (Opening, Ending, Recap)
    if (duration.inSeconds >= 50) {
      final aniskipArgs = AniSkipArgs(
        media: _media,
        episodeNumber: state.activeEpisode!.number,
        episodeLength: duration.inSeconds,
      );

      final skips = ref.read(aniSkipProvider(aniskipArgs)).value ?? [];
      if (skips.isNotEmpty) {
        final prefs = ref.read(aniskipPrefsProvider);
        for (final skip in skips) {
          if (prefs.mode(skip.type) != SkipMode.auto) continue;

          final isInside = seconds >= skip.startTime && seconds < skip.endTime;
          if (isInside && _alreadyAutoSkipped.add(skip.type)) {
            ref
                .read(videoEngineProvider)
                .seekTo(Duration(seconds: skip.endTime.ceil()));

            if (skip.type == SkipType.ending ||
                skip.type == SkipType.mixedEnding) {
              triggerEndingSkipCooldown();
            }
          }
        }
      }
    }

    // 2. Auto-Next Episode Trigger
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
      await _loadData(mode.episode, startPosition: mode.startPosition);
    } else if (mode is PlayerModeOffline) {
      _source = null;
      _media = null;
      await _loadOfflineData(mode);
    }
  }

  /// Loads a local file for offline playback (no servers, no quality picker).
  Future<void> _loadOfflineData(PlayerModeOffline mode) async {
    ref.read(videoEngineProvider).pause();
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

      state = state.copyWith(
        streams: [localStream],
        activeStream: localStream,
        qualities: [localStream],
        activeQuality: localStream,
        subtitles: [SubtitleTrack.none],
        activeSubtitle: SubtitleTrack.none,
        isLoading: false,
      );

      await ref
          .read(videoEngineProvider)
          .initialize(localStream, subtitle: null, startAt: Duration.zero);
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
      _progressTracker.resetThumbnail();
      ref.read(videoEngineProvider).pause();
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
      // Step 1: Fetch available video servers for this episode
      List<VideoServer> servers = state.servers;
      if (force || server == null || isNewEpisode) {
        servers = await _source!.getServers(episode.id);
        if (servers.isEmpty) throw Exception('No servers available.');
      }

      // Step 2: Pick server matching user's preferred type (sub/dub) or explicit choice
      final activeServer = _resolver.resolveServer(servers, explicit: server);

      // Step 3: Fetch video stream mirrors from selected server
      final streams = await _source!.getSources(episode.id, activeServer);
      if (streams.isEmpty) throw Exception('No streams available.');

      // Step 4: Pick stream matching preferred sub/dub type & quality settings
      final activeStream = _resolver.resolveStream(streams);

      // Step 5: Parse HLS M3U8 manifest into individual quality options (1080p, 720p, etc.)
      final httpClient = ref.read(httpClientProvider);
      final qualityResult = await _resolver.resolveQualities(
        activeStream,
        httpClient,
      );

      // Step 6: Select preferred subtitle language (or default to Off)
      final subtitles = [SubtitleTrack.none, ...activeStream.subtitles];
      final activeSubtitle = _resolver.resolveSubtitle(subtitles);

      // Step 7: Update controller state with resolved active options
      state = state.copyWith(
        servers: servers,
        activeServer: activeServer,
        streams: streams,
        activeStream: activeStream,
        qualities: qualityResult.list,
        activeQuality: qualityResult.active,
        subtitles: subtitles,
        activeSubtitle: activeSubtitle,
        isLoading: false,
      );

      // Step 8: Initialize video engine with selected quality and subtitle track
      final useCustomSub = ref.read(subtitlePrefsProvider).useCustomSubtitle;
      await ref
          .read(videoEngineProvider)
          .initialize(
            qualityResult.active,
            subtitle: useCustomSub || activeSubtitle.url.isEmpty
                ? null
                : activeSubtitle,
            startAt: startPosition,
          );

      // Step 9: Start progress tracking timer & update Discord Rich Presence
      _progressTracker.start(
        () => ProgressContext(
          media: _media,
          activeEpisode: state.activeEpisode,
          activeServer: state.activeServer,
          sourceInfo: _source?.sourceInfo,
        ),
      );
      _updateDiscordRpc();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Switch active server and reload streams while preserving playback position
  Future<void> changeServer(VideoServer newServer) async {
    final active = state.activeServer;
    if (active != null &&
        newServer.id == active.id &&
        newServer.type == active.type) {
      return; // Already on this server
    }

    // Save preferred server settings for future episodes
    _resolver.preferredServerId = newServer.id;
    _resolver.preferredServerType = newServer.type;
    ref.read(playerPrefsProvider.notifier).setDefaultServerType(newServer.type);

    final currentPos = ref.read(videoEngineProvider).currentPosition;
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

  // Switch between sub/dub stream labels within the active server
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

  // Switch stream mirror and parse available qualities
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
      final qualityResult = await _resolver.resolveQualities(
        newStream,
        httpClient,
      );

      state = state.copyWith(
        qualities: qualityResult.list,
        activeQuality: qualityResult.active,
        isLoading: false,
      );

      await engine.initialize(
        qualityResult.active,
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

  // Switch quality resolution while preserving current position
  Future<void> changeQuality(VideoStream newQuality) async {
    if (state.activeQuality?.quality == newQuality.quality &&
        state.activeQuality?.url == newQuality.url) {
      return;
    }

    _resolver.preferredQuality = newQuality.quality;
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
      final useCustomSub = ref.read(subtitlePrefsProvider).useCustomSubtitle;
      await engine.initialize(
        newQuality,
        subtitle: useCustomSub || state.activeSubtitle?.url.isEmpty == true
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

  // Update active subtitle track and save language preference
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

  // Update active audio track and save preference
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
    await ref.read(videoEngineProvider).setAudioTrack(track);
  }

  // Set native subtitle track (or clear it if using custom Flutter overlay)
  Future<void> _applyNativeSubtitle(SubtitleTrack? subtitle) async {
    final useCustom = ref.read(subtitlePrefsProvider).useCustomSubtitle;
    try {
      if (useCustom || subtitle?.url.isEmpty == true) {
        await ref.read(videoEngineProvider).setSubtitle(null);
      } else {
        await ref.read(videoEngineProvider).setSubtitle(subtitle);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to switch subtitle: $e');
    }
  }

  Future<void> changeSpeed(double speed) async {
    state = state.copyWith(playbackSpeed: speed);
    await ref.read(videoEngineProvider).setSpeed(speed);
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
    ref.read(videoEngineProvider).pause();
    return ScreenshotHelper.captureAndShare(
      _screenshotController,
      mediaTitle: _media?.title.availableTitle,
    );
  }

  Future<void> captureExitThumbnail() async {
    await _progressTracker.captureExitThumbnail(
      media: _media,
      activeEpisode: state.activeEpisode,
      activeServer: state.activeServer,
      sourceInfo: _source?.sourceInfo,
    );
  }

  void _updateDiscordRpc() {
    if (_isDisposed || _media == null) return;
    final activeEp = state.activeEpisode;
    if (activeEp == null) return;

    final engine = ref.read(videoEngineProvider);
    final isPlaying = ref.read(videoEngineStateProvider).isPlaying;
    final positionMs = engine.currentPosition.inMilliseconds;
    final durationMs = engine.currentDuration.inMilliseconds;

    if (isPlaying) {
      ref
          .read(discordRpcProvider.notifier)
          .updateAnimePresence(
            anime: _media!,
            episodeNumber: activeEp.number.toInt(),
            episodeTitle: activeEp.title,
            timeStampMs: positionMs > 0 ? positionMs : null,
            durationMs: durationMs > 0 ? durationMs : null,
            totalEpisodes: _media!.episodes,
          );
    } else {
      ref
          .read(discordRpcProvider.notifier)
          .updateAnimePresencePaused(
            anime: _media!,
            episodeNumber: activeEp.number.toInt(),
            timeStampMs: positionMs > 0 ? positionMs : null,
            durationMs: durationMs > 0 ? durationMs : null,
          );
    }
  }
}

final playerControllerProvider =
    NotifierProvider.autoDispose<PlayerController, PlayerState>(
      PlayerController.new,
    );
