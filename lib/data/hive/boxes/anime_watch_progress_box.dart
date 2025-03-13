import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';

// AnimeWatchProgressBox (unchanged from your provided code)
class AnimeWatchProgressBox {
  Box<AnimeWatchProgressEntry>? _box;
  final String boxName = 'anime_watch_progress';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox<AnimeWatchProgressEntry>(boxName);
    } else {
      _box = Hive.box<AnimeWatchProgressEntry>(boxName);
    }
  }

  bool get isInitialized => _box != null;

  ValueListenable<Box<AnimeWatchProgressEntry>> get boxValueListenable =>
      _box!.listenable();

  AnimeWatchProgressEntry? getEntry(int animeId) => _box?.get(animeId);

  Future<void> setEntry(AnimeWatchProgressEntry entry) async =>
      await _box?.put(entry.animeId, entry);

  Future<void> deleteEntry(int animeId) async => await _box?.delete(animeId);

  List<AnimeWatchProgressEntry> getAllEntries() => _box?.values.toList() ?? [];

  Future<void> clearAll() async => await _box?.clear();

  Future<void> updateEpisodeProgress({
    required Media animeMedia,
    required int episodeNumber,
    required String episodeTitle,
    required String? episodeThumbnail,
    required int progressInSeconds,
    required int durationInSeconds,
    bool isCompleted = false,
  }) async {
    final existingEntry = getEntry(animeMedia.id!);

    if (existingEntry != null) {
      final updatedEpisodes =
          Map<int, EpisodeProgress>.from(existingEntry.episodesProgress);

      final updatedEpisode = updatedEpisodes[episodeNumber]?.copyWith(
            progressInSeconds: progressInSeconds,
            durationInSeconds: durationInSeconds,
            isCompleted: isCompleted,
            watchedAt: DateTime.now(),
          ) ??
          EpisodeProgress(
            episodeNumber: episodeNumber,
            episodeTitle: episodeTitle,
            episodeThumbnail: episodeThumbnail,
            progressInSeconds: progressInSeconds,
            durationInSeconds: durationInSeconds,
            isCompleted: isCompleted,
            watchedAt: DateTime.now(),
          );

      updatedEpisodes[episodeNumber] = updatedEpisode;

      final updatedEntry = existingEntry.copyWith(
        episodesProgress: updatedEpisodes,
        lastUpdated: DateTime.now(),
      );

      await setEntry(updatedEntry);
    } else {
      final newEntry = AnimeWatchProgressEntry(
        animeId: animeMedia.id!,
        animeTitle: animeMedia.title?.english ??
            animeMedia.title?.romaji ??
            animeMedia.title?.native ??
            '',
        animeFormat: animeMedia.format ?? '',
        animeCover: animeMedia.coverImage?.large ?? '',
        totalEpisodes: 0,
        episodesProgress: {
          episodeNumber: EpisodeProgress(
            episodeNumber: episodeNumber,
            episodeTitle: episodeTitle,
            episodeThumbnail: episodeThumbnail,
            progressInSeconds: progressInSeconds,
            durationInSeconds: durationInSeconds,
            isCompleted: isCompleted,
            watchedAt: DateTime.now(),
          ),
        },
        lastUpdated: DateTime.now(),
      );

      await setEntry(newEntry);
    }
  }

  AnimeWatchProgressEntry? getMostRecentEntry() {
    final allEntries = getAllEntries();
    if (allEntries.isEmpty) return null;
    allEntries.sort((a, b) =>
        (b.lastUpdated ?? DateTime(0)).compareTo(a.lastUpdated ?? DateTime(0)));
    return allEntries.first;
  }

  EpisodeProgress? getMostRecentWatchedEpisode() {
    final allEntries = getAllEntries();
    if (allEntries.isEmpty) return null;

    EpisodeProgress? mostRecentEpisode;
    DateTime? latestWatchedAt;

    for (final entry in allEntries) {
      for (final episode in entry.episodesProgress.values) {
        if (episode.watchedAt != null &&
            (latestWatchedAt == null ||
                episode.watchedAt!.isAfter(latestWatchedAt))) {
          mostRecentEpisode = episode;
          latestWatchedAt = episode.watchedAt;
        }
      }
    }
    return mostRecentEpisode;
  }

  List<EpisodeProgress> getAllMostRecentWatchedEpisodes() {
    final allEntries = getAllEntries();
    final allWatchedEpisodes = allEntries
        .expand((entry) => entry.episodesProgress.values)
        .where((episode) => episode.watchedAt != null)
        .toList();
    allWatchedEpisodes.sort((a, b) => b.watchedAt!.compareTo(a.watchedAt!));
    return allWatchedEpisodes;
  }

  List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>
      getAllMostRecentWatchedEpisodesWithAnime() {
    final allEntries = getAllEntries();
    final allWatchedEpisodesWithAnime = allEntries.expand((entry) {
      return entry.episodesProgress.values
          .where((episode) => episode.watchedAt != null)
          .map((episode) => (anime: entry, episode: episode));
    }).toList();
    allWatchedEpisodesWithAnime
        .sort((a, b) => b.episode.watchedAt!.compareTo(a.episode.watchedAt!));
    return allWatchedEpisodesWithAnime;
  }

  EpisodeProgress? getMostRecentEpisodeProgressByAnimeId(int animeId) {
    final entry = getEntry(animeId);
    if (entry == null) return null;
    final watchedEpisodes = entry.episodesProgress.values
        .where((episode) => episode.watchedAt != null)
        .toList();
    if (watchedEpisodes.isEmpty) return null;
    watchedEpisodes.sort((a, b) => b.watchedAt!.compareTo(a.watchedAt!));
    return watchedEpisodes.first;
  }

  // New function to get all completed episodes
  List<EpisodeProgress> getAllCompletedEpisodes() {
    final allEntries = getAllEntries();
    return allEntries
        .expand((entry) => entry.episodesProgress.values)
        .where((episode) => episode.isCompleted)
        .toList();
  }

  // New function to get all progress of one anime by anime id
  List<EpisodeProgress> getAllProgressByAnimeId(int animeId) {
    final entry = getEntry(animeId);
    if (entry == null) return [];
    return entry.episodesProgress.values.toList();
  }
}
