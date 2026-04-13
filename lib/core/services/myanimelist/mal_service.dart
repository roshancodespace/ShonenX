import 'dart:convert';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/core/models/universal/universal_page_response.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/core/services/mappers/universal_media_mapper.dart';
import 'package:shonenx/core/services/mappers/list_entry_mapper.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/browse/model/search_filter.dart';
import 'package:shonenx/shared/providers/tracker/tracker_service.dart';
import 'package:shonenx/core/models/tracker/tracker_type.dart';
import 'package:shonenx/core/models/tracker/tracker_exception.dart';

class MyAnimeListService implements AnimeRepository, TrackerService {
  final String? Function() _getAccessTokenCallback;
  final bool Function() _getShowAdultCallback;
  final Future<bool> Function() _onTokenRefreshCallback;

  MyAnimeListService({
    required String? Function() getAccessToken,
    required bool Function() getShowAdult,
    required Future<bool> Function() onTokenRefresh,
  }) : _getAccessTokenCallback = getAccessToken,
       _getShowAdultCallback = getShowAdult,
       _onTokenRefreshCallback = onTokenRefresh;

  @override
  String get name => 'MyAnimeList';

  @override
  TrackerType get type => TrackerType.mal;

  String? _getAccessToken() => _getAccessTokenCallback();

  bool _getShowAdult() => _getShowAdultCallback();

  List<UniversalMedia> _parseMediaList(List<dynamic>? media) {
    if (media == null) return [];
    return media
        .map((e) => UniversalMediaMapper.fromMal(e['node'] as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, String>? headers,
    String operationName = 'GET',
  }) async {
    try {
      final token = _getAccessToken();
      if (token == null) throw TrackerException('User not authenticated');
      final endpoint = Uri.parse(url).pathSegments.last;

      final res = await UniversalHttpClient.instance.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', ...?headers},
      );

      if (res.statusCode == 401) {
        // token expired, refresh
        AppLogger.i('[MAL] Token expired, refreshing for $operationName...');
        final refreshed = await _onTokenRefreshCallback();
        if (refreshed) {
          return _get(url, headers: headers, operationName: operationName);
        } else {
          throw TrackerException(
            'Authentication failed: Refresh token expired.',
          );
        }
      }

      if (res.statusCode != 200) {
        throw TrackerException('$operationName request failed: ${res.body}');
      }

      AppLogger.success('[MAL] $operationName $endpoint ✓');
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.e('[MAL] $operationName error', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _put(
    String url,
    Map<String, String> body, {
    String operationName = 'PATCH',
  }) async {
    try {
      final token = _getAccessToken();
      if (token == null) throw TrackerException('User not authenticated');
      final endpoint = Uri.parse(url).pathSegments.last;
      AppLogger.i('[MAL] $operationName $endpoint | $body');

      final res = await UniversalHttpClient.instance.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (res.statusCode == 401) {
        AppLogger.i('[MAL] Token expired, refreshing for $operationName...');
        final refreshed = await _onTokenRefreshCallback();
        if (refreshed) {
          return _put(url, body, operationName: operationName);
        } else {
          throw TrackerException(
            'Authentication failed: Refresh token expired.',
          );
        }
      }

      if (res.statusCode != 200) {
        throw TrackerException('$operationName request failed: ${res.body}');
      }

      AppLogger.success('[MAL] $operationName $endpoint ✓');
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.e('[MAL] $operationName error', e, st);
      rethrow;
    }
  }

  // ---------------------- USER PROFILE ----------------------
  Future<Map<String, dynamic>> getUserProfile() async {
    return await _get(
      'https://api.myanimelist.net/v2/users/@me',
      operationName: 'GetUserProfile',
    );
  }

  // ---------------------- USER ANIME LIST ----------------------
  @override
  Future<UniversalPageResponse<UniversalMediaListEntry>> getUserAnimeList({
    required String type,
    required String status,
    required int page,
    required int perPage,
  }) async {
    try {
      final endpoint = type == "MANGA" ? "mangalist" : "animelist";
      final offset = (page - 1) * perPage;
      final url =
          'https://api.myanimelist.net/v2/users/@me/$endpoint?status=$status&limit=$perPage&offset=$offset&fields=list_status,num_episodes,start_season,average_mean_score';

      final data = await _get(url, operationName: 'GetUserAnimeList');

      final list = (data['data'] as List<dynamic>? ?? [])
          .map(
            (e) => UniversalMediaListEntryMapper.fromMal(e as Map<String, dynamic>),
          )
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
    } catch (e) {
      return UniversalPageResponse(
        pageInfo: UniversalPageInfo(
          total: 0,
          currentPage: 1,
          lastPage: 1,
          hasNextPage: false,
          perPage: perPage,
        ),
        data: [],
      );
    }
  }

  // ---------------------- ANIME DETAILS ----------------------
  @override
  Future<UniversalMedia?> getAnimeDetails(int animeId) async {
    try {
      const fields =
          'id,title,main_picture,alternative_titles,start_date,end_date,synopsis,mean,rank,popularity,num_list_users,num_scoring_users,nsfw,created_at,updated_at,media_type,status,genres,my_list_status,num_episodes,start_season,broadcast,source,average_episode_duration,rating,pictures,background,related_anime,related_manga,recommendations,studios,statistics';
      final url =
          'https://api.myanimelist.net/v2/anime/$animeId?fields=$fields';

      final data = await _get(url, operationName: 'GetAnimeDetails');
      return UniversalMediaMapper.fromMal(data);
    } catch (e) {
      return null;
    }
  }

  // ---------------------- FAVORITES ----------------------
  @override
  Future<UniversalPageResponse<UniversalMedia>> getFavorites({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final offset = (page - 1) * perPage;
      final url =
          'https://api.myanimelist.net/v2/users/@me/favorites'
          '?limit=$perPage'
          '&offset=$offset'
          '&fields=list_status,num_episodes,start_season,average_mean_score';

      final data = await _get(url, operationName: 'GetFavorites');
      final list = _parseMediaList(data['data'] as List<dynamic>?);

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
    } catch (e) {
      return UniversalPageResponse(
        pageInfo: UniversalPageInfo(
          total: 0,
          currentPage: 1,
          lastPage: 1,
          hasNextPage: false,
          perPage: perPage,
        ),
        data: [],
      );
    }
  }

  @override
  Future<List<UniversalMedia>> toggleFavorite(int animeId) async {
    throw UnimplementedError("MAL API doesn't support toggling favorites yet.");
  }

  // ---------------------- SEARCH ----------------------
  @override
  Future<List<UniversalMedia>> searchAnime(
    String title, {
    int page = 1,
    int perPage = 10,
    SearchFilter? filter,
  }) async {
    try {
      final offset = (page - 1) * perPage;
      final nsfwStub = _getShowAdult() ? '&nsfw=true' : '';

      final url =
          'https://api.myanimelist.net/v2/anime?q=$title&limit=$perPage&offset=$offset&fields=num_episodes,status,mean,media_type$nsfwStub';

      final data = await _get(url, operationName: 'SearchAnime');
      return _parseMediaList(data['data'] as List<dynamic>?);
    } catch (e) {
      return [];
    }
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
    try {
      final url =
          'https://api.myanimelist.net/v2/anime/$animeId?fields=my_list_status,num_episodes,main_picture,title,alternative_titles,synopsis,media_type,status,genres,start_date,end_date,mean';

      final data = await _get(url, operationName: 'GetAnimeEntry');

      final myListStatus = data['my_list_status'];
      if (myListStatus == null) {
        return null;
      }
      final adapted = {
        'node': {...data, 'list_status': myListStatus},
      };
      return UniversalMediaListEntryMapper.fromMal(adapted);
    } catch (e) {
      if (e is TrackerException &&
          (e.message.contains('404') || e.message.contains('not_found'))) {
        return null;
      }
      return null;
    }
  }

  // ---------------------- RANKING & LISTS ----------------------

  Future<UniversalPageResponse<UniversalMedia>> _getRankedAnime(
    String rankingType,
    int page,
    int perPage,
  ) async {
    try {
      final offset = (page - 1) * perPage;
      final nsfwStub = _getShowAdult() ? '&nsfw=true' : '';

      final url =
          'https://api.myanimelist.net/v2/anime/ranking?ranking_type=$rankingType&limit=$perPage&offset=$offset&fields=num_episodes,status,mean,media_type$nsfwStub';

      final data = await _get(
        url,
        operationName: 'GetRankedAnime-$rankingType',
      );

      final list = _parseMediaList(data['data'] as List<dynamic>?);
      final hasNextPage = data['paging']?['next'] != null;

      return UniversalPageResponse(
        pageInfo: UniversalPageInfo(
          total: -1, // MAL doesn't provide total size for API ranks easily
          currentPage: page,
          lastPage: hasNextPage ? page + 1 : page,
          hasNextPage: hasNextPage,
          perPage: perPage,
        ),
        data: list,
      );
    } catch (e) {
      return UniversalPageResponse(
        pageInfo: UniversalPageInfo(
          total: 0,
          currentPage: 1,
          lastPage: 1,
          hasNextPage: false,
          perPage: perPage,
        ),
        data: [],
      );
    }
  }

  @override
  Future<UniversalPageResponse<UniversalMedia>> getPopularAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    return _getRankedAnime('bypopularity', page, perPage);
  }

  @override
  Future<UniversalPageResponse<UniversalMedia>> getRecentlyUpdatedAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    return _getRankedAnime('airing', page, perPage);
  }

  @override
  Future<UniversalPageResponse<UniversalMedia>> getTopRatedAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    return _getRankedAnime('all', page, perPage);
  }

  @override
  Future<UniversalPageResponse<UniversalMedia>> getTrendingAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    return _getRankedAnime('airing', page, perPage);
  }

  @override
  Future<UniversalPageResponse<UniversalMedia>> getUpcomingAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    return _getRankedAnime('upcoming', page, perPage);
  }

  @override
  Future<UniversalPageResponse<UniversalMedia>> getMostFavoriteAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    return getPopularAnime(page: page, perPage: perPage);
  }

  @override
  Future<List<String>> getSupportedStatuses() async {
    return ['CURRENT', 'COMPLETED', 'PAUSED', 'DROPPED', 'PLANNING'];
  }

  @override
  Future<UniversalMediaListEntry?> updateUserAnimeList({
    required int mediaId,
    String? status,
    double? score,
    int? progress,
    FuzzyDate? startedAt,
    FuzzyDate? completedAt,
    int? repeat,
    String? notes,
    bool? private,
  }) async {
    try {
      final url =
          'https://api.myanimelist.net/v2/anime/$mediaId/my_list_status';
      final body = <String, String>{};

      if (status != null) body['status'] = _mapStatusToMal(status);
      if (score != null) body['score'] = score.toInt().toString();
      if (progress != null) body['num_watched_episodes'] = progress.toString();

      await _put(url, body, operationName: 'UpdateUserAnimeList');

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
    } catch (e) {
      return null;
    }
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

  @override
  Future<void> updateEntry({
    required String remoteId,
    String? status,
    int? progress,
    double? score,
    int? repeat,
    String? notes,
    bool? isPrivate,
  }) async {
    final mediaId = int.tryParse(remoteId);
    if (mediaId == null) return;
    await updateUserAnimeList(
      mediaId: mediaId,
      status: status,
      progress: progress,
      score: score,
      repeat: repeat,
      notes: notes,
      private: isPrivate,
    );
  }
}
