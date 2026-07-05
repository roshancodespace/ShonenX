import 'dart:developer';
import 'package:shonenx/core/network/http_client.dart';
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
          },
          cacheDuration: cacheDuration ?? const Duration(hours: 1),
        );

        final data = _validateAndParseResponse(response.json, 'getTrending');
        final rawList = data['data'] as List? ?? [];
        final links = data['links'] as Map? ?? {};
        final next = links['next'] as String?;

        final hasNextPage = next != null && next.isNotEmpty;

        final items = rawList.whereType<Map>().map((item) {
          return _mapToUnified(item, type, requestId);
        }).toList();

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
        };
        if (query.trim().isNotEmpty) {
          queryParams['filter[text]'] = query.trim();
        } else {
          queryParams['sort'] = '-userCount';
        }
        if (genres != null && genres.isNotEmpty) {
          queryParams['filter[categories]'] = genres.join(',');
        }

        final response = await http.get(
          'https://kitsu.io/api/edge/$endpoint',
          queryParameters: queryParams,
          cacheDuration: cacheDuration,
        );

        final data = _validateAndParseResponse(response.json, 'search');
        final rawList = data['data'] as List? ?? [];
        final links = data['links'] as Map? ?? {};
        final next = links['next'] as String?;

        final hasNextPage = next != null && next.isNotEmpty;

        final items = rawList.whereType<Map>().map((item) {
          return _mapToUnified(item, type, requestId);
        }).toList();

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
        cacheDuration: const Duration(days: 1),
      );

      final data = _validateAndParseResponse(response.json, 'getDetails');
      final item = data['data'] as Map? ?? {};

      return _mapToUnified(item, type, requestId);
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
    int requestId,
  ) {
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
    final synopsis = attr['synopsis']?.toString();
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

    return UnifiedMedia(
      id: json['id']?.toString() ?? '',
      title: title,
      type: type,
      cover: cover,
      description: synopsis,
      status: status,
      format: format ?? (type == MediaType.ANIME ? 'TV' : 'MANGA'),
      episodes: episodes,
      score: rating,
    );
  }
}
