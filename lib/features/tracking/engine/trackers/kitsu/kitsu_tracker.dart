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
import 'package:shonenx/features/tracking/engine/trackers/kitsu/kitsu_authenticator.dart';
import 'package:shonenx/features/tracking/engine/trackers/kitsu/kitsu_metadata.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/tracker_search_result.dart';

class KitsuTracker extends BaseTracker with KitsuMetadata implements RemoteTracker {
  final Ref ref;
  final HTTP _http;

  @override
  HTTP get http => _http;

  KitsuTracker(this.ref) : _http = ref.read(httpClientProvider);

  Future<String?> _getToken() async {
    final tokens = await ref.read(authTokensProvider.future);
    return tokens[TrackerType.kitsu];
  }

  @override
  Future<bool> get isAuthenticated async => (await _getToken()) != null;

  @override
  bool supportsMediaType(MediaType mediaType) => true;

  @override
  TrackerType get type => TrackerType.kitsu;

  @override
  Authenticator get authenticator => KitsuAuthenticator();

  Future<String> _getUserId(String token) async {
    final cachedProfile = ref.read(trackerProfileProvider)[TrackerType.kitsu];
    if (cachedProfile != null && cachedProfile.id.isNotEmpty) {
      return cachedProfile.id;
    }
    final profile = await fetchProfile();
    ref.read(trackerProfileProvider.notifier).saveProfile(TrackerType.kitsu, profile);
    return profile.id;
  }

  @override
  Future<List<TrackerSearchResult>> searchMedia(
    String query, {
    required MediaType type,
  }) {
    return executeApi('SEARCH', fallback: (_, __) => [], () async {
      final endpoint = type == MediaType.ANIME ? 'anime' : 'manga';

      final response = await _http.get(
        'https://kitsu.io/api/edge/$endpoint',
        queryParameters: {
          'filter[text]': query,
          'page[limit]': '20',
          'fields[$endpoint]': 'titles,canonicalTitle,posterImage,episodeCount,chapterCount',
        },
      );

      final body = response.json;
      if (body['errors'] != null) {
        throw Exception(body['errors']?.toString() ?? 'Search failed');
      }

      final data = body['data'] as List? ?? [];

      return data.map((item) {
        final attr = item['attributes'] as Map? ?? {};
        final titles = attr['titles'] as Map? ?? {};
        final title = attr['canonicalTitle']?.toString() ??
            titles['en_jp']?.toString() ??
            titles['en']?.toString() ??
            titles['ja_jp']?.toString() ??
            'Unknown Title';
        final posterImage = attr['posterImage'] as Map? ?? {};
        final cover = posterImage['large']?.toString() ??
            posterImage['medium']?.toString() ??
            posterImage['original']?.toString() ??
            '';

        return TrackerSearchResult(
          id: item['id']?.toString() ?? '',
          title: title,
          cover: cover,
        );
      }).toList();
    });
  }

  @override
  Future<TrackerProfile> fetchProfile() async {
    final token = await _getToken();
    if (token == null) throw Exception('Kitsu is not authenticated');

    return executeApi('PROFILE', () async {
      final res = await _http.get(
        'https://kitsu.io/api/edge/users?filter[self]=true',
        headers: {'Authorization': 'Bearer $token'},
      );

      final body = res.json;
      if (body['errors'] != null || (body['data'] as List? ?? []).isEmpty) {
        throw Exception('Failed to fetch Kitsu profile');
      }

      final user = (body['data'] as List)[0] as Map;
      final attr = user['attributes'] as Map? ?? {};
      final username = attr['name']?.toString() ?? 'Unknown';
      final avatar = attr['avatar'] as Map? ?? {};
      final avatarUrl = avatar['original']?.toString() ?? avatar['large']?.toString();

      return TrackerProfile(
        id: user['id']?.toString() ?? '',
        username: username,
        avatarUrl: avatarUrl,
        profileUrl: 'https://kitsu.io/users/$username',
        lastSyncedAt: DateTime.now(),
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

    return executeApi(
      status.name.toUpperCase(),
      fallback: (_, __) => [],
      () async {
        final userId = await _getUserId(token);
        final limit = 50;
        final offset = (page - 1) * limit;
        final kind = mediaType == MediaType.ANIME ? 'anime' : 'manga';

        final res = await _http.get(
          'https://kitsu.io/api/edge/library-entries',
          queryParameters: {
            'filter[userId]': userId,
            'filter[kind]': kind,
            'filter[status]': _toKitsuStatus(status),
            'page[limit]': limit.toString(),
            'page[offset]': offset.toString(),
            'include': kind,
          },
          headers: {'Authorization': 'Bearer $token'},
        );

        final body = res.json;
        if (body['errors'] != null) return [];

        final data = body['data'] as List? ?? [];
        final included = body['included'] as List? ?? [];
        final mediaMap = <String, Map>{};
        for (final inc in included.whereType<Map>()) {
          final id = inc['id']?.toString();
          if (id != null) mediaMap[id] = inc;
        }

        return data.map((item) {
          final attr = item['attributes'] as Map? ?? {};
          final rels = item['relationships'] as Map? ?? {};
          final mediaRel = rels[kind]?['data'] as Map? ?? {};
          final mediaId = mediaRel['id']?.toString() ?? '';
          final mediaObj = mediaMap[mediaId];
          final mediaAttr = mediaObj?['attributes'] as Map? ?? {};
          final titles = mediaAttr['titles'] as Map? ?? {};
          final title = mediaAttr['canonicalTitle']?.toString() ??
              titles['en_jp']?.toString() ??
              titles['en']?.toString() ??
              titles['ja_jp']?.toString() ??
              'Unknown';
          final posterImage = mediaAttr['posterImage'] as Map? ?? {};
          final cover = posterImage['large']?.toString() ??
              posterImage['medium']?.toString() ??
              '';
          final totalCount = mediaAttr['episodeCount'] as int? ?? mediaAttr['chapterCount'] as int?;

          final r20 = (attr['ratingTwenty'] as num?)?.toDouble() ?? 0.0;
          final score = r20 > 0 ? r20 / 2.0 : 0.0;
          final progress = (attr['progress'] as num?)?.toInt() ?? 0;

          return LibraryEntry()
            ..providerId = mediaId
            ..type = mediaType.id
            ..title = title
            ..cover = cover
            ..status = _parseKitsuStatus(attr['status']?.toString()).id
            ..score = score
            ..episodesWatched = progress
            ..episodes = totalCount;
        }).toList();
      },
    );
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
      fallback: (e, st) => null,
      () async {
        final userId = await _getUserId(token);
        final kindIdParam = mediaType == MediaType.ANIME ? 'animeId' : 'mangaId';

        final res = await _http.get(
          'https://kitsu.io/api/edge/library-entries',
          queryParameters: {
            'filter[userId]': userId,
            'filter[$kindIdParam]': mediaId,
          },
          headers: {'Authorization': 'Bearer $token'},
        );

        final body = res.json;
        if (body['errors'] != null) return null;

        final data = body['data'] as List? ?? [];
        if (data.isEmpty) return null;

        final entry = data[0] as Map;
        final attr = entry['attributes'] as Map? ?? {};
        final r20 = (attr['ratingTwenty'] as num?)?.toDouble() ?? 0.0;
        final score = r20 > 0 ? r20 / 2.0 : null;
        final progress = (attr['progress'] as num?)?.toDouble() ?? 0.0;

        return TrackedListItem(
          id: entry['id']?.toString(),
          status: _parseKitsuStatus(attr['status']?.toString()),
          progress: progress,
          score: score,
        );
      },
    );
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
    if (token == null) throw Exception('Kitsu is not authenticated');

    return executeApi('UPDATE_ENTRY', () async {
      final userId = await _getUserId(token);
      final kind = media.type == MediaType.ANIME ? 'anime' : 'manga';
      final kindIdParam = media.type == MediaType.ANIME ? 'animeId' : 'mangaId';

      String? libraryEntryId;
      final checkRes = await _http.get(
        'https://kitsu.io/api/edge/library-entries',
        queryParameters: {
          'filter[userId]': userId,
          'filter[$kindIdParam]': trackingId,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      final checkBody = checkRes.json;
      final checkData = checkBody['data'] as List? ?? [];
      if (checkData.isNotEmpty) {
        libraryEntryId = checkData[0]['id']?.toString();
      }

      if (libraryEntryId != null) {
        final attr = <String, dynamic>{};
        if (status != null) attr['status'] = _toKitsuStatus(status);
        if (progress != null) attr['progress'] = progress.toInt();
        if (score != null && score > 0) attr['ratingTwenty'] = (score * 2.0).round();

        if (attr.isEmpty) return;

        final patchBody = {
          "data": {
            "type": "libraryEntries",
            "id": libraryEntryId,
            "attributes": attr,
          }
        };

        final response = await _http.patch(
          'https://kitsu.io/api/edge/library-entries/$libraryEntryId',
          body: patchBody,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/vnd.api+json',
            'Accept': 'application/vnd.api+json',
          },
        );

        if (response.statusCode >= 400) {
          throw Exception('Kitsu Error ${response.statusCode}: Failed to update entry');
        }
      } else {
        final attr = <String, dynamic>{
          'status': status != null ? _toKitsuStatus(status) : 'current',
          'progress': progress != null ? progress.toInt() : 0,
        };
        if (score != null && score > 0) {
          attr['ratingTwenty'] = (score * 2.0).round();
        }

        final postBody = {
          "data": {
            "type": "libraryEntries",
            "attributes": attr,
            "relationships": {
              "user": {
                "data": { "type": "users", "id": userId }
              },
              kind: {
                "data": { "type": kind, "id": trackingId }
              }
            }
          }
        };

        final response = await _http.post(
          'https://kitsu.io/api/edge/library-entries',
          body: postBody,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/vnd.api+json',
            'Accept': 'application/vnd.api+json',
          },
        );

        if (response.statusCode >= 400) {
          throw Exception('Kitsu Error ${response.statusCode}: Failed to create entry');
        }
      }
    });
  }

  @override
  Future<void> removeEntry({
    required String trackingId,
    required MediaType mediaType,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Kitsu is not authenticated');

    return executeApi('DELETE', () async {
      final userId = await _getUserId(token);
      final kindIdParam = mediaType == MediaType.ANIME ? 'animeId' : 'mangaId';

      final res = await _http.get(
        'https://kitsu.io/api/edge/library-entries',
        queryParameters: {
          'filter[userId]': userId,
          'filter[$kindIdParam]': trackingId,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      final body = res.json;
      final data = body['data'] as List? ?? [];
      if (data.isEmpty) return;

      final libraryEntryId = data[0]['id']?.toString();
      if (libraryEntryId == null) return;

      final response = await _http.delete(
        'https://kitsu.io/api/edge/library-entries/$libraryEntryId',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode >= 400) {
        throw Exception('Kitsu Error ${response.statusCode}: Failed to remove entry');
      }
    });
  }

  TrackedStatus _parseKitsuStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'current':
        return TrackedStatus.watching;
      case 'planned':
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

  String _toKitsuStatus(TrackedStatus status) {
    switch (status) {
      case TrackedStatus.watching:
        return 'current';
      case TrackedStatus.planning:
        return 'planned';
      case TrackedStatus.completed:
        return 'completed';
      case TrackedStatus.paused:
        return 'on_hold';
      case TrackedStatus.dropped:
        return 'dropped';
      case TrackedStatus.unknown:
        return 'current';
    }
  }
}
