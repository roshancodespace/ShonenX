import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:shonenx/shared/models/unified_media.dart';

part 'watch_history_entry.g.dart';

@collection
class WatchHistoryEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true, composite: [CompositeIndex('episodeNumber')])
  late String animeId;

  double episodeNumber = 1.0;

  String? animeIdMal;
  late String animeTitle;
  String? episodeTitle;
  String? cover;
  String? banner;

  String? thumbnailUrl;
  int? totalEpisodes;

  int positionInMilliseconds = 0;
  int durationInMilliseconds = 0;

  String? sourceId;
  String? sourceName;
  String? providerId;

  String? externalIdsJson;

  @ignore
  MediaExternalIds get externalIds {
    if (externalIdsJson != null && externalIdsJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(externalIdsJson!) as Map<String, dynamic>;
        return MediaExternalIds.fromMap(decoded);
      } catch (_) {}
    }
    if (animeIdMal != null && animeIdMal!.isNotEmpty) {
      return MediaExternalIds(mal: animeIdMal);
    }
    return const MediaExternalIds();
  }

  set externalIds(MediaExternalIds ids) {
    animeIdMal = ids.mal;
    final map = ids.toMap();
    externalIdsJson = map.isNotEmpty ? jsonEncode(map) : null;
  }

  @Index()
  DateTime lastUpdated = DateTime.now();

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
    'externalIdsJson': externalIdsJson,
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
    ..externalIdsJson = m['externalIdsJson'] as String?
    ..lastUpdated = DateTime.tryParse(m['lastUpdated'] as String? ?? '') ?? DateTime.now();
}

