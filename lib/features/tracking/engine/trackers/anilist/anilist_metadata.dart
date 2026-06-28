import 'dart:developer';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/features/tracking/engine/base_tracker.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';

import 'anilist_tracker_queries.dart';

class AnilistException implements Exception {
  final String message;
  AnilistException(this.message);
  @override
  String toString() => message;
}

mixin AnilistMetadata on BaseTracker implements RemoteTracker {
  HTTP get http;

  final String _endpoint = 'https://graphql.anilist.co';

  Map<String, dynamic> _validateAndParseResponse(
    dynamic body,
    String operation,
  ) {
    if (body is! Map) {
      log(
        'Invalid response type: ${body.runtimeType}',
        name: 'AnilistTracker.$operation',
        error: body,
      );
      throw AnilistException('Invalid response format');
    }

    if (body['errors'] != null) {
      log(
        'GraphQL Errors returned',
        name: 'AnilistTracker.$operation',
        error: body['errors'],
      );
      throw AnilistException('GraphQL Error: ${body['errors']}');
    }

    final data = body['data'] as Map?;
    if (data == null) {
      log(
        'Response data is null',
        name: 'AnilistTracker.$operation',
        error: body,
      );
      throw AnilistException('Missing data field in response');
    }

    return Map<String, dynamic>.from(data);
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
        final response = await http.post(
          _endpoint,
          body: {
            'query': AnilistTrackerQueries.trending(adultMode),
            'variables': {'page': page, 'type': type.name},
          },
          cacheDuration: cacheDuration ?? const Duration(days: 1),
        );

        final data = _validateAndParseResponse(response.json, 'getTrending');
        final pageData = data['Page'] as Map?;

        if (pageData == null) {
          log('Page data is null', name: 'AnilistTracker.getTrending');
          return PaginatedResult(items: [], hasNextPage: false);
        }

        final hasNextPage = pageData['pageInfo']?['hasNextPage'] ?? false;
        final rawList = pageData['media'] as List? ?? [];

        final items = rawList
            .whereType<Map>()
            .map((json) => _mapToUnified(json, type, requestId))
            .toList();

        return PaginatedResult(items: items, hasNextPage: hasNextPage);
      },
      fallback: (error, stackTrace) {
        log(
          'Fallback triggered',
          name: 'AnilistTracker.getTrending',
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
    List<String> sort = const ['SEARCH_MATCH'],
  }) {
    final requestId = DateTime.now().microsecondsSinceEpoch;

    return executeApi(
      'SEARCH_METADATA',
      () async {
        final variables = <String, dynamic>{
          'search': query.isEmpty ? null : query,
          'page': page,
          'type': type.name,
          'sort': sort,
        };

        if (genres != null && genres.isNotEmpty) {
          variables['genre_in'] = genres;
        }

        if (tags != null && tags.isNotEmpty) {
          variables['tag_in'] = tags;
        }

        final response = await http.post(
          _endpoint,
          body: {
            'query': AnilistTrackerQueries.metadataSearch(adultMode),
            'variables': variables,
          },
          cacheDuration: cacheDuration,
        );

        final data = _validateAndParseResponse(response.json, 'search');
        final pageData = data['Page'] as Map?;

        if (pageData == null) {
          log('Page data is null', name: 'AnilistTracker.search');
          return PaginatedResult(items: [], hasNextPage: false);
        }

        final hasNextPage = pageData['pageInfo']?['hasNextPage'] ?? false;
        final rawList = pageData['media'] as List? ?? [];

        final items = rawList
            .whereType<Map>()
            .map((json) => _mapToUnified(json, type, requestId))
            .toList();

        return PaginatedResult(items: items, hasNextPage: hasNextPage);
      },
      fallback: (error, stackTrace) {
        log(
          'Fallback triggered',
          name: 'AnilistTracker.search',
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
        log(
          'Invalid providerId: $providerId',
          name: 'AnilistTracker.getDetails',
        );
        throw AnilistException('Invalid providerId: $providerId');
      }

      final response = await http.post(
        _endpoint,
        body: {
          'query': AnilistTrackerQueries.details,
          'variables': {'id': id, 'type': type.name},
        },
        cacheDuration: const Duration(days: 1),
      );

      final data = _validateAndParseResponse(response.json, 'getDetails');
      final json = data['Media'] as Map?;

      if (json == null) {
        log(
          'Media not found for id: $providerId',
          name: 'AnilistTracker.getDetails',
        );
        throw AnilistException('Media not found for id: $providerId');
      }

      return _mapToUnified(json, type, requestId);
    });
  }

  @override
  Future<List<String>> fetchGenres() async {
    return executeApi('FETCH_GENRES', () async {
      final response = await http.post(
        _endpoint,
        body: {'query': AnilistTrackerQueries.genres},
        cacheDuration: const Duration(days: 7),
      );

      final data = _validateAndParseResponse(response.json, 'fetchGenres');
      final list = data['GenreCollection'] as List? ?? [];
      return list.whereType<String>().toList();
    });
  }

  @override
  Future<List<String>> fetchTags() async {
    return executeApi('FETCH_TAGS', () async {
      final response = await http.post(
        _endpoint,
        body: {'query': AnilistTrackerQueries.tags},
        cacheDuration: const Duration(days: 7),
      );

      final data = _validateAndParseResponse(response.json, 'fetchTags');
      final list = data['MediaTagCollection'] as List? ?? [];
      return list
          .whereType<Map>()
          .map((e) => e['name'] as String?)
          .whereType<String>()
          .toList();
    });
  }

  UnifiedMedia _mapToUnified(
    Map<dynamic, dynamic> json,
    MediaType type,
    int requestId, {
    String? relationType,
  }) {
    try {
      final titleJson = json['title'] as Map? ?? {};

      final title = MediaTitle(
        english: titleJson['english'],
        romaji: titleJson['romaji'],
        native: titleJson['native'],
      );

      String status = 'Unknown';
      switch (json['status']) {
        case 'RELEASING':
          status = 'Ongoing';
          break;
        case 'FINISHED':
          status = 'Completed';
          break;
        case 'NOT_YET_RELEASED':
          status = 'Upcoming';
          break;
      }

      final relations = ((json['relations'] as Map?)?['edges'] as List?)
          ?.map((e) {
            final node = (e as Map?)?['node'];
            final relType = e?['relationType']?.toString();
            if (node == null) return null;
            final nodeType = MediaType.values.firstWhere(
              (t) => t.name == node['type'],
              orElse: () => MediaType.ANIME,
            );
            return _mapToUnified(
              node,
              nodeType,
              requestId,
              relationType: relType,
            );
          })
          .whereType<UnifiedMedia>()
          .toList();

      final tags = (json['tags'] as List?)
          ?.whereType<Map>()
          .map(
            (e) => MediaTag(
              id: e['id']?.toString() ?? '',
              name: e['name'] ?? '',
              category: e['category'] ?? '',
            ),
          )
          .toList();

      final recommendations =
          ((json['recommendations'] as Map?)?['nodes'] as List?)
              ?.map((e) => (e as Map?)?['mediaRecommendation'])
              .whereType<Map>()
              .map((node) {
                final nodeType = MediaType.values.firstWhere(
                  (t) => t.name == node['type'],
                  orElse: () => MediaType.ANIME,
                );
                return _mapToUnified(node, nodeType, requestId);
              })
              .toList();
      final airingAt = json['nextAiringEpisode']?['airingAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['nextAiringEpisode']['airingAt'] * 1000,
            )
          : null;
      final nextEpisode = json['nextAiringEpisode']?['episode'];

      return UnifiedMedia(
        id: json['id']?.toString() ?? '',
        idMal: json['idMal']?.toString(),
        type: type,
        airingAt: airingAt,
        providerId: json['id']?.toString() ?? '',
        title: title,
        format: json['format'],
        cover:
            (json['coverImage'] as Map?)?['extraLarge'] ??
            (json['coverImage'] as Map?)?['large'] ??
            (json['coverImage'] as Map?)?['medium'],
        banner: json['bannerImage'],
        description: json['description'],
        status: status,
        episodes: json['episodes'],
        relationType: relationType,
        relations: relations,
        recommendations: recommendations,
        nextEpisode: nextEpisode,
        genres: (json['genres'] as List?)?.map((e) => e.toString()).toList(),
        tags: tags,
      );
    } catch (e, stackTrace) {
      log(
        'Error mapping UnifiedMedia',
        name: 'AnilistTracker._mapToUnified',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
