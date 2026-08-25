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
        ..chapterNumber = (m['chapterNumber'] as num).toDouble()
        ..mangaId = m['mangaId'] as String
        ..mangaIdMal = m['mangaIdMal'] as String?
        ..mangaTitle = m['mangaTitle'] as String
        ..chapterTitle = m['chapterTitle'] as String?
        ..cover = m['cover'] as String?
        ..banner = m['banner'] as String?
        ..positionPage = m['positionPage'] as int
        ..totalPages = m['totalPages'] as int
        ..sourceId = m['sourceId'] as String?
        ..sourceName = m['sourceName'] as String?
        ..providerId = m['providerId'] as String?
        ..externalIdsJson = m['externalIdsJson'] as String?
        ..lastUpdated =
            DateTime.tryParse(m['lastUpdated'] as String? ?? '') ??
            DateTime.now();
}
