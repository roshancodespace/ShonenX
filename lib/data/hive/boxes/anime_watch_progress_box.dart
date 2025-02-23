import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';

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

  AnimeWatchProgressEntry? getEntry(int animeId) {
    return _box?.get(animeId);
  }

  Future<void> setEntry(AnimeWatchProgressEntry entry) async {
    await _box?.put(entry.animeId, entry);
  }

  Future<void> deleteEntry(int animeId) async {
    await _box?.delete(animeId);
  }

  List<AnimeWatchProgressEntry> getAllEntries() {
    return _box?.values.toList() ?? [];
  }

  Future<void> clearAll() async {
    await _box?.clear();
  }

  /// Update progress for a specific episode of an anime
  Future<void> updateEpisodeProgress({
    required int animeId,
    required int episodeNumber,
    required String episodeTitle,
    required String? episodeThumbnail,
    required int progressInSeconds,
    required int durationInSeconds,
    bool isCompleted = false,
  }) async {
    final existingEntry = getEntry(animeId);

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
      // If anime doesn't exist in box, create a new entry with this episode
      final newEntry = AnimeWatchProgressEntry(
        animeId: animeId,
        animeTitle: 'Unknown Title', // Or pass this in a real case
        animeFormat: 'Unknown Format',
        animeCover: '',
        totalEpisodes: 0, // Set appropriately if known
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

  /// Get the most recently watched anime entry based on `lastUpdated`
  AnimeWatchProgressEntry? getMostRecentEntry() {
    final allEntries = getAllEntries();
    if (allEntries.isEmpty) return null;

    // Sort by lastUpdated in descending order (most recent first)
    allEntries.sort(
      (a, b) => (b.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );

    return allEntries.first;
  }

  /// Get the most recently watched episode across all anime entries
  EpisodeProgress? getMostRecentWatchedEpisode() {
    final allEntries = getAllEntries();
    if (allEntries.isEmpty) return null;

    EpisodeProgress? mostRecentEpisode;
    DateTime? latestWatchedAt;

    for (final entry in allEntries) {
      for (final episode in entry.episodesProgress.values) {
        if (episode.watchedAt != null &&
            (latestWatchedAt == null ||
                episode.watchedAt!.isAfter(latestWatchedAt!))) {
          mostRecentEpisode = episode;
          latestWatchedAt = episode.watchedAt;
        }
      }
    }

    return mostRecentEpisode;
  }

  /// Get all watched episodes across all anime entries, sorted by most recent `watchedAt`
  List<EpisodeProgress> getAllMostRecentWatchedEpisodes() {
    final allEntries = getAllEntries();

    final allWatchedEpisodes = allEntries
        .expand((entry) => entry.episodesProgress.values)
        .where((episode) => episode.watchedAt != null)
        .toList();

    // Sort by watchedAt in descending order (most recent first)
    allWatchedEpisodes.sort((a, b) => b.watchedAt!.compareTo(a.watchedAt!));

    return allWatchedEpisodes;
  }

  /// Get all watched episodes along with their anime entry, sorted by most recent `watchedAt`.
  List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>
      getAllMostRecentWatchedEpisodesWithAnime() {
    final allEntries = getAllEntries();

    final allWatchedEpisodesWithAnime = allEntries.expand((entry) {
      return entry.episodesProgress.values
          .where((episode) => episode.watchedAt != null)
          .map((episode) => (anime: entry, episode: episode));
    }).toList();

    // Sort by watchedAt in descending order (most recent first)
    allWatchedEpisodesWithAnime
        .sort((a, b) => b.episode.watchedAt!.compareTo(a.episode.watchedAt!));
    return allWatchedEpisodesWithAnime;
  }

  /// Get the most recent watched episode progress for a specific anime by animeId.
  EpisodeProgress? getMostRecentEpisodeProgressByAnimeId(int animeId) {
    final entry = getEntry(animeId);

    if (entry == null) return null;

    final watchedEpisodes = entry.episodesProgress.values
        .where((episode) => episode.watchedAt != null)
        .toList();

    if (watchedEpisodes.isEmpty) return null;

    // Sort watched episodes by `watchedAt` in descending order (most recent first)
    watchedEpisodes.sort((a, b) => b.watchedAt!.compareTo(a.watchedAt!));

    return watchedEpisodes.first;
  }
}
