import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

part 'details_provider.g.dart';

@riverpod
class Details extends _$Details {
  @override
  FutureOr<UniversalMedia> build(int animeId) async {
    final repo = ref.read(animeRepositoryProvider);
    final details = await repo.getAnimeDetails(animeId);
    if (details == null) {
      throw Exception('Failed to fetch anime details');
    }
    return details;
  }

  void init(UniversalMedia initialMedia) {
    if (state is! AsyncData) {
      state = AsyncData(initialMedia);
      fetchDetails();
    }
  }

  Future<void> fetchDetails() async {
    final currentData = state.value;

    if (currentData != null) {
      state = AsyncLoading<UniversalMedia>();
    }

    try {
      final repo = ref.read(animeRepositoryProvider);
      final fresh = await repo.getAnimeDetails(animeId);

      if (fresh != null) {
        state = AsyncData(fresh);
      } else if (currentData != null) {
        state = AsyncData(currentData);
      }
    } catch (e, st) {
      AppLogger.e('Failed to fetch anime details for $animeId', e, st);
      if (currentData != null) {
        state = AsyncData(currentData);
      } else {
        state = AsyncError(e, st);
      }
    }
  }
}
