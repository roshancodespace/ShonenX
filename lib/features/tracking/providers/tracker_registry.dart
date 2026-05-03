import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/database/database_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/trackers/local/local_tracker.dart';
import 'package:shonenx/features/tracking/engine/trackers/mal/mal_tracker.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/features/tracking/engine/trackers/anilist/anilist_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';

final availableTrackersProvider = Provider<List<TrackingService>>(
  (ref) => [
    AnilistTracker(ref),
    MalTracker(ref),
    LocalTracker(ref.watch(databaseProvider)),
  ],
);

final primaryTrackerProvider = Provider<TrackingService>((ref) {
  return ref
      .watch(trackingPrefsProvider.select((s) => s.primaryTracker))
      .getTracker(ref);
});
