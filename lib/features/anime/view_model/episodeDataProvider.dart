// ignore_for_file: public_member_api_docs, sort_constructors_first
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
import 'package:shonenx/features/anime/view_model/playerStateProvider.dart';
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
  JikanService get _jikan => JikanService();
  ExperimentalFeaturesModel get _experimentalFeatures =>
      ref.read(experimentalProvider);
  AnimeProvider get _animeProvider => ref.read(selectedAnimeProvider)!;
  SourceNotifier get _sourceNotifier => ref.read(sourceProvider.notifier);

  @override
  EpisodeDataState build() {
    return const EpisodeDataState();
  }

  /// Centralized safe async runner
  Future<T?> _safeRun<T>(
    Future<T> Function() task, {
    String? errorTitle,
    String? errorMessage,
    bool showSnackBar = true,
  }) async {
    try {
      return await task();
    } catch (e, st) {
      AppLogger.e('Error: $e\n$st');
      final title = errorTitle ?? 'Error';
      final msg = errorMessage ?? 'Something went wrong.';
      state = state.copyWith(error: msg);

      if (showSnackBar) {
        showAppSnackBar(title, msg, type: ContentType.failure);
      }
      return null;
    }
  }

  Future<List<EpisodeDataModel>> fetchEpisodes({
    required String animeTitle,
    required String animeId,
    required bool force,
    bool play = true,
    List<EpisodeDataModel> episodes = const [],
    int initialEpisodeIdx = 0,
    Duration startAt = Duration.zero,
    String? mMangaUrl,
  }) async {
    state = state.copyWith(
      episodesLoading: true,
      error: null,
      animeId: animeId,
      animeTitle: animeTitle,
      mMangaUrl: mMangaUrl,
    );
    final useMangayomi = _experimentalFeatures.useMangayomiExtensions;

    // --- Skip fetching if already have episodes and not forced ---
    if (!force && episodes.isNotEmpty) {
      state = state.copyWith(episodes: episodes, episodesLoading: false);
      syncEpisodesWithJikan(page: 1);

      await _setupServersAndMaybePlay(play, initialEpisodeIdx, startAt,
          useMangayomi: useMangayomi);
      return episodes;
    }

    // --- Fetch episodes depending on source type ---
    if (useMangayomi && (state.mMangaUrl != null || mMangaUrl != null)) {
      AppLogger.w('Fetching episodes using Mangayomi extension');
      final url = state.mMangaUrl ?? mMangaUrl!;
      episodes = await _safeRun<List<EpisodeDataModel>>(
            () async {
              final details = await _sourceNotifier.getDetails(url);
              final mapped = details?.chapters
                      ?.map(
                        (ch) => EpisodeDataModel(
                          isFiller: false,
                          title: ch.name,
                          url: ch.url,
                          number: int.tryParse(
                            RegExp(r'\d+')
                                    .firstMatch(ch.name ?? '')
                                    ?.group(0) ??
                                '',
                          ),
                        ),
                      )
                      .toList() ??
                  [];

              // 🔑 Normalize: sort ascending by number if valid numbers exist
              if (mapped.isNotEmpty) {
                final hasNumbers =
                    mapped.any((e) => e.number != null && e.number! > 0);

                if (hasNumbers) {
                  mapped.sort((a, b) {
                    final na = a.number ?? 999999;
                    final nb = b.number ?? 999999;
                    return na.compareTo(nb);
                  });
                }
              }

              return mapped;
            },
            errorTitle: "Mangayomi",
            errorMessage: "Failed to fetch episodes. (Mangayomi)",
          ) ??
          [];
    } else {
      AppLogger.w('Fetching episodes using Legacy source');
      episodes = await _safeRun<List<EpisodeDataModel>>(
            () async =>
                (await _animeProvider.getEpisodes(animeId)).episodes ?? [],
            errorTitle: "Legacy Source",
            errorMessage: "Failed to fetch episodes.",
          ) ??
          [];
    }

    if (episodes.isEmpty) {
      state = state.copyWith(
        episodesLoading: false,
        error: "No episodes found for this anime.",
      );
      return [];
    }

    // --- Update state ---
    state = state.copyWith(episodes: episodes);
    syncEpisodesWithJikan(page: 1);

    await _setupServersAndMaybePlay(play, initialEpisodeIdx, startAt);

    return episodes;
  }

  Future<void> _setupServersAndMaybePlay(
      bool play, int initialEpisodeIdx, Duration startAt,
      {bool useMangayomi = false}) async {
    List<String> servers = [];
    bool dubOrSubSupport = false;
    if (!useMangayomi) {
      servers = _animeProvider.getSupportedServers();
      dubOrSubSupport = _animeProvider.getDubSubParamSupport();
    }

    state = state.copyWith(
      episodesLoading: false,
      servers: servers,
      selectedServer: servers.isNotEmpty ? servers.first : null,
      dubSubSupport: dubOrSubSupport,
    );

    if (play) {
      await changeEpisode(initialEpisodeIdx, startAt: startAt);
    }
  }

  Future<void> syncEpisodesWithJikan({required int page}) async {
    await _safeRun(() async {
      final shouldSyncEpisodes = _experimentalFeatures.episodeTitleSync;
      if (!shouldSyncEpisodes) return;
      if ((state.episodes.isEmpty &&
              (state.animeTitle == null && state.animeTitle!.isNotEmpty)) &&
          (state.animeId == null && state.animeId!.isNotEmpty)) return;
      List<({JikanMedia result, double similarity})> matchedTitles = [];
      if (state.jikanMatches.isEmpty) {
        matchedTitles = getBestMatches<JikanMedia>(
          results: await _jikan.getSearch(title: state.animeTitle!, limit: 25),
          title: state.animeTitle!,
          nameSelector: (e) => e.title,
          idSelector: (e) => e.mal_id.toString(),
        );
      } else {
        matchedTitles = state.jikanMatches;
      }

      if (matchedTitles.isNotEmpty && matchedTitles.first.similarity >= 0.56) {
        state = state.copyWith(jikanMatches: matchedTitles);
        final bestMatch = matchedTitles.first.result;
        final episodesByJikan =
            await _jikan.getEpisodes(bestMatch.mal_id, page);

        final syncedEpisodes = List.generate(
          state.episodes.length,
          (i) {
            final jikanEp =
                i < episodesByJikan.length ? episodesByJikan[i] : null;
            return state.episodes[i].copyWith(
              title: jikanEp?.title ?? state.episodes[i].title,
            );
          },
        );
        // final syncedEpisodes = state.episodes.map((episode) {
        //   final episodeNumber = episode.number!;

        //   return episode.copyWith(
        //       title: episodesByJikan
        //           .firstWhere((ep) => int.parse(ep.id!) == episodeNumber)
        //           .title);
        // }).toList();

        state = state.copyWith(episodes: syncedEpisodes);
      }
    },
        errorTitle: "JIKAN Sync",
        errorMessage: "Couldn't sync with Jikan episode titles");
  }

  Future<void> refreshEpisodes() async {
    if (state.animeId == null) return;
    fetchEpisodes(
        animeId: state.animeId!, animeTitle: state.animeTitle!, force: true);
  }

  Future<void> toggleDubSub() async {
    if (!state.dubSubSupport) return;
    final newCategory = state.selectedCategory == 'sub' ? 'dub' : 'sub';
    final currentPosition = ref.read(playerStateProvider).position;
    state = state.copyWith(selectedCategory: newCategory);
    await _fetchStreamData(startAt: currentPosition);
  }

  Future<void> changeEpisode(int episodeIdx,
      {Duration startAt = Duration.zero}) async {
    state = state.copyWith(selectedEpisodeIdx: episodeIdx);
    await _fetchStreamData(startAt: startAt);
  }

  Future<void> updateCategoryAndRefresh(String category) async {
    state = state.copyWith(selectedCategory: category);
    await _fetchStreamData();
  }

  Future<void> updateServerAndRefresh(String server) async {
    state = state.copyWith(selectedServer: server);
    await _fetchStreamData();
  }

  Future<void> changeSubtitle(int subtitleIdx) async {
    final subtitle = state.subtitles[subtitleIdx];
    if (subtitle.url == null) return;
    await ref
        .read(playerStateProvider.notifier)
        .setSubtitle(SubtitleTrack.uri(state.subtitles[subtitleIdx].url!));
    state = state.copyWith(selectedSubtitleIdx: subtitleIdx);
  }

  Future<void> changeQuality(int qualityIdx) async {
    if (qualityIdx < 0 || qualityIdx >= state.qualityOptions.length) return;

    final currentPosition = ref.read(playerStateProvider).position;
    final newQualityUrl = state.qualityOptions[qualityIdx]['url'];

    if (newQualityUrl == null) {
      state = state.copyWith(error: "Selected quality has an invalid URL.");
      return;
    }

    state = state.copyWith(selectedQualityIdx: qualityIdx);

    ref
        .read(playerStateProvider.notifier)
        .open(newQualityUrl, currentPosition, headers: state.headers);
  }

  Future<void> changeSource(int sourceIdx) async {
    AppLogger.d("Changed Source to $sourceIdx");

    final currentPosition = ref.read(playerStateProvider).position;
    state = state.copyWith(selectedSourceIdx: sourceIdx);
    await _loadAndPlaySource(sourceIdx, startAt: currentPosition);
  }

  Future<void> changeServer(int serverIdx) async {
    AppLogger.d("Changed Server to $serverIdx");

    final currentPosition = ref.read(playerStateProvider).position;
    state = state.copyWith(selectedServer: state.servers[serverIdx]);
    await _fetchStreamData(startAt: currentPosition);
  }

  Future<void> _fetchStreamData({Duration startAt = Duration.zero}) async {
    if (state.selectedEpisodeIdx == null) return;

    state = state.copyWith(sourceLoading: true, error: null);

    await _safeRun(() async {
      final episode = state.episodes[state.selectedEpisodeIdx!];
      late BaseSourcesModel? data;
      final url = state.episodes[state.selectedEpisodeIdx!].url;
      if (url != null &&
          url.isNotEmpty &&
          _experimentalFeatures.useMangayomiExtensions) {
        final sources = await _sourceNotifier.getSources(url);
        data = BaseSourcesModel(
            sources: sources
                .map(
                  (s) => Source(
                    url: s?.url,
                    isM3U8: s?.url.contains('.m3u8') ?? false,
                    isDub:
                        s?.originalUrl.toLowerCase().contains('dub') ?? false,
                    quality: s?.quality,
                  ),
                )
                .toList(),
            tracks: sources[0]
                    ?.subtitles
                    ?.map((sub) => Subtitle(url: sub.file, lang: sub.label))
                    .toList() ??
                []);
      } else {
        data = await _animeProvider.getSources(
          episode.id ?? '',
          episode.id ?? '',
          state.selectedServer,
          state.selectedCategory,
        );
      }

      if (data.sources.isEmpty) {
        throw Exception("No sources found.");
      }

      state = state.copyWith(
        sources: data.sources,
        subtitles: data.tracks,
        headers: data.headers,
        selectedSourceIdx: 0,
      );
      if (url != null && url.isNotEmpty) {
        await _loadAndPlayMSource(0, startAt: startAt);
      } else {
        await _loadAndPlaySource(0, startAt: startAt);
      }
    }, errorTitle: "Stream", errorMessage: "Failed to load stream");
  }

  Future<void> _loadAndPlayMSource(int sourceIdx,
      {Duration startAt = Duration.zero}) async {
    await _safeRun(() async {
      final source = state.sources[sourceIdx];
      state = state.copyWith(
        qualityOptions: [],
        selectedSourceIdx: sourceIdx,
        selectedQualityIdx: null,
      );
      if (source.url == null && source.url!.isEmpty) return;
      ref.read(playerStateProvider.notifier).open(source.url!, startAt);
    },
        errorTitle: 'Source',
        errorMessage: "Failed to load source",
        showSnackBar: true);
  }

  Future<void> _loadAndPlaySource(int sourceIndex,
      {Duration startAt = Duration.zero}) async {
    await _safeRun(() async {
      final source = state.sources[sourceIndex];
      final qualities = await _extractQualitiesFromSource(source);

      final urlToPlay =
          qualities.isNotEmpty ? qualities.first['url'] : source.url;

      if (urlToPlay == null) {
        throw Exception("No playable URL in the selected source.");
      }

      state = state.copyWith(
        qualityOptions: qualities,
        selectedSourceIdx: sourceIndex,
        selectedQualityIdx: qualities.isNotEmpty ? 0 : null,
      );

      ref.read(playerStateProvider.notifier).open(urlToPlay, startAt);
    },
        errorTitle: "Source",
        errorMessage: "Failed to load source",
        showSnackBar: true);

    state = state.copyWith(sourceLoading: false);
  }

  Future<List<Map<String, dynamic>>> _extractQualitiesFromSource(
      Source source) async {
    if (source.url == null) return [];

    try {
      if (source.isM3U8) {
        return await extractor.extractQualities(source.url!, {});
      } else {
        return [
          {'quality': source.quality ?? 'Default', 'url': source.url}
        ];
      }
    } catch (e) {
      return [
        {'quality': source.quality ?? 'Default', 'url': source.url}
      ];
    }
  }
}

final episodeDataProvider =
    AutoDisposeNotifierProvider<EpisodeDataNotifier, EpisodeDataState>(
        () => EpisodeDataNotifier());
