import 'package:hive/hive.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'anime_watch_progress_model.g.dart';

@HiveType(typeId: HiveTypeIds.progressEntry)
class AnimeWatchProgressEntry extends HiveObject {
  @HiveField(0)
  final int animeId;
  @HiveField(1)
  final String animeTitle;
  @HiveField(2)
  final String animeFormat;
  @HiveField(3)
  final String animeCover;
  @HiveField(4)
  final int totalEpisodes;
  @HiveField(5)
  final Map<int, EpisodeProgress> episodesProgress;

  @HiveField(6)
  final DateTime? lastUpdated;

  AnimeWatchProgressEntry({
    required this.animeId,
    required this.animeTitle,
    required this.animeFormat,
    required this.animeCover,
    required this.totalEpisodes,
    this.episodesProgress = const {},
    this.lastUpdated,
  });

  AnimeWatchProgressEntry copyWith({
    int? animeId,
    String? animeTitle,
    String? animeFormat,
    String? animeCover,
    int? totalEpisodes,
    Map<int, EpisodeProgress>? episodesProgress,
    DateTime? lastUpdated,
  }) {
    return AnimeWatchProgressEntry(
      animeId: animeId ?? this.animeId,
      animeTitle: animeTitle ?? this.animeTitle,
      animeFormat: animeFormat ?? this.animeFormat,
      animeCover: animeCover ?? this.animeCover,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      episodesProgress: episodesProgress ?? this.episodesProgress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

@HiveType(typeId: HiveTypeIds.progressEpisode)
class EpisodeProgress {
  @HiveField(0)
  final int episodeNumber;
  @HiveField(1)
  final String episodeTitle;
  @HiveField(2)
  final String? episodeThumbnail;
  @HiveField(3)
  final int? progressInSeconds; // For continue watching
  @HiveField(4)
  final int? durationInSeconds;
  @HiveField(5)
  final bool isCompleted;
  @HiveField(6)
  final DateTime? watchedAt;

  EpisodeProgress({
    required this.episodeNumber,
    required this.episodeTitle,
    required this.episodeThumbnail,
    this.progressInSeconds,
    this.durationInSeconds,
    this.isCompleted = false,
    this.watchedAt,
  });

  EpisodeProgress copyWith({
    int? episodeNumber,
    String? episodeTitle,
    String? episodeThumbnail,
    int? progressInSeconds,
    int? durationInSeconds,
    bool? isCompleted,
    DateTime? watchedAt,
  }) {
    return EpisodeProgress(
      episodeNumber: episodeNumber ?? this.episodeNumber,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      episodeThumbnail: episodeThumbnail ?? this.episodeThumbnail,
      progressInSeconds: progressInSeconds ?? this.progressInSeconds,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      watchedAt: watchedAt ?? this.watchedAt,
    );
  }
}
