import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/library/providers/cloud_library_provider.dart';
import 'package:shonenx/features/library/providers/local_library_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

enum LibraryMode { local, cloud }

class LibraryViewState {
  final LibraryMode mode;
  final TrackedStatus status;
  final MediaType mediaType;

  LibraryViewState({
    this.mode = LibraryMode.cloud,
    this.status = TrackedStatus.watching,
    this.mediaType = MediaType.ANIME,
  });

  LibraryViewState copyWith({LibraryMode? mode, TrackedStatus? status, MediaType? mediaType}) {
    return LibraryViewState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      mediaType: mediaType ?? this.mediaType,
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

  void setMediaType(MediaType mediaType) {
    state = state.copyWith(mediaType: mediaType);
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
        return ref.watch(localLibraryListProvider((status: libraryView.status, mediaType: libraryView.mediaType)));
      } else {
        return ref.watch(cloudLibraryProvider((status: libraryView.status, trackerType: null, mediaType: libraryView.mediaType)));
      }
    });
