import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class TrackingQuery {
  final TrackerType trackerType;
  final String mediaId;
  final MediaType mediaType;

  const TrackingQuery(this.trackerType, this.mediaId, this.mediaType);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackingQuery &&
          other.trackerType == trackerType &&
          other.mediaId == mediaId &&
          other.mediaType == mediaType;

  @override
  int get hashCode => trackerType.hashCode ^ mediaId.hashCode ^ mediaType.hashCode;
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
          trackingId = query.mediaId;
        } else {
          trackingId = await ref.watch(
            trackerLinkProvider(
              query.mediaId,
            ).selectAsync((links) => links[query.trackerType]?.trackingId),
          );
        }

        if (trackingId == null) return null;
        return tracker.fetchUserListItem(mediaId: trackingId, mediaType: query.mediaType);
      },
    );
