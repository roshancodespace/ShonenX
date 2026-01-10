import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view_model/episode_list_provider.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/main.dart';

class EpisodesTabState {
  final bool isSearchingMatch;
  final String? bestMatchName;
  final String? animeIdForSource;
  final String selectedRange;
  final List<String> rangeOptions;
  final bool isSortedDescending;
  final String? error;

  const EpisodesTabState({
    this.isSearchingMatch = false,
    this.bestMatchName,
    this.animeIdForSource,
    this.selectedRange = 'All',
    this.rangeOptions = const ['All'],
    this.isSortedDescending = false,
    this.error,
  });

  EpisodesTabState copyWith({
    bool? isSearchingMatch,
    String? bestMatchName,
    String? animeIdForSource,
    String? selectedRange,
    List<String>? rangeOptions,
    bool? isSortedDescending,
    String? error,
    bool setBestMatchNull = false,
  }) {
    return EpisodesTabState(
      isSearchingMatch: isSearchingMatch ?? this.isSearchingMatch,
      bestMatchName:
          setBestMatchNull ? null : (bestMatchName ?? this.bestMatchName),
      animeIdForSource:
          setBestMatchNull ? null : (animeIdForSource ?? this.animeIdForSource),
      selectedRange: selectedRange ?? this.selectedRange,
      rangeOptions: rangeOptions ?? this.rangeOptions,
      isSortedDescending: isSortedDescending ?? this.isSortedDescending,
      error: error ?? this.error,
    );
  }
}

class EpisodesTabNotifier extends StateNotifier<EpisodesTabState> {
  final Ref ref;
  final UniversalTitle mediaTitle;

  EpisodesTabNotifier(this.ref, this.mediaTitle)
      : super(const EpisodesTabState()) {
    _fetchEpisodes();
  }

  Future<void> _fetchEpisodes({bool force = false}) async {
    final episodeListState = ref.read(episodeListProvider);

    if (!force &&
        state.animeIdForSource != null &&
        (episodeListState.episodes.isNotEmpty || episodeListState.isLoading)) {
      return;
    }

    AppLogger.d(
        "Fetching episodes for: ${mediaTitle.english ?? mediaTitle.romaji}");

    final useMangayomi =
        ref.read(experimentalProvider.select((s) => s.useMangayomiExtensions));

    if (force && state.animeIdForSource == null) {
      state = state.copyWith(setBestMatchNull: true);
    }

    try {
      if (state.animeIdForSource == null) {
        state = state.copyWith(isSearchingMatch: true);

        final titles = [
          mediaTitle.english,
          mediaTitle.romaji,
        ]
            .where((t) => t != null && t.trim().isNotEmpty)
            .cast<String>()
            .toList();

        if (titles.isEmpty) throw Exception("No valid title available.");

        List<Map<String, String>> candidates = [];
        Map<String, String>? best;
        String? usedTitle;

        for (final title in titles) {
          // Mangayomi Extensions
          if (useMangayomi) {
            final res = await ref
                .read(sourceProvider.notifier)
                .search(Uri.encodeComponent(title));
            candidates = res.list
                .where((r) => r.name != null && r.link != null)
                .map((r) => {"id": r.link!, "name": r.name!})
                .toList();
          }
          if (!mounted)
            return;
          // Legacy Source
          else {
            final provider = ref.read(selectedAnimeProvider);
            if (provider == null) continue;

            final res = await provider.getSearch(title, null, 1);
            candidates = res.results
                .where((r) => r.id != null && r.name != null)
                .map((r) => {"id": r.id!, "name": r.name!})
                .toList();
          }
          if (!mounted) return;

          if (candidates.isEmpty) continue;

          final matches = getBestMatches<Map<String, String>>(
            results: candidates,
            title: title,
            nameSelector: (r) => r["name"]!,
            idSelector: (r) => r["id"]!,
          );

          if (matches.isNotEmpty && matches.first.similarity >= 0.75) {
            best = matches.first.result;
            usedTitle = title;
            break;
          }
        }

        if (best == null) {
          _fail('Anime Match', 'No suitable match found for any title.',
              ContentType.failure);
          return;
        }

        state = state.copyWith(
          animeIdForSource: best["id"],
          bestMatchName: best["name"],
        );

        AppLogger.d(
            'High-confidence match found: ${best["name"]} (via "$usedTitle")');
      }

      state = state.copyWith(isSearchingMatch: false);

      if (state.bestMatchName == null || state.animeIdForSource == null) {
        _fail('Anime Match', 'No suitable match found for any title.',
            ContentType.failure);
        return;
      }

      await ref.read(episodeListProvider.notifier).fetchEpisodes(
            animeTitle: state.bestMatchName!,
            animeId: state.animeIdForSource,
            force: force,
          );

      if (!mounted) return;

      _updateRanges();
    } catch (err, stack) {
      AppLogger.e(err, stack);
      if (!mounted) return;
      state = state.copyWith(isSearchingMatch: false, error: err.toString());
    } finally {
      if (mounted && state.isSearchingMatch) {
        state = state.copyWith(isSearchingMatch: false);
      }
    }
  }

  void _fail(String title, String message, ContentType type) {
    state = state.copyWith(isSearchingMatch: false, error: message);
    showAppSnackBar(title, message, type: ContentType.failure);
  }

  Future<void> refresh() async {
    state = state.copyWith(
      setBestMatchNull: true,
      selectedRange: 'All',
      isSortedDescending: false,
      error: null,
    );

    await _fetchEpisodes(force: true);
  }

  void setManualMatch(String id, String name) {
    state = state.copyWith(
      animeIdForSource: id,
      bestMatchName: name,
    );
    _fetchEpisodes(force: true);
  }

  void updateRange(String range) {
    state = state.copyWith(selectedRange: range);
  }

  void toggleSort() {
    state = state.copyWith(isSortedDescending: !state.isSortedDescending);
  }

  void _updateRanges() {
    final episodes = ref.read(episodeListProvider).episodes;
    final total = episodes.length;
    final ranges = <String>['All'];
    for (int i = 0; i < total; i += 50) {
      final start = i + 1;
      final end = (i + 50).clamp(0, total);
      ranges.add('$start–$end');
    }

    if (!listEquals(state.rangeOptions, ranges)) {
      state = state.copyWith(rangeOptions: ranges);
    }
  }
}

final episodesTabNotifierProvider = StateNotifierProvider.autoDispose
    .family<EpisodesTabNotifier, EpisodesTabState, UniversalTitle>(
        (ref, title) {
  return EpisodesTabNotifier(ref, title);
});
