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

  Future<T?> _executeGraphQLOperation<T>({
    required String? accessToken,
    required String query,
    Map<String, dynamic>? variables,
    bool isMutation = false,
    String operationName = '',
  }) async {
    try {
      AppLogger.d('Executing $operationName with variables: $variables');
      final client = AnilistClient.getClient(accessToken: accessToken);
      final options = isMutation
          ? MutationOptions(
              document: gql(query),
              variables: variables ?? {},
              fetchPolicy: FetchPolicy.networkOnly,
            )
          : QueryOptions(
              document: gql(query),
              variables: variables ?? {},
              fetchPolicy: FetchPolicy.cacheAndNetwork,
            );

      final result = isMutation
          ? await client.mutate(options as MutationOptions)
          : await client.query(options as QueryOptions);

      if (result.hasException) {
        AppLogger.e('GraphQL Error in $operationName', result.exception,
            StackTrace.current);
        throw AnilistServiceException(
            'GraphQL operation failed', result.exception);
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

  Future<List<Media>> searchAnime(String title,
      {int page = 1, int perPage = 10}) async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.searchAnimeQuery,
      variables: {'search': title, 'page': page, 'perPage': perPage},
      operationName: 'SearchAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
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
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.trendingAnimeQuery,
      variables: {'page': page, 'perPage': perPage},
      operationName: 'GetTrendingAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }

  Future<List<Media>> getPopularAnime({int page = 1, int perPage = 15}) async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.popularAnimeQuery,
      variables: {'page': page, 'perPage': perPage},
      operationName: 'GetPopularAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }

  Future<List<Media>> getTopRatedAnime({int page = 1, int perPage = 15}) async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.topRatedAnimeQuery,
      variables: {'page': page, 'perPage': perPage},
      operationName: 'GetTopRatedAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }

  Future<List<Media>> getRecentlyUpdatedAnime(
      {int page = 1, int perPage = 15}) async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.recentlyUpdatedAnimeQuery,
      variables: {'page': page, 'perPage': perPage},
      operationName: 'GetRecentlyUpdatedAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }

  Future<List<Media>> getUpcomingAnime({int page = 1, int perPage = 15}) async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.upcomingAnimeQuery,
      variables: {'page': page, 'perPage': perPage},
      operationName: 'GetUpcomingAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }
}

final anilistServiceProvider = Provider<AnilistService>((ref) {
  return AnilistService(ref);
});
