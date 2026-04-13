import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/repositories/source_preference_repository.dart';
import 'package:shonenx/data/isar/isar_source_preference.dart';
import 'package:shonenx/shared/providers/anime_match_service.dart';
import 'package:shonenx/shared/providers/anime_source_provider.dart';
import 'package:shonenx/shared/providers/settings/content_settings_notifier.dart';

part 'anime_search_notifier.g.dart';

class AnimeSearchState {
  final List<BaseAnimeModel> results;
  final bool isLoading;

  AnimeSearchState({this.results = const [], this.isLoading = true});

  AnimeSearchState copyWith({List<BaseAnimeModel>? results, bool? isLoading}) {
    return AnimeSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class AnimeSearchNotifier extends _$AnimeSearchNotifier {
  Timer? _debounce;
  
  @override
  AnimeSearchState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });
    return AnimeSearchState();
  }

  void tryAutoResolve(UniversalMedia media, bool autoMatch, Function(BaseAnimeModel) onMatch) async {
    final title = media.title.userPreferred;
    performSearch(title);

    if (autoMatch) {
      final match = await ref.read(animeMatchServiceProvider).findBestMatch(media.title);
      if (match != null) {
        onMatch(match);
      }
    }
  }

  Future<void> performSearch(String query) async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await ref.read(animeMatchServiceProvider).search(query);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(results: [], isLoading: false);
    }
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) return;

    _debounce = Timer(const Duration(milliseconds: 600), () {
      performSearch(query);
    });
  }

  void saveSelection(UniversalMedia media, BaseAnimeModel anime) {
    if (ref.read(contentSettingsProvider).smartSourceEnabled) {
      final sourceId = ref.read(selectedProviderKeyProvider);
      if (sourceId != null) {
        final selection = IsarSourcePreference(
          animeId: media.id.toString(),
          sourceId: sourceId,
          sourceType: 'legacy',
          matchedAnimeId: anime.id,
          matchedAnimeTitle: anime.name,
        );

        ref.read(sourcePreferenceRepositoryProvider).saveSourcePreference(
          media.id.toString(),
          (media.coverImage.medium ?? media.coverImage.large)!,
          selection,
        );
      }
    }
  }
}

