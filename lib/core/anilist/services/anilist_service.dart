import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shonenx/core/anilist/graphql_client.dart';
import 'package:shonenx/core/anilist/queries.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/anilist/page_response.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/features/browse/model/search_filter.dart';
import 'package:shonenx/features/settings/view_model/content_settings_notifier.dart';

class AnilistServiceException implements Exception {
  final String message;
  final dynamic error;

  AnilistServiceException(this.message, [this.error]);

  @override
  String toString() =>
      'AnilistServiceException: $message${error != null ? ' ($error)' : ''}';
}

class AnilistService {
  final Ref? _ref;
  AnilistService(this._ref);

  String get name => 'Anilist';

  static const _validStatuses = {
    'CURRENT',
    'COMPLETED',
    'PAUSED',
    'DROPPED',
    'PLANNING',
    'REPEATING',
  };

  static GraphQLClient? _client;

  ({String userId, String accessToken})? _getAuthContext() {
    if (_ref == null) return null;
    final authState = _ref.read(authProvider);

    if (!authState.isAniListAuthenticated ||
        authState.activePlatform != AuthPlatform.anilist) {
      AppLogger.w('Anilist operation requires a logged-in Anilist user.');
      return null;
    }

    final userId = authState.anilistUser?.id;
    final accessToken = authState.anilistAccessToken;

    if (userId == null || accessToken == null || accessToken.isEmpty) {
      AppLogger.w(
          'Invalid user ID or access token for authenticated operation.');
      return null;
    }
    return (userId: userId.toString(), accessToken: accessToken);
  }

  bool? _getAdultParam() {
    final settings = _ref?.read(contentSettingsProvider);
    return (settings?.showAnilistAdult == true) ? null : false;
  }

  Future<T?> _executeGraphQLOperation<T>({
    String? accessToken,
    required String query,
    Map<String, dynamic>? variables,
    bool isMutation = false,
    String operationName = '',
  }) async {
    try {
      AppLogger.d('Executing $operationName with variables: $variables');

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
        AppLogger.e(
          'GraphQL Error in $operationName',
          result.exception?.graphqlErrors,
          StackTrace.current,
        );
        throw AnilistServiceException(
          'GraphQL operation failed',
          result.exception,
        );
      }

      AppLogger.i('$operationName completed successfully');
      return result.data as T?;
    } catch (e, stackTrace) {
      AppLogger.e('Operation $operationName failed', e, stackTrace);
      rethrow;
    }
  }

  List<Media> _parseMediaList(List<dynamic>? media) =>
      media?.map((json) => Media.fromJson(json)).toList() ?? [];

  /// Fetch the logged-in user's profile
  Future<Map<String, dynamic>> getUserProfile(String accessToken) async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: accessToken,
      query: AnilistQueries.userProfileQuery,
      operationName: 'GetUserProfile',
    );

    return data?['Viewer'] ?? {};
  }

  /// Update the logged-in user's profile
  Future<Map<String, dynamic>> updateUser({
    required String about,
    // Add other fields here if needed e.g. titleLanguage etc.
  }) async {
    final auth = _getAuthContext();
    if (auth == null) return {};

    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: auth.accessToken,
      query: AnilistQueries.updateUserMutation,
      variables: {
        'about': about,
      },
      isMutation: true,
      operationName: 'UpdateUser',
    );

    return data?['UpdateUser'] ?? {};
  }

  // ---------------- OVERRIDES ----------------

  Future<PageResponse> getUserAnimeList({
    required String type,
    required String status,
    required int page,
    required int perPage,
  }) async {
    final auth = _getAuthContext();
    if (auth == null || !_validStatuses.contains(status)) {
      return PageResponse(
        pageInfo: PageInfo(
          total: 0,
          currentPage: 1,
          lastPage: 1,
          hasNextPage: false,
          perPage: perPage,
        ),
        mediaList: [],
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

    return data != null
        ? PageResponse.fromJson(data)
        : PageResponse(
            pageInfo: PageInfo(
              total: 0,
              currentPage: 1,
              lastPage: 1,
              hasNextPage: false,
              perPage: perPage,
            ),
            mediaList: [],
          );
  }

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
    final auth = _getAuthContext();
    if (auth == null || !_validStatuses.contains(status)) return null;

    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: auth.accessToken,
      query: AnilistQueries.updateAnimeMediaEntryMutation,
      variables: {
        'mediaId': mediaId,
        'status': status,
        'score': score,
        'progress': progress,
        'startedAt': startedAt?.toJson(),
        'completedAt': completedAt?.toJson(),
        'repeat': repeat,
        'private': private,
        'notes': notes,
      },
      operationName: 'UpdateUserAnimeList',
    );

    final rawEntry = data?['SaveMediaListEntry'];
    if (rawEntry == null) return null;

    return MediaListEntry.fromJson(rawEntry as Map<String, dynamic>);
  }

  Future<MediaListEntry?> getAnimeEntry(int animeId) async {
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

    return MediaListEntry.fromJson(rawEntry as Map<String, dynamic>);
  }

  Future<List<Media>> getFavorites() async {
    final auth = _getAuthContext();
    if (auth == null) return [];

    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: auth.accessToken,
      query: AnilistQueries.userFavoritesQuery,
      variables: {'userId': auth.userId},
      operationName: 'GetFavorites',
    );
    return _parseMediaList(data?['User']?['favourites']?['anime']?['nodes']);
  }

  Future<List<Media>> toggleFavorite(int animeId) async {
    final auth = _getAuthContext();
    if (auth == null) return [];

    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: auth.accessToken,
      query: AnilistQueries.toggleFavoriteQuery,
      variables: {'animeId': animeId},
      operationName: 'ToggleFavourite',
    );
    return _parseMediaList(
        data?['data']?['ToggleFavourite']?['anime']?['nodes']);
  }

  Future<List<Media>> searchAnime(
    String title, {
    int page = 1,
    int perPage = 10,
    SearchFilter? filter,
  }) async {
    final adultParam = _getAdultParam();
    final useAdult = adultParam != null;

    final variables = <String, dynamic>{
      'search': title,
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
      ),
      variables: variables,
      operationName: 'SearchAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }

  Future<List<String>> getGenres() async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.getGenresQuery,
      operationName: 'GetGenres',
    );
    return (data?['GenreCollection'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
  }

  Future<List<String>> getTags() async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.getTagsQuery,
      operationName: 'GetTags',
    );
    return (data?['MediaTagCollection'] as List<dynamic>?)
            ?.map((e) => e['name'].toString())
            .toList() ??
        [];
  }

  Future<Media?> getAnimeDetails(int animeId) async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.animeDetailsQuery,
      variables: {'id': animeId},
      operationName: 'GetAnimeDetails',
    );
    return Media.fromJson(data!['Media']);
  }

  Future<List<Media>> getTrendingAnime({int page = 1, int perPage = 15}) async {
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
    AppLogger.d(data);
    return _parseMediaList(data?['Page']?['media']);
  }

  Future<List<Media>> getPopularAnime({int page = 1, int perPage = 15}) async {
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
    return _parseMediaList(data?['Page']?['media']);
  }

  Future<List<Media>> getTopRatedAnime({int page = 1, int perPage = 15}) async {
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
    return _parseMediaList(data?['Page']?['media']);
  }

  Future<List<Media>> getRecentlyUpdatedAnime(
      {int page = 1, int perPage = 15}) async {
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
    return _parseMediaList(data?['Page']?['media']);
  }

  Future<List<Media>> getUpcomingAnime({int page = 1, int perPage = 15}) async {
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
    return _parseMediaList(data?['Page']?['media']);
  }

  Future<List<Media>> getMostFavoriteAnime(
      {int page = 1, int perPage = 15}) async {
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
    return _parseMediaList(data?['Page']?['media']);
  }
}

final anilistServiceProvider = Provider<AnilistService>((ref) {
  return AnilistService(ref);
});
