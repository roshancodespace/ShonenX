import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:shonenx/shared/models/unified_media.dart';

part 'read_history_entry.g.dart';

@collection
class ReadHistoryEntry {
  Id id = Isar.autoIncrement;

  @Index(
    unique: true,
    replace: true,
    composite: [CompositeIndex('chapterNumber')],
  )
  late String mangaId;

  double chapterNumber = 1.0;

  String? mangaIdMal;
  late String mangaTitle;
  String? chapterTitle;
  String? cover;
  String? banner;

  int positionPage = 0;
  int totalPages = 0;

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
    if (mangaIdMal != null && mangaIdMal!.isNotEmpty) {
      return MediaExternalIds(mal: mangaIdMal);
    }
    return const MediaExternalIds();
  }

  set externalIds(MediaExternalIds ids) {
    mangaIdMal = ids.mal;
    final map = ids.toMap();
    externalIdsJson = map.isNotEmpty ? jsonEncode(map) : null;
  }

  @Index()
  DateTime lastUpdated = DateTime.now();

  Map<String, dynamic> toBackupMap() => {
    'chapterNumber': chapterNumber,
    'mangaId': mangaId,
    'mangaIdMal': mangaIdMal,
    'mangaTitle': mangaTitle,
    'chapterTitle': chapterTitle,
    'cover': cover,
    'banner': banner,
    'positionPage': positionPage,
    'totalPages': totalPages,
    'sourceId': sourceId,
    'sourceName': sourceName,
    'providerId': providerId,
    'externalIdsJson': externalIdsJson,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  static ReadHistoryEntry fromBackupMap(Map<String, dynamic> m) =>
      ReadHistoryEntry()
        ..chapterNumber = (m['chapterNumber'] is num)
            ? (m['chapterNumber'] as num).toDouble()
            : (double.tryParse(m['chapterNumber']?.toString() ?? '') ?? 1.0)
        ..mangaId =
            (m['mangaId'] ?? m['providerId'] ?? m['id'] ?? '').toString()
        ..mangaIdMal = m['mangaIdMal']?.toString()
        ..mangaTitle =
            (m['mangaTitle'] ?? m['title'] ?? 'Unknown').toString()
        ..chapterTitle = m['chapterTitle']?.toString()
        ..cover = m['cover']?.toString()
        ..banner = m['banner']?.toString()
        ..positionPage = (m['positionPage'] is num)
            ? (m['positionPage'] as num).toInt()
            : (int.tryParse(m['positionPage']?.toString() ?? '') ?? 0)
        ..totalPages = (m['totalPages'] is num)
            ? (m['totalPages'] as num).toInt()
            : (int.tryParse(m['totalPages']?.toString() ?? '') ?? 0)
        ..sourceId = m['sourceId']?.toString()
        ..sourceName = m['sourceName']?.toString()
        ..providerId = m['providerId']?.toString()
        ..externalIdsJson = m['externalIdsJson']?.toString()
        ..lastUpdated =
            DateTime.tryParse(m['lastUpdated'] as String? ?? '') ??
            DateTime.now();
}
