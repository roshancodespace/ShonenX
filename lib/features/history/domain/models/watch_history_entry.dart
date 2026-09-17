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

  static WatchHistoryEntry fromBackupMap(Map<String, dynamic> m) =>
      WatchHistoryEntry()
        ..episodeNumber = (m['episodeNumber'] is num)
            ? (m['episodeNumber'] as num).toDouble()
            : (double.tryParse(m['episodeNumber']?.toString() ?? '') ?? 1.0)
        ..animeId =
            (m['animeId'] ?? m['providerId'] ?? m['id'] ?? '').toString()
        ..animeIdMal = m['animeIdMal']?.toString()
        ..animeTitle =
            (m['animeTitle'] ?? m['title'] ?? 'Unknown').toString()
        ..episodeTitle = m['episodeTitle']?.toString()
        ..cover = m['cover']?.toString()
        ..banner = m['banner']?.toString()
        ..thumbnailUrl = m['thumbnailUrl']?.toString()
        ..totalEpisodes = (m['totalEpisodes'] is num)
            ? (m['totalEpisodes'] as num).toInt()
            : int.tryParse(m['totalEpisodes']?.toString() ?? '')
        ..positionInMilliseconds = (m['positionInMilliseconds'] is num)
            ? (m['positionInMilliseconds'] as num).toInt()
            : (int.tryParse(m['positionInMilliseconds']?.toString() ?? '') ?? 0)
        ..durationInMilliseconds = (m['durationInMilliseconds'] is num)
            ? (m['durationInMilliseconds'] as num).toInt()
            : (int.tryParse(m['durationInMilliseconds']?.toString() ?? '') ?? 0)
        ..sourceId = m['sourceId']?.toString()
        ..sourceName = m['sourceName']?.toString()
        ..providerId = m['providerId']?.toString()
        ..externalIdsJson = m['externalIdsJson']?.toString()
        ..lastUpdated =
            DateTime.tryParse(m['lastUpdated'] as String? ?? '') ??
            DateTime.now();
}

