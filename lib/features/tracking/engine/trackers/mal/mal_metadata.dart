import 'dart:developer';
import 'dart:io';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
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
      'id,title,main_picture,alternative_titles,start_date,end_date,synopsis,mean,rank,popularity,num_list_users,num_scoring_users,status,genres,created_at,updated_at,media_type,nsfw,my_list_status,num_episodes,start_season,broadcast,source,average_episode_duration,rating,pictures,background,related_anime,related_manga,recommendations,studios,statistics';

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
    AdultContentMode adultMode = AdultContentMode.safe,
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

        final response = await http.get(
          '$_baseUrl/$endpoint',
          queryParameters: {
            'q': query,
            'limit': limit.toString(),
            'offset': offset.toString(),
            'fields': _fields,
            'nsfw': adultMode == AdultContentMode.safe ? 'false' : 'true',
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
  }) {
    try {
      final titleJson = json['title'] as String? ?? '';
      final mainPicture = json['main_picture'] as Map? ?? {};
      final altTitles = json['alternative_titles'] as Map?;

      final title = MediaTitle(
        english: altTitles?['en'] as String?,
        romaji: titleJson,
        native: altTitles?['ja'] as String?,
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
      final format = json['media_type']?.toString().toUpperCase();

      final relatedAnime = json['related_anime'] as List?;
      final relatedManga = json['related_manga'] as List?;
      final allRelations = [...?relatedAnime, ...?relatedManga];

      final relations = allRelations
          .map((e) {
            final node = e['node'];
            if (node == null) return null;
            final relTypeFormatted =
                e['relation_type_formatted']?.toString() ??
                e['relation_type']?.toString();
            final nodeType =
                (e['relation_type'] == 'related_manga' ||
                    relatedManga?.contains(e) == true)
                ? MediaType.MANGA
                : MediaType.ANIME;
            return _mapToUnified(
              node,
              nodeType,
              requestId,
              relationType: relTypeFormatted,
            );
          })
          .whereType<UnifiedMedia>()
          .toList();

      final recommendationsRaw = json['recommendations'] as List?;
      final recommendations = recommendationsRaw
          ?.map((e) {
            final node = e['node'];
            if (node == null) return null;
            return _mapToUnified(node, type, requestId);
          })
          .whereType<UnifiedMedia>()
          .toList();

      DateTime? airingAt;
      int? nextEpisode;

      if (status == 'Ongoing' && json['broadcast'] is Map) {
        final broadcast = json['broadcast'] as Map;
        final dayString = broadcast['day_of_the_week']
            ?.toString()
            .toLowerCase()
            .trim();
        final timeString = broadcast['start_time']?.toString().trim();

        final Map<String, int> weekdayMap = {
          'monday': DateTime.monday,
          'tuesday': DateTime.tuesday,
          'wednesday': DateTime.wednesday,
          'thursday': DateTime.thursday,
          'friday': DateTime.friday,
          'saturday': DateTime.saturday,
          'sunday': DateTime.sunday,
        };

        final targetWeekday = weekdayMap[dayString];
        if (targetWeekday != null &&
            timeString != null &&
            timeString.contains(':')) {
          final parts = timeString.split(':');
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);

          if (hour != null && minute != null) {
            final nowUtc = DateTime.now().toUtc();
            final nowJst = nowUtc.add(const Duration(hours: 9));

            // Candidate airing time today in JST
            final candidateJst = DateTime(
              nowJst.year,
              nowJst.month,
              nowJst.day,
              hour,
              minute,
            );
            var daysDiff = targetWeekday - nowJst.weekday;
            if (daysDiff < 0 ||
                (daysDiff == 0 && nowJst.isAfter(candidateJst))) {
              daysDiff += 7;
            }

            final airingTimeJst = candidateJst.add(Duration(days: daysDiff));
            airingAt = airingTimeJst
                .subtract(const Duration(hours: 9))
                .toLocal();

            // Calculate next episode number based on weeks elapsed since start_date
            final startDateStr = json['start_date'] as String?;
            if (startDateStr != null) {
              final startDate = DateTime.tryParse(startDateStr);
              if (startDate != null) {
                final diffDays = airingTimeJst.difference(startDate).inDays;
                if (diffDays >= 0) {
                  final calculatedEp = (diffDays / 7).floor() + 1;
                  if (episodes == null || calculatedEp <= episodes) {
                    nextEpisode = calculatedEp;
                  }
                }
              }
            }
          }
        }
      }

      return UnifiedMedia(
        id: json['id']?.toString() ?? '',
        idMal: json['id']?.toString(),
        type: type,
        providerId: json['id']?.toString() ?? '',
        title: title,
        format: format,
        cover: cover,
        banner: null,
        description: synopsis,
        status: status,
        episodes: episodes,
        airingAt: airingAt,
        nextEpisode: nextEpisode,
        relationType: relationType,
        relations: relations.isNotEmpty ? relations : null,
        recommendations: recommendations?.isNotEmpty == true
            ? recommendations
            : null,
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
