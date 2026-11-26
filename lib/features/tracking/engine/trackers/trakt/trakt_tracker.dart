import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_credentials.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_profile.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/base_tracker.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_auth_provider.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/tracker_search_result.dart';

import 'trakt_authenticator.dart';
import 'trakt_metadata.dart';

class TraktTracker extends BaseTracker
    with TraktMetadata
    implements RemoteTracker {
  final Ref ref;
  final HTTP _http;

  @override
  HTTP get http => _http;

  TraktTracker(this.ref) : _http = ref.read(httpClientProvider);

  @override
  TrackerType get type => TrackerType.trakt;

  @override
  TrackerCredentials? get customCredentials =>
      ref.read(trackingPrefsProvider).customCredentials[TrackerType.trakt];

  @override
  Authenticator get authenticator => TraktAuthenticator(
    customCredentials: customCredentials,
    authMode: ref.read(trackingPrefsProvider).authMode,
  );

  Future<String?> _getToken() async {
    final tokens = await ref.read(authTokensProvider.future);
    return tokens[TrackerType.trakt];
  }

  Map<String, String> _authHeaders(String token) => {
    ...traktHeaders,
    'Authorization': 'Bearer $token',
  };

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

  final Map<String, DateTime> _cacheTimes = {};
  final Map<String, List<dynamic>> _cachedLists = {};

  void _invalidateCache() {
    _cacheTimes.clear();
    _cachedLists.clear();
  }

  Future<List<dynamic>> _getCachedSyncList(
    String cacheKey,
    String url,
    String token,
  ) async {
    final lastTime = _cacheTimes[cacheKey];
    if (lastTime != null &&
        DateTime.now().difference(lastTime) < const Duration(minutes: 5)) {
      return _cachedLists[cacheKey] ?? const [];
    }

    final res = await _http.get(url, headers: _authHeaders(token));
    final list = res.json as List? ?? const [];
    _cachedLists[cacheKey] = list;
    _cacheTimes[cacheKey] = DateTime.now();
    return list;
  }

  String _syncBucket(MediaType type) =>
      type == MediaType.MOVIE ? 'movies' : 'shows';

  int _countWatchedEpisodes(Map<dynamic, dynamic> watchedItem) {
    final seasons = watchedItem['seasons'] as List?;
    if (seasons == null) return 0;
    var count = 0;
    for (final season in seasons.whereType<Map>()) {
      final eps = season['episodes'] as List?;
      if (eps != null) count += eps.length;
    }
    return count;
  }

  @override
  Future<TrackerProfile> fetchProfile() async {
    final token = await _getToken();
    if (token == null) throw Exception('Trakt is not authenticated');

    return executeApi('PROFILE', () async {
      final res = await _http.get(
        'https://api.trakt.tv/users/settings',
        headers: _authHeaders(token),
      );

      final data = res.json as Map? ?? {};
      final user = data['user'] as Map? ?? {};
      final ids = user['ids'] as Map? ?? {};
      final avatar = user['images']?['avatar']?['full']?.toString();

      return TrackerProfile(
        id: ids['slug']?.toString() ?? ids['uuid']?.toString() ?? '',
        username: user['username']?.toString() ?? 'User',
        avatarUrl: avatar,
        lastSyncedAt: DateTime.now(),
      );
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
    if (token == null) throw Exception('Trakt is not authenticated');

    return executeApi('UPDATE_ENTRY', () async {
      final id = int.tryParse(trackingId);
      if (id == null) throw Exception('Invalid tracking ID: $trackingId');

      final bucket = _syncBucket(media.type);
      final headers = _authHeaders(token);

      if (status != null) {
        if (status == TrackedStatus.planning) {
          await _http.post(
            'https://api.trakt.tv/sync/watchlist',
            body: {
              bucket: [
                {
                  'ids': {'trakt': id},
                },
              ],
            },
            headers: headers,
          );
        } else {
          await _http.post(
            'https://api.trakt.tv/sync/watchlist/remove',
            body: {
              bucket: [
                {
                  'ids': {'trakt': id},
                },
              ],
            },
            headers: headers,
          );
        }
      }

      if (score != null && score > 0) {
        await _http.post(
          'https://api.trakt.tv/sync/ratings',
          body: {
            bucket: [
              {
                'rating': score.round().clamp(1, 10),
                'ids': {'trakt': id},
              },
            ],
          },
          headers: headers,
        );
      }

      if (progress != null && progress > 0) {
        if (media.type == MediaType.MOVIE) {
          await _http.post(
            'https://api.trakt.tv/sync/history',
            body: {
              'movies': [
                {
                  'ids': {'trakt': id},
                },
              ],
            },
            headers: headers,
          );
        } else {
          final epCount = progress.toInt();
          final res = await _http.get(
            'https://api.trakt.tv/shows/$id/seasons',
            queryParameters: const {'extended': 'episodes'},
            headers: headers,
          );
          final seasons = (res.json as List? ?? []).whereType<Map>().toList();
          final episodesToMark = <Map<String, dynamic>>[];

          for (final season in seasons) {
            final seasonNum = (season['number'] as num?)?.toInt() ?? 0;
            if (seasonNum == 0) continue; // Skip specials
            final eps = (season['episodes'] as List? ?? []).whereType<Map>();
            for (final ep in eps) {
              if (episodesToMark.length >= epCount) break;
              final epId = ep['ids']?['trakt'];
              if (epId != null) {
                episodesToMark.add({
                  'ids': {'trakt': epId},
                });
              }
            }
            if (episodesToMark.length >= epCount) break;
          }

          if (episodesToMark.isNotEmpty) {
            await _http.post(
              'https://api.trakt.tv/sync/history',
              body: {'episodes': episodesToMark},
              headers: headers,
            );
          }
        }
      }

      _invalidateCache();
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
      final bucket = _syncBucket(mediaType);
      final watched = await _getCachedSyncList(
        'watched_$bucket',
        'https://api.trakt.tv/sync/watched/$bucket',
        token,
      );
      final watchlist = await _getCachedSyncList(
        'watchlist_$bucket',
        'https://api.trakt.tv/sync/watchlist/$bucket',
        token,
      );
      final ratings = await _getCachedSyncList(
        'ratings_$bucket',
        'https://api.trakt.tv/sync/ratings/$bucket',
        token,
      );

      double? userScore;
      for (final item in ratings.whereType<Map>()) {
        final inner = item['show'] as Map? ?? item['movie'] as Map?;
        final id = inner?['ids']?['trakt']?.toString();
        if (id == mediaId) {
          userScore = (item['rating'] as num?)?.toDouble();
          break;
        }
      }

      for (final item in watched.whereType<Map>()) {
        final inner = item['show'] as Map? ?? item['movie'] as Map?;
        final id = inner?['ids']?['trakt']?.toString();
        if (id == mediaId) {
          final count = mediaType == MediaType.MOVIE
              ? 1.0
              : _countWatchedEpisodes(item).toDouble();
          final total = (inner?['aired_episodes'] as num?)?.toInt();
          final isDone =
              mediaType == MediaType.MOVIE ||
              (total != null && total > 0 && count >= total);
          return TrackedListItem(
            id: id,
            status: isDone ? TrackedStatus.completed : TrackedStatus.watching,
            progress: count,
            score: userScore,
          );
        }
      }

      for (final item in watchlist.whereType<Map>()) {
        final inner = item['show'] as Map? ?? item['movie'] as Map?;
        final id = inner?['ids']?['trakt']?.toString();
        if (id == mediaId) {
          return TrackedListItem(
            id: id,
            status: TrackedStatus.planning,
            progress: 0,
            score: userScore,
          );
        }
      }

      if (userScore != null) {
        return TrackedListItem(
          id: mediaId,
          status: TrackedStatus.unknown,
          progress: 0,
          score: userScore,
        );
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
      final bucket = _syncBucket(mediaType);
      final headers = _authHeaders(token);

      if (status == TrackedStatus.planning) {
        final res = await _http.get(
          'https://api.trakt.tv/sync/watchlist/$bucket',
          queryParameters: const {'extended': 'full'},
          headers: headers,
        );
        final list = res.json as List? ?? [];
        return _mapLibraryEntries(
          list,
          status: status,
          mediaType: mediaType,
          isWatchlist: true,
        );
      }

      if (status == TrackedStatus.watching ||
          status == TrackedStatus.completed) {
        final res = await _http.get(
          'https://api.trakt.tv/sync/watched/$bucket',
          queryParameters: const {'extended': 'full'},
          headers: headers,
        );
        final list = res.json as List? ?? [];
        return _mapLibraryEntries(
          list,
          status: status,
          mediaType: mediaType,
          isWatchlist: false,
        );
      }

      return [];
    });
  }

  List<LibraryEntry> _mapLibraryEntries(
    List<dynamic> list, {
    required TrackedStatus status,
    required MediaType mediaType,
    required bool isWatchlist,
  }) {
    final entries = <LibraryEntry>[];
    final seenIds = <String>{};

    for (final item in list.whereType<Map>()) {
      final inner = item['show'] as Map? ?? item['movie'] as Map?;
      if (inner == null) continue;

      final id = inner['ids']?['trakt']?.toString();
      if (id == null || id.isEmpty || !seenIds.add(id)) continue;

      final totalEps = (inner['aired_episodes'] as num?)?.toInt();
      final watchedEp = isWatchlist
          ? 0
          : (mediaType == MediaType.MOVIE ? 1 : _countWatchedEpisodes(item));

      if (!isWatchlist) {
        final isCompleted =
            mediaType == MediaType.MOVIE ||
            (totalEps != null && totalEps > 0 && watchedEp >= totalEps);
        if (status == TrackedStatus.completed && !isCompleted) continue;
        if (status == TrackedStatus.watching && isCompleted) continue;
      }

      final images = inner['images'] as Map?;
      final poster = TraktMetadata.normalizeTraktImageUrl(
        (images?['poster'] as List?)?.firstOrNull?.toString(),
      );
      final banner = TraktMetadata.normalizeTraktImageUrl(
        (images?['fanart'] as List?)?.firstOrNull?.toString(),
      );

      final updatedStr =
          item['last_watched_at']?.toString() ??
          item['listed_at']?.toString() ??
          item['last_updated_at']?.toString();
      final updatedAt = updatedStr != null
          ? DateTime.tryParse(updatedStr) ?? DateTime.now()
          : DateTime.now();

      entries.add(
        LibraryEntry()
          ..providerId = id
          ..type = mediaType.id
          ..title = inner['title']?.toString() ?? 'Unknown'
          ..cover = poster ?? ''
          ..banner = banner ?? poster ?? ''
          ..status = status.id
          ..episodesWatched = watchedEp
          ..episodes = totalEps
          ..updatedAt = updatedAt
          ..sourceType = 'tracker'
          ..sourceId = TrackerType.trakt.id,
      );
    }

    entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entries;
  }

  @override
  Future<void> removeEntry({
    required String trackingId,
    required MediaType mediaType,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Trakt is not authenticated');

    return executeApi('DELETE', () async {
      final id = int.tryParse(trackingId);
      if (id == null) return;

      final bucket = _syncBucket(mediaType);
      final headers = _authHeaders(token);
      final payload = {
        bucket: [
          {
            'ids': {'trakt': id},
          },
        ],
      };

      await _http.post(
        'https://api.trakt.tv/sync/history/remove',
        body: payload,
        headers: headers,
      );
      await _http.post(
        'https://api.trakt.tv/sync/watchlist/remove',
        body: payload,
        headers: headers,
      );

      _invalidateCache();
    });
  }
}

