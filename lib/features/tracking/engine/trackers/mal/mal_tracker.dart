import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_profile.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/base_tracker.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/engine/trackers/mal/mal_authenticator.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/tracker_search_result.dart';
import 'mal_metadata.dart';

class MalTracker extends BaseTracker with MalMetadata implements RemoteTracker {
  final Ref ref;
  final HTTP _http;

  @override
  HTTP get http => _http;

  MalTracker(this.ref) : _http = ref.read(httpClientProvider);

  Future<String?> _getToken() async {
    final tokens = await ref.read(authTokensProvider.future);
    return tokens[TrackerType.myanimelist];
  }

  @override
  Future<bool> get isAuthenticated async => (await _getToken()) != null;

  @override
  bool supportsMediaType(MediaType mediaType) => true;

  @override
  TrackerType get type => TrackerType.myanimelist;

  @override
  Authenticator get authenticator => MalAuthenticator();

  @override
  Future<List<TrackerSearchResult>> searchMedia(
    String query, {
    required MediaType type,
  }) {
    return executeApi('SEARCH', fallback: (_, __) => [], () async {
      final token = await _getToken();
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw Exception('MyAnimeList is not authenticated');
      }

      final endpoint = type == MediaType.ANIME ? 'anime' : 'manga';

      final response = await _http.get(
        'https://api.myanimelist.net/v2/$endpoint',
        queryParameters: {'q': query, 'limit': '20'},
        headers: headers,
      );

      final body = response.json;
      if (body['error'] != null) {
        throw Exception(body['message'] ?? 'Search failed');
      }

      final data = body['data'] as List? ?? [];

      return data.map((item) {
        final node = item['node'];
        return TrackerSearchResult(
          id: node['id']?.toString() ?? '',
          title: node['title'] ?? 'Unknown Title',
          cover:
              node['main_picture']?['large'] ?? node['main_picture']?['medium'],
        );
      }).toList();
    });
  }

  @override
  Future<void> updateListItem({
    required UnifiedMedia media,
    required String trackingId,
    TrackedStatus? status,
    double? progress,
    double? score,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('MyAnimeList is not authenticated');

    return executeApi('UPDATE_ENTRY', () async {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = _toMalStatus(status, media.type);
      if (progress != null) {
        final progressKey = media.type == MediaType.ANIME
            ? 'num_watched_episodes'
            : 'num_chapters_read';
        body[progressKey] = progress.toInt();
      }
      if (score != null && score > 0) {
        body['score'] = score.toInt();
      }

      if (body.isEmpty) return;

      final bodyString = body.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
          )
          .join('&');

      final endpoint = media.type == MediaType.ANIME ? 'anime' : 'manga';

      final response = await _http.patch(
        'https://api.myanimelist.net/v2/$endpoint/$trackingId/my_list_status',
        body: bodyString,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode >= 400) {
        final resBody = response.json;
        throw Exception(
          'MAL Error ${response.statusCode}: ${resBody?['message'] ?? resBody?['error'] ?? 'Failed to update entry'}',
        );
      }
    });
  }

  @override
  Future<TrackerProfile> fetchProfile() async {
    final token = await _getToken();
    if (token == null) throw Exception('MyAnimeList is not authenticated');

    return executeApi('PROFILE', () async {
      final res = await _http.get(
        'https://api.myanimelist.net/v2/users/@me',
        queryParameters: {'fields': 'picture,anime_statistics'},
        headers: {'Authorization': 'Bearer $token'},
      );

      final body = res.json;
      if (body['error'] != null) {
        throw Exception(body['message'] ?? 'Failed to fetch profile');
      }

      final stats = body['anime_statistics'] as Map?;
      final totalWatching = (stats?['num_items_watching'] as num?)?.toInt() ?? 0;
      final totalCompleted = (stats?['num_items_completed'] as num?)?.toInt() ?? 0;
      final totalOnHold = (stats?['num_items_on_hold'] as num?)?.toInt() ?? 0;
      final totalDropped = (stats?['num_items_dropped'] as num?)?.toInt() ?? 0;
      final totalPlan = (stats?['num_items_plan_to_watch'] as num?)?.toInt() ?? 0;
      final totalAnime = totalWatching + totalCompleted + totalOnHold + totalDropped + totalPlan;

      final username = body['name']?.toString() ?? '';

      return TrackerProfile(
        id: body['id']?.toString() ?? '',
        username: username,
        avatarUrl: body['picture'],
        profileUrl: username.isNotEmpty ? 'https://myanimelist.net/profile/$username' : null,
        animeCount: stats != null ? totalAnime : null,
        episodesWatched: (stats?['num_episodes'] as num?)?.toInt(),
        meanScore: (stats?['mean_score'] as num?)?.toDouble(),
        statusCounts: stats != null
            ? {
                if (totalWatching > 0) 'CURRENT': totalWatching,
                if (totalCompleted > 0) 'COMPLETED': totalCompleted,
                if (totalOnHold > 0) 'PAUSED': totalOnHold,
                if (totalDropped > 0) 'DROPPED': totalDropped,
                if (totalPlan > 0) 'PLANNING': totalPlan,
              }
            : null,
        lastSyncedAt: DateTime.now(),
      );
    });
  }

  @override
  Future<TrackedListItem?> fetchUserListItem({
    required String mediaId,
    required MediaType mediaType,
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    return executeApi(
      'FETCH_ENTRY',
      fallback: (e, st) {
        return null;
      },
      () async {
        final endpoint = mediaType == MediaType.ANIME ? 'anime' : 'manga';

        final res = await _http.get(
          'https://api.myanimelist.net/v2/$endpoint/$mediaId',
          queryParameters: {'fields': 'my_list_status'},
          headers: {
            'Authorization': 'Bearer $token',
            'X-MAL-CLIENT-ID': MalMetadata.clientId,
          },
        );

        if (res.statusCode >= 400) {
          return null;
        }

        final body = res.json;
        if (body == null || body['error'] != null) {
          return null;
        }

        final listStatus = body['my_list_status'] as Map?;
        if (listStatus == null) return null;

        final rawScore = (listStatus['score'] as num?)?.toInt() ?? 0;
        
        final progressKey = mediaType == MediaType.ANIME
            ? 'num_episodes_watched'
            : 'num_chapters_read';
        final progress =
            (listStatus[progressKey] as num?)?.toDouble() ?? 0.0;

        return TrackedListItem(
          id: body['id']?.toString(),
          status: _parseMalStatus(listStatus['status']?.toString()),
          progress: progress,
          score: rawScore > 0 ? rawScore.toDouble() : null,
        );
      },
    );
  }

  @override
  Future<List<LibraryEntry>> fetchUserLibrary({
    TrackedStatus status = TrackedStatus.watching,
    MediaType mediaType = MediaType.ANIME,
    int page = 1,
  }) async {
    final token = await _getToken();
    if (token == null) return [];

    return executeApi(
      status.name.toUpperCase(),
      fallback: (_, __) => [],
      () async {
        final limit = 50;
        final offset = (page - 1) * limit;

        final endpoint = mediaType == MediaType.ANIME ? 'animelist' : 'mangalist';
        final progressKey = mediaType == MediaType.ANIME
            ? 'num_episodes_watched'
            : 'num_chapters_read';
        final totalCountKey = mediaType == MediaType.ANIME
            ? 'num_episodes'
            : 'num_chapters';

        final res = await _http.get(
          'https://api.myanimelist.net/v2/users/@me/$endpoint',
          queryParameters: {
            'status': _toMalStatus(status, mediaType),
            'limit': limit.toString(),
            'offset': offset.toString(),
            'fields': 'list_status,$totalCountKey,mean,main_picture',
          },
          headers: {'Authorization': 'Bearer $token'},
        );

        final body = res.json;
        if (body['error'] != null) return [];

        final data = body['data'] as List? ?? [];

        return data.map((item) {
          final node = item['node'];
          final listStatus = item['list_status'];

          final rawScore = (listStatus?['score'] as num?)?.toInt() ?? 0;

          return LibraryEntry()
            ..providerId = node['id']?.toString() ?? ''
            ..type = mediaType.id
            ..title = node['title'] ?? 'Unknown'
            ..cover =
                node['main_picture']?['large'] ??
                node['main_picture']?['medium'] ??
                ''
            ..status = _parseMalStatus(listStatus?['status']).id
            ..score = rawScore > 0 ? rawScore.toDouble() : 0
            ..episodesWatched =
                (listStatus?[progressKey] as num?)?.toInt() ?? 0
            ..episodes = node[totalCountKey];
        }).toList();
      },
    );
  }

  @override
  Future<void> removeEntry({
    required String trackingId,
    required MediaType mediaType,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('MyAnimeList is not authenticated');

    return executeApi('DELETE', () async {
      final endpoint = mediaType == MediaType.ANIME ? 'anime' : 'manga';

      final response = await _http.delete(
        'https://api.myanimelist.net/v2/$endpoint/$trackingId/my_list_status',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode >= 400) {
        String detail = 'Failed to remove entry';
        try {
          final resBody = response.json as Map?;
          detail = resBody?['message'] ?? resBody?['error'] ?? detail;
        } catch (_) {}
        throw Exception('MAL Error ${response.statusCode}: $detail');
      }
    });
  }

  TrackedStatus _parseMalStatus(String? status) {
    switch (status) {
      case 'watching':
      case 'reading':
        return TrackedStatus.watching;
      case 'plan_to_watch':
      case 'plan_to_read':
        return TrackedStatus.planning;
      case 'completed':
        return TrackedStatus.completed;
      case 'on_hold':
        return TrackedStatus.paused;
      case 'dropped':
        return TrackedStatus.dropped;
      default:
        return TrackedStatus.unknown;
    }
  }

  String _toMalStatus(TrackedStatus status, MediaType mediaType) {
    final isAnime = mediaType == MediaType.ANIME;
    switch (status) {
      case TrackedStatus.watching:
        return isAnime ? 'watching' : 'reading';
      case TrackedStatus.planning:
        return isAnime ? 'plan_to_watch' : 'plan_to_read';
      case TrackedStatus.completed:
        return 'completed';
      case TrackedStatus.paused:
        return 'on_hold';
      case TrackedStatus.dropped:
        return 'dropped';
      case TrackedStatus.unknown:
        return isAnime ? 'watching' : 'reading';
    }
  }
}
