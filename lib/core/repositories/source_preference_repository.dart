import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/app_utils.dart';
import 'package:shonenx/data/isar/isar_source_preference.dart';
import 'package:shonenx/main.dart';

final sourcePreferenceRepositoryProvider = Provider<SourcePreferenceRepository>(
  (ref) {
    return SourcePreferenceRepository();
  },
);

class SourcePreferenceRepository {
  SourcePreferenceRepository();

  // --- Source Selection ---

  Future<void> saveSourcePreference(
    String animeId,
    String animeCover,
    IsarSourcePreference preference,
  ) async {
    try {
      final id = fastHash(animeId);
      final entry = isar.isarSourcePreferences.getSync(id);

      final updatedEntry = entry != null
          ? (entry
              ..sourceId = preference.sourceId
              ..sourceType = preference.sourceType
              ..matchedAnimeId = preference.matchedAnimeId
              ..animeCover = animeCover
              ..matchedAnimeTitle = preference.matchedAnimeTitle ?? 'Unknown')
          : IsarSourcePreference(
              id: id,
              animeId: animeId,
              matchedAnimeTitle: preference.matchedAnimeTitle ?? 'Unknown',
              animeCover: animeCover,
              sourceId: preference.sourceId,
              sourceType: preference.sourceType,
              matchedAnimeId: preference.matchedAnimeId,
            );

      await isar.writeTxn(() async {
        await isar.isarSourcePreferences.put(updatedEntry);
      });
      AppLogger.d('Saved source preference for ID: $animeId');
    } catch (e, st) {
      AppLogger.e('Failed to save source preference', e, st);
    }
  }

  IsarSourcePreference? getSourcePreference(String animeId) {
    return isar.isarSourcePreferences.getSync(fastHash(animeId));
  }
}
