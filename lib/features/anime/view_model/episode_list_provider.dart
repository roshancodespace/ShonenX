import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/jikan/jikan_service.dart';
import 'package:shonenx/core/jikan/models/jikan_media.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/settings/model/experimental_model.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/main.dart';

@immutable
class EpisodeListState {
  final String? animeId;
  final String? animeTitle;
  final List<EpisodeDataModel> episodes;
  final List<({JikanMedia result, double similarity})> jikanMatches;
  final bool isLoading;
  final String? error;

  const EpisodeListState({
    this.animeId,
    this.animeTitle,
    this.episodes = const [],
    this.jikanMatches = const [],
    this.isLoading = false,
    this.error,
  });

  EpisodeListState copyWith({
    String? animeId,
    String? animeTitle,
    List<EpisodeDataModel>? episodes,
    List<({JikanMedia result, double similarity})>? jikanMatches,
    bool? isLoading,
    String? error,
  }) {
    return EpisodeListState(
      animeId: animeId ?? this.animeId,
      animeTitle: animeTitle ?? this.animeTitle,
      episodes: episodes ?? this.episodes,
      jikanMatches: jikanMatches ?? this.jikanMatches,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class EpisodeListNotifier extends AutoDisposeNotifier<EpisodeListState> {
  JikanService get _jikan => JikanService();
  ExperimentalFeaturesModel get _experimentalFeatures =>
      ref.read(experimentalProvider);
  AnimeProvider? _getProvider() => ref.read(selectedAnimeProvider);
  SourceNotifier get _sourceNotifier => ref.read(sourceProvider.notifier);

  @override
  EpisodeListState build() {
    return const EpisodeListState();
  }

  /// Fetches the list of episodes for a given anime.
  Future<List<EpisodeDataModel>> fetchEpisodes({
    required String animeTitle,
    String? animeId,
    required bool force,
    List<EpisodeDataModel> episodes = const [],
  }) async {
    AppLogger.i('Fetching episodes list for: $animeTitle (Force: $force)');

    if (!force && state.episodes.isNotEmpty && state.animeId == animeId) {
      AppLogger.d('Episodes already loaded. Skipping fetch.');
      return state.episodes;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      animeId: animeId,
      animeTitle: animeTitle,
    );

    if (episodes.isNotEmpty) {
      AppLogger.i('Using provided episode list (${episodes.length} episodes).');
      state = state.copyWith(episodes: episodes, isLoading: false);
      syncEpisodesWithJikan();
      return episodes;
    }

    final fetchedEpisodes = await _fetchEpisodeList(animeId);

    if (fetchedEpisodes.isEmpty) {
      AppLogger.w('Episode list returned empty.');
      state = state.copyWith(
        isLoading: false,
        error: "No episodes found for this anime.",
      );
      return [];
    }

    AppLogger.i('Fetched ${fetchedEpisodes.length} episodes.');
    state = state.copyWith(episodes: fetchedEpisodes, isLoading: false);
    syncEpisodesWithJikan();

    return fetchedEpisodes;
  }

  /// Refreshes the current episode list.
  Future<void> refreshEpisodes() async {
    final animeId = state.animeId;
    final animeTitle = state.animeTitle;
    if (animeId == null || animeTitle == null) {
      AppLogger.w('Cannot refresh: animeId or animeTitle is null.');
      return;
    }
    AppLogger.i('Refreshing episodes for $animeTitle.');
    await fetchEpisodes(animeId: animeId, animeTitle: animeTitle, force: true);
  }

  /// Centralized async function runner with error handling.
  Future<T?> _safeRun<T>(
    Future<T> Function() task, {
    Function(T)? onSuccess,
    Function()? onError,
    String? errorTitle,
    String? errorMessage,
    bool showSnackBar = true,
  }) async {
    try {
      final result = await task();
      onSuccess?.call(result);
      return result;
    } catch (e, st) {
      AppLogger.e('Error running task: $errorTitle', e, st);
      final title = errorTitle ?? 'Error';
      final msg = errorMessage ?? 'Something went wrong.';
      state = state.copyWith(error: msg, isLoading: false);

      if (showSnackBar) {
        showAppSnackBar(title, msg, type: ContentType.failure);
      }
      onError?.call();
      return null;
    }
  }

  /// Determines which source to use and fetches the episode list.
  Future<List<EpisodeDataModel>> _fetchEpisodeList(String? animeId) async {
    final useMangayomi = _experimentalFeatures.useMangayomiExtensions;

    if (useMangayomi) {
      AppLogger.d(
          'Attempting to fetch episodes using Mangayomi extension for URL: $animeId');
      return await _safeRun<List<EpisodeDataModel>>(
            () async {
              final details = await _sourceNotifier.getDetails(animeId!);
              final chapters = details?.chapters ?? [];
              AppLogger.d('Mangayomi returned ${chapters.length} chapters.');

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

              if (mapped.any((e) => e.number != null && e.number! > 0)) {
                mapped.sort((a, b) =>
                    (a.number ?? 999999).compareTo(b.number ?? 999999));
              }
              return mapped;
            },
            errorTitle: "Mangayomi Episode Fetch",
            errorMessage: "Failed to fetch episodes via Mangayomi.",
            onError: () => reset(),
          ) ??
          [];
    }

    AppLogger.d('Attempting to fetch episodes using Legacy source.');
    final animeProvider = _getProvider();
    if (animeProvider == null) {
      AppLogger.e('Legacy AnimeProvider is null.');
      return [];
    }
    if (animeId == null) {
      AppLogger.e('Legacy provider selected but animeId is null.');
      throw Exception('animeId is null');
    }
    return await _safeRun<List<EpisodeDataModel>>(
          () async => (await animeProvider.getEpisodes(animeId)).episodes ?? [],
          errorTitle: "Legacy Source Episode Fetch",
          errorMessage: "Failed to fetch episodes.",
          onError: () => reset(),
        ) ??
        [];
  }

  /// Syncs episode titles with data from Jikan/MAL.
  Future<void> syncEpisodesWithJikan() async {
    if (!_experimentalFeatures.episodeTitleSync || state.episodes.isEmpty) {
      AppLogger.d('Jikan Sync skipped: Disabled or episode list is empty.');
      return;
    }
    final animeTitle = state.animeTitle;
    if (animeTitle == null || animeTitle.isEmpty) {
      AppLogger.w('Jikan Sync skipped: Anime title is empty.');
      return;
    }
    AppLogger.i(
        'Attempting to sync episode titles with Jikan for: $animeTitle');

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
          AppLogger.d(
              'Jikan Sync failed: No good match found (best similarity: ${jikanMatches.firstOrNull?.similarity ?? 0.0}).');
          return;
        }

        state = state.copyWith(jikanMatches: jikanMatches);
        final bestMatch = jikanMatches.first.result;
        AppLogger.d(
            'Best Jikan match: ${bestMatch.title} (MAL ID: ${bestMatch.mal_id})');
        final jikanEpisodes = await _jikan.getEpisodes(bestMatch.mal_id, 1);

        if (jikanEpisodes.isEmpty) {
          AppLogger.d('Jikan returned no episode list for the best match.');
          return;
        }

        final updatedEpisodes = List.of(state.episodes);
        final syncCount = updatedEpisodes.length.clamp(0, jikanEpisodes.length);
        AppLogger.i('Syncing $syncCount episode titles.');

        for (int i = 0; i < syncCount; i++) {
          updatedEpisodes[i] =
              updatedEpisodes[i].copyWith(title: jikanEpisodes[i].title);
        }

        state = state.copyWith(episodes: updatedEpisodes);
      },
      errorTitle: "Jikan Sync",
      errorMessage: "Couldn't sync Jikan episode titles.",
      showSnackBar: false,
    );
  }

  // Reset State
  void reset() {
    state = const EpisodeListState();
  }
}

final episodeListProvider =
    AutoDisposeNotifierProvider<EpisodeListNotifier, EpisodeListState>(
        EpisodeListNotifier.new);
