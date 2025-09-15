import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shonenx/core/anilist/graphql_client.dart';
import 'package:shonenx/core/anilist/queries.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/anilist/page_response.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';

/// Custom exception for Anilist service errors
class AnilistServiceException implements Exception {
  final String message;
  final dynamic error;

  AnilistServiceException(this.message, [this.error]);

  @override
  String toString() =>
      'AnilistServiceException: $message${error != null ? ' ($error)' : ''}';
}

/// Service class for interacting with the AniList GraphQL API
class AnilistService implements AnimeRepository {
  final Ref _ref;

  AnilistService(this._ref);

  @override
  String get name => 'Anilist';

  static const _validStatuses = {
    'CURRENT',
    'COMPLETED',
    'PAUSED',
    'DROPPED',
    'PLANNING',
    'REPEATING',
  };

  // --- PRIVATE HELPERS ---
  ({int userId, String accessToken})? _getAuthContext() {
    final authState = _ref.read(authProvider);

    if (!authState.isLoggedIn ||
        authState.authPlatform != AuthPlatform.anilist) {
      AppLogger.w('Anilist operation requires a logged-in Anilist user.');
      return null;
    }

    final userId = authState.user?.id;
    final accessToken = authState.anilistAccessToken;

    if (userId == null || accessToken == null || accessToken.isEmpty) {
      AppLogger.w(
          'Invalid user ID or access token for authenticated operation.');
      return null;
    }
    return (userId: userId, accessToken: accessToken);
  }

  // Executes a GraphQL operation (query or mutation)
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

      AppLogger.d('$operationName completed successfully');
      return result.data as T?;
    } catch (e, stackTrace) {
      AppLogger.e('Operation $operationName failed', e, stackTrace);
      throw AnilistServiceException('Failed to execute $operationName', e);
    }
  }

  // Converts dynamic media list to typed Media list
  List<Media> _parseMediaList(List<dynamic>? media) =>
      media?.map((json) => Media.fromJson(json)).toList() ?? [];

  // --- METHODS FOR AUTHENTICATION FLOW ---
  Future<Map<String, dynamic>> getUserProfile(String accessToken) async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: accessToken,
      query: AnilistQueries.userProfileQuery,
      operationName: 'GetUserProfile',
    );
    return data?['Viewer'] ?? {};
  }

  // Search for anime by title
  @override
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

  // Fetch user anime list by status
  @override
  Future<PageResponse> getUserAnimeList({
    required String type,
    required String status,
    required int page,
    required int perPage,
  }) async {
    final auth = _getAuthContext();
    if (auth == null) {
      // Not logged in → return empty PageResponse
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

  // Fetch user's favorite anime
  @override
  Future<List<Media>> getFavorites() async {
    final auth = _getAuthContext();
    if (auth == null) {
      return []; // Not logged in, return empty.
    }

    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: auth.accessToken,
      query: AnilistQueries.userFavoritesQuery,
      variables: {'userId': auth.userId},
      operationName: 'GetFavorites',
    );
    return _parseMediaList(data?['User']?['favourites']?['anime']?['nodes']);
  }

  /// Fetch trending anime
  @override
  Future<List<Media>> getTrendingAnime() async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.trendingAnimeQuery,
      operationName: 'GetTrendingAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }

  /// Fetch popular anime
  @override
  Future<List<Media>> getPopularAnime() async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.popularAnimeQuery,
      operationName: 'GetPopularAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }

  /// Fetch recently updated anime
  @override
  Future<List<Media>> getRecentlyUpdatedAnime() async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.recentlyUpdatedAnimeQuery,
      operationName: 'GetRecentlyUpdatedAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }

  /// Fetch top-rated anime
  @override
  Future<List<Media>> getTopRatedAnime() async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.topRatedAnimeQuery,
      operationName: 'GetTopRatedAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }

  /// Fetch most favorited anime
  Future<List<Media>> getMostFavoriteAnime() async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.mostFavoritedAnimeQuery,
      operationName: 'GetMostFavoriteAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }

  /// Fetch most watched anime
  Future<List<Media>> getMostWatchedAnime() async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.mostWatchedAnimeQuery,
      operationName: 'GetMostWatchedAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }

  /// Fetch upcoming anime
  @override
  Future<List<Media>> getUpcomingAnime() async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.upcomingAnimeQuery,
      operationName: 'GetUpcomingAnime',
    );
    return _parseMediaList(data?['Page']?['media']);
  }

  /// Fetch detailed anime information
  @override
  Future<Media?> getAnimeDetails(int animeId) async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: null,
      query: AnilistQueries.animeDetailsQuery,
      variables: {'id': animeId},
      operationName: 'GetAnimeDetails',
    );
    return Media.fromJson(data!['Media']);
  }

  /// Toggle anime as favorite
  Future<List<Media>> toggleFavorite({
    required int animeId,
    required String? accessToken,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      AppLogger.w('Invalid accessToken for ToggleFavorite');
      return [];
    }

    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: accessToken,
      query: AnilistQueries.toggleFavoriteQuery,
      variables: {'animeId': animeId},
      isMutation: true,
      operationName: 'ToggleFavorite',
    );

    return _parseMediaList(data?['ToggleFavourite']?['anime']?['nodes']);
  }

  /// Save media progress
  Future<void> saveMediaProgress({
    required int mediaId,
    required String accessToken,
    required int episodeNumber,
  }) async {
    await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: accessToken,
      query: AnilistQueries.saveMediaProgressQuery,
      variables: {'mediaId': mediaId, 'progress': episodeNumber},
      isMutation: true,
      operationName: 'SaveMediaProgress',
    );
  }

  /// Update (or create) a user's anime list entry
  @override
  Future<MediaListEntry?> updateUserAnimeList({
    required int mediaId,
    String? status,
    double? score, // GraphQL expects Float
    int? progress,
    FuzzyDateInput? startedAt,
    FuzzyDateInput? completedAt,
    int? repeat,
    String? notes,
    bool? private,
  }) async {
    final auth = _getAuthContext();
    if (auth == null) return null;

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

  /// Check if an anime is favorited
  Future<bool> isAnimeFavorite({
    required int animeId,
    required String accessToken,
  }) async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: accessToken,
      query: AnilistQueries.isAnimeFavoriteQuery,
      variables: {'animeId': animeId},
      operationName: 'IsAnimeFavorite',
    );
    return data?['Media']?['isFavourite'] as bool? ?? false;
  }

  /// Update the status of an anime in the user's list
  Future<void> updateAnimeStatus({
    required int mediaId,
    required String accessToken,
    required String newStatus,
  }) async {
    final validatedStatus = validateMediaListStatus(newStatus);
    if (validatedStatus == 'INVALID') {
      AppLogger.w('Invalid MediaListStatus: $newStatus for UpdateAnimeStatus');
      throw AnilistServiceException('Invalid MediaListStatus: $newStatus');
    }

    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: accessToken,
      query: '''
        mutation UpdateAnimeStatus(\$mediaId: Int!, \$status: MediaListStatus!) {
          SaveMediaListEntry(mediaId: \$mediaId, status: \$status, progress: 0) {
            id
            mediaId
            status
            progress
            score
          }
        }
      ''',
      variables: {'mediaId': mediaId, 'status': validatedStatus},
      isMutation: true,
      operationName: 'UpdateAnimeStatus',
    );

    if (data?['SaveMediaListEntry'] == null) {
      AppLogger.e('Failed to update anime status for mediaId: $mediaId');
      throw AnilistServiceException('Failed to update anime status');
    }
  }

  /// Remove an anime from the user's list
  Future<void> deleteAnimeEntry({
    required int entryId,
    required String accessToken,
  }) async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: accessToken,
      query: '''
        mutation DeleteMediaListEntry(\$id: Int!) {
          DeleteMediaListEntry(id: \$id) {
            deleted
          }
        }
      ''',
      variables: {'id': entryId},
      isMutation: true,
      operationName: 'DeleteAnimeEntry',
    );

    if (data?['DeleteMediaListEntry']?['deleted'] != true) {
      AppLogger.e('Failed to delete anime entry with id: $entryId');
      throw AnilistServiceException('Failed to delete anime entry');
    }
  }

  /// Fetch the current status of an anime for a user
  Future<Map<String, dynamic>?> getAnimeStatus({
    required String accessToken,
    required int userId,
    required int animeId,
  }) async {
    final data = await _executeGraphQLOperation<Map<String, dynamic>>(
      accessToken: accessToken,
      query: '''
        query GetAnimeStatus(\$userId: Int!, \$animeId: Int!) {
          MediaList(userId: \$userId, mediaId: \$animeId) {
            id
            status
          }
        }
      ''',
      variables: {'userId': userId, 'animeId': animeId},
      operationName: 'GetAnimeStatus',
    );
    return data?['MediaList'] as Map<String, dynamic>?;
  }

  /// Get Streaming Episodes
  Future<List<StreamingEpisode>> getStreamingEpisodes(int mediaId) async {
    try {
      final data = await _executeGraphQLOperation(
          accessToken: null, query: AnilistQueries.streamingEpisodes);
      return (data?['Media']?['streamingEpisodes'] as List<dynamic>)
          .map((itemJson) => StreamingEpisode.fromJson(itemJson))
          .toList();
    } catch (err) {
      return [];
    }
  }

  /// Validate and convert status to a valid MediaListStatus value
  String validateMediaListStatus(String status) {
    final upperStatus = status.toUpperCase();
    if (!_validStatuses.contains(upperStatus)) {
      AppLogger.w(
          'Invalid MediaListStatus: $status. Valid values: $_validStatuses');
      return 'INVALID';
    }
    return upperStatus;
  }
}

// =========================================================================
// NEW: Create a provider for this service.
// This is now the ONLY correct way to get an instance of AnilistService.
// =========================================================================
final anilistServiceProvider = Provider<AnilistService>((ref) {
  return AnilistService(ref);
});
