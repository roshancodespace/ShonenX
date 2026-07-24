import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/contracts/tracking_service.dart';
import 'package:shonenx/features/tracking/engine/trackers/index.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/database_provider.dart';

/// Central registry for constructing and retrieving tracking service instances.
class TrackerRegistry {
  /// Instantiates a [TrackingService] for the given [TrackerType].
  static TrackingService createTracker(TrackerType type, Ref ref) {
    switch (type) {
      case TrackerType.anilist:
        return AnilistTracker(ref);
      case TrackerType.myanimelist:
        return MalTracker(ref);
      case TrackerType.kitsu:
        return KitsuTracker(ref);
      case TrackerType.local:
        return LocalTracker(ref.watch(databaseProvider));
    }
  }

  /// Returns all registered tracker instances for the application.
  static List<TrackingService> getAllTrackers(Ref ref) {
    return TrackerType.values.map((type) => createTracker(type, ref)).toList();
  }
}

final availableTrackersProvider = Provider<List<TrackingService>>(
  (ref) => TrackerRegistry.getAllTrackers(ref),
);

final primaryTrackerProvider = Provider<TrackingService>((ref) {
  final preferredType = ref.watch(
    trackingPrefsProvider.select((s) => s.primaryTracker),
  );

  if (preferredType == TrackerType.local) {
    return TrackerRegistry.createTracker(preferredType, ref);
  }

  final profiles = ref.watch(trackerProfileProvider);
  if (profiles.containsKey(preferredType)) {
    return TrackerRegistry.createTracker(preferredType, ref);
  }

  // Preferred is cloud but not logged in. Find next logged in cloud tracker.
  final loggedInCloudTypes = profiles.keys
      .where((t) => t != TrackerType.local)
      .toList();
  if (loggedInCloudTypes.isNotEmpty) {
    return TrackerRegistry.createTracker(loggedInCloudTypes.first, ref);
  }

  // Fallback to local
  return TrackerRegistry.createTracker(TrackerType.local, ref);
});

final activeTrackersProvider =
    Provider.family<List<TrackingService>, MediaType>((ref, mediaType) {
      final availableTrackers = ref.watch(availableTrackersProvider);
      return availableTrackers
          .where((t) => t.supportsMediaType(mediaType))
          .toList();
    });
