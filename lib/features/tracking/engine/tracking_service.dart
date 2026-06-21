import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

abstract class TrackingService {
  TrackerType get type;

  Future<bool> get isAuthenticated;

  bool supportsMediaType(MediaType mediaType);

  Future<void> updateListItem({
    required String trackingId,
    required UnifiedMedia media,
    TrackedStatus? status,
    double? progress,
    double? score,
  });

  Future<List<LibraryEntry>> fetchUserLibrary({
    TrackedStatus status = TrackedStatus.watching,
    MediaType mediaType = MediaType.ANIME,
    int page = 1,
  });

  Future<TrackedListItem?> fetchUserListItem({
    required String mediaId,
    required MediaType mediaType,
  });

  Future<void> removeEntry({
    required String trackingId,
    required MediaType mediaType,
  });
}

extension TrackingServiceX on TrackingService {
  void toggleTracker(Ref ref, bool isEnabled) =>
      ref.read(trackingPrefsProvider.notifier).toggleTracker(type, isEnabled);
}
