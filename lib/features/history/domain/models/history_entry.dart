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

  Map<String, dynamic> toBackupMap() {
    double safeItemNumber = itemNumber;
    if (safeItemNumber.isNaN || safeItemNumber.isInfinite) {
      safeItemNumber = 1.0;
    }
    return {
      'mediaId': mediaId,
      'mediaType': mediaType,
      'itemNumber': safeItemNumber,
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
  }

  static HistoryEntry fromBackupMap(Map<String, dynamic> m) {
    final rawMediaId = m['mediaId'] ?? m['animeId'] ?? m['mangaId'] ?? m['id'];
    final safeMediaId =
        rawMediaId?.toString() ??
        'unknown_${DateTime.now().millisecondsSinceEpoch}';

    String safeMediaType = m['mediaType']?.toString().toLowerCase() ?? '';
    if (safeMediaType.isEmpty) {
      if (m.containsKey('episodeNumber') ||
          m.containsKey('animeId') ||
          m.containsKey('durationInMilliseconds')) {
        safeMediaType = MediaType.ANIME.id;
      } else if (m.containsKey('chapterNumber') ||
          m.containsKey('mangaId') ||
          m.containsKey('positionPage')) {
        safeMediaType = MediaType.MANGA.id;
      } else {
        safeMediaType = MediaType.ANIME.id;
      }
    }

    double safeItemNumber = 1.0;
    final rawItemNumber =
        m['itemNumber'] ??
        m['episodeNumber'] ??
        m['chapterNumber'] ??
        m['number'];
    if (rawItemNumber is num &&
        !rawItemNumber.isNaN &&
        !rawItemNumber.isInfinite) {
      safeItemNumber = rawItemNumber.toDouble();
    } else if (rawItemNumber is String) {
      safeItemNumber = double.tryParse(rawItemNumber) ?? 1.0;
    }

    String safeMediaTitle = '';
    final rawMediaTitle =
        m['mediaTitle'] ?? m['animeTitle'] ?? m['mangaTitle'] ?? m['title'];
    if (rawMediaTitle is String) {
      safeMediaTitle = rawMediaTitle;
    } else if (rawMediaTitle is Map) {
      safeMediaTitle =
          rawMediaTitle['english']?.toString() ??
          rawMediaTitle['romaji']?.toString() ??
          rawMediaTitle['native']?.toString() ??
          '';
    }
    if (safeMediaTitle.isEmpty) {
      safeMediaTitle = 'Untitled';
    }

    int safeProgress = 0;
    final rawProgress =
        m['progress'] ??
        m['positionInMilliseconds'] ??
        m['positionPage'] ??
        m['position'];
    if (rawProgress is num) {
      safeProgress = rawProgress.toInt();
    } else if (rawProgress is String) {
      safeProgress =
          int.tryParse(rawProgress) ??
          (double.tryParse(rawProgress)?.toInt() ?? 0);
    }

    int safeTotal = 0;
    final rawTotal =
        m['total'] ??
        m['durationInMilliseconds'] ??
        m['totalPages'] ??
        m['duration'];
    if (rawTotal is num) {
      safeTotal = rawTotal.toInt();
    } else if (rawTotal is String) {
      safeTotal =
          int.tryParse(rawTotal) ?? (double.tryParse(rawTotal)?.toInt() ?? 0);
    }

    // Convert legacy watch history from milliseconds to seconds if needed
    if (safeMediaType == MediaType.ANIME.id) {
      if (m.containsKey('positionInMilliseconds') && safeProgress > 1000) {
        safeProgress = Duration(milliseconds: safeProgress).inSeconds;
      }
      if (m.containsKey('durationInMilliseconds') && safeTotal > 1000) {
        safeTotal = Duration(milliseconds: safeTotal).inSeconds;
      }
    }

    int? safeTotalItems;
    final rawTotalItems =
        m['totalItems'] ?? m['totalEpisodes'] ?? m['totalChapters'];
    if (rawTotalItems is num) {
      safeTotalItems = rawTotalItems.toInt();
    } else if (rawTotalItems is String) {
      safeTotalItems = int.tryParse(rawTotalItems);
    }

    return HistoryEntry()
      ..mediaId = safeMediaId
      ..mediaType = safeMediaType
      ..itemNumber = safeItemNumber
      ..mediaIdMal = (m['mediaIdMal'] ?? m['animeIdMal'] ?? m['mangaIdMal'])
          ?.toString()
      ..mediaTitle = safeMediaTitle
      ..itemTitle = (m['itemTitle'] ?? m['episodeTitle'] ?? m['chapterTitle'])
          ?.toString()
      ..cover = (m['cover'] ?? m['coverImage'] ?? m['image'])?.toString()
      ..banner = m['banner']?.toString()
      ..thumbnailUrl = m['thumbnailUrl']?.toString()
      ..progress = safeProgress
      ..total = safeTotal
      ..totalItems = safeTotalItems
      ..sourceId = m['sourceId']?.toString()
      ..sourceName = m['sourceName']?.toString()
      ..providerId = m['providerId']?.toString()
      ..externalIdsJson = m['externalIdsJson']?.toString()
      ..lastUpdated =
          DateTime.tryParse(m['lastUpdated']?.toString() ?? '') ??
          DateTime.now();
  }
}
