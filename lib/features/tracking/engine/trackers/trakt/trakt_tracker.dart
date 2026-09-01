import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
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

import 'trakt_authenticator.dart';
import 'trakt_metadata.dart';

class TraktTracker extends BaseTracker with TraktMetadata implements RemoteTracker {
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
  Authenticator get authenticator =>
      TraktAuthenticator(customCredentials: customCredentials);

  Future<String?> getToken() async {
    final tokens = await ref.read(authTokensProvider.future);
    return tokens[TrackerType.trakt];
  }

  @override
  Future<bool> get isAuthenticated async => (await getToken()) != null;

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
            title: m.title.availableTitle,
            cover: m.posterImage,
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
    final token = await getToken();
    if (token == null) throw Exception('Trakt is not authenticated');

    return executeApi('UPDATE_ENTRY', () async {
      final headers = {
        'Content-Type': 'application/json',
        'trakt-api-version': '2',
        'trakt-api-key': clientId,
        'Authorization': 'Bearer $token',
      };

      if (progress != null && progress > 0) {
        final body = jsonEncode({
          'shows': [
            {
              'ids': {'trakt': int.tryParse(trackingId) ?? trackingId},
              'seasons': [
                {
                  'number': 1,
                  'episodes': [
                    {'number': progress.toInt()}
                  ]
                }
              ]
            }
          ]
        });

        await _http.post(
          'https://api.trakt.tv/sync/history',
          headers: headers,
          body: body,
        );
      }
    });
  }

  @override
  Future<TrackedListItem?> fetchUserListItem({
    required String mediaId,
    required MediaType mediaType,
  }) async {
    final token = await getToken();
    if (token == null) return null;

    return executeApi('FETCH_ENTRY', fallback: (_, __) => null, () async {
      final headers = {
        'Content-Type': 'application/json',
        'trakt-api-version': '2',
        'trakt-api-key': clientId,
        'Authorization': 'Bearer $token',
      };

      final response = await _http.get(
        'https://api.trakt.tv/sync/history/shows?extended=full',
        headers: headers,
      );

      if (response.statusCode != 200) return null;
      final List<dynamic> list = jsonDecode(response.body);

      for (final item in list) {
        if (item is! Map) continue;
        final show = item['show'] as Map<String, dynamic>?;
        if (show == null) continue;

        final ids = show['ids'] as Map<String, dynamic>? ?? {};
        final traktId = ids['trakt']?.toString();

        if (traktId == mediaId) {
          final watchedCount = (item['watched_episodes_count'] as num?)?.toDouble() ?? 1.0;
          return TrackedListItem(
            trackingId: traktId ?? mediaId,
            status: TrackedStatus.watching,
            progress: watchedCount.toInt(),
            totalEpisodes: show['aired_episodes'] as int?,
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
    final token = await getToken();
    if (token == null) return [];

    return executeApi('FETCH_LIBRARY', () async {
      final headers = {
        'Content-Type': 'application/json',
        'trakt-api-version': '2',
        'trakt-api-key': clientId,
        'Authorization': 'Bearer $token',
      };

      final response = await _http.get(
        'https://api.trakt.tv/sync/history/shows?extended=full',
        headers: headers,
      );

      if (response.statusCode != 200) return [];
      final List<dynamic> list = jsonDecode(response.body);
      final List<LibraryEntry> entries = [];

      for (final item in list) {
        if (item is! Map) continue;
        final show = item['show'] as Map<String, dynamic>?;
        if (show == null) continue;

        final ids = show['ids'] as Map<String, dynamic>? ?? {};
        final traktId = ids['trakt']?.toString();
        if (traktId == null) continue;

        final title = show['title'] as String? ?? 'Unknown';
        final watchedEp = (item['watched_episodes_count'] as num?)?.toInt() ?? 1;

        entries.add(
          LibraryEntry()
            ..providerId = traktId
            ..type = mediaType.id
            ..title = title
            ..status = status.id
            ..episodesWatched = watchedEp
            ..episodes = show['aired_episodes'] as int?
            ..updatedAt = DateTime.now()
            ..sourceType = 'tracker'
            ..sourceId = 'trakt',
        );
      }

      return entries;
    });
  }

  @override
  Future<void> removeEntry({
    required String trackingId,
    required MediaType mediaType,
  }) async {
    // Optional remove from Trakt history
  }
}
