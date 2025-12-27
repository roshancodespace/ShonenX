import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';
import 'package:shonenx/features/settings/model/experimental_model.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/player_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';

import 'package:shonenx/main.dart';
import 'package:shonenx/utils/extractors.dart' as extractor;

@immutable
class EpisodeDataState {
  final Map<String, String>? headers;
  final List<Source> sources;
  final List<Subtitle> subtitles;
  final List<Map<String, dynamic>> qualityOptions;
  final List<ServerData> servers;

  final int? selectedQualityIdx;
  final int? selectedSourceIdx;
  final int? selectedEpisodeIdx;
  final int? selectedSubtitleIdx;
  final ServerData? selectedServer;

  final bool sourceLoading;
  final String? error;

  const EpisodeDataState({
    this.sources = const [],
    this.subtitles = const [],
    this.qualityOptions = const [],
    this.servers = const [],
    this.headers,
    this.selectedQualityIdx,
    this.selectedSourceIdx,
    this.selectedEpisodeIdx,
    this.selectedSubtitleIdx = 0,
    this.selectedServer,
    this.sourceLoading = false,
    this.error,
  });

  EpisodeDataState copyWith({
    Map<String, String>? headers,
    List<Source>? sources,
    List<Subtitle>? subtitles,
    List<Map<String, dynamic>>? qualityOptions,
    List<ServerData>? servers,
    int? selectedQualityIdx,
    int? selectedSourceIdx,
    int? selectedEpisodeIdx,
    int? selectedSubtitleIdx,
    ServerData? selectedServer,
    bool? dubSubSupport,
    bool? sourceLoading,
    String? error,
  }) {
    return EpisodeDataState(
      headers: headers ?? this.headers,
      sources: sources ?? this.sources,
      subtitles: subtitles ?? this.subtitles,
      qualityOptions: qualityOptions ?? this.qualityOptions,
      servers: servers ?? this.servers,
      selectedQualityIdx: selectedQualityIdx ?? this.selectedQualityIdx,
      selectedSourceIdx: selectedSourceIdx ?? this.selectedSourceIdx,
      selectedEpisodeIdx: selectedEpisodeIdx ?? this.selectedEpisodeIdx,
      selectedSubtitleIdx: selectedSubtitleIdx ?? this.selectedSubtitleIdx,
      selectedServer: selectedServer ?? this.selectedServer,
      sourceLoading: sourceLoading ?? this.sourceLoading,
      error: error ?? this.error,
    );
  }
}

class EpisodeDataNotifier extends AutoDisposeNotifier<EpisodeDataState> {
  List<EpisodeDataModel> get _episodes =>
      ref.read(episodeListProvider).episodes;

  ExperimentalFeaturesModel get _experimentalFeatures =>
      ref.read(experimentalProvider);
  AnimeProvider? _getProvider() => ref.read(selectedAnimeProvider);
  SourceNotifier get _sourceNotifier => ref.read(sourceProvider.notifier);
  bool get dubSubSupport => state.servers.any((s) => s.isDub == true);

  @override
  EpisodeDataState build() {
    ref.onDispose(() {
      ref.read(episodeListProvider.notifier).reset();
    });
    return const EpisodeDataState();
  }

  /// Loads and plays a specific episode.
  Future<void> loadEpisode({
    required int episodeIdx,
    bool play = true,
    Duration startAt = Duration.zero,
  }) async {
    AppLogger.i('Loading episode index: $episodeIdx');
    state = state.copyWith(selectedEpisodeIdx: episodeIdx);
    await _setupAndPlay(play, episodeIdx, startAt);
  }

  /// Toggles between 'sub' and 'dub' audio tracks if supported.
  Future<void> toggleDubSub() async {
    final newServer =
        state.servers.firstWhere((s) => s.isDub != state.selectedServer?.isDub);
    AppLogger.i(
        'Toggling category from ${state.selectedServer?.isDub == true ? 'dub' : 'sub'} to $newServer.');
    await changeServer(newServer);
  }

  /// Changes the current episode and fetches its stream data.
  Future<void> changeEpisode(int episodeIdx,
      {Duration startAt = Duration.zero}) async {
    if (episodeIdx < 0 || episodeIdx >= _episodes.length) {
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
  Future<void> changeServer(ServerData server) async {
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
      state = state.copyWith(error: msg, sourceLoading: false);

      if (showSnackBar) {
        showAppSnackBar(title, msg, type: ContentType.failure);
      }
      return null;
    }
  }

  /// Configures servers and starts playback if requested.
  Future<void> _setupAndPlay(
      bool play, int initialEpisodeIdx, Duration startAt) async {
    final bool useMangayomi = _experimentalFeatures.useMangayomiExtensions;
    List<ServerData> servers = [];

    if (!useMangayomi) {
      final animeProvider = _getProvider();
      final currentEpisode =
          ref.read(episodeListProvider).episodes[initialEpisodeIdx];
      servers = (await animeProvider?.getSupportedServers(metadata: {
        'id': currentEpisode.id,
        'epNumber': currentEpisode.number
      }))!
          .flatten();
      state = state.copyWith(servers: servers, selectedServer: servers.first);
      AppLogger.d('Legacy setup: ${servers.length} servers found.');
    } else {
      AppLogger.d('Mangayomi setup: Skipping server/dub-sub configuration.');
    }

    if (play) {
      AppLogger.d(
          'Starting playback from initial episode index: $initialEpisodeIdx');
      await changeEpisode(initialEpisodeIdx, startAt: startAt);
    }
  }

  // Return Downloadable Sources
  Future<BaseSourcesModel?> downloadSources(int episodeIdx) async {
    final episode = _episodes[episodeIdx];
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
                    headers: s?.headers))
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
        state.selectedServer?.id,
        state.selectedServer?.isDub == true ? 'dub' : 'sub',
      ),
      errorTitle: "Legacy Stream",
      errorMessage: "Failed to get sources from Legacy provider.",
    );
  }

  /// Reset Entire State
  void reset() {
    state = const EpisodeDataState();
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
      headers: (data.headers as Map<dynamic, dynamic>).cast<String, String>(),
      selectedSourceIdx: 0,
    );

    await _loadAndPlaySource(0, startAt: startAt);
  }

  /// Determines the source type and fetches the source data.
  Future<BaseSourcesModel?> _fetchSources(int episodeIdx) async {
    final episode = _episodes[episodeIdx];
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
        state.selectedServer?.id,
        state.selectedServer?.isDub == true ? 'dub' : 'sub',
      ),
      errorTitle: "Legacy Stream",
      errorMessage: "Failed to get sources from Legacy provider.",
    );
  }

  /// Loads a source, extracts qualities if necessary, and starts playback.
  Future<void> _loadAndPlaySource(int sourceIndex,
      {Duration startAt = Duration.zero}) async {
    final qualityPreference = ref
        .read(playerSettingsProvider)
        .defaultQuality; // Auto | 1080p --- 360p
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
      final qualityIndex = qualityPreference == 'Auto'
          ? 0
          : qualities.indexWhere((q) => (q['quality'] as String)
              .contains(qualityPreference.split('p').first));
      final urlToPlay =
          qualityIndex != -1 ? qualities[qualityIndex]['url'] : sourceUrl;

      if (urlToPlay == null) {
        AppLogger.e("No playable URL found after quality extraction.");
        throw Exception("No playable URL found in the selected source.");
      }

      AppLogger.d(
          'Playable URL selected: $urlToPlay. Found ${qualities.length} quality options.');

      state = state.copyWith(
        qualityOptions: qualities,
        selectedSourceIdx: sourceIndex,
        selectedQualityIdx: qualityIndex,
        selectedSubtitleIdx: state.subtitles
            .indexWhere((s) => s.lang!.toLowerCase().contains('eng')),
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
