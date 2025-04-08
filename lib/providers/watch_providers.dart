import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/api/models/anime/source_model.dart';
import 'package:shonenx/api/registery/anime_source_registery_provider.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:shonenx/providers/selected_provider.dart';
import 'package:shonenx/utils/extractors.dart' as extractor;

// Optimized WatchState
@immutable
class WatchState {
  final String animeId;
  final bool isExpanded;
  final String? selectedCategory;
  final String? selectedSource;
  final String? selectedServer;
  final List<Map<String, dynamic>> qualityOptions;
  final List<EpisodeDataModel> episodes;
  final List<Source> sources;
  final List<Subtitle> subtitles;
  final int? selectedQualityIdx;
  final int? selectedSubtitleIdx;
  final int? selectedSourceIdx;
  final int? selectedEpisodeIdx;
  final String? error; // Error message to be displayed or handled
  final bool episodesLoading;
  final bool sourceLoading;
  final String? loadingMessage;

  const WatchState({
    required this.animeId,
    this.error,
    this.sourceLoading = true,
    this.episodesLoading = true,
    this.isExpanded = false,
    this.selectedCategory = 'sub',
    this.selectedSource,
    this.selectedServer,
    this.qualityOptions = const [],
    this.episodes = const [],
    this.sources = const [],
    this.subtitles = const [],
    this.selectedEpisodeIdx = 0,
    this.selectedQualityIdx = 0,
    this.selectedSourceIdx = 0,
    this.selectedSubtitleIdx,
    this.loadingMessage,
  });

  WatchState copyWith({
    String? error,
    bool? episodesLoading,
    bool? sourceLoading,
    String? animeId,
    bool? isExpanded,
    String? selectedCategory,
    String? selectedSource,
    String? selectedServer,
    List<Map<String, dynamic>>? qualityOptions,
    List<EpisodeDataModel>? episodes,
    List<Source>? sources,
    List<Subtitle>? subtitles,
    int? selectedQualityIdx,
    int? selectedSubtitleIdx,
    int? selectedSourceIdx,
    int? selectedEpisodeIdx,
    String? loadingMessage,
  }) {
    return WatchState(
      error: error, // Allow null to clear error
      episodesLoading: episodesLoading ?? this.episodesLoading,
      sourceLoading: sourceLoading ?? this.sourceLoading,
      animeId: animeId ?? this.animeId,
      isExpanded: isExpanded ?? this.isExpanded,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedSource: selectedSource ?? this.selectedSource,
      selectedServer: selectedServer ?? this.selectedServer,
      qualityOptions: qualityOptions ?? this.qualityOptions,
      episodes: episodes ?? this.episodes,
      sources: sources ?? this.sources,
      subtitles: subtitles ?? this.subtitles,
      selectedQualityIdx: selectedQualityIdx ?? this.selectedQualityIdx,
      selectedSubtitleIdx: selectedSubtitleIdx ?? this.selectedSubtitleIdx,
      selectedSourceIdx: selectedSourceIdx ?? this.selectedSourceIdx,
      selectedEpisodeIdx: selectedEpisodeIdx ?? this.selectedEpisodeIdx,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }
}

// Optimized WatchStateNotifier with Error Handling
class WatchStateNotifier extends StateNotifier<WatchState> {
  final Player? player;
  final VideoController? controller;
  final AnimeProvider animeProvider;

  WatchStateNotifier({
    required this.player,
    required this.controller,
    required this.animeProvider,
  }) : super(const WatchState(animeId: ''));

  // Clear any existing error
  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetState() {
    state = const WatchState(animeId: '');
  }

  void updateCategory(String category) {
    state = state.copyWith(selectedCategory: category, error: null);
  }

  void updateServer(String server) {
    state = state.copyWith(selectedServer: server, error: null);
  }

  Future<void> changeEpisode(int episodeIdx, {bool withPlay = true}) async {
    if (episodeIdx < 0 || episodeIdx >= state.episodes.length) {
      state = state.copyWith(error: 'Invalid episode index');
      return;
    }
    try {
      await fetchStreamData(episodeIdx: episodeIdx, withPlay: withPlay);
      state = state.copyWith(error: null); // Clear error on success
    } catch (e, stackTrace) {
      _handleError('Failed to change episode: $e', stackTrace);
    }
  }

  Future<void> togglePanel(AnimationController controller) async {
    try {
      state = state.copyWith(isExpanded: !state.isExpanded);
      await (state.isExpanded ? controller.forward() : controller.reverse());
      state = state.copyWith(error: null);
    } catch (e, stackTrace) {
      _handleError('Failed to toggle panel: $e', stackTrace);
    }
  }

  Future<void> updateVideoSource({
    required String? sourceUrl,
    bool withPlay = true,
    Duration startAt = Duration.zero,
  }) async {
    if (sourceUrl == null) {
      state = state.copyWith(error: 'No video source provided');
      return;
    }
    try {
      state = state.copyWith(selectedSource: sourceUrl, error: null);
      if (withPlay && player != null) {
        await player?.open(Media(sourceUrl), play: false);
        await player?.stream.duration.firstWhere((d) => d > Duration.zero);
        await player?.seek(startAt);
        await player?.play();
        log('Video source updated: $sourceUrl, seeked to: $startAt');
      }
    } catch (e, stackTrace) {
      _handleError('Failed to update video source: $e', stackTrace);
    }
  }

  Future<void> changeQuality({
    required int qualityIdx,
    required Duration lastPosition,
  }) async {
    if (state.qualityOptions.isEmpty) {
      state = state.copyWith(error: 'No quality options available');
      return;
    }
    if (qualityIdx < 0 || qualityIdx >= state.qualityOptions.length) {
      state = state.copyWith(error: 'Invalid quality index');
      return;
    }
    try {
      state = state.copyWith(selectedQualityIdx: qualityIdx, error: null);
      final quality = state.qualityOptions[qualityIdx];
      await updateVideoSource(sourceUrl: quality['url'], startAt: lastPosition);
    } catch (e, stackTrace) {
      _handleError('Failed to change quality: $e', stackTrace);
    }
  }

  Future<void> changeCategory(String category, {bool withPlay = true}) async {
    try {
      state = state.copyWith(selectedCategory: category, error: null);
      await fetchStreamData(
          episodeIdx: state.selectedEpisodeIdx ?? 0, withPlay: withPlay);
    } catch (e, stackTrace) {
      _handleError('Failed to change category: $e', stackTrace);
    }
  }

  Future<void> changeSource({
    required int sourceIdx,
    required Duration lastPosition,
  }) async {
    if (state.sources.isEmpty) {
      state = state.copyWith(error: 'No sources available');
      return;
    }
    if (sourceIdx < 0 || sourceIdx >= state.sources.length) {
      state = state.copyWith(error: 'Invalid source index');
      return;
    }
    try {
      state = state.copyWith(selectedSourceIdx: sourceIdx, error: null);
      await updateVideoSource(sourceUrl: state.sources[sourceIdx].url);
    } catch (e, stackTrace) {
      _handleError('Failed to change source: $e', stackTrace);
    }
  }

  Future<void> changeServer(String server) async {
    try {
      state = state.copyWith(selectedServer: server, error: null);
      await fetchStreamData(episodeIdx: state.selectedEpisodeIdx ?? 0);
    } catch (e, stackTrace) {
      _handleError('Failed to change server: $e', stackTrace);
    }
  }

  Future<void> updateSubtitleTrack({required int? subtitleIdx}) async {
    if (player == null) {
      state = state.copyWith(error: 'Player not initialized');
      return;
    }
    try {
      if (subtitleIdx == null) {
        await player?.setSubtitleTrack(SubtitleTrack.no());
        state = state.copyWith(selectedSubtitleIdx: null, error: null);
      } else if (subtitleIdx >= 0 && subtitleIdx < state.subtitles.length) {
        final subtitle = state.subtitles[subtitleIdx];
        if (subtitle.url == null) {
          state = state.copyWith(error: 'Subtitle URL is null');
          return;
        }
        await player?.setSubtitleTrack(SubtitleTrack.uri(
          subtitle.url!,
          title: subtitle.lang,
          language: subtitle.lang,
        ));
        state = state.copyWith(selectedSubtitleIdx: subtitleIdx, error: null);
      } else {
        state = state.copyWith(error: 'Invalid subtitle index');
      }
    } catch (e, stackTrace) {
      _handleError('Failed to update subtitle track: $e', stackTrace);
    }
  }

  Future<void> fetchEpisodes({required dynamic animeId}) async {
    try {
      state = state.copyWith(
          episodesLoading: true,
          error: null,
          loadingMessage: 'Loading episodes...');
      final episodes = (await animeProvider.getEpisodes(animeId)).episodes;
      state = state.copyWith(
          episodesLoading: false,
          animeId: animeId,
          episodes: episodes,
          selectedServer: animeProvider.getSupportedServers().first,
          error: null,
          loadingMessage: null);
    } catch (e, stackTrace) {
      _handleError('Failed to fetch episodes: $e', stackTrace);
      state = state.copyWith(episodesLoading: false, loadingMessage: null);
    }
  }

  Future<void> fetchStreamData({
    required int episodeIdx,
    bool withPlay = true,
  }) async {
    if (episodeIdx >= state.episodes.length) {
      state = state.copyWith(error: 'Invalid episode index');
      return;
    }
    try {
      state = state.copyWith(
        selectedEpisodeIdx: episodeIdx,
        sourceLoading: true,
        error: null,
        loadingMessage: 'Loading sources...',
      );
      final data = await animeProvider.getSources(
        state.animeId,
        state.episodes[episodeIdx].id ?? '',
        state.selectedServer ?? '',
        state.selectedCategory ?? 'sub',
      );

      state = state.copyWith(
        sourceLoading: false,
        loadingMessage: null,
        selectedSource: data.sources.isNotEmpty ? data.sources.first.url : null,
        sources: data.sources,
        subtitles: data.tracks,
        error: null,
      );

      await _extractQualities();
      final qualityUrl = state.qualityOptions.isNotEmpty
          ? state.qualityOptions[0]['url']
          : null;
      if (qualityUrl != null) {
        await updateVideoSource(sourceUrl: qualityUrl, withPlay: withPlay);
      } else if (data.sources.isNotEmpty) {
        await updateVideoSource(
            sourceUrl: data.sources.first.url, withPlay: withPlay);
      } else {
        state = state.copyWith(error: 'No playable sources found');
      }
    } catch (e, stackTrace) {
      _handleError('Failed to fetch stream data: $e', stackTrace);
      state = state.copyWith(sourceLoading: false, loadingMessage: null);
    }
  }

  Future<void> _extractQualities() async {
    if (state.selectedSource == null) {
      state =
          state.copyWith(error: 'No source selected for quality extraction');
      return;
    }
    try {
      final qualities =
          await extractor.extractQualities(state.selectedSource!, {});
      state = state.copyWith(
          qualityOptions: qualities, selectedQualityIdx: 0, error: null);
    } catch (e, stackTrace) {
      _handleError('Failed to extract qualities: $e', stackTrace);
    }
  }

  void _handleError(String message, StackTrace stackTrace) {
    log(message,
        stackTrace: stackTrace, level: 1000); // Log error with high severity
    state = state.copyWith(error: message);
  }
}

// Optimized PlayerState
@immutable
class PlayerState {
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isCompleted;
  final List<String> subtitle;

  const PlayerState({
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100.0,
    this.isCompleted = false,
    this.subtitle = const [],
  });

  PlayerState copyWith({
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isCompleted,
    List<String>? subtitle,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isCompleted: isCompleted ?? this.isCompleted,
      subtitle: subtitle ?? this.subtitle,
    );
  }
}

// Optimized PlayerStateNotifier
class PlayerStateNotifier extends StateNotifier<PlayerState> {
  final Player player;
  late final List<StreamSubscription> _subscriptions;

  PlayerStateNotifier(this.player) : super(const PlayerState()) {
    _subscriptions = [
      player.stream.playing
          .listen((playing) => state = state.copyWith(isPlaying: playing)),
      player.stream.buffering.listen(
          (buffering) => state = state.copyWith(isBuffering: buffering)),
      player.stream.position
          .listen((position) => state = state.copyWith(position: position)),
      player.stream.duration
          .listen((duration) => state = state.copyWith(duration: duration)),
      player.stream.volume
          .listen((volume) => state = state.copyWith(volume: volume)),
      player.stream.completed.listen(
          (completed) => state = state.copyWith(isCompleted: completed)),
      player.stream.subtitle
          .listen((subtitle) => state = state.copyWith(subtitle: subtitle)),
    ];
  }

  Future<void> playOrPause() => player.playOrPause();
  Future<void> seek(Duration position) => player.seek(position);
  Future<void> setVolume(double volume) => player.setVolume(volume);

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

// Providers
final watchProvider =
    StateNotifierProvider<WatchStateNotifier, WatchState>((ref) {
  return WatchStateNotifier(
    player: ref.watch(playerProvider),
    controller: ref.watch(controllerProvider),
    animeProvider: ref.read(animeSourceRegistryProvider).getProvider(
        ref.read(selectedProviderKeyProvider).selectedProviderKey)!,
  );
});

final playerProvider = Provider<Player>((ref) {
  final player = Player();
  ref.onDispose(() => player.dispose());
  return player;
});

final controllerProvider = Provider<VideoController>((ref) {
  final controller = VideoController(ref.watch(playerProvider));
  return controller;
});

final playerStateProvider =
    StateNotifierProvider<PlayerStateNotifier, PlayerState>((ref) {
  return PlayerStateNotifier(ref.watch(playerProvider));
});
