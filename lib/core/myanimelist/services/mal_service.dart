import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/anilist/page_response.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/core/myanimelist/services/auth_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/providers/auth_provider.dart';
import 'package:shonenx/features/settings/view_model/content_settings_notifier.dart';
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
  final Ref _ref;
  final MyAnimeListAuthService _authService;
  MyAnimeListService(this._ref, this._authService);

  @override
  String get name => 'MyAnimeList';

  String? _getAccessToken() {
    final authState = _ref.read(authProvider);
    if (!authState.isMalAuthenticated ||
        authState.activePlatform != AuthPlatform.mal) {
      AppLogger.w('MAL operation requires a logged-in MAL user.');
      return null;
    }
    final token = authState.malAccessToken;
    if (token == null || token.isEmpty) {
      AppLogger.w('Access token is missing for MAL operation.');
      return null;
    }
    return token;
  }

  bool _getShowAdult() {
    final settings = _ref.read(contentSettingsProvider);
    return settings.showMalAdult;
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final token = _getAccessToken();
    if (token == null) throw Exception('User not authenticated');

    final res = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
      ...?headers,
    });

    if (res.statusCode == 401) {
      // token expired, refresh
      final refreshed = await _authService.refreshToken();
      if (refreshed != null) {
        // update state
        _ref.read(authProvider.notifier).refreshMalToken();
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

    final res = await http.put(
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
        _ref.read(authProvider.notifier).refreshMalToken();
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
  Future<PageResponse> getUserAnimeList({
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
        .map((e) => MediaListEntry.fromMal(e as Map<String, dynamic>))
        .toList();

    final hasNextPage = data['paging']?['next'] != null;

    return PageResponse(
      pageInfo: PageInfo(
        total: -1,
        currentPage: page,
        lastPage: hasNextPage ? page + 1 : page,
        hasNextPage: hasNextPage,
        perPage: perPage,
      ),
      mediaList: list,
    );
  }

  // ---------------------- ANIME DETAILS ----------------------
  @override
  Future<Media?> getAnimeDetails(int animeId) async {
    const fields =
        'id,title,main_picture,alternative_titles,start_date,end_date,synopsis,mean,rank,popularity,num_list_users,num_scoring_users,nsfw,created_at,updated_at,media_type,status,genres,my_list_status,num_episodes,start_season,broadcast,source,average_episode_duration,rating,pictures,background,related_anime,related_manga,recommendations,studios,statistics';
    final url = 'https://api.myanimelist.net/v2/anime/$animeId?fields=$fields';
    final data = await _get(url);
    return Media.fromMal(data);
  }

  // ---------------------- FAVORITES ----------------------
  @override
  Future<List<Media>> getFavorites() async {
    return [];
  }

  @override
  Future<List<Media>> toggleFavorite(int animeId) async {
    // MAL API does not have toggle endpoint; would need POST to add/remove from favorites
    return [] as List<Media>;
  }

  // ---------------------- SEARCH ----------------------
  @override
  Future<List<Media>> searchAnime(
    String title, {
    int page = 1,
    int perPage = 10,
    SearchFilter? filter,
  }) async {
    final offset = (page - 1) * perPage;
    final nsfwStub = _getShowAdult() ? '&nsfw=true' : '';
    // MAL doesn't support advanced filters easily in basic search endpoint

    // Construct simplified query
    final url =
        'https://api.myanimelist.net/v2/anime?q=$title&limit=$perPage&offset=$offset&fields=num_episodes,status,mean,media_type$nsfwStub';
    final data = await _get(url);

    return (data['data'] as List<dynamic>? ?? [])
        .map((e) => Media.fromMal(e['node'] as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<String>> getGenres() async {
    // MAL API v2 doesn't have a direct genre list endpoint easily accessible without auth/wrapper
    // Returning empty or basic list for now
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
      'Supernatural'
    ];
  }

  @override
  Future<List<String>> getTags() async {
    return const []; // MAL doesn't really have tags like AniList
  }

// ---------------------- SINGLE ENTRY ----------------------
  @override
  Future<MediaListEntry?> getAnimeEntry(int animeId) async {
    // Only works if the anime is in the user's list
    final url =
        'https://api.myanimelist.net/v2/users/@me/animelist/$animeId?fields=list_status';
    try {
      final data = await _get(url);
      return MediaListEntry.fromMal(data);
    } catch (e) {
      if (e is MyAnimeListServiceException && e.message.contains('404')) {
        return null;
      }
      AppLogger.e('Failed to fetch anime entry', e);
      return null;
    }
  }

  // ---------------------- RANKING & LISTS ----------------------

  Future<List<Media>> _getRankedAnime(
      String rankingType, int page, int perPage) async {
    final offset = (page - 1) * perPage;
    final nsfwStub = _getShowAdult() ? '&nsfw=true' : '';
    final url =
        'https://api.myanimelist.net/v2/anime/ranking?ranking_type=$rankingType&limit=$perPage&offset=$offset&fields=num_episodes,status,mean,media_type$nsfwStub';
    final data = await _get(url);
    return (data['data'] as List<dynamic>? ?? [])
        .map((e) => Media.fromMal(e['node'] as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Media>> getPopularAnime({int page = 1, int perPage = 15}) async {
    return _getRankedAnime('bypopularity', page, perPage);
  }

  @override
  Future<List<Media>> getRecentlyUpdatedAnime(
      {int page = 1, int perPage = 15}) async {
    return _getRankedAnime('airing', page, perPage);
  }

  @override
  Future<List<Media>> getTopRatedAnime({int page = 1, int perPage = 15}) async {
    return _getRankedAnime('all', page, perPage);
  }

  @override
  Future<List<Media>> getTrendingAnime({int page = 1, int perPage = 15}) async {
    return _getRankedAnime('airing', page, perPage);
  }

  @override
  Future<List<Media>> getUpcomingAnime({int page = 1, int perPage = 15}) async {
    return _getRankedAnime('upcoming', page, perPage);
  }

  @override
  Future<List<Media>> getMostFavoriteAnime(
      {int page = 1, int perPage = 15}) async {
    return getPopularAnime(page: page, perPage: perPage);
  }

  @override
  Future<List<String>> getSupportedStatuses() async {
    return ['watching', 'completed', 'on_hold', 'dropped', 'plan_to_watch'];
  }

  @override
  Future<MediaListEntry?> updateUserAnimeList({
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

    return MediaListEntry(
      id: mediaId,
      status: status ?? 'UNKNOWN',
      score: score ?? 0,
      progress: progress ?? 0,
      media: Media(id: mediaId),
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

final malServiceProvider = Provider<MyAnimeListService>((ref) {
  final authService = ref.read(malAuthServiceProvider);
  return MyAnimeListService(ref, authService);
});
