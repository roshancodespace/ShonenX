import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shonenx/api/anilist/graphql_client.dart';
import 'package:shonenx/api/anilist/queries.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/api/models/anilist/anilist_favorites.dart';

class AnilistService {
  /// **Generic method to execute GraphQL queries**
  Future<dynamic> _executeGraphQLOperation({
    required String? accessToken,
    required String query,
    dynamic variables,
    bool isMutation = false,
  }) async {
    final client = AnilistClient.getClient(accessToken: accessToken);

    final result = isMutation
        ? await client.mutate(
            MutationOptions(
              document: gql(query),
              variables: variables ?? {},
              fetchPolicy: FetchPolicy.networkOnly,
            ),
          )
        : await client.query(
            QueryOptions(
              document: gql(query),
              variables: variables ?? {},
              fetchPolicy: FetchPolicy.cacheAndNetwork,
            ),
          );

    if (result.hasException) {
      debugPrint(query);
      debugPrint('GraphQL Operation Failed: ${result.exception}');
      throw Exception('GraphQL Operation Failed: ${result.exception}');
    }

    return result.data;
  }

  /// **Search for anime by title**
  Future<List<Media>> searchAnime(String title) async {
    final data = await _executeGraphQLOperation(
      accessToken: null,
      query: AnilistQueries.searchAnimeQuery,
      variables: {'search': title},
    );

    final mediaList = (data?['Page']?['media'] as List<dynamic>)
        .map((mediaJson) => Media.fromJson(mediaJson))
        .toList();
    return mediaList;
  }

  /// **Fetch user profile data**
  Future<Map<String, dynamic>> getUserProfile(String accessToken) async {
    final data = await _executeGraphQLOperation(
      accessToken: accessToken,
      query: AnilistQueries.userProfileQuery,
    );

    if (data?['Viewer'] == null) {
      throw Exception('User profile not found');
    }
    return data?['Viewer'];
  }

  /// **Fetch user anime list by status**
  Future<MediaListCollection> getUserAnimeList({
    required String accessToken,
    required String userId,
    required String type, // e.g., 'ANIME' or 'MANGA'
    required String status, // e.g., 'CURRENT', 'COMPLETED', etc.
  }) async {
    if (accessToken.isEmpty) return MediaListCollection(lists: []);
    debugPrint(
        'Fetching anime list: User ID: $userId, Type: $type, Status: $status');

    final data = await _executeGraphQLOperation(
      accessToken: accessToken,
      query: AnilistQueries.userAnimeListQuery,
      variables: {'userId': userId, 'status': status, 'type': type},
    );

    if (data == null) {
      throw Exception('Failed to fetch anime list for status: $status');
    }

    return MediaListCollection.fromJson(data);
  }

  /// **Fetch trending anime**
  Future<List<Media>> getTrendingAnime() async {
    final data = await _executeGraphQLOperation(
      accessToken: null,
      query: AnilistQueries.trendingAnimeQuery,
    );

    final mediaList = (data?['Page']?['media'] as List<dynamic>? ?? [])
        .map((mediaJson) => Media.fromJson(mediaJson))
        .toList();
    return mediaList;
  }

  /// **Fetch popular anime**
  Future<List<Media>> getPopularAnime() async {
    final data = await _executeGraphQLOperation(
      accessToken: null,
      query: AnilistQueries.popularAnimeQuery,
    );

    final mediaList = (data?['Page']?['media'] as List<dynamic>)
        .map((mediaJson) => Media.fromJson(mediaJson))
        .toList();
    return mediaList;
  }

  /// **Fetch recently updated anime**
  Future<List<Media>> getRecentlyUpdatedAnime() async {
    final data = await _executeGraphQLOperation(
      accessToken: null,
      query: AnilistQueries.recentlyUpdatedAnimeQuery,
    );

    final mediaList = (data?['Page']?['media'] as List<dynamic>)
        .map((mediaJson) => Media.fromJson(mediaJson))
        .toList();
    return mediaList;
  }

  /// **Fetch upcoming anime**
  Future<List<Map<String, dynamic>>> getUpcomingAnime() async {
    final data = await _executeGraphQLOperation(
      accessToken: null,
      query: AnilistQueries.upcomingAnimeQuery,
    );

    final mediaList = data?['Page']?['media'] as List<dynamic>? ?? [];
    return mediaList.cast<Map<String, dynamic>>();
  }

  /// **Fetch detailed anime information**
  Future<Media> getAnimeDetails(int animeId) async {
    final data = await _executeGraphQLOperation(
      accessToken: null,
      query: AnilistQueries.animeDetailsQuery,
      variables: {'id': animeId},
    );

    if (data?['Media'] == null) {
      throw Exception('Anime details not found');
    }

    return Media.fromJson(data?['Media']);
  }

  /// **Fetch user's favorite anime**
  Future<AnilistFavorites?> getFavorites(
      {required int? userId, required String? accessToken}) async {
    if (userId == null || accessToken == null || accessToken.isEmpty) {
      debugPrint('❌ User ID or access token is null');
      return null;
    }
    debugPrint('Fetching favorite anime list for user ID: $userId');
    final data = await _executeGraphQLOperation(
      accessToken: accessToken,
      query: AnilistQueries.userFavoritesQuery,
      variables: {'userId': userId},
    );
    if (data == null) {
      throw Exception('Failed to fetch favorite anime list');
    }
    return AnilistFavorites(
      anime: (data['User']?['favourites']?['anime']?['nodes'] as List<dynamic>)
          .map((json) => Media.fromJson(json))
          .toList(),
    );
  }

  /// **Toggle anime as favorite**
  Future<List<Media>> toggleFavorite(
      {required int animeId, required accessToken}) async {
    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('❌ User ID or access token is null');
    }
    debugPrint('💖 Toggling Favorite for $animeId');
    final data = await _executeGraphQLOperation(
        accessToken: accessToken,
        query: AnilistQueries.toggleFavoriteQuery,
        variables: {'animeId': animeId},
        isMutation: true);
    if (data == null) {
      throw Exception('Failed to toggle favorite');
    }
    return (data['ToggleFavourite']?['anime']?['nodes'] as List<dynamic>)
        .map((mediaJson) => Media.fromJson(mediaJson))
        .toList();
  }

  Future<void> saveMediaProgress(
      {required int mediaId,
      required String accessToken,
      required int episodeNumber}) async {
    final data = await _executeGraphQLOperation(
        accessToken: accessToken,
        query: AnilistQueries.saveMediaProgressQuery,
        variables: {'mediaId': mediaId, 'progress': episodeNumber},
        isMutation: true);
    log(data);
  }

  /// **Check if an anime is favorited**
  Future<bool> isAnimeFavorite(
      {required int animeId, required String accessToken}) async {
    final data = await _executeGraphQLOperation(
      accessToken: accessToken,
      query: AnilistQueries.isAnimeFavoriteQuery,
      variables: {'animeId': animeId},
    );
    return (data?['Media']?['isFavourite'] as bool);
  }

  /// **Update the status of an anime in the user's list**
  Future<void> updateAnimeStatus({
    required int mediaId,
    required String accessToken,
    required String newStatus, // Example: "CURRENT", "COMPLETED", etc.
  }) async {
    final data = await _executeGraphQLOperation(
      accessToken: accessToken,
      query: AnilistQueries.updateAnimeStatusMutation,
      variables: {
        'mediaId': mediaId,
        'status': newStatus, // Must be one of "CURRENT", "COMPLETED", etc.
      },
      isMutation: true,
    );

    if (data != null) {
      debugPrint('✅ Anime status updated successfully: $data');
    } else {
      throw Exception('❌ Failed to update anime status.');
    }
  }

  /// **Remove an anime from the user's list**
  Future<void> deleteAnimeEntry({
    required int entryId, // The ID of the MediaList entry
    required String accessToken,
  }) async {
    final data = await _executeGraphQLOperation(
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
    );

    if (data?['DeleteMediaListEntry']?['deleted'] != true) {
      throw Exception('Failed to delete anime entry');
    }
    debugPrint('✅ Anime entry deleted successfully');
  }

  /// **Fetch the current status of an anime for a user**
  Future<Map<String, dynamic>?> getAnimeStatus({
    required String accessToken,
    required int userId,
    required int animeId,
  }) async {
    final data = await _executeGraphQLOperation(
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
    );

    return data?['MediaList'] as Map<String, dynamic>?;
  }
}
