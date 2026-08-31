import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_credentials.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_profile.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/base_tracker.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/tracker_search_result.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';

import 'simkl_authenticator.dart';
import 'simkl_metadata.dart';

class SimklTracker extends BaseTracker
    with SimklMetadata
    implements RemoteTracker {
  final Ref ref;
  final HTTP _http;

  @override
  HTTP get http => _http;

  SimklTracker(this.ref) : _http = ref.read(httpClientProvider);

  @override
  TrackerType get type => TrackerType.simkl;

  @override
  TrackerCredentials? get customCredentials =>
      ref.read(trackingPrefsProvider).customCredentials[TrackerType.simkl];

  @override
  Authenticator get authenticator =>
      SimklAuthenticator(customCredentials: customCredentials);

  Future<String?> _getToken() async {
    final tokens = await ref.read(authTokensProvider.future);
    return tokens[TrackerType.simkl];
  }

  @override
  Future<bool> get isAuthenticated async => (await _getToken()) != null;

  @override
  List<MediaType> get supportedMediaTypes => [
    MediaType.ANIME,
    MediaType.TV,
    MediaType.MOVIE,
  ];

  @override
  bool supportsMediaType(MediaType mediaType) =>
      supportedMediaTypes.contains(mediaType);

  @override
  Future<List<TrackerSearchResult>> searchMedia(
    String query, {
    required MediaType type,
    bool withCache = true,
  }) async {
    final result = await search(
      query,
      type: type,
      cacheDuration: withCache ? null : Duration.zero,
    );
    return result.items
        .map(
          (m) => TrackerSearchResult(id: m.id, title: m.title, cover: m.cover),
        )
        .toList();
  }

  final Map<String, DateTime> _lastFetchTime = {};
  final Map<String, List> _cachedSimklItems = {};

  void _invalidateCache() {
    _lastFetchTime.clear();
    _cachedSimklItems.clear();
  }

  Future<List> _getAllItemsCached(String simklType, String token) async {
    final lastTime = _lastFetchTime[simklType];
    if (lastTime != null &&
        DateTime.now().difference(lastTime) < const Duration(minutes: 5)) {
      return _cachedSimklItems[simklType] ?? [];
    }

    final res = await _http.get(
      'https://api.simkl.com/sync/all-items/$simklType',
      headers: {
        'Authorization': 'Bearer $token',
        'simkl-api-key': clientId,
        'Content-Type': 'application/json',
      },
    );

    final data = res.json;
    List list = [];
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = data[simklType] as List? ?? data['items'] as List? ?? [];
    }

    _cachedSimklItems[simklType] = list;
    _lastFetchTime[simklType] = DateTime.now();
    return list;
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
    if (token == null) throw Exception('Simkl is not authenticated');

    return executeApi('UPDATE_ENTRY', () async {
      final simklType = media.type == MediaType.ANIME
          ? 'anime'
          : (media.type == MediaType.MOVIE ? 'movies' : 'shows');
      final id = int.tryParse(trackingId);
      if (id == null) throw Exception('Invalid tracking ID: $trackingId');

      final headers = {
        'Authorization': 'Bearer $token',
        'simkl-api-key': clientId,
        'Content-Type': 'application/json',
      };

      if (status != null) {
        await _http.post(
          'https://api.simkl.com/sync/add-to-list',
          body: {
            simklType: [
              {
                'to': _toSimklStatus(status),
                'ids': {'simkl': id},
              },
            ],
          },
          headers: headers,
        );
      }

      if (score != null) {
        await _http.post(
          'https://api.simkl.com/sync/ratings',
          body: {
            simklType: [
              {
                'rating': score.toInt(),
                'ids': {'simkl': id},
              },
            ],
          },
          headers: headers,
        );
      }

      if (progress != null && progress > 0) {
        final episodesList = List.generate(
          progress.toInt(),
          (i) => {'number': i + 1},
        );
        await _http.post(
          'https://api.simkl.com/sync/history',
          body: {
            simklType: [
              {
                'ids': {'simkl': id},
                if (media.type != MediaType.MOVIE) 'episodes': episodesList,
              },
            ],
          },
          headers: headers,
        );
      }

      _invalidateCache();
    });
  }

  @override
  Future<TrackerProfile> fetchProfile() async {
    final token = await _getToken();
    if (token == null) throw Exception('Simkl is not authenticated');

    return executeApi('PROFILE', () async {
      final res = await _http.post(
        'https://api.simkl.com/users/settings',
        headers: {
          'Authorization': 'Bearer $token',
          'simkl-api-key': clientId,
          'Content-Type': 'application/json',
        },
      );

      final data = res.json;
      final user = data['user'] as Map? ?? {};

      return TrackerProfile(
        id: user['id']?.toString() ?? '',
        username: user['name'] ?? 'User',
        avatarUrl: user['avatar'],
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

    return executeApi('FETCH_ENTRY', fallback: (_, __) => null, () async {
      final simklType = mediaType == MediaType.ANIME
          ? 'anime'
          : (mediaType == MediaType.MOVIE ? 'movies' : 'shows');
      final id = int.tryParse(mediaId);
      if (id == null) return null;

      final list = await _getAllItemsCached(simklType, token);

      for (final item in list) {
        if (item is! Map) continue;

        final inner =
            item['show'] as Map? ??
            item['movie'] as Map? ??
            item['anime'] as Map? ??
            item[simklType] as Map? ??
            item;

        final itemId = (inner['ids']?['simkl'] ?? inner['id'])?.toString();
        if (itemId == mediaId || itemId == id.toString()) {
          final statusStr = item['status']?.toString();
          final userRating =
              (item['user_rating'] as num?)?.toDouble() ??
              (item['rating'] as num?)?.toDouble();
          final progress =
              (item['watched_episodes_count'] as num?)?.toDouble() ??
              ((item['episodes'] as List?)?.length.toDouble() ?? 0.0);

          return TrackedListItem(
            id: itemId,
            status: _parseSimklStatus(statusStr),
            progress: progress,
            score: (userRating != null && userRating > 0) ? userRating : null,
          );
        }
      }

      return null;
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

    return executeApi('FETCH_LIBRARY', () async {
      final simklType = mediaType == MediaType.ANIME ? 'anime' : 'shows';
      final simklStatus = _toSimklStatus(status);

      final res = await _http.get(
        'https://api.simkl.com/sync/all-items/$simklType/$simklStatus',
        headers: {
          'Authorization': 'Bearer $token',
          'simkl-api-key': clientId,
          'Content-Type': 'application/json',
        },
      );

      final jsonResponse = res.json;
      List list = [];
      if (jsonResponse is Map) {
        list = jsonResponse[simklType] as List? ?? [];
      } else if (jsonResponse is List) {
        list = jsonResponse;
      }

      final entries = list
          .whereType<Map>()
          .map((item) {
            final inner =
                item['show'] as Map? ??
                item['movie'] as Map? ??
                item['anime'] as Map? ??
                item[simklType] as Map?;
            if (inner == null) return null;

            final id = inner['ids']?['simkl']?.toString();
            if (id == null) return null;

            final poster = inner['poster']?.toString();
            final coverUrl = poster != null
                ? 'https://simkl.in/posters/${poster}_m.webp'
                : '';

            final lastWatchedStr =
                item['last_watched_at']?.toString() ??
                item['updated_at']?.toString();
            final updatedAt = lastWatchedStr != null
                ? DateTime.tryParse(lastWatchedStr) ?? DateTime.now()
                : DateTime.now();

            final rating = (item['user_rating'] as num?)?.toDouble();
            final watchedEp =
                (item['watched_episodes_count'] as num?)?.toInt() ?? 0;

            return LibraryEntry()
              ..providerId = id
              ..type = mediaType.id
              ..title = inner['title'] ?? 'Unknown'
              ..cover = coverUrl
              ..banner = coverUrl
              ..status = status.id
              ..score = rating != null && rating > 0 ? rating : null
              ..episodesWatched = watchedEp
              ..episodes = inner['total_episodes']
              ..updatedAt = updatedAt
              ..sourceType = 'tracker'
              ..sourceId = 'simkl';
          })
          .whereType<LibraryEntry>()
          .toList();

      entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return entries;
    });
  }

  @override
  Future<void> removeEntry({
    required String trackingId,
    required MediaType mediaType,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Simkl is not authenticated');

    return executeApi('DELETE', () async {
      final simklType = mediaType == MediaType.ANIME
          ? 'anime'
          : (mediaType == MediaType.MOVIE ? 'movies' : 'shows');
      final id = int.tryParse(trackingId);
      if (id == null) return;

      final headers = {
        'Authorization': 'Bearer $token',
        'simkl-api-key': clientId,
        'Content-Type': 'application/json',
      };

      await _http.post(
        'https://api.simkl.com/sync/history/remove',
        body: {
          simklType: [
            {
              'ids': {'simkl': id},
            },
          ],
        },
        headers: headers,
      );

      _invalidateCache();
    });
  }

  TrackedStatus _parseSimklStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'watching':
        return TrackedStatus.watching;
      case 'plantowatch':
      case 'plan_to_watch':
      case 'plan to watch':
        return TrackedStatus.planning;
      case 'completed':
        return TrackedStatus.completed;
      case 'hold':
      case 'on_hold':
      case 'on hold':
        return TrackedStatus.paused;
      case 'dropped':
        return TrackedStatus.dropped;
      default:
        return TrackedStatus.unknown;
    }
  }

  String _toSimklStatus(TrackedStatus status) {
    switch (status) {
      case TrackedStatus.watching:
        return 'watching';
      case TrackedStatus.planning:
        return 'plantowatch';
      case TrackedStatus.completed:
        return 'completed';
      case TrackedStatus.paused:
        return 'hold';
      case TrackedStatus.dropped:
        return 'dropped';
      case TrackedStatus.unknown:
        return 'watching';
    }
  }
}
