import 'package:hive/hive.dart';

part 'continue_watching_model.g.dart';

@HiveType(typeId: 4)
class ContinueWatchingEntry {
  @HiveField(0)
  final int animeId;
  @HiveField(1)
  final String animeTitle;
  @HiveField(2)
  final String animeImage;
  @HiveField(3)
  final int episodeNumber;
  @HiveField(4)
  final int totalEpisodes;
  @HiveField(5)
  final int progressInSeconds;
  @HiveField(6)
  final String lastUpdated;

  ContinueWatchingEntry({
    required this.animeId,
    required this.animeTitle,
    required this.animeImage,
    required this.episodeNumber,
    required this.totalEpisodes,
    required this.progressInSeconds,
    required this.lastUpdated,
  });
}
