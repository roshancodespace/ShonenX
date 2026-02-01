import 'dart:convert';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/core/models/universal/universal_page_response.dart';
import 'package:shonenx/core/network/universal_client.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/core/myanimelist/services/auth_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/browse/model/search_filter.dart';

class MyAnimeListServiceException implements Exception {
  final String message;
  final dynamic error;
  MyAnimeListServiceException(this.message, [this.error]);

  @override
  String toString() =>
      'MyAnimeListServiceException: $message${error != null ? ' ($error)' : ''}';
}

class MyAnimeListService implements AnimeRepository {
  final MyAnimeListAuthService _authService;
  final String? Function() _getAccessTokenCallback;
  final bool Function() _getShowAdultCallback;
  final Future<void> Function() _onTokenRefreshCallback;

  MyAnimeListService(
    this._authService, {
    required String? Function() getAccessToken,
    required bool Function() getShowAdult,
    required Future<void> Function() onTokenRefresh,
  }) : _getAccessTokenCallback = getAccessToken,
       _getShowAdultCallback = getShowAdult,
       _onTokenRefreshCallback = onTokenRefresh;

  @override
  String get name => 'MyAnimeList';

  String? _getAccessToken() => _getAccessTokenCallback();

  bool _getShowAdult() => _getShowAdultCallback();

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final token = _getAccessToken();
    if (token == null) throw Exception('User not authenticated');

    final res = await UniversalHttpClient.instance.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', ...?headers},
    );

    if (res.statusCode == 401) {
      // token expired, refresh
      final refreshed = await _authService.refreshToken();
      if (refreshed != null) {
        // update state
        await _onTokenRefreshCallback();
        return _get(url, headers: headers);
      }
    }

    if (res.statusCode != 200) {
      throw MyAnimeListServiceException('GET request failed: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _put(
    String url,
    Map<String, String> body,
  ) async {
    final token = _getAccessToken();
    if (token == null) throw Exception('User not authenticated');

    final res = await UniversalHttpClient.instance.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (res.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed != null) {
        await _onTokenRefreshCallback();
        return _put(url, body);
      }
    }

    if (res.statusCode != 200) {
      throw MyAnimeListServiceException('PUT request failed: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---------------------- USER PROFILE ----------------------
  Future<Map<String, dynamic>> getUserProfile() async {
    final data = await _get('https://api.myanimelist.net/v2/users/@me');
    return data;
  }

  // ---------------------- USER ANIME LIST ----------------------
  @override
  Future<UniversalPageResponse<UniversalMediaListEntry>> getUserAnimeList({
    required String type,
    required String status,
    required int page,
    required int perPage,
  }) async {
    final endpoint = type == "MANGA" ? "mangalist" : "animelist";
    final url =
        'https://api.myanimelist.net/v2/users/@me/$endpoint?status=$status&limit=$perPage&offset=${(page - 1) * perPage}&fields=list_status,num_episodes,start_season,average_mean_score';
    final data = await _get(url);

    final list = (data['data'] as List<dynamic>? ?? [])
        .map((e) => UniversalMediaListEntry.fromMal(e as Map<String, dynamic>))
        .toList();

    final hasNextPage = data['paging']?['next'] != null;

    return UniversalPageResponse(
      pageInfo: UniversalPageInfo(
        total: -1,
        currentPage: page,
        lastPage: hasNextPage ? page + 1 : page,
        hasNextPage: hasNextPage,
        perPage: perPage,
      ),
      data: list,
    );
  }

  // ---------------------- ANIME DETAILS ----------------------
  @override
  Future<UniversalMedia?> getAnimeDetails(int animeId) async {
    const fields =
        'id,title,main_picture,alternative_titles,start_date,end_date,synopsis,mean,rank,popularity,num_list_users,num_scoring_users,nsfw,created_at,updated_at,media_type,status,genres,my_list_status,num_episodes,start_season,broadcast,source,average_episode_duration,rating,pictures,background,related_anime,related_manga,recommendations,studios,statistics';
    final url = 'https://api.myanimelist.net/v2/anime/$animeId?fields=$fields';
    final data = await _get(url);
    return UniversalMedia.fromMal(data);
  }

  // ---------------------- FAVORITES ----------------------
  @override
  Future<UniversalPageResponse<UniversalMedia>> getFavorites({
    int page = 1,
    int perPage = 25,
  }) async {
    final url =
        'https://api.myanimelist.net/v2/users/@me/favorites'
        '?limit=$perPage'
        '&offset=${(page - 1) * perPage}'
        '&fields=list_status,num_episodes,start_season,average_mean_score';

    final data = await _get(url);

    final list = (data['data'] as List<dynamic>? ?? [])
        .map((e) => UniversalMedia.fromMal(e['node'] as Map<String, dynamic>))
        .toList();

    final paging = data['paging'] as Map<String, dynamic>?;
    final hasNextPage = paging?['next'] != null;

    return UniversalPageResponse(
      pageInfo: UniversalPageInfo(
        total: -1,
        currentPage: page,
        lastPage: hasNextPage ? page + 1 : page,
        hasNextPage: hasNextPage,
        perPage: perPage,
      ),
      data: list,
    );
  }

  @override
  Future<List<UniversalMedia>> toggleFavorite(int animeId) async {
    throw UnimplementedError();
  }

  // ---------------------- SEARCH ----------------------
  @override
  Future<List<UniversalMedia>> searchAnime(
    String title, {
    int page = 1,
    int perPage = 10,
    SearchFilter? filter,
  }) async {
    final offset = (page - 1) * perPage;
    final nsfwStub = _getShowAdult() ? '&nsfw=true' : '';

    final url =
        'https://api.myanimelist.net/v2/anime?q=$title&limit=$perPage&offset=$offset&fields=num_episodes,status,mean,media_type$nsfwStub';
    final data = await _get(url);

    return (data['data'] as List<dynamic>? ?? [])
        .map((e) => UniversalMedia.fromMal(e['node'] as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<String>> getGenres() async {
    return const [
      'Action',
      'Adventure',
      'Comedy',
      'Drama',
      'Fantasy',
      'Horror',
      'Mystery',
      'Romance',
      'Sci-Fi',
      'Slice of Life',
      'Sports',
      'Supernatural',
    ];
  }

  @override
  Future<List<String>> getTags() async {
    return const [];
  }

  // ---------------------- SINGLE ENTRY ----------------------
  @override
  Future<UniversalMediaListEntry?> getAnimeEntry(int animeId) async {
    // Only works if the anime is in the user's list
    final url =
        'https://api.myanimelist.net/v2/users/@me/animelist/$animeId?fields=list_status';
    try {
      final data = await _get(url);
      return UniversalMediaListEntry.fromMal({'node': data});
    } catch (e) {
      if (e is MyAnimeListServiceException && e.message.contains('404')) {
        return null;
      }
      AppLogger.e('Failed to fetch anime entry', e);
      return null;
    }
  }

  // ---------------------- RANKING & LISTS ----------------------

  Future<List<UniversalMedia>> _getRankedAnime(
    String rankingType,
    int page,
    int perPage,
  ) async {
    final offset = (page - 1) * perPage;
    final nsfwStub = _getShowAdult() ? '&nsfw=true' : '';
    final url =
        'https://api.myanimelist.net/v2/anime/ranking?ranking_type=$rankingType&limit=$perPage&offset=$offset&fields=num_episodes,status,mean,media_type$nsfwStub';
    final data = await _get(url);
    return (data['data'] as List<dynamic>? ?? [])
        .map((e) => UniversalMedia.fromMal(e['node'] as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<UniversalMedia>> getPopularAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    return _getRankedAnime('bypopularity', page, perPage);
  }

  @override
  Future<List<UniversalMedia>> getRecentlyUpdatedAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    return _getRankedAnime('airing', page, perPage);
  }

  @override
  Future<List<UniversalMedia>> getTopRatedAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    return _getRankedAnime('all', page, perPage);
  }

  @override
  Future<List<UniversalMedia>> getTrendingAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    return _getRankedAnime('airing', page, perPage);
  }

  @override
  Future<List<UniversalMedia>> getUpcomingAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    return _getRankedAnime('upcoming', page, perPage);
  }

  @override
  Future<List<UniversalMedia>> getMostFavoriteAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    return getPopularAnime(page: page, perPage: perPage);
  }

  @override
  Future<List<String>> getSupportedStatuses() async {
    return ['watching', 'completed', 'on_hold', 'dropped', 'plan_to_watch'];
  }

  @override
  Future<UniversalMediaListEntry?> updateUserAnimeList({
    required int mediaId,
    String? status,
    double? score,
    int? progress,
    FuzzyDateInput? startedAt,
    FuzzyDateInput? completedAt,
    int? repeat,
    String? notes,
    bool? private,
  }) async {
    final url = 'https://api.myanimelist.net/v2/anime/$mediaId/my_list_status';
    final body = <String, String>{};

    if (status != null) body['status'] = _mapStatusToMal(status);
    if (score != null) body['score'] = score.toInt().toString();
    if (progress != null) body['num_watched_episodes'] = progress.toString();
    await _put(url, body);

    return UniversalMediaListEntry(
      id: mediaId.toString(),
      status: status ?? 'UNKNOWN',
      score: score ?? 0,
      progress: progress ?? 0,
      media: UniversalMedia(
        id: mediaId.toString(),
        title: const UniversalTitle(),
        coverImage: const UniversalCoverImage(),
      ),
      repeat: repeat ?? 0,
      isPrivate: private ?? false,
      notes: notes ?? '',
    );
  }

  String _mapStatusToMal(String status) {
    switch (status.toUpperCase()) {
      case 'CURRENT':
        return 'watching';
      case 'COMPLETED':
        return 'completed';
      case 'PAUSED':
        return 'on_hold';
      case 'DROPPED':
        return 'dropped';
      case 'PLANNING':
        return 'plan_to_watch';
      default:
        return 'plan_to_watch';
    }
  }
}
