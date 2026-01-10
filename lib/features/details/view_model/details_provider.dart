import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

class DetailsNotifier extends StateNotifier<AsyncValue<UniversalMedia>> {
  final Ref ref;
  final int animeId;

  DetailsNotifier(this.ref, this.animeId) : super(const AsyncLoading());

  void init(UniversalMedia initialMedia) {
    if (!state.hasValue) {
      state = AsyncData(initialMedia);
      fetchDetails();
    }
  }

  Future<void> fetchDetails() async {
    final currentData = state.value;
    // Set loading state while preserving previous data
    if (currentData != null) {
      state = AsyncLoading<UniversalMedia>()
          .copyWithPrevious(AsyncData(currentData));
    }

    try {
      final repo = ref.read(animeRepositoryProvider);
      final fresh = await repo.getAnimeDetails(animeId);

      if (fresh != null) {
        state = AsyncData(fresh);
      } else {
        // If fetch returns null (e.g. cancelled?), revert to current data
        if (currentData != null) state = AsyncData(currentData);
      }
    } catch (e, st) {
      AppLogger.e('Failed to fetch anime details for $animeId', e, st);
      // On error, revert to current data silent failure
      if (currentData != null) {
        state = AsyncData(currentData);
      } else {
        state = AsyncError(e, st);
      }
    }
  }
}

final detailsProvider = StateNotifierProvider.family<DetailsNotifier,
    AsyncValue<UniversalMedia>, int>((ref, id) {
  return DetailsNotifier(ref, id);
});
