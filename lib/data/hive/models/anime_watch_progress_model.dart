import 'package:hive_ce/hive.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'anime_watch_progress_model.g.dart';

@HiveType(typeId: HiveTypeIds.progressEntry)
class AnimeWatchProgressEntry extends HiveObject {
  @HiveField(0)
  final String animeId;
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

  @HiveField(7)
  final int currentEpisode;

  @HiveField(8)
  final String status;

  AnimeWatchProgressEntry({
    required this.animeId,
    required this.animeTitle,
    required this.animeFormat,
    required this.animeCover,
    required this.totalEpisodes,
    this.episodesProgress = const {},
    this.lastUpdated,
    this.currentEpisode = 1,
    this.status = 'watching',
  });

  AnimeWatchProgressEntry copyWith({
    String? animeId,
    String? animeTitle,
    String? animeFormat,
    String? animeCover,
    int? totalEpisodes,
    Map<int, EpisodeProgress>? episodesProgress,
    DateTime? lastUpdated,
    int? currentEpisode,
    String? status,
  }) {
    return AnimeWatchProgressEntry(
      animeId: animeId ?? this.animeId,
      animeTitle: animeTitle ?? this.animeTitle,
      animeFormat: animeFormat ?? this.animeFormat,
      animeCover: animeCover ?? this.animeCover,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      episodesProgress: episodesProgress ?? this.episodesProgress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      status: status ?? this.status,
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
  @HiveField(5, defaultValue: false)
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
