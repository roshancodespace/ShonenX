import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';

abstract class TrackingService {
  TrackerType get type;

  Future<bool> get isAuthenticated;

  Future<void> updateListItem({
    required String trackingId,
    TrackedStatus? status,
    double? progress,
    double? score,
  });

  Future<List<LibraryEntry>> fetchUserLibrary({
    TrackedStatus status = TrackedStatus.watching,
    int page = 1,
  });

  Future<TrackedListItem?> fetchUserListItem({required String mediaId});

  Future<void> removeEntry({required String trackingId});
}

extension TrackingServiceX on TrackingService {
  void toggleTracker(Ref ref, bool isEnabled) =>
      ref.read(trackingPrefsProvider.notifier).toggleTracker(type, isEnabled);
}
