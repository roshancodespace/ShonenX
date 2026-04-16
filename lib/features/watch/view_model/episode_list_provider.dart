import 'dart:async';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:collection/collection.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shonenx/core/jikan/jikan_service.dart';
import 'package:shonenx/core/jikan/models/jikan_media.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/shared/providers/anime_source_provider.dart';
import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/models/settings/experimental_model.dart';
import 'package:shonenx/shared/providers/settings/experimental_notifier.dart';
import 'package:shonenx/shared/providers/settings/source_notifier.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/main.dart';

part 'episode_list_provider.g.dart';

@immutable
class EpisodeListState {
  final String? animeId;
  final String? animeTitle;
  final List<EpisodeDataModel> episodes;
  final List<({JikanMedia result, double similarity})> jikanMatches;
  final bool isLoading;
  final bool isJikanSyncing;
  final String? error;

  const EpisodeListState({
    this.animeId,
    this.animeTitle,
    this.episodes = const [],
    this.jikanMatches = const [],
    this.isLoading = false,
    this.isJikanSyncing = false,
    this.error,
  });

  EpisodeListState copyWith({
    String? animeId,
    String? animeTitle,
    List<EpisodeDataModel>? episodes,
    List<({JikanMedia result, double similarity})>? jikanMatches,
    bool? isLoading,
    bool? isJikanSyncing,
    String? error,
  }) {
    return EpisodeListState(
      animeId: animeId ?? this.animeId,
      animeTitle: animeTitle ?? this.animeTitle,
      episodes: episodes ?? this.episodes,
      jikanMatches: jikanMatches ?? this.jikanMatches,
      isLoading: isLoading ?? this.isLoading,
      isJikanSyncing: isJikanSyncing ?? this.isJikanSyncing,
      error: error,
    );
  }

  EpisodeDataModel? getEpisode(int episode) => episodes.firstWhereOrNull((e) => e.number == episode);
}

@Riverpod(keepAlive: true)
class EpisodeListNotifier extends _$EpisodeListNotifier {
  final JikanService _jikan = JikanService();

  ExperimentalFeaturesModel get _exp => ref.read(experimentalProvider);
  AnimeProvider? get _animeProvider => ref.read(selectedAnimeProvider);
  SourceNotifier get _sourceNotifier => ref.read(sourceProvider.notifier);

  @override
  EpisodeListState build() => const EpisodeListState();

  // --- Core Fetching Logic ---

  Future<List<EpisodeDataModel>> fetchEpisodes({
    required String animeTitle,
    String? animeId,
    required bool force,
    List<EpisodeDataModel> episodes = const [],
    DMedia? media,
  }) async {
    // 1. Check Cache
    if (!force && state.episodes.isNotEmpty && state.animeId == animeId) {
      AppLogger.d('Episode list cache hit for: $animeTitle');
      return state.episodes;
    }

    state = state.copyWith(isLoading: true, error: null, animeId: animeId, animeTitle: animeTitle);
    AppLogger.section('Fetching Episodes: $animeTitle');

    // 2. Use provided episodes if available
    if (episodes.isNotEmpty) {
      AppLogger.success('Using ${episodes.length} pre-provided episodes');
      state = state.copyWith(episodes: episodes, isLoading: false);
      _syncJikanIfEnabled();
      return episodes;
    }

    // 3. Fetch from remote sources
    final fetched = await _fetchEpisodesInternal(animeId, media: media);

    if (fetched.isEmpty) {
      AppLogger.fail('No episodes found for $animeTitle');
      state = state.copyWith(isLoading: false, error: 'No episodes found');
      return [];
    }

    AppLogger.success('Successfully loaded ${fetched.length} episodes');
    state = state.copyWith(episodes: fetched, isLoading: false);
    _syncJikanIfEnabled();
    
    return fetched;
  }

  Future<void> refreshEpisodes() async {
    final id = state.animeId;
    final title = state.animeTitle;
    if (id == null || title == null) return;

    await fetchEpisodes(animeId: id, animeTitle: title, force: true);
  }

  void reset() => state = const EpisodeListState();

  // --- Internal Source Routing ---

  Future<List<EpisodeDataModel>> _fetchEpisodesInternal(String? animeId, {DMedia? media}) async {
    try {
      return _exp.useExtensions 
          ? await _fetchExtensionEpisodes(media) 
          : await _fetchLegacyEpisodes(animeId);
    } catch (e, st) {
      AppLogger.e('Episode fetch pipeline failed', e, st);
      showAppSnackBar('Episode Fetch', 'Failed to load episodes', type: ContentType.failure);
      reset();
      return [];
    }
  }

  Future<List<EpisodeDataModel>> _fetchExtensionEpisodes(DMedia? media) async {
    if (media == null) return [];

    AppLogger.d('Fetching episodes via Extensions');
    final details = await _sourceNotifier.getDetails(media);
    final chapters = details?.episodes ?? [];

    final mapped = chapters.map((ch) {
      // Safely extract episode number string before parsing
      final numStr = ch.episodeNumber.isNotEmpty 
          ? ch.episodeNumber 
          : RegExp(r'\d+').firstMatch(ch.name ?? '')?.group(0) ?? '';
          
      return EpisodeDataModel(
        title: ch.name,
        url: ch.url,
        isFiller: false,
        number: int.tryParse(numStr),
      );
    }).toList();

    // Sort ascending if valid numbers exist
    if (mapped.isNotEmpty && mapped.first.number != null) {
      mapped.sort((a, b) => (a.number ?? 999999).compareTo(b.number ?? 999999));
    }

    return mapped;
  }

  Future<List<EpisodeDataModel>> _fetchLegacyEpisodes(String? animeId) async {
    final provider = _animeProvider;
    if (provider == null || animeId == null) {
      AppLogger.warning('Legacy provider or AnimeID is null');
      return [];
    }

    AppLogger.d('Fetching episodes via Legacy Provider: $provider');
    return (await provider.getEpisodes(animeId)).episodes ?? [];
  }

  // --- Jikan Metadata Syncing ---

  void _syncJikanIfEnabled() {
    if (!_exp.episodeTitleSync || state.episodes.isEmpty || state.animeTitle == null) {
      return;
    }

    state = state.copyWith(isJikanSyncing: true);
    AppLogger.i('Initializing Jikan title sync for: ${state.animeTitle}');
    
    // unawaited ensures Riverpod doesn't block while fetching non-critical metadata
    unawaited(
      _syncWithJikan().whenComplete(() => state = state.copyWith(isJikanSyncing: false)),
    );
  }

  Future<void> _syncWithJikan() async {
    try {
      var matches = state.jikanMatches;

      // Only search Jikan if we haven't already cached the matches
      if (matches.isEmpty) {
        final searchResults = await _jikan.getSearch(title: state.animeTitle!, limit: 10);
        matches = getBestMatches<JikanMedia>(
          results: searchResults,
          title: state.animeTitle!,
          nameSelector: (e) => e.title,
          idSelector: (e) => e.malId.toString(),
        );
      }

      if (matches.isEmpty || matches.first.similarity < 0.55) {
        AppLogger.warning('No strong Jikan match found for title sync. Aborting sync.');
        return;
      }

      state = state.copyWith(jikanMatches: matches);
      final malId = matches.first.result.malId;
      
      AppLogger.d('Fetching MAL episode data for ID: $malId');
      final jikanEpisodes = await _jikan.getEpisodes(malId, 1);

      if (jikanEpisodes.isEmpty) return;

      // Create a mutable copy of the list to update titles
      final updated = List<EpisodeDataModel>.of(state.episodes);
      final count = updated.length.clamp(0, jikanEpisodes.length);

      for (var i = 0; i < count; i++) {
        updated[i] = updated[i].copyWith(title: jikanEpisodes[i].title);
      }

      AppLogger.success('Successfully synced $count episode titles from Jikan');
      state = state.copyWith(episodes: updated);
      
    } catch (e, st) {
      AppLogger.w('Jikan sync failed dynamically', e, st);
    }
  }
}