// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:hive/hive.dart';

part 'continue_watching_model.g.dart';

@HiveType(typeId: 5)
class ContinueWatchingEntry extends HiveObject {
  @HiveField(0)
  final int? animeId;
  @HiveField(1)
  final String? animeTitle;
  @HiveField(2)
  final String? animeFormat; 
  @HiveField(3)
  final String? episodeTitle; 
  @HiveField(4)
  final int? episodeNumber; 
  @HiveField(5)
  final String? episodeThumbnail;
  @HiveField(6)
  final String? animeCover;
  @HiveField(7)
  final int? totalEpisodes;
  @HiveField(8)
  final int? progressInSeconds;
  @HiveField(9)
  final int? durationInSeconds;
  @HiveField(10)
  final String? lastUpdated;

  ContinueWatchingEntry({
    this.animeId,
    this.animeTitle,
    this.animeFormat, // Added anime format to constructor
    this.episodeTitle, // Added episode title to constructor
    this.episodeNumber, // Added episode number to constructor
    this.episodeThumbnail,
    this.animeCover, // Added anime cover to constructor
    this.totalEpisodes,
    this.progressInSeconds,
    this.durationInSeconds,
    this.lastUpdated,
  });



  ContinueWatchingEntry copyWith({
    int? animeId,
    String? animeTitle,
    String? animeFormat,
    String? episodeTitle,
    int? episodeNumber,
    String? episodeThumbnail,
    String? animeCover,
    int? totalEpisodes,
    int? progressInSeconds,
    int? durationInSeconds,
    String? lastUpdated,
  }) {
    return ContinueWatchingEntry(
      animeId: animeId ?? this.animeId,
      animeTitle: animeTitle ?? this.animeTitle,
      animeFormat: animeFormat ?? this.animeFormat,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      episodeThumbnail: episodeThumbnail ?? this.episodeThumbnail,
      animeCover: animeCover ?? this.animeCover,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      progressInSeconds: progressInSeconds ?? this.progressInSeconds,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
