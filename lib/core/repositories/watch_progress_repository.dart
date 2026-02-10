import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/app_utils.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/data/isar/models/isar_anime_watch_progress.dart';
import 'package:shonenx/main.dart';

final watchProgressRepositoryProvider = Provider<WatchProgressRepository>((
  ref,
) {
  return WatchProgressRepository();
});

final watchProgressStreamProvider =
    StreamProvider.autoDispose<List<AnimeWatchProgressEntry>>((ref) {
      final repository = ref.watch(watchProgressRepositoryProvider);
      return repository.watchAllProgress();
    });

class WatchProgressRepository {
  WatchProgressRepository();

  Future<void> migrateFromHive() async {
    try {
      if (sharedPrefs.getBool('migrated_watch_progress_isar') == true) return;

      AppLogger.i('Starting migration of watch progress to Isar...');

      Box<AnimeWatchProgressEntry> box;
      if (Hive.isBoxOpen('anime_watch_progress')) {
        box = Hive.box<AnimeWatchProgressEntry>('anime_watch_progress');
      } else {
        box = await Hive.openBox<AnimeWatchProgressEntry>(
          'anime_watch_progress',
        );
      }

      if (box.isEmpty) {
        await sharedPrefs.setBool('migrated_watch_progress_isar', true);
        return;
      }

      final entries = box.values.toList();
      final isarEntries = entries.map((e) {
        return IsarAnimeWatchProgress(
          id: fastHash(e.animeId),
          animeId: e.animeId,
          animeTitle: e.animeTitle,
          animeFormat: e.animeFormat,
          animeCover: e.animeCover,
          totalEpisodes: e.totalEpisodes,
          lastUpdated: e.lastUpdated,
          currentEpisode: e.currentEpisode,
          status: e.status,
          episodesProgress: e.episodesProgress.values.map((ep) {
            return IsarEpisodeProgress(
              episodeNumber: ep.episodeNumber,
              episodeTitle: ep.episodeTitle,
              episodeThumbnail: ep.episodeThumbnail,
              progressInSeconds: ep.progressInSeconds,
              durationInSeconds: ep.durationInSeconds,
              isCompleted: ep.isCompleted,
              watchedAt: ep.watchedAt,
            );
          }).toList(),
        );
      }).toList();

      await isar.writeTxn(() async {
        await isar.isarAnimeWatchProgress.putAll(isarEntries);
      });

      await sharedPrefs.setBool('migrated_watch_progress_isar', true);
      AppLogger.success('Successfully migrated ${entries.length} to Isar');
    } catch (e, st) {
      AppLogger.e('Failed to migrate watch progress', e, st);
    }
  }

  Future<void> saveProgress(AnimeWatchProgressEntry entry) async {
    try {
      final isarEntry = IsarAnimeWatchProgress(
        id: fastHash(entry.animeId),
        animeId: entry.animeId,
        animeTitle: entry.animeTitle,
        animeFormat: entry.animeFormat,
        animeCover: entry.animeCover,
        totalEpisodes: entry.totalEpisodes,
        lastUpdated: entry.lastUpdated,
        currentEpisode: entry.currentEpisode,
        status: entry.status,
        episodesProgress: entry.episodesProgress.values.map((ep) {
          return IsarEpisodeProgress(
            episodeNumber: ep.episodeNumber,
            episodeTitle: ep.episodeTitle,
            episodeThumbnail: ep.episodeThumbnail,
            progressInSeconds: ep.progressInSeconds,
            durationInSeconds: ep.durationInSeconds,
            isCompleted: ep.isCompleted,
            watchedAt: ep.watchedAt,
          );
        }).toList(),
      );

      await isar.writeTxn(() async {
        await isar.isarAnimeWatchProgress.put(isarEntry);
      });

      AppLogger.d(
        'Saved progress for anime: ${entry.animeTitle} (ID: ${entry.animeId})',
      );
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
    final isarEntry = isar.isarAnimeWatchProgress.getSync(fastHash(animeId));
    if (isarEntry == null) return null;

    return AnimeWatchProgressEntry(
      animeId: isarEntry.animeId,
      animeTitle: isarEntry.animeTitle,
      animeFormat: isarEntry.animeFormat,
      animeCover: isarEntry.animeCover,
      totalEpisodes: isarEntry.totalEpisodes,
      lastUpdated: isarEntry.lastUpdated,
      currentEpisode: isarEntry.currentEpisode,
      status: isarEntry.status,
      episodesProgress: {
        for (var ep in isarEntry.episodesProgress)
          ep.episodeNumber: EpisodeProgress(
            episodeNumber: ep.episodeNumber,
            episodeTitle: ep.episodeTitle,
            episodeThumbnail: ep.episodeThumbnail,
            progressInSeconds: ep.progressInSeconds,
            durationInSeconds: ep.durationInSeconds,
            isCompleted: ep.isCompleted,
            watchedAt: ep.watchedAt,
          ),
      },
    );
  }

  Future<void> updateEpisodeProgress(
    String animeId,
    EpisodeProgress episodeProgress,
  ) async {
    final entry = getProgress(animeId);
    if (entry != null) {
      final updatedEpisodes = Map<int, EpisodeProgress>.from(
        entry.episodesProgress,
      );

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
        'Cannot update episode progress: Entry not found for anime ID $animeId',
      );
      showAppSnackBar(
        'Save Failed',
        'Failed to automatically save watch progress.',
        type: ContentType.failure,
      );
    }
  }

  EpisodeProgress? getEpisodeProgress(String animeId, int episodeNumber) {
    final entry = getProgress(animeId);
    return entry?.episodesProgress[episodeNumber];
  }

  Future<void> deleteProgress(String animeId) async {
    await isar.writeTxn(() async {
      await isar.isarAnimeWatchProgress.delete(fastHash(animeId));
    });
    AppLogger.d('Deleted progress for anime: $animeId');
  }

  Future<void> deleteEpisodeProgress(String animeId, int episodeNumber) async {
    final entry = getProgress(animeId);
    if (entry != null) {
      final updatedEpisodes = Map<int, EpisodeProgress>.from(
        entry.episodesProgress,
      );
      updatedEpisodes.remove(episodeNumber);

      if (updatedEpisodes.isEmpty) {
        await deleteProgress(animeId);
      } else {
        final newCurrentEpisode = updatedEpisodes.keys.reduce(
          (a, b) => a > b ? a : b,
        );

        final updatedEntry = entry.copyWith(
          episodesProgress: updatedEpisodes,
          lastUpdated: DateTime.now(),
          currentEpisode: newCurrentEpisode,
        );
        await saveProgress(updatedEntry);
      }
      AppLogger.d(
        'Deleted episode $episodeNumber progress for anime: $animeId',
      );
    }
  }

  Future<void> deleteMultipleProgress(List<String> animeIds) async {
    await isar.writeTxn(() async {
      await isar.isarAnimeWatchProgress.deleteAll(
        animeIds.map((id) => fastHash(id)).toList(),
      );
    });
    AppLogger.d('Deleted progress for ${animeIds.length} animes');
  }

  List<AnimeWatchProgressEntry> getAllProgress() {
    final isarEntries = isar.isarAnimeWatchProgress.where().findAllSync();
    return isarEntries.map((isarEntry) {
      return AnimeWatchProgressEntry(
        animeId: isarEntry.animeId,
        animeTitle: isarEntry.animeTitle,
        animeFormat: isarEntry.animeFormat,
        animeCover: isarEntry.animeCover,
        totalEpisodes: isarEntry.totalEpisodes,
        lastUpdated: isarEntry.lastUpdated,
        currentEpisode: isarEntry.currentEpisode,
        status: isarEntry.status,
        episodesProgress: {
          for (var ep in isarEntry.episodesProgress)
            ep.episodeNumber: EpisodeProgress(
              episodeNumber: ep.episodeNumber,
              episodeTitle: ep.episodeTitle,
              episodeThumbnail: ep.episodeThumbnail,
              progressInSeconds: ep.progressInSeconds,
              durationInSeconds: ep.durationInSeconds,
              isCompleted: ep.isCompleted,
              watchedAt: ep.watchedAt,
            ),
        },
      );
    }).toList();
  }

  Stream<List<AnimeWatchProgressEntry>> watchAllProgress() async* {
    yield getAllProgress();
    await for (final _ in isar.isarAnimeWatchProgress.where().watch()) {
      yield getAllProgress();
    }
  }
}
