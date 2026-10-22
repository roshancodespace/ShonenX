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

  Map<String, dynamic> toBackupMap() {
    double? safeScore = score;
    if (safeScore != null && (safeScore.isNaN || safeScore.isInfinite)) {
      safeScore = null;
    }
    return {
      'providerId': providerId,
      'title': title,
      'cover': cover,
      'type': type,
      'format': format,
      'score': safeScore,
      'status': status,
      'episodes': episodes,
      'episodesWatched': episodesWatched,
      'addedAt': addedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sourceType': sourceType,
      'sourceId': sourceId,
      'externalIdsJson': externalIdsJson,
    };
  }

  static LibraryEntry fromBackupMap(Map<String, dynamic> m) {
    final rawId =
        m['providerId'] ??
        m['id'] ??
        m['mediaId'] ??
        m['animeId'] ??
        m['mangaId'];
    final safeProviderId =
        rawId?.toString() ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';

    String safeTitle = '';
    final rawTitle =
        m['title'] ??
        m['name'] ??
        m['mediaTitle'] ??
        m['animeTitle'] ??
        m['mangaTitle'];
    if (rawTitle is String) {
      safeTitle = rawTitle;
    } else if (rawTitle is Map) {
      safeTitle =
          rawTitle['english']?.toString() ??
          rawTitle['romaji']?.toString() ??
          rawTitle['native']?.toString() ??
          rawTitle['userPreferred']?.toString() ??
          '';
    }
    if (safeTitle.isEmpty) {
      safeTitle = 'Untitled';
    }

    final rawCover =
        m['cover'] ??
        m['coverImage'] ??
        m['image'] ??
        m['thumbnailUrl'] ??
        m['poster'];
    final safeCover = rawCover?.toString() ?? '';

    double? safeScore;
    final rawScore = m['score'] ?? m['rating'];
    if (rawScore is num && !rawScore.isNaN && !rawScore.isInfinite) {
      safeScore = rawScore.toDouble();
    } else if (rawScore is String) {
      safeScore = double.tryParse(rawScore);
      if (safeScore != null && (safeScore.isNaN || safeScore.isInfinite)) {
        safeScore = null;
      }
    }

    int? safeEpisodes;
    final rawEpisodes =
        m['episodes'] ?? m['totalEpisodes'] ?? m['totalChapters'];
    if (rawEpisodes is num) {
      safeEpisodes = rawEpisodes.toInt();
    } else if (rawEpisodes is String) {
      safeEpisodes = int.tryParse(rawEpisodes);
    }

    int safeWatched = 0;
    final rawWatched =
        m['episodesWatched'] ??
        m['episodesProgress'] ??
        m['watchedEpisodes'] ??
        m['chaptersRead'] ??
        m['progress'];
    if (rawWatched is num) {
      safeWatched = rawWatched.toInt();
    } else if (rawWatched is String) {
      safeWatched = int.tryParse(rawWatched) ?? 0;
    }

    final safeAddedAt =
        DateTime.tryParse(m['addedAt']?.toString() ?? '') ??
        DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final safeUpdatedAt =
        DateTime.tryParse(m['updatedAt']?.toString() ?? '') ??
        DateTime.tryParse(m['lastUpdated']?.toString() ?? '') ??
        DateTime.now();

    return LibraryEntry()
      ..providerId = safeProviderId
      ..title = safeTitle
      ..cover = safeCover
      ..type = m['type']?.toString() ?? m['mediaType']?.toString()
      ..format = m['format']?.toString()
      ..score = safeScore
      ..status = m['status']?.toString()
      ..episodes = safeEpisodes
      ..episodesWatched = safeWatched
      ..addedAt = safeAddedAt
      ..updatedAt = safeUpdatedAt
      ..sourceType = m['sourceType']?.toString()
      ..sourceId = m['sourceId']?.toString()
      ..externalIdsJson = m['externalIdsJson']?.toString();
  }
}
