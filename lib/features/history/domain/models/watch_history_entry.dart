import 'package:isar_community/isar.dart';

part 'watch_history_entry.g.dart';

@collection
class WatchHistoryEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late double episodeNumber;

  late String animeId;
  late String? animeIdMal;
  late String animeTitle;
  String? episodeTitle;

  late String? thumbnailUrl;
  late int? totalEpisodes;

  late int positionInMilliseconds;
  late int durationInMilliseconds;

  String? sourceId;
  String? sourceName;
  String? providerId;

  @Index()
  late DateTime lastUpdated;
}
