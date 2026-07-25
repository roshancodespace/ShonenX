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
          (m) => TrackerSearchResult(
            id: m.id,
            title: m.title.english ?? m.title.romaji ?? 'Unknown',
            cover: m.cover,
          ),
        )
        .toList();
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
      final simklType = media.type == MediaType.ANIME ? 'anime' : 'shows';
      final id = int.parse(trackingId);
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
              {'id': id, 'to': _toSimklStatus(status)},
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
              {'id': id, 'rating': score.toInt()},
            ],
          },
          headers: headers,
        );
      }

      if (progress != null) {
        // Simkl typically expects episode objects or bulk history additions.
        // This is a best-effort fallback based on standard Simkl history endpoints.
        await _http.post(
          'https://api.simkl.com/sync/history',
          body: {
            simklType: [
              {'id': id, 'watched_episodes': progress.toInt()},
            ],
          },
          headers: headers,
        );
      }
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
    // Note: Simkl doesn't have a direct endpoint for a single list item status efficiently without full list sync.
    // We would generally return null here unless we cache the full library locally.
    return null;
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

      final list = res.json as List? ?? [];

      return list
          .whereType<Map>()
          .map((item) {
            final inner = item[simklType] as Map?;
            if (inner == null) return null;

            final id = inner['ids']?['simkl']?.toString();
            if (id == null) return null;

            final poster = inner['poster']?.toString();
            final coverUrl = poster != null
                ? 'https://simkl.in/posters/$poster\_m.webp'
                : '';

            return LibraryEntry()
              ..providerId = id
              ..type = mediaType.id
              ..title = inner['title'] ?? 'Unknown'
              ..cover = coverUrl
              ..status = status.id
              ..episodes = inner['total_episodes'];
          })
          .whereType<LibraryEntry>()
          .toList();
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
      // Simkl removes item from list if status is 'not_interesting' or dropped sometimes.
      // But they also have specific drop endpoints.
    });
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
