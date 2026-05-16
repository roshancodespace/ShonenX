import 'dart:developer';
import 'dart:io';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';
import 'package:shonenx/features/tracking/engine/base_tracker.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';

class MalException implements Exception {
  final String message;
  MalException(this.message);
  @override
  String toString() => message;
}

mixin MalMetadata on BaseTracker implements RemoteTracker {
  HTTP get http;

  static const String _baseUrl = 'https://api.myanimelist.net/v2';
  static String get clientId => Platform.isWindows || Platform.isLinux
      ? Env.MAL_CLIENT_ID_LIST.last
      : Env.MAL_CLIENT_ID_LIST.first;
  static const String _fields =
      'id,title,main_picture,start_date,end_date,synopsis,mean,rank,popularity,num_list_users,num_scoring_users,status,genres,created_at,updated_at,media_type,nsfw,my_list_status,num_episodes,start_season,broadcast,source,average_episode_duration,rating,pictures,background,related_anime,related_manga,recommendations,studios,statistics';

  Map<String, dynamic> _validateAndParseResponse(
    dynamic body,
    String operation,
  ) {
    if (body is! Map) {
      log(
        'Invalid response type: ${body.runtimeType}',
        name: 'MalTracker.$operation',
        error: body,
      );
      throw MalException('Invalid response format');
    }

    final errorVal = body['error']?.toString();
    final messageVal = body['message']?.toString();

    if (errorVal != null && errorVal.isNotEmpty) {
      log(
        'API Error: ${messageVal ?? errorVal}',
        name: 'MalTracker.$operation',
        error: body,
      );
      throw MalException('API Error: ${messageVal ?? errorVal}');
    }

    if (body['errors'] != null) {
      log(
        'API Errors: ${body['errors']}',
        name: 'MalTracker.$operation',
        error: body,
      );
      throw MalException('API Error: ${body['errors']}');
    }

    return Map<String, dynamic>.from(body);
  }

  @override
  Future<PaginatedResult<UnifiedMedia>> getTrending({
    int page = 1,
    MediaType type = MediaType.ANIME,
    Duration? cacheDuration,
  }) {
    final requestId = DateTime.now().microsecondsSinceEpoch;

    return executeApi(
      'TRENDING',
      () async {
        final limit = 20;
        final offset = (page - 1) * limit;
        final rankingType = type == MediaType.ANIME ? 'airing' : 'bypopularity';
        final endpoint = type == MediaType.ANIME ? 'anime' : 'manga';

        final response = await http.get(
          '$_baseUrl/$endpoint/ranking',
          queryParameters: {
            'ranking_type': rankingType,
            'limit': limit.toString(),
            'offset': offset.toString(),
            'fields': _fields,
          },
          headers: {'X-MAL-CLIENT-ID': clientId},
          cacheDuration: cacheDuration ?? const Duration(hours: 1),
        );

        final data = _validateAndParseResponse(response.json, 'getTrending');
        final rawList = data['data'] as List? ?? [];
        final paging = data['paging'] as Map? ?? {};
        final next = paging['next'] as String?;

        final hasNextPage = next != null && next.isNotEmpty;

        final items = rawList.whereType<Map>().map((item) {
          final node = item['node'] as Map? ?? {};
          return _mapToUnified(node, type, requestId);
        }).toList();

        return PaginatedResult(items: items, hasNextPage: hasNextPage);
      },
      fallback: (error, stackTrace) {
        log(
          'Fallback triggered',
          name: 'MalTracker.getTrending',
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
    Duration? cacheDuration,
  }) {
    final requestId = DateTime.now().microsecondsSinceEpoch;

    return executeApi(
      'SEARCH_METADATA',
      () async {
        final limit = 20;
        final offset = (page - 1) * limit;
        final endpoint = type == MediaType.ANIME ? 'anime' : 'manga';

        final response = await http.get(
          '$_baseUrl/$endpoint',
          queryParameters: {
            'q': query,
            'limit': limit.toString(),
            'offset': offset.toString(),
            'fields': _fields,
          },
          headers: {'X-MAL-CLIENT-ID': clientId},
          cacheDuration: cacheDuration,
        );

        final data = _validateAndParseResponse(response.json, 'search');
        final rawList = data['data'] as List? ?? [];
        final paging = data['paging'] as Map? ?? {};
        final next = paging['next'] as String?;

        final hasNextPage = next != null && next.isNotEmpty;

        final items = rawList.whereType<Map>().map((item) {
          final node = item['node'] as Map? ?? {};
          return _mapToUnified(node, type, requestId);
        }).toList();

        return PaginatedResult(items: items, hasNextPage: hasNextPage);
      },
      fallback: (error, stackTrace) {
        log(
          'Fallback triggered',
          name: 'MalTracker.search',
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
        log('Invalid providerId: $providerId', name: 'MalTracker.getDetails');
        throw MalException('Invalid providerId: $providerId');
      }

      final endpoint = type == MediaType.ANIME ? 'anime' : 'manga';

      final response = await http.get(
        '$_baseUrl/$endpoint/$id',
        queryParameters: {'fields': _fields},
        headers: {'X-MAL-CLIENT-ID': clientId},
        cacheDuration: const Duration(days: 1),
      );

      final data = _validateAndParseResponse(response.json, 'getDetails');

      return _mapToUnified(data, type, requestId);
    });
  }

  UnifiedMedia _mapToUnified(
    Map<dynamic, dynamic> json,
    MediaType type,
    int requestId,
  ) {
    try {
      final titleJson = json['title'] as String? ?? '';
      final mainPicture = json['main_picture'] as Map? ?? {};

      final title = MediaTitle(
        english: json['title_english'] as String?,
        romaji: titleJson,
        native: json['title_japanese'] as String?,
      );

      String status = 'Unknown';
      switch (json['status']) {
        case 'currently_airing':
        case 'currently_publishing':
          status = 'Ongoing';
          break;
        case 'finished_airing':
        case 'finished':
          status = 'Completed';
          break;
        case 'not_yet_aired':
        case 'not_yet_published':
          status = 'Upcoming';
          break;
      }

      final genres = (json['genres'] as List?)
          ?.map((e) => (e as Map?)?['name'] as String?)
          .whereType<String>()
          .toList();

      final episodes = json['num_episodes'] as int?;
      final cover =
          mainPicture['large'] as String? ?? mainPicture['medium'] as String?;
      final synopsis = json['synopsis'] as String?;

      return UnifiedMedia(
        id: json['id']?.toString() ?? '',
        idMal: json['id']?.toString(),
        type: type,
        providerId: json['id']?.toString() ?? '',
        title: title,
        cover: cover,
        banner: null,
        description: synopsis,
        status: status,
        episodes: episodes,
        genres: genres,
      );
    } catch (e, stackTrace) {
      log(
        'Error mapping UnifiedMedia',
        name: 'MalTracker._mapToUnified',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
