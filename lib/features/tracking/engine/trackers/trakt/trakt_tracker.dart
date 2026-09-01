import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
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

class TraktTracker extends BaseTracker implements RemoteTracker {
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

  Future<String?> _getToken() async {
    final tokens = await ref.read(authTokensProvider.future);
    return tokens[TrackerType.trakt];
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
  Future<TrackerProfile?> getUserProfile() async {
    final token = await _getToken();
    if (token == null) return null;
    return await TraktMetadata.fetchUserProfile(
      token,
      clientId: customCredentials?.clientId,
    );
  }

  @override
  Future<List<TrackerSearchResult>> searchMedia(
    String query, {
    required MediaType type,
    bool withCache = true,
  }) async {
    final token = await _getToken();
    final items = await TraktMetadata.searchAnime(
      query,
      token: token,
      clientId: customCredentials?.clientId,
    );
    return items
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
  Future<UnifiedMedia?> getMediaDetails(
    String id, {
    required MediaType type,
  }) async {
    final token = await _getToken();
    return await TraktMetadata.getMediaDetails(
      id,
      token: token,
      clientId: customCredentials?.clientId,
    );
  }

  @override
  Future<List<TrackedListItem>> getUserList(
    TrackerCategory category, {
    required MediaType mediaType,
  }) async {
    final token = await _getToken();
    if (token == null) return [];
    return await TraktMetadata.fetchUserList(
      token,
      category,
      clientId: customCredentials?.clientId,
    );
  }

  @override
  Future<void> updateEntry(
    LibraryEntry entry, {
    int? progress,
    TrackedStatus? status,
    double? rating,
  }) async {
    final token = await _getToken();
    if (token == null) return;

    if (progress != null) {
      await TraktMetadata.updateProgress(
        token,
        traktId: entry.id,
        episodeNumber: progress,
        clientId: customCredentials?.clientId,
      );
    }
  }
}
