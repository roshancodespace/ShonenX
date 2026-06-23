import 'package:isar_community/isar.dart';
import 'package:shonenx/shared/models/unified_media.dart';

part 'library_entry.g.dart';

@collection
class LibraryEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true, composite: [CompositeIndex('type')])
  late String providerId;

  @Index()
  late String title;
  late String cover;
  String? type;
  String? format;
  double? score;
  String? status;
  int? episodes;

  int episodesWatched = 0;
  DateTime addedAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  UnifiedMedia toUnifiedMedia() {
    return UnifiedMedia(
      id: providerId,
      type: MediaType.values.firstWhere((e) => e.id == type),
      providerId: providerId,
      cover: cover,
      title: MediaTitle(english: title),
      format: format,
      status: status,
      episodes: episodes,
    );
  }

  Map<String, dynamic> toBackupMap() => {
    'providerId': providerId,
    'title': title,
    'cover': cover,
    'type': type,
    'format': format,
    'score': score,
    'status': status,
    'episodes': episodes,
    'episodesWatched': episodesWatched,
    'addedAt': addedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static LibraryEntry fromBackupMap(Map<String, dynamic> m) => LibraryEntry()
    ..providerId = m['providerId'] as String
    ..title = m['title'] as String
    ..cover = m['cover'] as String
    ..type = m['type'] as String?
    ..format = m['format'] as String?
    ..score = (m['score'] as num?)?.toDouble()
    ..status = m['status'] as String?
    ..episodes = m['episodes'] as int?
    ..episodesWatched = m['episodesWatched'] as int? ?? 0
    ..addedAt =
        DateTime.tryParse(m['addedAt'] as String? ?? '') ?? DateTime.now()
    ..updatedAt =
        DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime.now();
}
