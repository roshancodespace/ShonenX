import 'dart:convert';
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

  String? sourceType;
  String? sourceId;

  String? externalIdsJson;

  @ignore
  String? banner;

  @ignore
  String? description;

  @ignore
  List<String>? genres;

  @ignore
  int? year;

  @ignore
  MediaExternalIds get externalIds {
    if (externalIdsJson != null && externalIdsJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(externalIdsJson!) as Map<String, dynamic>;
        return MediaExternalIds.fromMap(decoded);
      } catch (_) {}
    }
    return const MediaExternalIds();
  }

  set externalIds(MediaExternalIds ids) {
    final map = ids.toMap();
    externalIdsJson = map.isNotEmpty ? jsonEncode(map) : null;
  }

  UnifiedMedia toUnifiedMedia() {
    return UnifiedMedia(
      id: providerId,
      type: MediaType.values.firstWhere(
        (e) => e.id == type,
        orElse: () => MediaType.ANIME,
      ),
      providerId: providerId,
      externalIds: externalIds,
      cover: cover,
      banner: banner,
      description: description,
      genres: genres,
      year: year,
      score: score,
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
    'sourceType': sourceType,
    'sourceId': sourceId,
    'externalIdsJson': externalIdsJson,
  };

  static LibraryEntry fromBackupMap(Map<String, dynamic> m) => LibraryEntry()
    ..providerId =
        (m['providerId'] ?? m['id'] ?? m['animeId'] ?? '').toString()
    ..title = (m['title'] ?? m['name'] ?? 'Unknown').toString()
    ..cover =
        (m['cover'] ?? m['coverImage'] ?? m['imageUrl'] ?? '').toString()
    ..type = m['type']?.toString()
    ..format = m['format']?.toString()
    ..score = (m['score'] is num)
        ? (m['score'] as num).toDouble()
        : double.tryParse(m['score']?.toString() ?? '')
    ..status = m['status']?.toString()
    ..episodes = (m['episodes'] is num)
        ? (m['episodes'] as num).toInt()
        : int.tryParse(m['episodes']?.toString() ?? '')
    ..episodesWatched = (m['episodesWatched'] is num)
        ? (m['episodesWatched'] as num).toInt()
        : (int.tryParse(m['episodesWatched']?.toString() ?? '') ?? 0)
    ..addedAt =
        DateTime.tryParse(m['addedAt'] as String? ?? '') ?? DateTime.now()
    ..updatedAt =
        DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime.now()
    ..sourceType = m['sourceType']?.toString()
    ..sourceId = m['sourceId']?.toString()
    ..externalIdsJson = m['externalIdsJson']?.toString();
}
