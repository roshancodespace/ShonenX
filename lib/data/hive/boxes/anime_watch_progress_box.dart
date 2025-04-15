import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'dart:developer' as dev;

class AnimeWatchProgressBox {
  Box<AnimeWatchProgressEntry>? _box;
  final String boxName = 'anime_watch_progress';

  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox<AnimeWatchProgressEntry>(boxName);
      dev.log('Box opened');
    } else {
      _box = Hive.box<AnimeWatchProgressEntry>(boxName);
      dev.log('Box reused');
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
    required String episodeThumbnail, // Changed to non-nullable
    required int progressInSeconds,
    required int durationInSeconds,
    bool isCompleted = false,
  }) async {
    dev.log('Updating episode progress: animeId=${animeMedia.id}, '
        'episode=$episodeNumber, thumbnailLength=${episodeThumbnail.length}');

    // Validate thumbnail
    if (episodeThumbnail.isEmpty) {
      dev.log('WARNING: Empty thumbnail provided, using default');
      episodeThumbnail = _defaultThumbnail();
    }

    final existingEntry = getEntry(animeMedia.id!);

    if (existingEntry != null) {
      final updatedEpisodes =
          Map<int, EpisodeProgress>.from(existingEntry.episodesProgress);

      final updatedEpisode = updatedEpisodes[episodeNumber]?.copyWith(
            episodeTitle: episodeTitle,
            episodeThumbnail: episodeThumbnail, // Explicitly update thumbnail
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
      dev.log('Updated existing entry for episode $episodeNumber');
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
      dev.log('Created new entry for episode $episodeNumber');
    }

    // Verify save
    final savedEntry = getEntry(animeMedia.id!);
    final savedThumbnail =
        savedEntry?.episodesProgress[episodeNumber]?.episodeThumbnail;
    dev.log('Verified save: thumbnailLength=${savedThumbnail?.length ?? 'null'}');
  }

  // Default thumbnail (1x1 blue pixel JPEG)
  String _defaultThumbnail() {
    return 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAAAAAAAD/4QAuRXhpZgAATU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAAqACAAQAAAABAAAAAKADAAQAAAABAAAAAP/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAAAP/EABQBAQAAAAAAAAAAAAAAAAAAAAH/xAAUAQEAAAAAAAAAAAAAAAAAAAAA/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AAAD/2Q==';
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

  List<EpisodeProgress> getAllCompletedEpisodes() {
    final allEntries = getAllEntries();
    return allEntries
        .expand((entry) => entry.episodesProgress.values)
        .where((episode) => episode.isCompleted)
        .toList();
  }

  List<EpisodeProgress> getAllProgressByAnimeId(int animeId) {
    final entry = getEntry(animeId);
    if (entry == null) return [];
    return entry.episodesProgress.values.toList();
  }
}