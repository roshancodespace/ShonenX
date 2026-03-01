// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:graphql/client.dart';
import 'package:shonenx/core/services/anilist/graphql_client.dart';
import 'package:shonenx/core/services/anilist/queries.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/core/models/universal/universal_page_response.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/browse/model/search_filter.dart';
import 'package:shonenx/shared/providers/tracker/tracker_service.dart';
import 'package:shonenx/core/models/tracker/tracker_type.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/core/models/tracker/tracker_exception.dart';

class AnilistService implements AnimeRepository, TrackerService {
  final ({String userId, String accessToken})? Function()
  _getAuthContextCallback;
  final bool? Function() _getAdultParamCallback;

  AnilistService({
    required ({String userId, String accessToken})? Function() getAuthContext,
    required bool? Function() getAdultParam,
  }) : _getAuthContextCallback = getAuthContext,
       _getAdultParamCallback = getAdultParam;

  @override
  String get name => 'Anilist';

  @override
  TrackerType get type => TrackerType.anilist;

  static const _validStatuses = {
    'CURRENT',
    'COMPLETED',
    'PAUSED',
    'DROPPED',
    'PLANNING',
    'REPEATING',
  };

  static GraphQLClient? _client;

  ({String userId, String accessToken})? _getAuthContext() =>
      _getAuthContextCallback();

  bool? _getAdultParam() => _getAdultParamCallback();

  Future<T?> _executeGraphQLOperation<T>({
    String? accessToken,
    required String query,
    Map<String, dynamic>? variables,
    bool isMutation = false,
    String operationName = 'GraphQL',
  }) async {
    try {
      AppLogger.i('[AniList] $operationName starting...');
      _client = await AnilistClient.getClient(accessToken: accessToken);

      final document = gql(query);

      final result = isMutation
          ? await _client!.mutate(
              MutationOptions(
                document: document,
                variables: variables ?? const {},
                fetchPolicy: FetchPolicy.networkOnly,
              ),
            )
          : await _client!.query(
              QueryOptions(
                document: document,
                variables: variables ?? const {},
                fetchPolicy: FetchPolicy.cacheFirst,
              ),
            );

      if (result.hasException) {
        throw TrackerException('GraphQL operation failed', result.exception);
      }

      AppLogger.success('[AniList] $operationName ✓');
      return result.data as T?;
    } catch (e, stackTrace) {
      AppLogger.e('[AniList] $operationName error', e, stackTrace);
      rethrow;
    }
  }

  List<UniversalMedia> _parseMediaList(List<dynamic>? media) =>
      media
          ?.map(
            (json) =>
                UniversalMedia.fromAnilist(Map<String, dynamic>.from(json)),
          )
          .toList() ??
      [];

  // Fetch the logged-in user's profile
  Future<Map<String, dynamic>> getUserProfile(String accessToken) async {
    try {
      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: accessToken,
        query: AnilistQueries.userProfileQuery,
        operationName: 'GetUserProfile',
      );

      return data?['Viewer'] ?? {};
    } catch (e) {
      return {};
    }
  }

  /// Update the logged-in user's profile
  Future<Map<String, dynamic>> updateUser({required String about}) async {
    try {
      final auth = _getAuthContext();
      if (auth == null) return {};

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: auth.accessToken,
        query: AnilistQueries.updateUserMutation,
        variables: {'about': about},
        isMutation: true,
        operationName: 'UpdateUser',
      );

      return data?['UpdateUser'] ?? {};
    } catch (e) {
      return {};
    }
  }

  // ---------------- OVERRIDES ----------------

  @override
  Future<UniversalPageResponse<UniversalMediaListEntry>> getUserAnimeList({
    required String type,
    required String status,
    required int page,
    required int perPage,
  }) async {
    try {
      final auth = _getAuthContext();
      if (auth == null || !_validStatuses.contains(status)) {
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

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: auth.accessToken,
        query: AnilistQueries.userAnimeListQuery,
        variables: {
          'page': page,
          'perPage': perPage,
          'userId': auth.userId,
          'type': type,
          'status': status,
        },
        operationName: 'GetUserAnimeList',
      );

      if (data == null) {
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

      final pageData = data['Page'];
      return UniversalPageResponse(
        pageInfo: UniversalPageInfo(
          total: pageData['pageInfo']['total'] ?? 0,
          currentPage: pageData['pageInfo']['currentPage'] ?? 1,
          lastPage: pageData['pageInfo']['lastPage'] ?? 1,
          hasNextPage: pageData['pageInfo']['hasNextPage'] ?? false,
          perPage: pageData['pageInfo']['perPage'] ?? perPage,
        ),
        data:
            (pageData['mediaList'] as List<dynamic>?)
                ?.map(
                  (e) => UniversalMediaListEntry.fromAnilist(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList() ??
            [],
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
      final auth = _getAuthContext();
      if (auth == null) return null;
      if (status != null && !_validStatuses.contains(status)) return null;

      final variables = {
        'mediaId': mediaId,
        'status': status,
        'score': score,
        'progress': progress,
        'startedAt': startedAt?.toJson(),
        'completedAt': completedAt?.toJson(),
        'repeat': repeat,
        'private': private,
        'notes': notes,
      }..removeWhere((key, value) => value == null);

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: auth.accessToken,
        query: AnilistQueries.updateAnimeMediaEntryMutation,
        variables: variables,
        isMutation: true,
        operationName: 'UpdateUserAnimeList',
      );

      final rawEntry = data?['SaveMediaListEntry'];
      if (rawEntry == null) return null;

      return UniversalMediaListEntry.fromAnilist(
        rawEntry as Map<String, dynamic>,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UniversalMediaListEntry?> getAnimeEntry(int animeId) async {
    try {
      final auth = _getAuthContext();
      if (auth == null) return null;

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: auth.accessToken,
        query: AnilistQueries.mediaListEntryByAnimeIdQuery,
        variables: {'userId': auth.userId, 'animeId': animeId},
        operationName: 'GetAnimeEntry',
      );

      final rawEntry = data?['MediaList'];
      if (rawEntry == null) return null;

      return UniversalMediaListEntry.fromAnilist(
        rawEntry as Map<String, dynamic>,
      );
    } catch (e) {
      if (e is TrackerException && e.toString().contains('Not Found')) {
        return null;
      }
      return null;
    }
  }

  @override
  Future<UniversalPageResponse<UniversalMedia>> getFavorites({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final auth = _getAuthContext();
      if (auth == null) {
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

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: auth.accessToken,
        query: AnilistQueries.userFavoritesQuery,
        variables: {'userId': auth.userId, 'page': page, 'perPage': perPage},
        operationName: 'GetFavorites',
      );

      final anime = data?['User']?['favourites']?['anime'];
      if (anime == null) {
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

      return UniversalPageResponse(
        pageInfo: UniversalPageInfo(
          total: anime['pageInfo']['total'] ?? 0,
          currentPage: anime['pageInfo']['currentPage'] ?? 1,
          lastPage: anime['pageInfo']['lastPage'] ?? 1,
          hasNextPage: anime['pageInfo']['hasNextPage'] ?? false,
          perPage: anime['pageInfo']['perPage'] ?? perPage,
        ),
        data: _parseMediaList(anime['nodes'] as List<dynamic>?),
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
    try {
      final auth = _getAuthContext();
      if (auth == null) return [];

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: auth.accessToken,
        query: AnilistQueries.toggleFavoriteQuery,
        variables: {'animeId': animeId},
        isMutation: true,
        operationName: 'ToggleFavourite',
      );
      return _parseMediaList(data?['ToggleFavourite']?['anime']?['nodes']);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<UniversalMedia>> searchAnime(
    String title, {
    int page = 1,
    int perPage = 25,
    SearchFilter? filter,
  }) async {
    try {
      final adultParam = _getAdultParam();
      final useAdult = adultParam != null;

      final hasSearch = title.trim().isNotEmpty;

      final variables = <String, dynamic>{
        if (hasSearch) 'search': title,
        'page': page,
        'perPage': perPage,
      };

      if (useAdult) variables['isAdult'] = adultParam;
      if (filter != null) {
        if (filter.genres.isNotEmpty) variables['genre'] = filter.genres;
        if (filter.season != null) variables['season'] = filter.season;
        if (filter.year != null) variables['year'] = filter.year;
        if (filter.format != null) variables['format'] = filter.format;
        if (filter.status != null) variables['status'] = filter.status;
        if (filter.sort != null) variables['sort'] = filter.sort!.toUpperCase();
        if (filter.tags.isNotEmpty) variables['tag'] = filter.tags;
      }

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: null,
        query: AnilistQueries.searchAnimeQuery(
          includeAdult: useAdult,
          hasGenre: filter?.genres.isNotEmpty ?? false,
          hasSeason: filter?.season != null,
          hasYear: filter?.year != null,
          hasFormat: filter?.format != null,
          hasStatus: filter?.status != null,
          hasSort: filter?.sort != null,
          hasTag: filter?.tags.isNotEmpty ?? false,
          hasSearch: hasSearch,
        ),
        variables: variables,
        operationName: 'SearchAnime',
      );
      return _parseMediaList(data?['Page']?['media']);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<String>> getGenres() async {
    try {
      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: null,
        query: AnilistQueries.getGenresQuery,
        operationName: 'GetGenres',
      );
      return (data?['GenreCollection'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<String>> getTags() async {
    try {
      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: null,
        query: AnilistQueries.getTagsQuery,
        operationName: 'GetTags',
      );
      return (data?['MediaTagCollection'] as List<dynamic>?)
              ?.map((e) => e['name'].toString())
              .toList() ??
          [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<UniversalMedia?> getAnimeDetails(int animeId) async {
    try {
      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: null,
        query: AnilistQueries.animeDetailsQuery,
        variables: {'id': animeId},
        operationName: 'GetAnimeDetails',
      );
      if (data == null || data['Media'] == null) return null;
      return UniversalMedia.fromAnilist(data['Media']);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UniversalPageResponse<UniversalMedia>> getTrendingAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final adultParam = _getAdultParam();
      final useAdult = adultParam != null;

      final variables = <String, dynamic>{'page': page, 'perPage': perPage};
      if (useAdult) variables['isAdult'] = adultParam;

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: null,
        query: AnilistQueries.trendingAnimeQuery(useAdult),
        variables: variables,
        operationName: 'GetTrendingAnime',
      );

      final pageData = data?['Page'];
      return UniversalPageResponse(
        pageInfo: UniversalPageInfo(
          total: pageData?['pageInfo']?['total'] ?? 0,
          currentPage: pageData?['pageInfo']?['currentPage'] ?? 1,
          lastPage: pageData?['pageInfo']?['lastPage'] ?? 1,
          hasNextPage: pageData?['pageInfo']?['hasNextPage'] ?? false,
          perPage: pageData?['pageInfo']?['perPage'] ?? perPage,
        ),
        data: _parseMediaList(pageData?['media']),
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
    int perPage = 15,
  }) async {
    try {
      final adultParam = _getAdultParam();
      final useAdult = adultParam != null;

      final variables = <String, dynamic>{'page': page, 'perPage': perPage};
      if (useAdult) variables['isAdult'] = adultParam;

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: null,
        query: AnilistQueries.popularAnimeQuery(useAdult),
        variables: variables,
        operationName: 'GetPopularAnime',
      );

      final pageData = data?['Page'];
      return UniversalPageResponse(
        pageInfo: UniversalPageInfo(
          total: pageData?['pageInfo']?['total'] ?? 0,
          currentPage: pageData?['pageInfo']?['currentPage'] ?? 1,
          lastPage: pageData?['pageInfo']?['lastPage'] ?? 1,
          hasNextPage: pageData?['pageInfo']?['hasNextPage'] ?? false,
          perPage: pageData?['pageInfo']?['perPage'] ?? perPage,
        ),
        data: _parseMediaList(pageData?['media']),
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
  Future<UniversalPageResponse<UniversalMedia>> getTopRatedAnime({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final adultParam = _getAdultParam();
      final useAdult = adultParam != null;

      final variables = <String, dynamic>{'page': page, 'perPage': perPage};
      if (useAdult) variables['isAdult'] = adultParam;

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: null,
        query: AnilistQueries.topRatedAnimeQuery(useAdult),
        variables: variables,
        operationName: 'GetTopRatedAnime',
      );

      final pageData = data?['Page'];
      return UniversalPageResponse(
        pageInfo: UniversalPageInfo(
          total: pageData?['pageInfo']?['total'] ?? 0,
          currentPage: pageData?['pageInfo']?['currentPage'] ?? 1,
          lastPage: pageData?['pageInfo']?['lastPage'] ?? 1,
          hasNextPage: pageData?['pageInfo']?['hasNextPage'] ?? false,
          perPage: pageData?['pageInfo']?['perPage'] ?? perPage,
        ),
        data: _parseMediaList(pageData?['media']),
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
  Future<UniversalPageResponse<UniversalMedia>> getRecentlyUpdatedAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final adultParam = _getAdultParam();
      final useAdult = adultParam != null;

      final variables = <String, dynamic>{'page': page, 'perPage': perPage};
      if (useAdult) variables['isAdult'] = adultParam;

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: null,
        query: AnilistQueries.recentlyUpdatedAnimeQuery(useAdult),
        variables: variables,
        operationName: 'GetRecentlyUpdatedAnime',
      );

      final pageData = data?['Page'];
      return UniversalPageResponse(
        pageInfo: UniversalPageInfo(
          total: pageData?['pageInfo']?['total'] ?? 0,
          currentPage: pageData?['pageInfo']?['currentPage'] ?? 1,
          lastPage: pageData?['pageInfo']?['lastPage'] ?? 1,
          hasNextPage: pageData?['pageInfo']?['hasNextPage'] ?? false,
          perPage: pageData?['pageInfo']?['perPage'] ?? perPage,
        ),
        data: _parseMediaList(pageData?['media']),
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
  Future<UniversalPageResponse<UniversalMedia>> getUpcomingAnime({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final adultParam = _getAdultParam();
      final useAdult = adultParam != null;

      final variables = <String, dynamic>{'page': page, 'perPage': perPage};
      if (useAdult) variables['isAdult'] = adultParam;

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: null,
        query: AnilistQueries.upcomingAnimeQuery(useAdult),
        variables: variables,
        operationName: 'GetUpcomingAnime',
      );

      final pageData = data?['Page'];
      return UniversalPageResponse(
        pageInfo: UniversalPageInfo(
          total: pageData?['pageInfo']?['total'] ?? 0,
          currentPage: pageData?['pageInfo']?['currentPage'] ?? 1,
          lastPage: pageData?['pageInfo']?['lastPage'] ?? 1,
          hasNextPage: pageData?['pageInfo']?['hasNextPage'] ?? false,
          perPage: pageData?['pageInfo']?['perPage'] ?? perPage,
        ),
        data: _parseMediaList(pageData?['media']),
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
  Future<UniversalPageResponse<UniversalMedia>> getMostFavoriteAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final adultParam = _getAdultParam();
      final useAdult = adultParam != null;

      final variables = <String, dynamic>{'page': page, 'perPage': perPage};
      if (useAdult) variables['isAdult'] = adultParam;

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: null,
        query: AnilistQueries.mostFavoriteAnimeQuery(useAdult),
        variables: variables,
        operationName: 'GetMostFavoriteAnime',
      );

      final pageData = data?['Page'];
      return UniversalPageResponse(
        pageInfo: UniversalPageInfo(
          total: pageData?['pageInfo']?['total'] ?? 0,
          currentPage: pageData?['pageInfo']?['currentPage'] ?? 1,
          lastPage: pageData?['pageInfo']?['lastPage'] ?? 1,
          hasNextPage: pageData?['pageInfo']?['hasNextPage'] ?? false,
          perPage: pageData?['pageInfo']?['perPage'] ?? perPage,
        ),
        data: _parseMediaList(pageData?['media']),
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

  Future<bool> deleteUserAnimeList(int mediaId) async {
    try {
      final auth = _getAuthContext();
      if (auth == null) return false;

      final entry = await getAnimeEntry(mediaId);
      if (entry == null) return false;

      final data = await _executeGraphQLOperation<Map<String, dynamic>>(
        accessToken: auth.accessToken,
        query: AnilistQueries.deleteMediaListEntryMutation,
        variables: {'id': entry.id},
        isMutation: true,
        operationName: 'DeleteMediaListEntry',
      );

      return data?['DeleteMediaListEntry']?['deleted'] ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> getSupportedStatuses() async {
    return _validStatuses.toList();
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
      score: score,
      progress: progress,
      repeat: repeat,
      notes: notes,
      private: isPrivate,
    );
  }
}
