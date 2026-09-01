import 'dart:convert';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_profile.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/shared/models/media_title.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class TraktMetadata {
  static const String _baseUrl = 'https://api.trakt.tv';
  static final HTTP _http = HTTP();
  static final _log = AppLogger.scope(TraktMetadata);

  static const String defaultClientId =
      '030ef1d48c8b417c8052aa8bc0d9eb4f40f0c0587d1591880ca0eb65851725cf';

  static Map<String, String> _headers(String? token, {String? clientId}) {
    return {
      'Content-Type': 'application/json',
      'trakt-api-version': '2',
      'trakt-api-key': clientId ?? defaultClientId,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<TrackerProfile?> fetchUserProfile(
    String token, {
    String? clientId,
  }) async {
    try {
      final response = await _http.get(
        '$_baseUrl/users/me?extended=full',
        headers: _headers(token, clientId: clientId),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final username = data['username'] as String? ?? 'Trakt User';
      final name = data['name'] as String? ?? username;
      final avatar = data['images']?['avatar']?['full'] as String?;

      return TrackerProfile(
        tracker: TrackerType.trakt,
        username: username,
        name: name,
        avatarUrl: avatar,
      );
    } catch (e) {
      _log.w('Error fetching Trakt user profile: $e');
      return null;
    }
  }

  static Future<List<UnifiedMedia>> searchAnime(
    String query, {
    String? token,
    String? clientId,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/search/show,movie?query=${Uri.encodeComponent(query)}&extended=full',
      );
      final response = await _http.get(
        url.toString(),
        headers: _headers(token, clientId: clientId),
      );

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      final List<UnifiedMedia> list = [];

      for (final item in data) {
        final type = item['type'] as String?;
        final show = (type == 'movie') ? item['movie'] : item['show'];
        if (show == null) continue;

        final ids = show['ids'] as Map<String, dynamic>? ?? {};
        final traktId = ids['trakt']?.toString() ?? '';
        final title = show['title'] as String? ?? 'Unknown';
        final overview = show['overview'] as String?;
        final year = show['year'] as int?;
        final rating = (show['rating'] as num?)?.toDouble();

        list.add(
          UnifiedMedia(
            id: traktId,
            sourceId: 'trakt',
            providerId: 'trakt',
            type: (type == 'movie') ? MediaType.ANIME : MediaType.ANIME,
            title: MediaTitle(english: title, romaji: title, userPreferred: title),
            description: overview,
            year: year,
            averageScore: rating != null ? (rating * 10).round() : null,
            genres: (show['genres'] as List<dynamic>?)?.cast<String>(),
            externalIds: ExternalIds(
              mal: ids['mal']?.toString(),
              anilist: ids['anilist']?.toString(),
            ),
          ),
        );
      }

      return list;
    } catch (e) {
      _log.w('Error searching Trakt: $e');
      return [];
    }
  }

  static Future<UnifiedMedia?> getMediaDetails(
    String traktId, {
    String? token,
    String? clientId,
  }) async {
    try {
      final response = await _http.get(
        '$_baseUrl/shows/$traktId?extended=full',
        headers: _headers(token, clientId: clientId),
      );

      if (response.statusCode != 200) return null;
      final show = jsonDecode(response.body);
      final ids = show['ids'] as Map<String, dynamic>? ?? {};
      final title = show['title'] as String? ?? 'Unknown';

      // Fetch seasons and episodes
      final seasonsResp = await _http.get(
        '$_baseUrl/shows/$traktId/seasons?extended=episodes',
        headers: _headers(token, clientId: clientId),
      );

      final List<UnifiedEpisode> episodesList = [];
      if (seasonsResp.statusCode == 200) {
        final List<dynamic> seasons = jsonDecode(seasonsResp.body);
        for (final season in seasons) {
          final sNum = season['number'] as int? ?? 1;
          final List<dynamic> eps = season['episodes'] ?? [];
          for (final ep in eps) {
            final eNum = ep['number'] as int? ?? 1;
            final epTitle = ep['title'] as String? ?? 'Episode $eNum';
            episodesList.add(
              UnifiedEpisode(
                id: '${traktId}_s${sNum}_e$eNum',
                number: eNum.toDouble(),
                title: epTitle,
                overview: ep['overview'] as String?,
                seasonNumber: sNum,
              ),
            );
          }
        }
      }

      return UnifiedMedia(
        id: traktId,
        sourceId: 'trakt',
        providerId: 'trakt',
        type: MediaType.ANIME,
        title: MediaTitle(english: title, romaji: title, userPreferred: title),
        description: show['overview'] as String?,
        year: show['year'] as int?,
        genres: (show['genres'] as List<dynamic>?)?.cast<String>(),
        episodes: episodesList,
        totalEpisodes: episodesList.isNotEmpty ? episodesList.length : null,
        externalIds: ExternalIds(
          mal: ids['mal']?.toString(),
          anilist: ids['anilist']?.toString(),
        ),
      );
    } catch (e) {
      _log.w('Error fetching Trakt media details: $e');
      return null;
    }
  }

  static Future<List<TrackedListItem>> fetchUserList(
    String token,
    TrackerCategory category, {
    String? clientId,
  }) async {
    try {
      final response = await _http.get(
        '$_baseUrl/sync/history/shows?extended=full',
        headers: _headers(token, clientId: clientId),
      );

      if (response.statusCode != 200) return [];

      final List<dynamic> list = jsonDecode(response.body);
      final List<TrackedListItem> result = [];

      for (final item in list) {
        final show = item['show'] as Map<String, dynamic>?;
        if (show == null) continue;

        final ids = show['ids'] as Map<String, dynamic>? ?? {};
        final traktId = ids['trakt']?.toString() ?? '';
        final title = show['title'] as String? ?? 'Unknown';
        final watchedCount = item['watched_episodes_count'] as int? ?? 1;

        result.add(
          TrackedListItem(
            trackingId: traktId,
            title: title,
            mediaType: MediaType.ANIME,
            status: TrackedStatus.watching,
            progress: watchedCount,
            totalEpisodes: show['aired_episodes'] as int?,
          ),
        );
      }

      return result;
    } catch (e) {
      _log.w('Error fetching Trakt user list: $e');
      return [];
    }
  }

  static Future<bool> updateProgress(
    String token, {
    required String traktId,
    required int episodeNumber,
    int seasonNumber = 1,
    String? clientId,
  }) async {
    try {
      final body = jsonEncode({
        'shows': [
          {
            'ids': {'trakt': int.tryParse(traktId) ?? traktId},
            'seasons': [
              {
                'number': seasonNumber,
                'episodes': [
                  {'number': episodeNumber}
                ]
              }
            ]
          }
        ]
      });

      final response = await _http.post(
        '$_baseUrl/sync/history',
        headers: _headers(token, clientId: clientId),
        body: body,
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      _log.w('Error updating Trakt progress: $e');
      return false;
    }
  }
}
