// ignore_for_file: public_member_api_docs, sort_constructors_first
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

  const WatchState({
    required this.animeId,
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
  });

  WatchState copyWith({
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
  }) {
    return WatchState(
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
    );
  }
}

// Optimized WatchStateNotifier
class WatchStateNotifier extends StateNotifier<WatchState> {
  final Player? player;
  final VideoController? controller;
  final AnimeProvider animeProvider;

  WatchStateNotifier({
    required this.player,
    required this.controller,
    required this.animeProvider,
  }) : super(const WatchState(animeId: ''));

  void resetState() {
    state = const WatchState(animeId: '');
  }

  void updateCategory(String category) =>
      state = state.copyWith(selectedCategory: category);

  void updateServer(String server) =>
      state = state.copyWith(selectedServer: server);

  Future<void> changeEpisode(int episodeIdx, {bool withPlay = true}) async {
    if (episodeIdx < 0 || episodeIdx >= state.episodes.length || !mounted) {
      return;
    }
    await fetchStreamData(episodeIdx: episodeIdx, withPlay: withPlay);
  }

  Future<void> togglePanel(AnimationController controller) async {
    state = state.copyWith(isExpanded: !state.isExpanded);
    await (state.isExpanded ? controller.forward() : controller.reverse());
  }

  Future<void> updateVideoSource({
    required String? sourceUrl,
    bool withPlay = true,
    Duration startAt = Duration.zero,
  }) async {
    if (sourceUrl == null || !mounted) return;
    state = state.copyWith(selectedSource: sourceUrl);
    if (withPlay && player != null) {
      await player?.open(Media(sourceUrl), play: false);
      await player?.stream.duration.firstWhere((d) => d > Duration.zero);
      await player?.seek(startAt);
      await player?.play();
      log('Video source updated: $sourceUrl, seeked to: $startAt');
    }
  }

  Future<void> changeQuality({
    required int qualityIdx,
    required Duration lastPosition,
  }) async {
    if (state.qualityOptions.isEmpty || !mounted) return;
    state = state.copyWith(selectedQualityIdx: qualityIdx);
    final quality = state.qualityOptions[qualityIdx];
    await updateVideoSource(sourceUrl: quality['url'], startAt: lastPosition);
  }

  Future<void> changeCategory(String category, {bool withPlay = true}) async {
    state = state.copyWith(selectedCategory: category);
    await fetchStreamData(
        episodeIdx: state.selectedEpisodeIdx ?? 0, withPlay: withPlay);
  }

  Future<void> changeSource({
    required int sourceIdx,
    required Duration lastPosition,
  }) async {
    if (state.sources.isEmpty || !mounted) return;
    state = state.copyWith(selectedSourceIdx: sourceIdx);
    await updateVideoSource(sourceUrl: state.sources[sourceIdx].url);
  }

  Future<void> changeServer(String server) async {
    state = state.copyWith(selectedServer: server);
    await fetchStreamData(episodeIdx: state.selectedEpisodeIdx ?? 0);
  }

  Future<void> updateSubtitleTrack({required int? subtitleIdx}) async {
    if (!mounted || player == null) return;
    if (subtitleIdx == null) {
      await player?.setSubtitleTrack(SubtitleTrack.no());
      state = state.copyWith(selectedSubtitleIdx: null);
    } else if (subtitleIdx >= 0 &&
        subtitleIdx < state.subtitles.length &&
        state.subtitles[subtitleIdx].url != null) {
      final subtitle = state.subtitles[subtitleIdx];
      await player?.setSubtitleTrack(SubtitleTrack.uri(subtitle.url!,
          title: subtitle.lang, language: subtitle.lang));
      state = state.copyWith(selectedSubtitleIdx: subtitleIdx);
    }
  }

  Future<void> fetchEpisodes({required dynamic animeId}) async {
    if (!mounted) return;
    final episodes = (await animeProvider.getEpisodes(animeId)).episodes;
    state = state.copyWith(
      animeId: animeId,
      episodes: episodes,
      selectedServer: animeProvider.getSupportedServers().first,
    );
  }

  Future<void> fetchStreamData({
    required int episodeIdx,
    bool withPlay = true,
  }) async {
    if (!mounted || episodeIdx >= state.episodes.length) return;
    state = state.copyWith(selectedEpisodeIdx: episodeIdx);
    final data = await animeProvider.getSources(
      state.animeId,
      state.episodes[episodeIdx].id ?? '',
      state.selectedServer ?? '',
      state.selectedCategory ?? 'sub',
    );

    state = state.copyWith(
      selectedSource: data.sources.isNotEmpty ? data.sources.first.url : null,
      sources: data.sources,
      subtitles: data.tracks,
    );

    await _extractQualities();
    final qualityUrl =
        state.qualityOptions.isNotEmpty ? state.qualityOptions[0]['url'] : null;
    if (qualityUrl != null) {
      await updateVideoSource(sourceUrl: qualityUrl, withPlay: withPlay);
    } else if (data.sources.isNotEmpty) {
      await updateVideoSource(
          sourceUrl: data.sources.first.url, withPlay: withPlay);
    }
  }

  Future<void> _extractQualities() async {
    if (state.selectedSource == null || !mounted) return;
    final qualities =
        await extractor.extractQualities(state.selectedSource!, {});
    state = state.copyWith(qualityOptions: qualities, selectedQualityIdx: 0);
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
