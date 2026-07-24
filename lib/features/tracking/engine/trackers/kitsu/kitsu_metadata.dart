import 'dart:developer';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';
import 'package:shonenx/features/tracking/engine/base_tracker.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';

class KitsuException implements Exception {
  final String message;
  KitsuException(this.message);
  @override
  String toString() => message;
}

mixin KitsuMetadata on BaseTracker implements RemoteTracker {
  HTTP get http;

  @override
  List<TrackerCategory> get supportedCategories => [
    TrackerCategory.trending,
    TrackerCategory.popular,
    TrackerCategory.topRated,
  ];

  @override
  Future<PaginatedResult<UnifiedMedia>> getCategoryItems(
    TrackerCategory category, {
    int page = 1,
    MediaType type = MediaType.ANIME,
    Duration? cacheDuration,
    AdultContentMode adultMode = AdultContentMode.safe,
  }) {
    final String sortOption;
    switch (category) {
      case TrackerCategory.popular:
      case TrackerCategory.popularThisSeason:
        sortOption = '-userCount';
        break;
      case TrackerCategory.topRated:
        sortOption = '-averageRating';
        break;
      case TrackerCategory.recentlyUpdated:
        sortOption = '-updatedAt';
        break;
      case TrackerCategory.trending:
      default:
        sortOption = '-userCount';
        break;
    }

    final requestId = DateTime.now().microsecondsSinceEpoch;

    return executeApi(
      'CATEGORY_${category.name.toUpperCase()}',
      () async {
        final limit = 20;
        final offset = (page - 1) * limit;
        final endpoint = type == MediaType.ANIME ? 'anime' : 'manga';

        final response = await http.get(
          'https://kitsu.io/api/edge/$endpoint',
          queryParameters: {
            'sort': sortOption,
            'page[limit]': limit.toString(),
            'page[offset]': offset.toString(),
            'include': 'categories,genres',
          },
          cacheDuration: cacheDuration ?? const Duration(hours: 1),
        );

        final data = _validateAndParseResponse(
          response.json,
          'getCategoryItems',
        );
        final rawList = data['data'] as List? ?? [];
        final includedMap = _buildIncludedMap(data['included']);
        final links = data['links'] as Map? ?? {};
        final next = links['next'] as String?;

        final hasNextPage = next != null && next.isNotEmpty;

        final items = rawList
            .whereType<Map>()
            .map((item) {
              try {
                return _mapToUnified(
                  item,
                  type,
                  requestId,
                  includedMap: includedMap,
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<UnifiedMedia>()
            .toList();

        return PaginatedResult(items: items, hasNextPage: hasNextPage);
      },
      fallback: (error, stackTrace) {
        return PaginatedResult(items: [], hasNextPage: false);
      },
    );
  }

  Map<String, dynamic> _validateAndParseResponse(
    dynamic body,
    String operation,
  ) {
    if (body is! Map) {
      log(
        'Invalid response type: ${body.runtimeType}',
        name: 'KitsuTracker.$operation',
        error: body,
      );
      throw KitsuException('Invalid response format');
    }

    if (body['errors'] != null) {
      log(
        'API Errors: ${body['errors']}',
        name: 'KitsuTracker.$operation',
        error: body,
      );
      throw KitsuException('API Error: ${body['errors']}');
    }

    return Map<String, dynamic>.from(body);
  }

  Map<String, Map<dynamic, dynamic>> _buildIncludedMap(dynamic included) {
    final map = <String, Map<dynamic, dynamic>>{};
    if (included is List) {
      for (final item in included.whereType<Map>()) {
        final id = item['id']?.toString();
        final type = item['type']?.toString();
        if (id != null && type != null) {
          map['$type:$id'] = item;
        }
      }
    }
    return map;
  }

  @override
  Future<PaginatedResult<UnifiedMedia>> getTrending({
    int page = 1,
    MediaType type = MediaType.ANIME,
    Duration? cacheDuration,
    AdultContentMode adultMode = AdultContentMode.safe,
  }) {
    final requestId = DateTime.now().microsecondsSinceEpoch;

    return executeApi(
      'TRENDING',
      () async {
        final limit = 20;
        final offset = (page - 1) * limit;
        final endpoint = type == MediaType.ANIME ? 'anime' : 'manga';

        final response = await http.get(
          'https://kitsu.io/api/edge/$endpoint',
          queryParameters: {
            'sort': '-userCount',
            'page[limit]': limit.toString(),
            'page[offset]': offset.toString(),
            'include': 'categories,genres',
          },
          cacheDuration: cacheDuration ?? const Duration(hours: 1),
        );

        final data = _validateAndParseResponse(response.json, 'getTrending');
        final rawList = data['data'] as List? ?? [];
        final includedMap = _buildIncludedMap(data['included']);
        final links = data['links'] as Map? ?? {};
        final next = links['next'] as String?;

        final hasNextPage = next != null && next.isNotEmpty;

        final items = rawList
            .whereType<Map>()
            .map((item) {
              try {
                return _mapToUnified(
                  item,
                  type,
                  requestId,
                  includedMap: includedMap,
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<UnifiedMedia>()
            .toList();

        return PaginatedResult(items: items, hasNextPage: hasNextPage);
      },
      fallback: (error, stackTrace) {
        log(
          'Fallback triggered',
          name: 'KitsuTracker.getTrending',
          error: error,
          stackTrace: stackTrace,
        );
        return PaginatedResult(items: [], hasNextPage: false);
      },
    );
  }

  @override
  Future<PaginatedResult<UnifiedMedia>> search(
    String query, {
    int page = 1,
    MediaType type = MediaType.ANIME,
    List<String>? genres,
    List<String>? tags,
    Duration? cacheDuration,
    AdultContentMode adultMode = AdultContentMode.safe,
  }) {
    final requestId = DateTime.now().microsecondsSinceEpoch;

    return executeApi(
      'SEARCH_METADATA',
      () async {
        final limit = 20;
        final offset = (page - 1) * limit;
        final endpoint = type == MediaType.ANIME ? 'anime' : 'manga';

        final queryParams = <String, String>{
          'page[limit]': limit.toString(),
          'page[offset]': offset.toString(),
          'include': 'categories,genres',
        };
        if (query.trim().isNotEmpty) {
          queryParams['filter[text]'] = query.trim();
        } else {
          queryParams['sort'] = '-userCount';
        }

        final categoryFilters =
            <String>[if (genres != null) ...genres, if (tags != null) ...tags]
                .map((g) => g.toLowerCase().trim().replaceAll(' ', '-'))
                .where((g) => g.isNotEmpty)
                .toSet()
                .toList();

        if (categoryFilters.isNotEmpty) {
          queryParams['filter[categories]'] = categoryFilters.join(',');
        }

        final response = await http.get(
          'https://kitsu.io/api/edge/$endpoint',
          queryParameters: queryParams,
          cacheDuration: cacheDuration,
        );

        final data = _validateAndParseResponse(response.json, 'search');
        final rawList = data['data'] as List? ?? [];
        final includedMap = _buildIncludedMap(data['included']);
        final links = data['links'] as Map? ?? {};
        final next = links['next'] as String?;

        final hasNextPage = next != null && next.isNotEmpty;

        final items = rawList
            .whereType<Map>()
            .map((item) {
              try {
                return _mapToUnified(
                  item,
                  type,
                  requestId,
                  includedMap: includedMap,
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<UnifiedMedia>()
            .toList();

        return PaginatedResult(items: items, hasNextPage: hasNextPage);
      },
      fallback: (error, stackTrace) {
        log(
          'Fallback triggered',
          name: 'KitsuTracker.search',
          error: error,
          stackTrace: stackTrace,
        );
        return PaginatedResult(items: [], hasNextPage: false);
      },
    );
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) {
    final requestId = DateTime.now().microsecondsSinceEpoch;

    return executeApi('DETAILS', () async {
      final id = int.tryParse(providerId);
      if (id == null) {
        log('Invalid providerId: $providerId', name: 'KitsuTracker.getDetails');
        throw KitsuException('Invalid providerId: $providerId');
      }

      final endpoint = type == MediaType.ANIME ? 'anime' : 'manga';

      final response = await http.get(
        'https://kitsu.io/api/edge/$endpoint/$id',
        queryParameters: {
          'include':
              'categories,genres,mediaRelationships.destination,mappings',
        },
        cacheDuration: const Duration(days: 1),
      );

      final data = _validateAndParseResponse(response.json, 'getDetails');
      final item = data['data'] as Map? ?? {};
      final includedMap = _buildIncludedMap(data['included']);

      return _mapToUnified(item, type, requestId, includedMap: includedMap);
    });
  }

  @override
  Future<List<String>> fetchGenres() async {
    return [
      'Action',
      'Adventure',
      'Comedy',
      'Drama',
      'Fantasy',
      'Romance',
      'Sci-Fi',
      'Slice of Life',
      'Sports',
      'Thriller',
      'Mystery',
      'Supernatural',
      'Horror',
      'Mecha',
      'Psychological',
      'Isekai',
      'Mahou Shoujo',
      'Music',
    ];
  }

  @override
  Future<List<String>> fetchTags() async {
    return [];
  }

  UnifiedMedia _mapToUnified(
    Map<dynamic, dynamic> json,
    MediaType type,
    int requestId, {
    String? relationType,
    Map<String, Map<dynamic, dynamic>>? includedMap,
  }) {
    try {
      final attr = json['attributes'] as Map? ?? {};
      final titles = attr['titles'] as Map? ?? {};
      final canonicalTitle =
          attr['canonicalTitle']?.toString() ??
          titles['en_jp']?.toString() ??
          titles['en']?.toString() ??
          titles['ja_jp']?.toString() ??
          'Unknown Title';

      final title = MediaTitle(
        english: titles['en']?.toString() ?? attr['canonicalTitle']?.toString(),
        romaji: titles['en_jp']?.toString() ?? canonicalTitle,
        native: titles['ja_jp']?.toString(),
      );

      String status = 'Unknown';
      switch (attr['status']?.toString().toLowerCase()) {
        case 'current':
          status = 'Ongoing';
          break;
        case 'finished':
          status = 'Completed';
          break;
        case 'upcoming':
        case 'tba':
        case 'unreleased':
          status = 'Upcoming';
          break;
      }

      final episodes =
          attr['episodeCount'] as int? ?? attr['chapterCount'] as int?;
      final posterImage = attr['posterImage'] as Map? ?? {};
      final cover =
          posterImage['large']?.toString() ??
          posterImage['medium']?.toString() ??
          posterImage['original']?.toString() ??
          '';
      final coverImage = attr['coverImage'] as Map? ?? {};
      final banner =
          coverImage['original']?.toString() ??
          coverImage['large']?.toString() ??
          coverImage['small']?.toString();

      final synopsis =
          attr['synopsis']?.toString() ?? attr['description']?.toString();
      final format = attr['subtype']?.toString().toUpperCase();

      final avgRatingStr = attr['averageRating']?.toString();
      double? rating;
      if (avgRatingStr != null) {
        final parsed = double.tryParse(avgRatingStr);
        if (parsed != null && parsed > 0) {
          rating = parsed / 10.0;
        }
      } else if (attr['ratingTwenty'] != null) {
        final r20 = (attr['ratingTwenty'] as num).toDouble();
        if (r20 > 0) rating = r20 / 2.0;
      }

      final nsfw = attr['nsfw'] as bool? ?? false;
      final ageRating = attr['ageRating']?.toString().toUpperCase();
      final isAdult = nsfw || ageRating == 'R18' || ageRating == 'R18+';

      String? season;
      DateTime? airingAt;
      final startDateStr = attr['startDate']?.toString();
      if (startDateStr != null) {
        final startDate = DateTime.tryParse(startDateStr);
        if (startDate != null && type == MediaType.ANIME) {
          if (startDate.month >= 1 && startDate.month <= 3) {
            season = 'WINTER ${startDate.year}';
          } else if (startDate.month >= 4 && startDate.month <= 6) {
            season = 'SPRING ${startDate.year}';
          } else if (startDate.month >= 7 && startDate.month <= 9) {
            season = 'SUMMER ${startDate.year}';
          } else {
            season = 'FALL ${startDate.year}';
          }
        }
      }

      final nextReleaseStr = attr['nextRelease']?.toString();
      if (nextReleaseStr != null) {
        airingAt = DateTime.tryParse(nextReleaseStr)?.toLocal();
      }

      final genresList = <String>[];
      final tagsList = <MediaTag>[];
      final relationsList = <UnifiedMedia>[];
      String? idMal;

      if (includedMap != null) {
        final rels = json['relationships'] as Map? ?? {};

        // Extract Categories & Genres
        final catData = (rels['categories'] as Map?)?['data'] as List?;
        if (catData != null) {
          for (final c in catData.whereType<Map>()) {
            final cId = c['id']?.toString();
            if (cId == null) continue;
            final catNode = includedMap['categories:$cId'];
            if (catNode == null) continue;
            final catTitle = (catNode['attributes'] as Map?)?['title']
                ?.toString();
            if (catTitle != null &&
                catTitle.isNotEmpty &&
                !genresList.contains(catTitle)) {
              genresList.add(catTitle);
              tagsList.add(
                MediaTag(id: cId, name: catTitle, category: 'Category'),
              );
            }
          }
        }

        final genData = (rels['genres'] as Map?)?['data'] as List?;
        if (genData != null) {
          for (final g in genData.whereType<Map>()) {
            final gId = g['id']?.toString();
            if (gId == null) continue;
            final genNode = includedMap['genres:$gId'];
            if (genNode == null) continue;
            final genTitle =
                (genNode['attributes'] as Map?)?['name']?.toString() ??
                (genNode['attributes'] as Map?)?['title']?.toString();
            if (genTitle != null &&
                genTitle.isNotEmpty &&
                !genresList.contains(genTitle)) {
              genresList.add(genTitle);
              tagsList.add(
                MediaTag(id: gId, name: genTitle, category: 'Genre'),
              );
            }
          }
        }

        // Extract Media Relationships
        final relData = (rels['mediaRelationships'] as Map?)?['data'] as List?;
        if (relData != null) {
          for (final r in relData.whereType<Map>()) {
            final rId = r['id']?.toString();
            if (rId == null) continue;
            final relNode = includedMap['mediaRelationships:$rId'];
            if (relNode == null) continue;
            final relAttr = relNode['attributes'] as Map? ?? {};
            final role = relAttr['role']?.toString();

            final destData =
                (relNode['relationships'] as Map?)?['destination']?['data']
                    as Map?;
            if (destData == null) continue;
            final destId = destData['id']?.toString();
            final destTypeStr = destData['type']?.toString();
            if (destId == null || destTypeStr == null) continue;
            final destNode = includedMap['$destTypeStr:$destId'];
            if (destNode == null) continue;

            final destMediaType = destTypeStr == 'manga'
                ? MediaType.MANGA
                : MediaType.ANIME;
            relationsList.add(
              _mapToUnified(
                destNode,
                destMediaType,
                requestId,
                relationType: role,
                includedMap: includedMap,
              ),
            );
          }
        }

        // Extract MAL ID from mappings if present
        final mapData = (rels['mappings'] as Map?)?['data'] as List?;
        if (mapData != null) {
          for (final m in mapData.whereType<Map>()) {
            final mId = m['id']?.toString();
            if (mId == null) continue;
            final mapNode = includedMap['mappings:$mId'];
            if (mapNode == null) continue;
            final mapAttr = mapNode['attributes'] as Map? ?? {};
            final extSite = mapAttr['externalSite']?.toString().toLowerCase();
            if (extSite != null && extSite.contains('myanimelist')) {
              idMal = mapAttr['externalId']?.toString();
              if (idMal != null && idMal.isNotEmpty) break;
            }
          }
        }
      }

      return UnifiedMedia(
        id: json['id']?.toString() ?? '',
        providerId: json['id']?.toString() ?? '',
        idMal: idMal,
        title: title,
        type: type,
        cover: cover,
        banner: banner,
        description: synopsis,
        status: status,
        format: format ?? (type == MediaType.ANIME ? 'TV' : 'MANGA'),
        episodes: episodes,
        score: rating,
        isAdult: isAdult,
        season: season,
        airingAt: airingAt,
        relationType: relationType,
        relations: relationsList.isNotEmpty ? relationsList : null,
        genres: genresList.isNotEmpty ? genresList : null,
        tags: tagsList.isNotEmpty ? tagsList : null,
      );
    } catch (e, stackTrace) {
      log(
        'Error mapping UnifiedMedia',
        name: 'KitsuTracker._mapToUnified',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
