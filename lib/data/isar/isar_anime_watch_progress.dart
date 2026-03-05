import 'package:isar_community/isar.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';

part 'isar_anime_watch_progress.g.dart';

@collection
class IsarAnimeWatchProgress {
  Id? id;

  @Index(unique: true, replace: true)
  late String animeId;

  late String animeTitle;
  late String? animeFormat;
  late String animeCover;
  late int totalEpisodes;

  List<IsarEpisodeProgress> episodesProgress;

  DateTime? lastUpdated;
  int currentEpisode;
  String status;

  IsarAnimeWatchProgress({
    this.id,
    required this.animeId,
    required this.animeTitle,
    this.animeFormat,
    required this.animeCover,
    required this.totalEpisodes,
    this.episodesProgress = const [],
    this.lastUpdated,
    this.currentEpisode = 1,
    this.status = 'watching',
  });

  UniversalMedia toUniversalMedia() {
    return UniversalMedia(
      id: animeId,
      title: UniversalTitle(
        native: animeTitle,
        romaji: animeTitle,
        english: animeTitle,
      ),
      format: animeFormat,
      coverImage: UniversalCoverImage(large: animeCover, medium: animeCover),
      episodes: totalEpisodes,
      status: status,
      startDate: UniversalFuzzyDate(
        year: DateTime.now().year,
        month: DateTime.now().month,
        day: DateTime.now().day,
      ),
      endDate: UniversalFuzzyDate(
        year: DateTime.now().year,
        month: DateTime.now().month,
        day: DateTime.now().day,
      ),
    );
  }
}

@embedded
class IsarEpisodeProgress {
  late int episodeNumber;
  late String episodeTitle;
  String? episodeThumbnail;
  int? progressInSeconds;
  int? durationInSeconds;
  bool isCompleted;
  DateTime? watchedAt;

  IsarEpisodeProgress({
    this.episodeNumber = 0,
    this.episodeTitle = '',
    this.episodeThumbnail,
    this.progressInSeconds,
    this.durationInSeconds,
    this.isCompleted = false,
    this.watchedAt,
  });
}

