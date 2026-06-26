import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_profile.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/base_tracker.dart';
import 'package:shonenx/features/tracking/engine/trackers/anilist/anilist_tracker_queries.dart';
import 'package:shonenx/features/tracking/engine/trackers/anilist/anilist_authenticator.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/tracker_search_result.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'anilist_metadata.dart';

class AnilistTracker extends BaseTracker
    with AnilistMetadata
    implements RemoteTracker {
  final Ref ref;
  final HTTP _http;

  @override
  HTTP get http => _http;

  AnilistTracker(this.ref) : _http = ref.read(httpClientProvider);

  Future<String?> _getToken() async {
    final tokens = await ref.read(authTokensProvider.future);
    return tokens[TrackerType.anilist];
  }

  @override
  Future<bool> get isAuthenticated async => (await _getToken()) != null;

  @override
  bool supportsMediaType(MediaType mediaType) => true;

  @override
  TrackerType get type => TrackerType.anilist;

  @override
  Authenticator get authenticator => AnilistAuthenticator();

  @override
  Future<List<TrackerSearchResult>> searchMedia(
    String query, {
    required MediaType type,
    bool withCache = true,
  }) {
    return executeApi('SEARCH', fallback: (_, __) => [], () async {
      String normalize(String input) {
        return input
            .replaceAll('’', "'")
            .replaceAll('‘', "'")
            .replaceAll('“', '"')
            .replaceAll('”', '"');
      }

      final cleanQuery = normalize(query);

      final response = await _http.post(
        'https://graphql.anilist.co',
        body: {
          'query': AnilistTrackerQueries.search,
          'variables': {
            'search': cleanQuery,
            'type': _toAnilistMediaType(type),
          },
        },
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final body = response.json;

      if (body is! Map || body['errors'] != null) {
        return [];
      }

      final media = body['data']?['Page']?['media'] as List? ?? [];

      return media.map((item) {
        final title =
            item['title']?['english'] ??
            item['title']?['romaji'] ??
            'Unknown Title';
        final cover = item['coverImage']?['large'];
        return TrackerSearchResult(
          id: item['id']?.toString() ?? '',
          title: title,
          cover: cover,
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
    if (token == null) throw Exception('Anilist is not authenticated');

    return executeApi('UPDATE_ENTRY', () async {
      final mediaId = int.tryParse(trackingId);
      if (mediaId == null) return;

      final response = await _http.post(
        'https://graphql.anilist.co',
        body: {
          'query': AnilistTrackerQueries.updateEntry,
          'variables': {
            'mediaId': mediaId,
            if (status != null) 'status': _toAnilistStatus(status),
            if (progress != null) 'progress': progress.toInt(),
            if (score != null) 'scoreRaw': (score * 10).toInt(),
          },
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final body = response.json;
      if (body is Map && body['errors'] != null) {
        throw Exception(body['errors'][0]['message']);
      }
    });
  }

  @override
  Future<TrackerProfile> fetchProfile() async {
    final token = await _getToken();
    if (token == null) throw Exception('Anilist is not authenticated');

    return executeApi('PROFILE', () async {
      final res = await _http.post(
        'https://graphql.anilist.co',
        body: {'query': AnilistTrackerQueries.viewerProfile},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final body = res.json;

      if (body is! Map || body['errors'] != null) {
        throw Exception('Invalid profile response');
      }

      final viewer = body['data']?['Viewer'] as Map?;
      if (viewer == null) {
        throw Exception('Viewer null');
      }

      final stats = viewer['statistics'] as Map?;
      final animeStats = stats?['anime'] as Map?;
      final mangaStats = stats?['manga'] as Map?;

      Map<String, int>? parseStatuses(List? list) {
        if (list == null) return null;
        final map = <String, int>{};
        for (final item in list) {
          if (item is Map) {
            final st = item['status']?.toString();
            final cnt = (item['count'] as num?)?.toInt() ?? 0;
            if (st != null && cnt > 0) map[st] = cnt;
          }
        }
        return map.isEmpty ? null : map;
      }

      List<String>? parseFavs(Map? favMap) {
        final nodes = favMap?['anime']?['nodes'] as List?;
        if (nodes == null) return null;
        final res = <String>[];
        for (final n in nodes) {
          if (n is Map) {
            final url = n['coverImage']?['large']?.toString();
            if (url != null) res.add(url);
          }
        }
        return res.isEmpty ? null : res;
      }

      return TrackerProfile(
        id: viewer['id']?.toString() ?? '',
        username: viewer['name'] ?? '',
        avatarUrl: viewer['avatar']?['large'],
        bannerUrl: viewer['bannerImage'],
        bio: viewer['about'],
        profileUrl: viewer['siteUrl'],
        animeCount: (animeStats?['count'] as num?)?.toInt(),
        episodesWatched: (animeStats?['episodesWatched'] as num?)?.toInt(),
        minutesWatched: (animeStats?['minutesWatched'] as num?)?.toInt(),
        meanScore: (animeStats?['meanScore'] as num?)?.toDouble(),
        mangaCount: (mangaStats?['count'] as num?)?.toInt(),
        chaptersRead: (mangaStats?['chaptersRead'] as num?)?.toInt(),
        statusCounts: parseStatuses(animeStats?['statuses'] as List?),
        lastSyncedAt: DateTime.now(),
        favorites: parseFavs(viewer['favourites'] as Map?),
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

    final userId = (await fetchProfile()).id;

    return executeApi('FETCH_ENTRY', fallback: (_, __) => null, () async {
      final res = await _http.post(
        'https://graphql.anilist.co',
        body: {
          'query': AnilistTrackerQueries.mediaListItem,
          'variables': {
            'mediaId': int.parse(mediaId),
            'userId': int.parse(userId),
          },
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = res.json['data']['MediaList'];

      if (data == null) return null;

      return TrackedListItem(
        id: data['id']?.toString(),
        status: _parseAnilistStatus(data['status']),
        progress: data['progress']?.toDouble(),
        score: data['score'] != null ? (data['score'] as num).toDouble() : null,
      );
    });
  }

  @override
  Future<List<LibraryEntry>> fetchUserLibrary({
    TrackedStatus status = TrackedStatus.watching,
    MediaType mediaType = MediaType.ANIME,
    int page = 1,
  }) async {
    final token = await _getToken();
    if (token == null) return [];

    final userId = (await fetchProfile()).id;

    return executeApi(
      status.name.toUpperCase(),
      fallback: (_, __) => [],
      () async {
        final parsedUserId = int.tryParse(userId);
        if (parsedUserId == null) return [];

        final res = await _http.post(
          'https://graphql.anilist.co',
          body: {
            'query': AnilistTrackerQueries.userLibrary,
            'variables': {
              'userId': parsedUserId,
              'status': _toAnilistStatus(status),
              'page': page,
              'type': _toAnilistMediaType(mediaType),
            },
          },
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        final body = res.json;

        if (body is! Map || body['errors'] != null) {
          return [];
        }

        final pageData = body['data']?['Page'] as Map?;
        if (pageData == null) return [];

        final mediaList = pageData['mediaList'] as List? ?? [];

        return mediaList
            .map((entry) {
              final media = entry['media'] as Map?;

              if (media == null) return null;

              return LibraryEntry()
                ..providerId = media['id']?.toString() ?? ''
                ..type = mediaType.id
                ..title =
                    media['title']?['english'] ??
                    media['title']?['romaji'] ??
                    'Unknown'
                ..format = media['format']?.toString() ?? ''
                ..cover = media['coverImage']?['large'] ?? ''
                ..status = _parseAnilistStatus(media['status']).id
                ..episodes = media['episodes'];
            })
            .whereType<LibraryEntry>()
            .toList();
      },
    );
  }

  @override
  Future<void> removeEntry({
    required String trackingId,
    required MediaType mediaType,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Anilist is not authenticated');

    return executeApi('DELETE', () async {
      final id = int.tryParse(trackingId);
      if (id == null) return;

      final res = await fetchUserListItem(
        mediaId: trackingId,
        mediaType: mediaType,
      );
      if (res == null) return;

      await _http.post(
        'https://graphql.anilist.co',
        body: {
          'query': AnilistTrackerQueries.deleteEntry,
          'variables': {'id': res.id},
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    });
  }

  Future<void> updateBio(String bio) async {
    final token = await _getToken();
    if (token == null) return;
    await executeApi('UPDATE_BIO', () async {
      await _http.post(
        'https://graphql.anilist.co',
        body: {
          'query': 'mutation (\$about: String) { UpdateUser(about: \$about) { id about } }',
          'variables': {'about': bio},
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    });
  }

  TrackedStatus _parseAnilistStatus(String? status) {
    switch (status) {
      case 'CURRENT':
        return TrackedStatus.watching;
      case 'PLANNING':
        return TrackedStatus.planning;
      case 'COMPLETED':
        return TrackedStatus.completed;
      case 'PAUSED':
        return TrackedStatus.paused;
      case 'DROPPED':
        return TrackedStatus.dropped;
      default:
        return TrackedStatus.unknown;
    }
  }

  String _toAnilistStatus(TrackedStatus status) {
    switch (status) {
      case TrackedStatus.watching:
        return 'CURRENT';
      case TrackedStatus.planning:
        return 'PLANNING';
      case TrackedStatus.completed:
        return 'COMPLETED';
      case TrackedStatus.paused:
        return 'PAUSED';
      case TrackedStatus.dropped:
        return 'DROPPED';
      case TrackedStatus.unknown:
        return 'CURRENT';
    }
  }

  String _toAnilistMediaType(MediaType type) {
    switch (type) {
      case MediaType.ANIME:
        return 'ANIME';
      case MediaType.MANGA:
        return 'MANGA';
    }
  }
}
