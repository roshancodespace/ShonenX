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
  String? cover;
  String? banner;

  late String? thumbnailUrl;
  late int? totalEpisodes;

  late int positionInMilliseconds;
  late int durationInMilliseconds;

  String? sourceId;
  String? sourceName;
  String? providerId;

  @Index()
  late DateTime lastUpdated;

  Map<String, dynamic> toBackupMap() => {
    'episodeNumber': episodeNumber,
    'animeId': animeId,
    'animeIdMal': animeIdMal,
    'animeTitle': animeTitle,
    'episodeTitle': episodeTitle,
    'cover': cover,
    'banner': banner,
    'thumbnailUrl': thumbnailUrl,
    'totalEpisodes': totalEpisodes,
    'positionInMilliseconds': positionInMilliseconds,
    'durationInMilliseconds': durationInMilliseconds,
    'sourceId': sourceId,
    'sourceName': sourceName,
    'providerId': providerId,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  static WatchHistoryEntry fromBackupMap(Map<String, dynamic> m) => WatchHistoryEntry()
    ..episodeNumber = (m['episodeNumber'] as num).toDouble()
    ..animeId = m['animeId'] as String
    ..animeIdMal = m['animeIdMal'] as String?
    ..animeTitle = m['animeTitle'] as String
    ..episodeTitle = m['episodeTitle'] as String?
    ..cover = m['cover'] as String?
    ..banner = m['banner'] as String?
    ..thumbnailUrl = m['thumbnailUrl'] as String?
    ..totalEpisodes = m['totalEpisodes'] as int?
    ..positionInMilliseconds = m['positionInMilliseconds'] as int
    ..durationInMilliseconds = m['durationInMilliseconds'] as int
    ..sourceId = m['sourceId'] as String?
    ..sourceName = m['sourceName'] as String?
    ..providerId = m['providerId'] as String?
    ..lastUpdated = DateTime.tryParse(m['lastUpdated'] as String? ?? '') ?? DateTime.now();
}
