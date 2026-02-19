import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anilist/media.dart';

class AnimeWatchProgressEntry {
  final String animeId;
  final String animeTitle;
  final String? animeFormat;
  final String animeCover;
  final int totalEpisodes;
  final Map<int, EpisodeProgress> episodesProgress;
  final DateTime? lastUpdated;
  final int currentEpisode;
  final String status;

  AnimeWatchProgressEntry({
    required this.animeId,
    required this.animeTitle,
    this.animeFormat,
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

  toMedia() {
    return Media(
      id: animeId,
      title: Title(native: animeTitle, romaji: animeTitle, english: animeTitle),
      format: animeFormat,
      coverImage: CoverImage(large: animeCover, medium: animeCover),
      episodes: totalEpisodes,
      status: status,
      startDate: FuzzyDate(
        year: DateTime.now().year,
        month: DateTime.now().month,
        day: DateTime.now().day,
      ),
      endDate: FuzzyDate(
        year: DateTime.now().year,
        month: DateTime.now().month,
        day: DateTime.now().day,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'animeId': animeId,
      'animeTitle': animeTitle,
      'animeFormat': animeFormat,
      'animeCover': animeCover,
      'totalEpisodes': totalEpisodes,
      'episodesProgress': episodesProgress.map(
        (k, v) => MapEntry(k.toString(), v.toMap()),
      ),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'currentEpisode': currentEpisode,
      'status': status,
    };
  }

  factory AnimeWatchProgressEntry.fromMap(Map<String, dynamic> map) {
    return AnimeWatchProgressEntry(
      animeId: map['animeId'] ?? '',
      animeTitle: map['animeTitle'] ?? '',
      animeFormat: map['animeFormat'] ?? '',
      animeCover: map['animeCover'] ?? '',
      totalEpisodes: map['totalEpisodes']?.toInt() ?? 0,
      episodesProgress:
          (map['episodesProgress'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              int.parse(k),
              EpisodeProgress.fromMap(Map<String, dynamic>.from(v)),
            ),
          ) ??
          {},
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'])
          : null,
      currentEpisode: map['currentEpisode']?.toInt() ?? 1,
      status: map['status'] ?? 'watching',
    );
  }
}

class EpisodeProgress {
  final int episodeNumber;
  final String episodeTitle;
  final String? episodeThumbnail;
  final int? progressInSeconds;
  final int? durationInSeconds;
  final bool isCompleted;
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

  Map<String, dynamic> toMap() {
    return {
      'episodeNumber': episodeNumber,
      'episodeTitle': episodeTitle,
      'episodeThumbnail': episodeThumbnail,
      'progressInSeconds': progressInSeconds,
      'durationInSeconds': durationInSeconds,
      'isCompleted': isCompleted,
      'watchedAt': watchedAt?.toIso8601String(),
    };
  }

  factory EpisodeProgress.fromMap(Map<String, dynamic> map) {
    return EpisodeProgress(
      episodeNumber: map['episodeNumber']?.toInt() ?? 0,
      episodeTitle: map['episodeTitle'] ?? '',
      episodeThumbnail: map['episodeThumbnail'],
      progressInSeconds: map['progressInSeconds']?.toInt(),
      durationInSeconds: map['durationInSeconds']?.toInt(),
      isCompleted: map['isCompleted'] ?? false,
      watchedAt: map['watchedAt'] != null
          ? DateTime.tryParse(map['watchedAt'])
          : null,
    );
  }
}
