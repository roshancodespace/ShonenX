import 'package:isar_community/isar.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class LocalTracker implements TrackingService {
  final Isar _isar;

  LocalTracker(this._isar);

  @override
  TrackerType get type => TrackerType.local;

  @override
  Future<bool> get isAuthenticated async => true; // Local tracker is always ready

  @override
  Future<void> updateListItem({
    required String trackingId,
    TrackedStatus? status,
    double? progress,
    double? score,
  }) async {
    await _isar.writeTxn(() async {
      LibraryEntry? entry = await _isar.libraryEntrys.getByProviderId(
        trackingId,
      );

      entry ??= LibraryEntry()
        ..providerId = trackingId
        ..addedAt = DateTime.now();

      if (progress != null) {
        entry.episodesWatched = progress.toInt();
      }

      if (status != null) {
        entry.status = status.id;
      }

      if (score != null) {
        entry.score = score;
      }

      await _isar.libraryEntrys.putByProviderId(entry);
    });
  }

  @override
  Future<List<LibraryEntry>> fetchUserLibrary({
    TrackedStatus status = TrackedStatus.watching,
    MediaType mediaType = MediaType.ANIME,
    int page = 1,
  }) async {
    return _isar.libraryEntrys
        .where()
        .filter()
        .statusEqualTo(status.id)
        .typeEqualTo(mediaType.id)
        .sortByAddedAtDesc()
        .offset((page - 1) * 50)
        .limit(50)
        .findAll();
  }

  @override
  Future<TrackedListItem?> fetchUserListItem({required String mediaId}) async {
    final entry = await _isar.libraryEntrys.getByProviderId(mediaId);
    if (entry == null) return null;

    return TrackedListItem(
      id: entry.providerId,
      status: TrackedStatus.values.firstWhere(
        (e) => e.id == entry.status,
        orElse: () => TrackedStatus.unknown,
      ),
      progress: entry.episodesWatched.toDouble(),
      score: null,
    );
  }

  @override
  Future<void> removeEntry({required String trackingId}) async {
    await _isar.writeTxn(() async {
      await _isar.libraryEntrys.deleteByProviderId(trackingId);
    });
  }
}
