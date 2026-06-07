import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/library/providers/local_library_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';

enum LibraryMode { local, cloud }

class LibraryViewState {
  final LibraryMode mode;
  final TrackedStatus status;

  LibraryViewState({
    this.mode = LibraryMode.cloud,
    this.status = TrackedStatus.watching,
  });

  LibraryViewState copyWith({LibraryMode? mode, TrackedStatus? status}) {
    return LibraryViewState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
    );
  }
}

class LibraryViewNotifier extends Notifier<LibraryViewState> {
  @override
  LibraryViewState build() {
    return LibraryViewState();
  }

  void setMode(LibraryMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setStatus(TrackedStatus status) {
    state = state.copyWith(status: status);
  }
}

final libraryViewStateProvider =
    NotifierProvider<LibraryViewNotifier, LibraryViewState>(
      LibraryViewNotifier.new,
    );

final dynamicLibraryProvider =
    Provider.autoDispose<AsyncValue<List<LibraryEntry>>>((ref) {
      final primaryTrackerType = ref.watch(
        trackingPrefsProvider.select((s) => s.primaryTracker),
      );
      final libraryView = ref.watch(libraryViewStateProvider);
      final isCloudLoggedIn = ref.watch(trackerProfileProvider)[primaryTrackerType] != null;

      if (libraryView.mode == LibraryMode.local ||
          primaryTrackerType == TrackerType.local ||
          !isCloudLoggedIn) {
        return ref.watch(localLibraryListProvider(libraryView.status));
      } else {
        return ref.watch(cloudLibraryProvider(libraryView.status));
      }
    });
