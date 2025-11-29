import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/main.dart';

final watchProgressRepositoryProvider =
    Provider<WatchProgressRepository>((ref) {
  return WatchProgressRepository();
});

class WatchProgressRepository {
  final Box<AnimeWatchProgressEntry> _box;

  WatchProgressRepository()
      : _box = Hive.box<AnimeWatchProgressEntry>('anime_watch_progress');

  Future<void> saveProgress(AnimeWatchProgressEntry entry) async {
    try {
      await _box.put(entry.animeId, entry);
      AppLogger.d(
          'Saved progress for anime: ${entry.animeTitle} (ID: ${entry.animeId})');
    } catch (e, st) {
      AppLogger.e('Failed to save anime progress', e, st);
      showAppSnackBar(
        'Save Failed',
        'Failed to automatically save watch progress.',
        type: ContentType.failure,
      );
    }
  }

  AnimeWatchProgressEntry? getProgress(String animeId) {
    return _box.get(animeId);
  }

  Future<void> updateEpisodeProgress(
      String animeId, EpisodeProgress episodeProgress) async {
    final entry = _box.get(animeId);
    if (entry != null) {
      final updatedEpisodes =
          Map<int, EpisodeProgress>.from(entry.episodesProgress);
      updatedEpisodes[episodeProgress.episodeNumber] = episodeProgress;

      final updatedEntry = entry.copyWith(
        episodesProgress: updatedEpisodes,
        lastUpdated: DateTime.now(),
        currentEpisode: episodeProgress.episodeNumber,
      );

      await saveProgress(updatedEntry);
    } else {
      AppLogger.w(
          'Cannot update episode progress: Entry not found for anime ID $animeId');
      showAppSnackBar(
        'Save Failed',
        'Failed to automatically save watch progress.',
        type: ContentType.failure,
      );
    }
  }

  EpisodeProgress? getEpisodeProgress(String animeId, int episodeNumber) {
    final entry = _box.get(animeId);
    return entry?.episodesProgress[episodeNumber];
  }

  Future<void> deleteProgress(String animeId) async {
    await _box.delete(animeId);
    AppLogger.d('Deleted progress for anime: $animeId');
  }

  List<AnimeWatchProgressEntry> getAllProgress() {
    return _box.values.toList();
  }
}
