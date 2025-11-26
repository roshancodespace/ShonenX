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

  const EpisodeDataState({
    this.animeId,
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
    this.selectedSubtitleIdx = 0,
    this.selectedCategory = 'sub',
    this.dubSubSupport = false,
    this.selectedServer,
    this.episodesLoading = true,
    this.sourceLoading = false,
    this.error,
    this.mMangaUrl,
  });

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

class EpisodeDataNotifier extends AutoDisposeNotifier<EpisodeDataState> {
  JikanService get _jikan => JikanService();
  ExperimentalFeaturesModel get _experimentalFeatures =>
      ref.read(experimentalProvider);
  AnimeProvider? _getProvider() => ref.read(selectedAnimeProvider);
  SourceNotifier get _sourceNotifier => ref.read(sourceProvider.notifier);

  @override
  EpisodeDataState build() {
    return const EpisodeDataState();
  }

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
    AppLogger.i(
        'Fetching episodes for: $animeTitle (Force: $force, Initial Index: $initialEpisodeIdx)');

    if (!force && state.episodes.isNotEmpty) {
      AppLogger.d('Episodes already loaded. Skipping fetch.');
      await _setupAndPlay(play, initialEpisodeIdx, startAt);
      return state.episodes;
    }

    state = state.copyWith(
      episodesLoading: true,
      error: null,
      animeId: animeId,
      animeTitle: animeTitle,
      mMangaUrl: mMangaUrl,
    );

    final fetchedEpisodes = await _fetchEpisodeList(animeId, mMangaUrl);

    if (fetchedEpisodes.isEmpty) {
      AppLogger.w('Episode list returned empty.');
      state = state.copyWith(
        episodesLoading: false,
        error: "No episodes found for this anime.",
      );
      return [];
    }

    AppLogger.i('Fetched ${fetchedEpisodes.length} episodes.');
    state = state.copyWith(episodes: fetchedEpisodes);
    syncEpisodesWithJikan();

    await _setupAndPlay(play, initialEpisodeIdx, startAt);

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

  /// Toggles between 'sub' and 'dub' audio tracks if supported.
  Future<void> toggleDubSub() async {
    if (!state.dubSubSupport) {
      AppLogger.w('Toggle failed: Dub/Sub switching is not supported.');
      return;
    }
    final newCategory = state.selectedCategory == 'sub' ? 'dub' : 'sub';
    final currentPosition = ref.read(playerStateProvider).position;
    AppLogger.i(
        'Toggling category from ${state.selectedCategory} to $newCategory.');
    state = state.copyWith(selectedCategory: newCategory);
    await _fetchStreamData(startAt: currentPosition);
  }

  /// Changes the current episode and fetches its stream data.
  Future<void> changeEpisode(int episodeIdx,
      {Duration startAt = Duration.zero}) async {
    if (episodeIdx < 0 || episodeIdx >= state.episodes.length) {
      AppLogger.e('Attempted to change to invalid episode index: $episodeIdx');
      return;
    }
    ref.read(playerStateProvider.notifier).pause();
    AppLogger.i('Changing to episode index: $episodeIdx');
    state = state.copyWith(selectedEpisodeIdx: episodeIdx);
    await _fetchStreamData(startAt: startAt);
  }

  /// Changes the video quality and restarts the player from the current position.
  Future<void> changeQuality(int qualityIdx) async {
    if (qualityIdx < 0 || qualityIdx >= state.qualityOptions.length) {
      AppLogger.e('Attempted to change to invalid quality index: $qualityIdx');
      return;
    }

    final newQualityUrl = state.qualityOptions[qualityIdx]['url'] as String?;
    if (newQualityUrl == null) {
      AppLogger.e('Selected quality $qualityIdx has a null URL.');
      state = state.copyWith(error: "Selected quality has an invalid URL.");
      return;
    }

    AppLogger.i(
        'Changing quality to index: $qualityIdx (${state.qualityOptions[qualityIdx]['quality']})');
    state = state.copyWith(selectedQualityIdx: qualityIdx);
    final currentPosition = ref.read(playerStateProvider).position;
    ref
        .read(playerStateProvider.notifier)
        .open(newQualityUrl, currentPosition, headers: state.headers);
  }

  /// Changes the streaming source and reloads the player.
  Future<void> changeSource(int sourceIdx) async {
    if (sourceIdx < 0 || sourceIdx >= state.sources.length) {
      AppLogger.e('Attempted to change to invalid source index: $sourceIdx');
      return;
    }
    final currentPosition = ref.read(playerStateProvider).position;
    AppLogger.i('Changing source to index: $sourceIdx');
    state = state.copyWith(selectedSourceIdx: sourceIdx);
    await _loadAndPlaySource(sourceIdx, startAt: currentPosition);
  }

  /// Changes the streaming server and reloads the stream.
  Future<void> changeServer(String server) async {
    AppLogger.i('Changing server to: $server');
    final currentPosition = ref.read(playerStateProvider).position;
    state = state.copyWith(selectedServer: server);
    await _fetchStreamData(startAt: currentPosition);
  }

  /// Changes the subtitle track.
  Future<void> changeSubtitle(int subtitleIdx) async {
    AppLogger.i('Changing subtitle to index: $subtitleIdx');
    if (subtitleIdx == 0) {
      AppLogger.i('Changing subtitle to none.');
      await ref
          .read(playerStateProvider.notifier)
          .setSubtitle(SubtitleTrack.no());
      state = state.copyWith(selectedSubtitleIdx: 0);
      return;
    }
    if (subtitleIdx < 0 || subtitleIdx >= state.subtitles.length) {
      AppLogger.e(
          'Attempted to change to invalid subtitle index: $subtitleIdx');
      return;
    }
    final subtitle = state.subtitles[subtitleIdx];
    if (subtitle.url == null) {
      AppLogger.w('Subtitle track at index $subtitleIdx has a null URL.');
      return;
    }

    AppLogger.i('Changing subtitle to index: $subtitleIdx (${subtitle.lang})');
    await ref
        .read(playerStateProvider.notifier)
        .setSubtitle(SubtitleTrack.uri(subtitle.url!));
    state = state.copyWith(selectedSubtitleIdx: subtitleIdx);
  }

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
      AppLogger.e('Error running task: $errorTitle', e, st);
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
      AppLogger.d(
          'Attempting to fetch episodes using Mangayomi extension for URL: $url');
      return await _safeRun<List<EpisodeDataModel>>(
            () async {
              final details = await _sourceNotifier.getDetails(url);
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
      AppLogger.d(
          'Legacy setup: ${servers.length} servers found. Dub/Sub support: $supportDubSub');
    } else {
      AppLogger.d('Mangayomi setup: Skipping server/dub-sub configuration.');
    }

    state = state.copyWith(
      episodesLoading: false,
      servers: servers,
      selectedServer: servers.isNotEmpty ? servers.first : null,
      dubSubSupport: supportDubSub,
    );

    if (play) {
      AppLogger.d(
          'Starting playback from initial episode index: $initialEpisodeIdx');
      await changeEpisode(initialEpisodeIdx, startAt: startAt);
    }
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

  /// Fetches the streaming sources (video links, subtitles) for the current episode.
  Future<void> _fetchStreamData({Duration startAt = Duration.zero}) async {
    final episodeIdx = state.selectedEpisodeIdx;
    if (episodeIdx == null) {
      AppLogger.w('Cannot fetch stream data: selectedEpisodeIdx is null.');
      return;
    }

    AppLogger.i('Fetching stream data for episode index: $episodeIdx');
    state = state.copyWith(sourceLoading: true, error: null);

    final data = await _fetchSources(episodeIdx);

    if (data == null || data.sources.isEmpty) {
      AppLogger.e('Source fetch failed: No sources returned.');
      state = state.copyWith(
          sourceLoading: false, error: "No sources found for this episode.");
      return;
    }

    AppLogger.d(
        'Found ${data.sources.length} sources and ${data.tracks.length} subtitle tracks.');
    state = state.copyWith(
      sources: data.sources,
      subtitles: [Subtitle(lang: 'None'), ...data.tracks],
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
      AppLogger.d('Using Mangayomi source getter for URL: $url');
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
    if (animeProvider == null) {
      AppLogger.e("Legacy provider not selected.");
      throw Exception("Legacy provider not selected.");
    }

    AppLogger.d('Using Legacy source getter for episode ID: ${episode.id}');
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
        AppLogger.e('Load failed: Invalid source index $sourceIndex');
        throw Exception("Invalid source index.");
      }
      final source = state.sources[sourceIndex];
      final sourceUrl = source.url;
      AppLogger.i('Loading source index $sourceIndex: URL: $sourceUrl');

      if (sourceUrl == null || sourceUrl.isEmpty) {
        AppLogger.e("Source URL is empty.");
        throw Exception("Source URL is empty.");
      }

      final qualities = await _extractQualitiesFromSource(source);
      final urlToPlay =
          qualities.isNotEmpty ? qualities.first['url'] : sourceUrl;

      if (urlToPlay == null) {
        AppLogger.e("No playable URL found after quality extraction.");
        throw Exception("No playable URL found in the selected source.");
      }

      AppLogger.d(
          'Playable URL selected: $urlToPlay. Found ${qualities.length} quality options.');

      state = state.copyWith(
        qualityOptions: qualities,
        selectedSourceIdx: sourceIndex,
        selectedQualityIdx: qualities.isNotEmpty ? 0 : null,
      );

      ref
          .read(playerStateProvider.notifier)
          .open(urlToPlay, startAt, headers: state.headers);
    },
        errorTitle: 'Load and Play Source',
        errorMessage: 'Failed to load video source.');

    state = state.copyWith(sourceLoading: false);
  }

  /// Extracts video quality options from a source URL (primarily for M3U8).
  Future<List<Map<String, dynamic>>> _extractQualitiesFromSource(
      Source source) async {
    final url = source.url;
    if (url == null) return [];

    try {
      if (source.isM3U8) {
        AppLogger.d('Extracting qualities from M3U8 URL.');
        return await extractor.extractQualities(url, state.headers ?? {});
      }
      // For non-M3U8, create a single quality option.
      AppLogger.d('Using single non-M3U8 source quality: ${source.quality}');
      return [
        {'quality': source.quality ?? 'Default', 'url': url}
      ];
    } catch (e, st) {
      AppLogger.e("Failed to extract qualities from M3U8 URL: $url", e, st);
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
