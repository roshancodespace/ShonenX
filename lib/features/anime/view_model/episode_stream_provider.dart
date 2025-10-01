import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'package:shonenx/core/jikan/jikan_service.dart';
import 'package:shonenx/core/jikan/models/jikan_media.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/features/settings/model/experimental_model.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/utils/extractors.dart' as extractor;

@immutable
class EpisodeDataState {
  final String? animeId;
  final String? animeTitle;
  final List<EpisodeDataModel> episodes;
  final Map<String, String>? headers;
  final List<Source> sources;
  final List<Subtitle> subtitles;
  final List<Map<String, dynamic>> qualityOptions;
  final List<String> servers;
  final List<({JikanMedia result, double similarity})> jikanMatches;

  final int? selectedQualityIdx;
  final int? selectedSourceIdx;
  final int? selectedEpisodeIdx;
  final int? selectedSubtitleIdx;
  final String selectedCategory;
  final String? selectedServer;

  final bool dubSubSupport;
  final bool episodesLoading;
  final bool sourceLoading;
  final String? error;

  final String? mMangaUrl;

  const EpisodeDataState(
      {this.animeId,
      this.animeTitle,
      this.episodes = const [],
      this.sources = const [],
      this.subtitles = const [],
      this.qualityOptions = const [],
      this.servers = const [],
      this.jikanMatches = const [],
      this.headers,
      this.selectedQualityIdx,
      this.selectedSourceIdx,
      this.selectedEpisodeIdx,
      this.selectedSubtitleIdx,
      this.selectedCategory = 'sub',
      this.dubSubSupport = false,
      this.selectedServer,
      this.episodesLoading = true,
      this.sourceLoading = false,
      this.error,
      this.mMangaUrl});

  EpisodeDataState copyWith({
    String? animeId,
    String? animeTitle,
    List<EpisodeDataModel>? episodes,
    Map<String, String>? headers,
    List<Source>? sources,
    List<Subtitle>? subtitles,
    List<Map<String, dynamic>>? qualityOptions,
    List<String>? servers,
    int? selectedQualityIdx,
    int? selectedSourceIdx,
    int? selectedEpisodeIdx,
    int? selectedSubtitleIdx,
    String? selectedCategory,
    String? selectedServer,
    List<({JikanMedia result, double similarity})>? jikanMatches,
    bool? dubSubSupport,
    bool? episodesLoading,
    bool? sourceLoading,
    String? error,
    String? mMangaUrl,
  }) {
    return EpisodeDataState(
      animeId: animeId ?? this.animeId,
      animeTitle: animeTitle ?? this.animeTitle,
      episodes: episodes ?? this.episodes,
      headers: headers ?? this.headers,
      sources: sources ?? this.sources,
      subtitles: subtitles ?? this.subtitles,
      qualityOptions: qualityOptions ?? this.qualityOptions,
      servers: servers ?? this.servers,
      selectedQualityIdx: selectedQualityIdx ?? this.selectedQualityIdx,
      selectedSourceIdx: selectedSourceIdx ?? this.selectedSourceIdx,
      selectedEpisodeIdx: selectedEpisodeIdx ?? this.selectedEpisodeIdx,
      selectedSubtitleIdx: selectedSubtitleIdx ?? this.selectedSubtitleIdx,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedServer: selectedServer ?? this.selectedServer,
      dubSubSupport: dubSubSupport ?? this.dubSubSupport,
      jikanMatches: jikanMatches ?? this.jikanMatches,
      episodesLoading: episodesLoading ?? this.episodesLoading,
      sourceLoading: sourceLoading ?? this.sourceLoading,
      error: error ?? this.error,
      mMangaUrl: mMangaUrl ?? this.mMangaUrl,
    );
  }
}

// The Notifier for fetching and holding episode data
class EpisodeDataNotifier extends AutoDisposeNotifier<EpisodeDataState> {
  // --- Dependencies ---
  JikanService get _jikan => JikanService();
  ExperimentalFeaturesModel get _experimentalFeatures =>
      ref.read(experimentalProvider);
  AnimeProvider? _getProvider() => ref.read(selectedAnimeProvider);
  SourceNotifier get _sourceNotifier => ref.read(sourceProvider.notifier);

  @override
  EpisodeDataState build() {
    return const EpisodeDataState();
  }

  // --- Public API ---

  /// Fetches the list of episodes for a given anime.
  Future<List<EpisodeDataModel>> fetchEpisodes({
    required String animeTitle,
    String? animeId,
    required bool force,
    bool play = true,
    List<EpisodeDataModel> episodes = const [],
    int initialEpisodeIdx = 0,
    Duration startAt = Duration.zero,
    String? mMangaUrl,
  }) async {
    // If episodes are already loaded and not forcing a refresh, just set up and play.
    if (!force && state.episodes.isNotEmpty) {
      await _setupAndPlay(play, initialEpisodeIdx, startAt);
      return state.episodes;
    }

    // Set loading state and clear previous errors.
    state = state.copyWith(
      episodesLoading: true,
      error: null,
      animeId: animeId,
      animeTitle: animeTitle,
      mMangaUrl: mMangaUrl,
    );

    final fetchedEpisodes = await _fetchEpisodeList(animeId, mMangaUrl);

    if (fetchedEpisodes.isEmpty) {
      state = state.copyWith(
        episodesLoading: false,
        error: "No episodes found for this anime.",
      );
      return [];
    }

    // Update state with fetched episodes and sync with Jikan.
    state = state.copyWith(episodes: fetchedEpisodes);
    syncEpisodesWithJikan();

    await _setupAndPlay(play, initialEpisodeIdx, startAt);

    return fetchedEpisodes;
  }

  /// Refreshes the current episode list.
  Future<void> refreshEpisodes() async {
    final animeId = state.animeId;
    final animeTitle = state.animeTitle;
    if (animeId == null || animeTitle == null) return;
    await fetchEpisodes(animeId: animeId, animeTitle: animeTitle, force: true);
  }

  /// Toggles between 'sub' and 'dub' audio tracks if supported.
  Future<void> toggleDubSub() async {
    if (!state.dubSubSupport) return;
    final newCategory = state.selectedCategory == 'sub' ? 'dub' : 'sub';
    final currentPosition = ref.read(playerStateProvider).position;
    state = state.copyWith(selectedCategory: newCategory);
    await _fetchStreamData(startAt: currentPosition);
  }

  /// Changes the current episode and fetches its stream data.
  Future<void> changeEpisode(int episodeIdx,
      {Duration startAt = Duration.zero}) async {
    if (episodeIdx < 0 || episodeIdx >= state.episodes.length) return;
    ref.read(playerStateProvider.notifier).pause();
    AppLogger.d('Playing episode at index: $episodeIdx');
    state = state.copyWith(selectedEpisodeIdx: episodeIdx);
    await _fetchStreamData(startAt: startAt);
  }

  /// Changes the video quality and restarts the player from the current position.
  Future<void> changeQuality(int qualityIdx) async {
    if (qualityIdx < 0 || qualityIdx >= state.qualityOptions.length) return;

    final newQualityUrl = state.qualityOptions[qualityIdx]['url'] as String?;
    if (newQualityUrl == null) {
      state = state.copyWith(error: "Selected quality has an invalid URL.");
      return;
    }

    state = state.copyWith(selectedQualityIdx: qualityIdx);
    final currentPosition = ref.read(playerStateProvider).position;
    ref
        .read(playerStateProvider.notifier)
        .open(newQualityUrl, currentPosition, headers: state.headers);
  }

  /// Changes the streaming source and reloads the player.
  Future<void> changeSource(int sourceIdx) async {
    if (sourceIdx < 0 || sourceIdx >= state.sources.length) return;
    final currentPosition = ref.read(playerStateProvider).position;
    state = state.copyWith(selectedSourceIdx: sourceIdx);
    await _loadAndPlaySource(sourceIdx, startAt: currentPosition);
  }

  /// Changes the streaming server and reloads the stream.
  Future<void> changeServer(String server) async {
    final currentPosition = ref.read(playerStateProvider).position;
    state = state.copyWith(selectedServer: server);
    await _fetchStreamData(startAt: currentPosition);
  }

  /// Changes the subtitle track.
  Future<void> changeSubtitle(int subtitleIdx) async {
    if (subtitleIdx < 0 || subtitleIdx >= state.subtitles.length) return;
    final subtitle = state.subtitles[subtitleIdx];
    if (subtitle.url == null) return;

    await ref
        .read(playerStateProvider.notifier)
        .setSubtitle(SubtitleTrack.uri(subtitle.url!));
    state = state.copyWith(selectedSubtitleIdx: subtitleIdx);
  }

  // --- Private Helper Methods ---

  /// Centralized async function runner with error handling.
  Future<T?> _safeRun<T>(
    Future<T> Function() task, {
    String? errorTitle,
    String? errorMessage,
    bool showSnackBar = true,
  }) async {
    try {
      return await task();
    } catch (e, st) {
      AppLogger.e('Error in EpisodeDataNotifier: $e\n$st');
      final title = errorTitle ?? 'Error';
      final msg = errorMessage ?? 'Something went wrong.';
      state = state.copyWith(
          error: msg, episodesLoading: false, sourceLoading: false);

      if (showSnackBar) {
        showAppSnackBar(title, msg, type: ContentType.failure);
      }
      return null;
    }
  }

  /// Determines which source to use and fetches the episode list.
  Future<List<EpisodeDataModel>> _fetchEpisodeList(
      String? animeId, String? mMangaUrl) async {
    final useMangayomi = _experimentalFeatures.useMangayomiExtensions;
    final url = state.mMangaUrl ?? mMangaUrl;
    if (useMangayomi && url != null) {
      AppLogger.w('Fetching episodes using Mangayomi extension');
      return await _safeRun<List<EpisodeDataModel>>(
            () async {
              final details = await _sourceNotifier.getDetails(url);
              final chapters = details?.chapters ?? [];
              final mapped = chapters
                  .map((ch) => EpisodeDataModel(
                        isFiller: false,
                        title: ch.name,
                        url: ch.url,
                        number: int.tryParse(
                          RegExp(r'\d+').firstMatch(ch.name ?? '')?.group(0) ??
                              '',
                        ),
                      ))
                  .toList();

              // Normalize: sort ascending by number if valid numbers exist
              if (mapped.any((e) => e.number != null && e.number! > 0)) {
                mapped.sort((a, b) =>
                    (a.number ?? 999999).compareTo(b.number ?? 999999));
              }
              return mapped;
            },
            errorTitle: "Mangayomi",
            errorMessage: "Failed to fetch episodes via Mangayomi.",
          ) ??
          [];
    }

    AppLogger.w('Fetching episodes using Legacy source');
    final animeProvider = _getProvider();
    if (animeProvider == null) return [];
    if (animeId == null) throw Exception('animeId is null');
    return await _safeRun<List<EpisodeDataModel>>(
          () async => (await animeProvider.getEpisodes(animeId)).episodes ?? [],
          errorTitle: "Legacy Source",
          errorMessage: "Failed to fetch episodes.",
        ) ??
        [];
  }

  /// Configures servers and starts playback if requested.
  Future<void> _setupAndPlay(
      bool play, int initialEpisodeIdx, Duration startAt) async {
    final bool useMangayomi = _experimentalFeatures.useMangayomiExtensions;
    List<String> servers = [];
    bool supportDubSub = false;
    if (!useMangayomi) {
      final animeProvider = _getProvider();
      servers = await animeProvider?.getSupportedServers() ?? [];
      supportDubSub = animeProvider?.getDubSubParamSupport() ?? false;
    }

    state = state.copyWith(
      episodesLoading: false,
      servers: servers,
      selectedServer: servers.isNotEmpty ? servers.first : null,
      dubSubSupport: supportDubSub,
    );

    if (play) {
      await changeEpisode(initialEpisodeIdx, startAt: startAt);
    }
  }

  /// Syncs episode titles with data from Jikan/MAL.
  Future<void> syncEpisodesWithJikan() async {
    if (!_experimentalFeatures.episodeTitleSync || state.episodes.isEmpty) {
      return;
    }
    final animeTitle = state.animeTitle;
    if (animeTitle == null || animeTitle.isEmpty) return;

    await _safeRun(
      () async {
        final jikanMatches = state.jikanMatches.isNotEmpty
            ? state.jikanMatches
            : getBestMatches<JikanMedia>(
                results: await _jikan.getSearch(title: animeTitle, limit: 10),
                title: animeTitle,
                nameSelector: (e) => e.title,
                idSelector: (e) => e.mal_id.toString(),
              );

        if (jikanMatches.isEmpty || jikanMatches.first.similarity < 0.55) {
          return;
        }

        state = state.copyWith(jikanMatches: jikanMatches);
        final bestMatch = jikanMatches.first.result;
        final jikanEpisodes = await _jikan.getEpisodes(bestMatch.mal_id, 1);

        if (jikanEpisodes.isEmpty) return;

        final updatedEpisodes = List.of(state.episodes);
        for (int i = 0;
            i < updatedEpisodes.length && i < jikanEpisodes.length;
            i++) {
          updatedEpisodes[i] =
              updatedEpisodes[i].copyWith(title: jikanEpisodes[i].title);
        }

        state = state.copyWith(episodes: updatedEpisodes);
      },
      errorTitle: "Jikan Sync",
      errorMessage: "Couldn't sync Jikan episode titles.",
      showSnackBar: false, // Non-critical error
    );
  }

  /// Fetches the streaming sources (video links, subtitles) for the current episode.
  Future<void> _fetchStreamData({Duration startAt = Duration.zero}) async {
    final episodeIdx = state.selectedEpisodeIdx;
    if (episodeIdx == null) return;

    state = state.copyWith(sourceLoading: true, error: null);

    final data = await _fetchSources(episodeIdx);

    if (data == null || data.sources.isEmpty) {
      state = state.copyWith(
          sourceLoading: false, error: "No sources found for this episode.");
      return;
    }

    state = state.copyWith(
      sources: data.sources,
      subtitles: data.tracks,
      headers: data.headers,
      selectedSourceIdx: 0,
    );

    await _loadAndPlaySource(0, startAt: startAt);
  }

  /// Determines the source type and fetches the source data.
  Future<BaseSourcesModel?> _fetchSources(int episodeIdx) async {
    final episode = state.episodes[episodeIdx];
    final useMangayomi = _experimentalFeatures.useMangayomiExtensions;
    final url = episode.url;

    if (useMangayomi && url != null && url.isNotEmpty) {
      return await _safeRun(
        () async {
          final sources = await _sourceNotifier.getSources(url);
          return BaseSourcesModel(
            sources: sources
                .map((s) => Source(
                      url: s?.url,
                      isM3U8: s?.url.contains('.m3u8') ?? false,
                      isDub:
                          s?.originalUrl.toLowerCase().contains('dub') ?? false,
                      quality: s?.quality,
                    ))
                .toList(),
            tracks: sources.firstOrNull?.subtitles
                    ?.map((sub) => Subtitle(url: sub.file, lang: sub.label))
                    .toList() ??
                [],
          );
        },
        errorTitle: "Mangayomi Stream",
        errorMessage: "Failed to get sources from Mangayomi.",
      );
    }

    final animeProvider = _getProvider();
    if (animeProvider == null) throw Exception("Legacy provider not selected.");

    return await _safeRun(
      () => animeProvider.getSources(
        episode.id ?? '',
        episode.id ?? '',
        state.selectedServer,
        state.selectedCategory,
      ),
      errorTitle: "Legacy Stream",
      errorMessage: "Failed to get sources from Legacy provider.",
    );
  }

  /// Loads a source, extracts qualities if necessary, and starts playback.
  Future<void> _loadAndPlaySource(int sourceIndex,
      {Duration startAt = Duration.zero}) async {
    await _safeRun(() async {
      if (sourceIndex < 0 || sourceIndex >= state.sources.length) {
        throw Exception("Invalid source index.");
      }
      final source = state.sources[sourceIndex];
      final sourceUrl = source.url;
      if (sourceUrl == null || sourceUrl.isEmpty) {
        throw Exception("Source URL is empty.");
      }

      final qualities = await _extractQualitiesFromSource(source);
      final urlToPlay =
          qualities.isNotEmpty ? qualities.first['url'] : sourceUrl;

      if (urlToPlay == null) {
        throw Exception("No playable URL found in the selected source.");
      }

      state = state.copyWith(
        qualityOptions: qualities,
        selectedSourceIdx: sourceIndex,
        selectedQualityIdx: qualities.isNotEmpty ? 0 : null,
      );

      ref
          .read(playerStateProvider.notifier)
          .open(urlToPlay, startAt, headers: state.headers);
    });
    state = state.copyWith(sourceLoading: false);
  }

  /// Extracts video quality options from a source URL (primarily for M3U8).
  Future<List<Map<String, dynamic>>> _extractQualitiesFromSource(
      Source source) async {
    final url = source.url;
    if (url == null) return [];

    try {
      if (source.isM3U8) {
        return await extractor.extractQualities(url, state.headers ?? {});
      }
      // For non-M3U8, create a single quality option.
      return [
        {'quality': source.quality ?? 'Default', 'url': url}
      ];
    } catch (e) {
      AppLogger.e("Failed to extract qualities: $e");
      // Fallback to the default source URL if extraction fails.
      return [
        {'quality': source.quality ?? 'Default', 'url': url}
      ];
    }
  }
}

final episodeDataProvider =
    AutoDisposeNotifierProvider<EpisodeDataNotifier, EpisodeDataState>(
        EpisodeDataNotifier.new);
