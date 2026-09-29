import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:shonenx/shared/models/unified_media.dart';

part 'history_entry.g.dart';

@collection
class HistoryEntry {
  Id id = Isar.autoIncrement;

  /// Identifier of the overarching media (e.g., Anime ID or Manga ID)
  @Index(unique: true, replace: true, composite: [CompositeIndex('itemNumber')])
  late String mediaId;

  /// 'anime' or 'manga'
  @Index()
  late String mediaType;

  /// Represents episodeNumber or chapterNumber
  double itemNumber = 1.0;

  String? mediaIdMal;
  late String mediaTitle;
  String? itemTitle;
  String? cover;
  String? banner;
  String? thumbnailUrl;

  /// positionInMilliseconds or positionPage
  int progress = 0;

  /// durationInMilliseconds or totalPages
  int total = 0;

  int? totalItems;

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
    if (mediaIdMal != null && mediaIdMal!.isNotEmpty) {
      return MediaExternalIds(mal: mediaIdMal);
    }
    return const MediaExternalIds();
  }

  set externalIds(MediaExternalIds ids) {
    mediaIdMal = ids.mal;
    final map = ids.toMap();
    externalIdsJson = map.isNotEmpty ? jsonEncode(map) : null;
  }

  @Index()
  DateTime lastUpdated = DateTime.now();

  Map<String, dynamic> toBackupMap() => {
    'mediaId': mediaId,
    'mediaType': mediaType,
    'itemNumber': itemNumber,
    'mediaIdMal': mediaIdMal,
    'mediaTitle': mediaTitle,
    'itemTitle': itemTitle,
    'cover': cover,
    'banner': banner,
    'thumbnailUrl': thumbnailUrl,
    'progress': progress,
    'total': total,
    'totalItems': totalItems,
    'sourceId': sourceId,
    'sourceName': sourceName,
    'providerId': providerId,
    'externalIdsJson': externalIdsJson,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  static HistoryEntry fromBackupMap(Map<String, dynamic> m) => HistoryEntry()
    ..mediaId = m['mediaId'] as String
    ..mediaType = m['mediaType'] as String
    ..itemNumber = (m['itemNumber'] as num).toDouble()
    ..mediaIdMal = m['mediaIdMal'] as String?
    ..mediaTitle = m['mediaTitle'] as String
    ..itemTitle = m['itemTitle'] as String?
    ..cover = m['cover'] as String?
    ..banner = m['banner'] as String?
    ..thumbnailUrl = m['thumbnailUrl'] as String?
    ..progress = (m['progress'] as num).toInt()
    ..total = (m['total'] as num).toInt()
    ..totalItems = m['totalItems'] as int?
    ..sourceId = m['sourceId'] as String?
    ..sourceName = m['sourceName'] as String?
    ..providerId = m['providerId'] as String?
    ..externalIdsJson = m['externalIdsJson'] as String?
    ..lastUpdated =
        DateTime.tryParse(m['lastUpdated'] as String? ?? '') ?? DateTime.now();
}
