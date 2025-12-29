import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/main.dart';

final watchProgressRepositoryProvider =
    Provider<WatchProgressRepository>((ref) {
  return WatchProgressRepository();
});

final watchProgressStreamProvider =
    StreamProvider.autoDispose<List<AnimeWatchProgressEntry>>((ref) {
  final repository = ref.watch(watchProgressRepositoryProvider);
  return repository.watchAllProgress();
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

      // Preserve existing thumbnail if new one is null
      EpisodeProgress? existingEp =
          updatedEpisodes[episodeProgress.episodeNumber];
      String? thumbnailToUse = episodeProgress.episodeThumbnail;
      if (thumbnailToUse == null && existingEp != null) {
        thumbnailToUse = existingEp.episodeThumbnail;
      }

      final mergedEpisodeProgress = episodeProgress.copyWith(
        episodeThumbnail: thumbnailToUse,
      );

      updatedEpisodes[episodeProgress.episodeNumber] = mergedEpisodeProgress;

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

  Future<void> deleteEpisodeProgress(String animeId, int episodeNumber) async {
    final entry = _box.get(animeId);
    if (entry != null) {
      final updatedEpisodes =
          Map<int, EpisodeProgress>.from(entry.episodesProgress);
      updatedEpisodes.remove(episodeNumber);

      if (updatedEpisodes.isEmpty) {
        await deleteProgress(animeId);
      } else {
        final newCurrentEpisode =
            updatedEpisodes.keys.reduce((a, b) => a > b ? a : b);

        final updatedEntry = entry.copyWith(
          episodesProgress: updatedEpisodes,
          lastUpdated: DateTime.now(),
          currentEpisode: newCurrentEpisode,
        );
        await saveProgress(updatedEntry);
      }
      AppLogger.d(
          'Deleted episode $episodeNumber progress for anime: $animeId');
    }
  }

  Future<void> deleteMultipleProgress(List<String> animeIds) async {
    await _box.deleteAll(animeIds);
    AppLogger.d('Deleted progress for ${animeIds.length} animes');
  }

  List<AnimeWatchProgressEntry> getAllProgress() {
    return _box.values.toList();
  }

  Stream<List<AnimeWatchProgressEntry>> watchAllProgress() async* {
    yield getAllProgress();
    await for (final _ in _box.watch()) {
      yield getAllProgress();
    }
  }
}
