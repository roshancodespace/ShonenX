import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';

import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/shared/models/unified_media.dart';

typedef CloudLibraryParams = ({TrackedStatus status, TrackerType? trackerType, MediaType mediaType});

final cloudLibraryProvider = AsyncNotifierProvider.autoDispose
    .family<CloudLibraryNotifier, List<LibraryEntry>, CloudLibraryParams>(
      CloudLibraryNotifier.new,
    );

class CloudLibraryNotifier extends AsyncNotifier<List<LibraryEntry>> {
  CloudLibraryParams params;

  CloudLibraryNotifier(this.params);

  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<LibraryEntry>> build() async {
    ref.keepAlive();

    _page = 1;
    _hasMore = true;
    return _fetchPage(1);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    _page++;

    try {
      final newEntries = await _fetchPage(_page);
      if (newEntries.isEmpty) {
        _hasMore = false;
      } else {
        final currentList = state.value ?? [];
        state = AsyncData([...currentList, ...newEntries]);
      }
    } catch (e, st) {
      _page--;
      state = AsyncError(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<List<LibraryEntry>> _fetchPage(int page) async {
    final TrackingService tracker = params.trackerType != null
        ? ref
              .watch(availableTrackersProvider)
              .firstWhere((t) => t.type == params.trackerType!)
        : ref.watch(primaryTrackerProvider);

    if (!(await tracker.isAuthenticated)) return [];

    return await tracker.fetchUserLibrary(status: params.status, page: page, mediaType: params.mediaType);
  }

  Future<void> removeEntry(String providerId, MediaType mediaType) async {
    final TrackingService tracker = params.trackerType != null
        ? ref
              .watch(availableTrackersProvider)
              .firstWhere((t) => t.type == params.trackerType!)
        : ref.watch(primaryTrackerProvider);

    if (!(await tracker.isAuthenticated)) return;

    await tracker.removeEntry(trackingId: providerId, mediaType: mediaType);

    final currentList = state.value ?? [];
    state = AsyncData(
      currentList.where((e) => e.providerId != providerId).toList(),
    );
  }

  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    state = const AsyncLoading();
    state = AsyncData(await _fetchPage(1));
  }
}
