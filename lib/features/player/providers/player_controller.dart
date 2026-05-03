import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import 'package:shonenx/core/utils/extensions.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/player/providers/active_engine_provider.dart';
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

  @override
  PlayerState build() {
    ref.onDispose(() => _progressTimer?.cancel);
    return const PlayerState();
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
    await _loadData(episode, startPosition: startPosition);
  }

  Future<void> changeServer(VideoServer newServer) async {
    final active = state.activeServer;
    if (active != null &&
        newServer.id == active.id &&
        newServer.type == active.type) {
      return;
    }

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

      final activeServer = server ?? servers.first;
      final streams = await _source.getSources(episode.id, activeServer);
      if (streams.isEmpty) throw Exception('No streams available.');

      final activeStream = streams.first;
      final subtitles = activeStream.subtitles;
      final activeSubtitle = subtitles.firstOrNull;

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
            subtitle: activeSubtitle,
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
      activeStream: newStream,
      subtitles: newStream.subtitles,
      activeSubtitle: newStream.subtitles.firstOrNull,
      error: null,
    );

    try {
      await engine.initialize(
        newStream,
        subtitle: newStream.subtitles.firstOrNull,
        startAt: currentPos,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to switch stream: $e');
    }
  }

  Future<void> changeSubtitle(SubtitleTrack? newSubtitle) async {
    state = state.copyWith(activeSubtitle: newSubtitle, error: null);
    try {
      await ref.read(videoEngineProvider).setSubtitle(newSubtitle);
    } catch (e) {
      state = state.copyWith(error: 'Failed to switch subtitle: $e');
    }
  }

  Future<void> _startProgressTracker() async {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async => await _saveCurrentProgress(),
    );
  }

  Future<void> _saveCurrentProgress() async {
    if (!ref.mounted) {
      _progressTimer?.cancel();
      return;
    }

    if (state.activeServer == null) return;

    final engine = ref.read(videoEngineProvider);
    final position = engine.currentPosition;
    final duration = engine.currentDuration;
    if (position == Duration.zero || duration == Duration.zero) return;

    final image = await _screenshot.capture(pixelRatio: 0.5);
    final thumbnail = image != null ? base64Encode(image) : '';

    final entry = WatchHistoryEntry()
      ..episodeNumber = state.activeEpisode?.number ?? 1
      ..totalEpisodes = _media.episodes
      ..animeId = _media.id
      ..animeIdMal = _media.idMal
      ..animeTitle = _media.title.availableTitle
      ..episodeTitle = state.activeEpisode?.title
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
            primaryMediaId: _media.id,
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
