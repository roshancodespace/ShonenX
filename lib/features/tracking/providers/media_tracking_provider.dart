import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

/// Resolves the effective tracking ID for a given tracker type and media.
///
/// Resolution priority:
/// 1. Local tracker -> uses media ID directly.
/// 2. Explicit user link from local database (`links[trackerType]`).
/// 3. Multi-platform external identifier on the media (`media.externalIds.get(trackerType)`).
/// 4. Direct MAL ID property (`media.idMal`) if querying MyAnimeList.
/// 5. Direct media ID (`media.id`) if media metadata originates from this tracker without an extension source.
String? resolveTrackingIdFromMedia({
  required TrackerType trackerType,
  required UnifiedMedia media,
  Map<TrackerType, TrackerMapping>? links,
}) {
  if (trackerType == TrackerType.local) {
    return media.id;
  }

  // 1. Explicit user link from local database
  final userLinkedId = links?[trackerType]?.trackingId;
  if (userLinkedId != null && userLinkedId.isNotEmpty) {
    return userLinkedId;
  }

  // 2. Known external ID from media metadata
  final externalId = media.externalIds.get(trackerType.id);
  if (externalId != null && externalId.isNotEmpty) {
    return externalId;
  }

  // 3. Direct MAL ID legacy field
  if (trackerType == TrackerType.myanimelist &&
      media.idMal != null &&
      media.idMal!.isNotEmpty) {
    return media.idMal;
  }

  // 4. Tracker metadata origin (when not from an extension source)
  final isSourceDiscovery =
      media.sourceId != null &&
      media.sourceId != 'anilist' &&
      media.sourceId != 'mal' &&
      media.sourceId != 'myanimelist' &&
      media.sourceId != 'simkl' &&
      media.sourceId != 'kitsu';

  if (!isSourceDiscovery) {
    final provider = media.providerId?.toLowerCase();
    if (provider == trackerType.id ||
        (trackerType == TrackerType.myanimelist &&
            (provider == 'mal' || provider == 'myanimelist')) ||
        (provider == null && trackerType == TrackerType.anilist)) {
      return media.id;
    }
  }

  return null;
}

class TrackingQuery {
  final TrackerType trackerType;
  final UnifiedMedia media;

  const TrackingQuery(this.trackerType, this.media);

  String get mediaId => media.id;
  MediaType get mediaType => media.type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackingQuery &&
          other.trackerType == trackerType &&
          other.media.id == media.id;

  @override
  int get hashCode => trackerType.hashCode ^ media.id.hashCode;
}

final mediaTrackingProvider =
    FutureProvider.family<TrackedListItem?, TrackingQuery>(
      retry: (retryCount, error) => null,
      (ref, query) async {
        final tracker = ref
            .read(availableTrackersProvider)
            .firstWhere((t) => t.type.id == query.trackerType.id);

        if (!(await tracker.isAuthenticated)) return null;

        String? trackingId;
        if (query.trackerType == TrackerType.local) {
          trackingId = query.media.id;
        } else {
          final links = await ref.watch(
            trackerLinkProvider(query.media.id).future,
          );
          trackingId =
              links[query.trackerType]?.trackingId ??
              resolveTrackingIdFromMedia(
                trackerType: query.trackerType,
                media: query.media,
                links: links,
              );
        }

        if (trackingId == null) return null;
        return tracker.fetchUserListItem(
          mediaId: trackingId,
          mediaType: query.media.type,
        );
      },
    );
