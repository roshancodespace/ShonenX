import 'dart:developer';
import 'dart:io';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_credentials.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';
import 'package:shonenx/features/tracking/engine/base_tracker.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';

class SimklException implements Exception {
  final String message;
  SimklException(this.message);
  @override
  String toString() => message;
}

mixin SimklMetadata on BaseTracker implements RemoteTracker {
  HTTP get http;

  TrackerCredentials? get customCredentials => null;

  static const String _baseUrl = 'https://api.simkl.com';

  static String get defaultClientId => Platform.isWindows || Platform.isLinux
      ? Env.SIMKL_CLIENT_ID_LIST.last
      : Env.SIMKL_CLIENT_ID_LIST.first;

  String get clientId => customCredentials?.clientId ?? defaultClientId;

  @override
  List<TrackerCategory> get supportedCategories => [
    TrackerCategory.trending,
    TrackerCategory.popular,
  ];

  Map<String, String> get _headers => {
    'simkl-api-key': clientId,
    'Content-Type': 'application/json',
  };

  @override
  Future<PaginatedResult<UnifiedMedia>> getCategoryItems(
    TrackerCategory category, {
    int page = 1,
    MediaType type = MediaType.ANIME,
    Duration? cacheDuration,
    AdultContentMode adultMode = AdultContentMode.safe,
  }) {
    if (category == TrackerCategory.trending) {
      return getTrending(
        page: page,
        type: type,
        cacheDuration: cacheDuration,
        adultMode: adultMode,
      );
    }

    return getTrending(
      page: page,
      type: type,
      cacheDuration: cacheDuration,
      adultMode: adultMode,
    );
  }

  String _getEndpoint(MediaType type) {
    switch (type) {
      case MediaType.ANIME:
        return 'anime';
      case MediaType.MOVIE:
        return 'movies';
      case MediaType.TV:
        return 'tv';
      case MediaType.MANGA:
      case MediaType.NOVEL:
        throw SimklException('Unsupported media type for Simkl: $type');
    }
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
        final endpoint = _getEndpoint(type);
        final limit = 20;

        final url =
            'https://data.simkl.in/discover/trending/$endpoint/today_100.json';

        final response = await http.get(
          url,
          queryParameters: {
            'client_id': clientId,
            'app-name': 'ShonenX',
            'app-version': '1.0',
          },
          headers: _headers,
          cacheDuration: cacheDuration ?? const Duration(hours: 1),
        );

        final dataList = response.json as List? ?? [];

        final start = (page - 1) * limit;
        List itemsList;
        bool hasNextPage;

        if (start >= dataList.length) {
          itemsList = [];
          hasNextPage = false;
        } else {
          final end = start + limit;
          itemsList = dataList.sublist(
            start,
            end > dataList.length ? dataList.length : end,
          );
          hasNextPage = end < dataList.length;
        }

        final items = itemsList.whereType<Map>().map((item) {
          return _mapToUnified(item, type, requestId);
        }).toList();

        return PaginatedResult(items: items, hasNextPage: hasNextPage);
      },
      fallback: (error, stackTrace) {
        log(
          'Fallback triggered',
          name: 'SimklTracker.getTrending',
          error: error,
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
    List<String>? statusIn,
    Duration? cacheDuration,
    AdultContentMode adultMode = AdultContentMode.safe,
  }) {
    final requestId = DateTime.now().microsecondsSinceEpoch;

    return executeApi(
      'SEARCH',
      () async {
        final endpoint = _getEndpoint(type);

        final response = await http.get(
          '$_baseUrl/search/$endpoint',
          queryParameters: {'q': query, 'page': page.toString(), 'limit': '20'},
          headers: _headers,
          cacheDuration: cacheDuration,
        );

        final dataList = response.json as List? ?? [];
        final hasNextPage = dataList.length == 20;

        final items = dataList.whereType<Map>().map((item) {
          return _mapToUnified(item, type, requestId);
        }).toList();

        return PaginatedResult(items: items, hasNextPage: hasNextPage);
      },
      fallback: (error, stackTrace) {
        log('Fallback triggered', name: 'SimklTracker.search', error: error);
        return PaginatedResult(items: [], hasNextPage: false);
      },
    );
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) {
    final requestId = DateTime.now().microsecondsSinceEpoch;

    return executeApi('DETAILS', () async {
      final endpoint = _getEndpoint(type);

      final response = await http.get(
        '$_baseUrl/$endpoint/$providerId',
        queryParameters: {'extended': 'full'},
        headers: _headers,
        cacheDuration: const Duration(days: 1),
      );

      final data = response.json as Map? ?? {};
      return _mapToUnified(data, type, requestId);
    });
  }

  @override
  Future<List<String>> fetchGenres() async => [];

  @override
  Future<List<String>> fetchTags() async => [];

  @override
  Future<PaginatedResult<MediaCharacter>> getCharacters(
    String providerId, {
    int page = 1,
    int perPage = 25,
    MediaType type = MediaType.ANIME,
  }) async {
    return PaginatedResult(items: [], hasNextPage: false);
  }

  @override
  Future<MediaCharacter?> getCharacterDetails(String characterId) async {
    return null;
  }

  UnifiedMedia _mapToUnified(
    Map<dynamic, dynamic> json,
    MediaType type,
    int requestId,
  ) {
    final title = MediaTitle(
      english: json['title'] as String?,
      romaji: json['title'] as String?,
      native: json['title_ja'] as String?,
    );

    String id =
        (json['ids']?['simkl'] ?? json['ids']?['simkl_id'] ?? json['id'])
            ?.toString() ??
        '';
    if (id.isEmpty && json['url'] != null) {
      final url = json['url'].toString();
      final match = RegExp(r'(?:anime|tv|movies)/(\d+)').firstMatch(url);
      if (match != null) {
        id = match.group(1) ?? '';
      } else {
        final parts = url.split('/');
        if (parts.length > 1) id = parts[1];
      }
    }
    if (id.isEmpty) {
      id =
          json['title']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString();
    }

    String status = 'Unknown';
    final simklStatus = (json['status']?.toString().toLowerCase()) ?? '';
    if (simklStatus.contains('airing') || simklStatus.contains('returning')) {
      status = 'Ongoing';
    } else if (simklStatus.contains('ended') ||
        simklStatus.contains('finished')) {
      status = 'Completed';
    }

    final poster = json['poster']?.toString();
    final cover = poster != null
        ? 'https://simkl.in/posters/${poster}_m.webp'
        : null;

    final banner = json['fanart']?.toString();
    final bannerUrl = banner != null
        ? 'https://simkl.in/fanart/${banner}_medium.webp'
        : null;

    return UnifiedMedia(
      id: id,
      providerId: id,
      type: type,
      title: title,
      cover: cover,
      banner: bannerUrl,
      description: json['overview'] as String?,
      status: status,
      episodes: json['total_episodes'] as int?,
      score: (json['ratings']?['simkl']?['rating'] as num?)?.toDouble(),
      format: type.name,
    );
  }
}
