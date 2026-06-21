import 'package:isar_community/isar.dart';

part 'read_history_entry.g.dart';

@collection
class ReadHistoryEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late double chapterNumber;

  late String mangaId;
  String? mangaIdMal;
  late String mangaTitle;
  String? chapterTitle;
  String? cover;
  String? banner;

  late int positionPage;
  late int totalPages;

  String? sourceId;
  String? sourceName;
  String? providerId;

  @Index()
  late DateTime lastUpdated;

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
        ..lastUpdated =
            DateTime.tryParse(m['lastUpdated'] as String? ?? '') ??
            DateTime.now();
}
