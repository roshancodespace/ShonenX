import 'dart:io';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/features/discovery/domain/models/search_filter_options.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_credentials.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_filter_options.dart';
import 'package:shonenx/features/tracking/engine/base_tracker.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';

class TraktException implements Exception {
  final String message;
  TraktException(this.message);
  @override
  String toString() => message;
}

mixin TraktMetadata on BaseTracker implements RemoteTracker {
  HTTP get http;

  TrackerCredentials? get customCredentials => null;

  static const String _baseUrl = 'https://api.trakt.tv';

  static String get defaultClientId => Platform.isWindows || Platform.isLinux
      ? Env.TRAKT_CLIENT_ID_LIST.last
      : Env.TRAKT_CLIENT_ID_LIST.first;

  String get clientId {
    final custom = customCredentials?.clientId.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return defaultClientId;
  }

  Map<String, String> get traktHeaders => {
    'Content-Type': 'application/json',
    'trakt-api-version': '2',
    'trakt-api-key': clientId,
  };

  @override
  List<TrackerCategory> get supportedCategories => [
    TrackerCategory.trending,
    TrackerCategory.popular,
    TrackerCategory.upcoming,
  ];

  String _endpointFor(MediaType type) {
    switch (type) {
      case MediaType.ANIME:
      case MediaType.TV:
        return 'shows';
      case MediaType.MOVIE:
        return 'movies';
      case MediaType.MANGA:
      case MediaType.NOVEL:
        throw TraktException('Unsupported media type for Trakt: $type');
    }
  }

  String _searchTypeFor(MediaType type) {
    switch (type) {
      case MediaType.ANIME:
      case MediaType.TV:
        return 'show';
      case MediaType.MOVIE:
        return 'movie';
      case MediaType.MANGA:
      case MediaType.NOVEL:
        throw TraktException('Unsupported media type for Trakt: $type');
    }
  }

  @override
  Future<PaginatedResult<UnifiedMedia>> getCategoryItems(
    TrackerCategory category, {
    int page = 1,
    MediaType type = MediaType.ANIME,
    Duration? cacheDuration,
    AdultContentMode adultMode = AdultContentMode.safe,
  }) {
    final endpoint = _endpointFor(type);
    final segment = switch (category) {
      TrackerCategory.trending => 'trending',
      TrackerCategory.popular => 'popular',
      TrackerCategory.topRated => 'popular',
      TrackerCategory.upcoming => 'anticipated',
      TrackerCategory.popularThisSeason => 'trending',
      TrackerCategory.recentlyUpdated => 'updates',
    };

    return executeApi('CATEGORY | ${category.name} | ${type.displayName}', () async {
      const limit = 20;
      final response = await http.get(
        '$_baseUrl/$endpoint/$segment',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'extended': 'full',
          if (type == MediaType.ANIME) 'genres': 'anime',
        },
        headers: traktHeaders,
        cacheDuration: cacheDuration ?? const Duration(hours: 1),
      );

      final dataList = response.json as List? ?? [];
      final items = dataList
          .whereType<Map>()
          .map((item) => mapTraktToUnified(item, type))
          .toList();

      return PaginatedResult(
        items: items,
        hasNextPage: dataList.length >= limit,
      );
    });
  }

  @override
  Future<PaginatedResult<UnifiedMedia>> getTrending({
    int page = 1,
    MediaType type = MediaType.ANIME,
    Duration? cacheDuration,
    AdultContentMode adultMode = AdultContentMode.safe,
  }) => getCategoryItems(
    TrackerCategory.trending,
    page: page,
    type: type,
    cacheDuration: cacheDuration,
    adultMode: adultMode,
  );

  @override
  Future<PaginatedResult<UnifiedMedia>> search(
    String query, {
    int page = 1,
    MediaType type = MediaType.ANIME,
    List<String>? genres,
    List<String>? tags,
    SearchSort sort = SearchSort.popularity,
    SearchStatusFilter status = SearchStatusFilter.all,
    SearchFormatFilter format = SearchFormatFilter.all,
    Duration? cacheDuration,
    AdultContentMode adultMode = AdultContentMode.safe,
  }) {
    final searchType = _searchTypeFor(type);

    return executeApi('SEARCH', () async {
      const limit = 20;
      final genreFilter = <String>{
        if (type == MediaType.ANIME) 'anime',
        ...?genres?.map((g) => g.toLowerCase()),
      };

      final response = await http.get(
        '$_baseUrl/search/$searchType',
        queryParameters: {
          'query': query,
          'page': page.toString(),
          'limit': limit.toString(),
          'extended': 'full',
          if (genreFilter.isNotEmpty) 'genres': genreFilter.join(','),
        },
        headers: traktHeaders,
        cacheDuration: cacheDuration,
      );

      final dataList = response.json as List? ?? [];
      final items = dataList
          .whereType<Map>()
          .map((item) => mapTraktToUnified(item, type))
          .toList();

      return PaginatedResult(
        items: items,
        hasNextPage: dataList.length >= limit,
      );
    });
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) {
    final endpoint = _endpointFor(type);

    return executeApi('DETAILS', () async {
      final response = await http.get(
        '$_baseUrl/$endpoint/$providerId',
        queryParameters: const {'extended': 'full'},
        headers: traktHeaders,
        cacheDuration: const Duration(days: 1),
      );

      final data = response.json as Map? ?? {};
      return mapTraktToUnified(data, type);
    });
  }

  @override
  Future<TrackerFilterOptions> fetchFilterOptions([MediaType? type]) async {
    final genres = await fetchGenres();
    return TrackerFilterOptions(genres: genres);
  }

  @override
  Future<List<String>> fetchGenres() async {
    return executeApi('GENRES', fallback: (_, __) => <String>[], () async {
      final response = await http.get(
        '$_baseUrl/genres/shows',
        headers: traktHeaders,
        cacheDuration: const Duration(days: 7),
      );
      final list = response.json as List? ?? [];
      return list
          .whereType<Map>()
          .map((e) => e['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    });
  }

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

  static String? normalizeTraktImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return 'https://$raw';
  }

  UnifiedMedia mapTraktToUnified(
    Map<dynamic, dynamic> rawJson,
    MediaType type,
  ) {
    final json =
        (rawJson['show'] as Map?) ?? (rawJson['movie'] as Map?) ?? rawJson;
    final ids = json['ids'] as Map? ?? {};

    final traktId = ids['trakt']?.toString() ?? '';
    final slug = ids['slug']?.toString();
    final tmdbId = ids['tmdb']?.toString();
    final imdbId = ids['imdb']?.toString();
    final tvdbId = ids['tvdb']?.toString();
    final id = traktId.isNotEmpty ? traktId : (slug ?? '');

    final images = json['images'] as Map?;
    final posterList = images?['poster'] as List?;
    final fanartList = images?['fanart'] as List?;
    final bannerList = images?['banner'] as List?;

    final cover = normalizeTraktImageUrl(posterList?.firstOrNull?.toString());
    final banner =
        normalizeTraktImageUrl(fanartList?.firstOrNull?.toString()) ??
        normalizeTraktImageUrl(bannerList?.firstOrNull?.toString());

    final rawStatus = json['status']?.toString().toLowerCase() ?? '';
    String status = 'Unknown';
    if (rawStatus.contains('returning') || rawStatus.contains('in production')) {
      status = 'Ongoing';
    } else if (rawStatus.contains('ended') || rawStatus.contains('released')) {
      status = 'Completed';
    } else if (rawStatus.contains('canceled')) {
      status = 'Cancelled';
    } else if (rawStatus.contains('planned')) {
      status = 'Upcoming';
    }

    final genresList = (json['genres'] as List?)
        ?.map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
        .toList();

    final titleText = json['title']?.toString() ?? 'Unknown';
    final urlSegment = type == MediaType.MOVIE ? 'movies' : 'shows';

    return UnifiedMedia(
      id: id,
      providerId: id,
      type: type,
      url: slug != null && slug.isNotEmpty
          ? 'https://trakt.tv/$urlSegment/$slug'
          : null,
      externalIds: MediaExternalIds(
        tmdb: tmdbId,
        extra: {
          if (traktId.isNotEmpty) 'trakt': traktId,
          if (slug != null && slug.isNotEmpty) 'slug': slug,
          if (imdbId != null && imdbId.isNotEmpty) 'imdb': imdbId,
          if (tvdbId != null && tvdbId.isNotEmpty) 'tvdb': tvdbId,
        },
      ),
      title: MediaTitle(english: titleText, romaji: titleText),
      cover: cover,
      banner: banner,
      description: json['overview']?.toString(),
      status: status,
      year: (json['year'] as num?)?.toInt(),
      trailer: json['trailer']?.toString(),
      episodes: (json['aired_episodes'] as num?)?.toInt(),
      score: (json['rating'] as num?)?.toDouble(),
      genres: genresList,
      format: type == MediaType.MOVIE ? 'MOVIE' : 'TV',
    );
  }
}
