import 'dart:async';

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
}

class EpisodeListNotifier extends AutoDisposeNotifier<EpisodeListState> {
  final JikanService _jikan = JikanService();

  ExperimentalFeaturesModel get _exp => ref.read(experimentalProvider);

  AnimeProvider? get _animeProvider => ref.read(selectedAnimeProvider);

  SourceNotifier get _sourceNotifier => ref.read(sourceProvider.notifier);

  @override
  EpisodeListState build() => const EpisodeListState();

  /* ───────────────────────── PUBLIC API ───────────────────────── */

  Future<List<EpisodeDataModel>> fetchEpisodes({
    required String animeTitle,
    String? animeId,
    required bool force,
    List<EpisodeDataModel> episodes = const [],
  }) async {
    if (!force && state.episodes.isNotEmpty && state.animeId == animeId) {
      AppLogger.d('Episode list cache hit');
      return state.episodes;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      animeId: animeId,
      animeTitle: animeTitle,
    );

    if (episodes.isNotEmpty) {
      state = state.copyWith(
        episodes: episodes,
        isLoading: false,
      );
      _syncJikanIfEnabled();
      return episodes;
    }

    final fetched = await _fetchEpisodesInternal(animeId);

    if (fetched.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'No episodes found',
      );
      return [];
    }

    state = state.copyWith(
      episodes: fetched,
      isLoading: false,
    );

    _syncJikanIfEnabled();
    return fetched;
  }

  Future<void> refreshEpisodes() async {
    final id = state.animeId;
    final title = state.animeTitle;
    if (id == null || title == null) return;

    await fetchEpisodes(
      animeId: id,
      animeTitle: title,
      force: true,
    );
  }

  void reset() => state = const EpisodeListState();

  /* ───────────────────────── INTERNAL ───────────────────────── */

  Future<List<EpisodeDataModel>> _fetchEpisodesInternal(String? animeId) async {
    try {
      return _exp.useMangayomiExtensions
          ? await _fetchMangayomiEpisodes(animeId)
          : await _fetchLegacyEpisodes(animeId);
    } catch (e, st) {
      AppLogger.e('Episode fetch failed', e, st);
      showAppSnackBar(
        'Episode Fetch',
        'Failed to load episodes',
        type: ContentType.failure,
      );
      reset();
      return [];
    }
  }

  Future<List<EpisodeDataModel>> _fetchMangayomiEpisodes(
      String? animeId) async {
    if (animeId == null) return [];

    final details = await _sourceNotifier.getDetails(animeId);
    final chapters = details?.chapters ?? [];

    final mapped = chapters
        .map(
          (ch) => EpisodeDataModel(
            title: ch.name,
            url: ch.url,
            isFiller: false,
            number: int.tryParse(
              RegExp(r'\d+').firstMatch(ch.name ?? '')?.group(0) ?? '',
            ),
          ),
        )
        .toList();

    if (mapped.any((e) => (e.number ?? 0) > 0)) {
      mapped.sort(
        (a, b) => (a.number ?? 999999).compareTo(b.number ?? 999999),
      );
    }

    return mapped;
  }

  Future<List<EpisodeDataModel>> _fetchLegacyEpisodes(String? animeId) async {
    final provider = _animeProvider;
    if (provider == null || animeId == null) return [];

    return (await provider.getEpisodes(animeId)).episodes ?? [];
  }

  /* ───────────────────────── JIKAN SYNC ───────────────────────── */

  void _syncJikanIfEnabled() {
    if (!_exp.episodeTitleSync ||
        state.episodes.isEmpty ||
        state.animeTitle == null) {
      return;
    }

    state = state.copyWith(isJikanSyncing: true);
    // fire & forget (non-blocking)
    unawaited(_syncWithJikan().whenComplete(() => state = state.copyWith(isJikanSyncing: false)));
  }

  Future<void> _syncWithJikan() async {
    try {
      final matches = state.jikanMatches.isNotEmpty
          ? state.jikanMatches
          : getBestMatches<JikanMedia>(
              results: await _jikan.getSearch(
                title: state.animeTitle!,
                limit: 10,
              ),
              title: state.animeTitle!,
              nameSelector: (e) => e.title,
              idSelector: (e) => e.malId.toString(),
            );

      if (matches.isEmpty || matches.first.similarity < 0.55) {
        return;
      }

      state = state.copyWith(jikanMatches: matches);

      final malId = matches.first.result.malId;
      final jikanEpisodes = await _jikan.getEpisodes(malId, 1);

      if (jikanEpisodes.isEmpty) return;

      final updated = List<EpisodeDataModel>.of(
        state.episodes,
      );

      final count = updated.length.clamp(0, jikanEpisodes.length);

      for (var i = 0; i < count; i++) {
        updated[i] = updated[i].copyWith(
          title: jikanEpisodes[i].title,
        );
      }

      state = state.copyWith(episodes: updated);
    } catch (e, st) {
      AppLogger.w('Jikan sync failed', e, st);
    }
  }
}

final episodeListProvider =
    AutoDisposeNotifierProvider<EpisodeListNotifier, EpisodeListState>(
  EpisodeListNotifier.new,
);
