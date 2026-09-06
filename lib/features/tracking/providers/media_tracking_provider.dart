import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/database_provider.dart';

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
          trackingId = links[query.trackerType]?.trackingId;
        }

        if (trackingId == null || trackingId.isEmpty) return null;
        return tracker.fetchUserListItem(
          mediaId: trackingId,
          mediaType: query.media.type,
        );
      },
    );

/// Auto-links active remote trackers to [media] if [TrackingPrefsState.autoTrackPrimary]
/// is enabled and matching external IDs can be resolved.
Future<void> autoLinkTrackers({
  required WidgetRef ref,
  required UnifiedMedia media,
  bool Function()? isMounted,
}) async {
  final prefs = ref.read(trackingPrefsProvider);
  if (!prefs.autoTrackPrimary) return;

  final allTrackers = ref.read(availableTrackersProvider);
  final linksNotifier = ref.read(trackerLinkProvider(media.id).notifier);
  final currentLinks = await ref.read(trackerLinkProvider(media.id).future);

  if (isMounted != null && !isMounted()) return;

  final toSave = <TrackerType, TrackerMapping>{};

  for (final tracker in allTrackers) {
    if (tracker.type == TrackerType.local) continue;
    if (!prefs.isTrackerEnabled(tracker.type)) continue;
    if (!(await tracker.isAuthenticated)) continue;
    if (isMounted != null && !isMounted()) return;
    if (currentLinks.containsKey(tracker.type)) continue;

    final trackingId = resolveTrackingIdFromMedia(
      trackerType: tracker.type,
      media: media,
      links: currentLinks,
    );

    if (trackingId != null && trackingId.isNotEmpty) {
      toSave[tracker.type] = TrackerMapping()
        ..trackerId = tracker.type.id
        ..trackingId = trackingId
        ..trackingTitle = media.title.availableTitle;
    }
  }

  if (isMounted != null && !isMounted()) return;

  if (toSave.isNotEmpty) {
    linksNotifier.saveLinks(toSave);
  }
}

/// Cleans up auto-linked tracker mappings on screen dispose if the media was
/// neither watched/read nor added to any tracker or library entry.
void cleanupUnusedTrackerLinks({
  required ProviderContainer container,
  required UnifiedMedia media,
}) {
  Future(() {
    final isar = container.read(databaseProvider);

    // 1: Retain if user has watch or read history
    final hasWatchHistory = isar.watchHistoryEntrys
        .filter()
        .animeIdEqualTo(media.id)
        .isNotEmptySync();
    if (hasWatchHistory) return;

    final hasReadHistory = isar.readHistoryEntrys
        .filter()
        .mangaIdEqualTo(media.id)
        .isNotEmptySync();
    if (hasReadHistory) return;

    // 2: Retain if saved to local library
    final inLocalLibrary = isar.libraryEntrys
        .filter()
        .providerIdEqualTo(media.id)
        .isNotEmptySync();
    if (inLocalLibrary) return;

    // 3: Retain if media has active downloads
    final hasDownloads = isar.downloadTasks
        .filter()
        .mediaIdEqualTo(media.id)
        .isNotEmptySync();
    if (hasDownloads) return;

    // 4: Retain if any tracker has an active user list entry
    final trackers = container.read(availableTrackersProvider);
    for (final tracker in trackers) {
      final query = TrackingQuery(tracker.type, media);
      if (container.exists(mediaTrackingProvider(query))) {
        final trackingState = container.read(mediaTrackingProvider(query));
        if (trackingState.value != null) return;
      }
    }

    // 5: Unused and unadded -> delete auto-linked mapping
    container.read(trackerLinkProvider(media.id).notifier).deleteLinks();
  });
}
