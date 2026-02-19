import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shonenx/core/models/tracker/tracker_models.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/core/services/tracker/external_tracker_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/data/isar/external_track_binding.dart';
import 'package:shonenx/shared/auth/providers/auth_notifier.dart';
import 'package:shonenx/shared/providers/tracker_service_providers.dart';

/// State for the external tracker feature on a per-media basis.
class ExternalTrackerState {
  final Map<TrackerType, TrackerEntry?> entries;
  final Map<TrackerType, bool> isLoading;
  final Map<TrackerType, int?> boundRemoteIds;
  final String? error;

  const ExternalTrackerState({
    this.entries = const {},
    this.isLoading = const {},
    this.boundRemoteIds = const {},
    this.error,
  });

  ExternalTrackerState copyWith({
    Map<TrackerType, TrackerEntry?>? entries,
    Map<TrackerType, bool>? isLoading,
    Map<TrackerType, int?>? boundRemoteIds,
    String? error,
    bool clearError = false,
  }) {
    return ExternalTrackerState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      boundRemoteIds: boundRemoteIds ?? this.boundRemoteIds,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Whether this media has any active tracker binding.
  bool get hasAnyBinding => boundRemoteIds.values.any((id) => id != null);

  /// Get a brief status summary for display on the Track button.
  String? getStatusSummary(TrackerType tracker) {
    final entry = entries[tracker];
    if (entry == null) return null;
    final status = TrackerStatus.displayName(entry.status);
    if (entry.totalEpisodes != null) {
      return '$status • ${entry.progress}/${entry.totalEpisodes}';
    }
    return '$status • ${entry.progress}';
  }

  /// Get a combined status summary for the Track button.
  String? get combinedStatusSummary {
    for (final tracker in TrackerType.values) {
      final summary = getStatusSummary(tracker);
      if (summary != null) return summary;
    }
    return null;
  }
}

/// Manages tracker state for a given media item.
class ExternalTrackerNotifier extends StateNotifier<ExternalTrackerState> {
  final Ref _ref;

  ExternalTrackerNotifier(this._ref) : super(const ExternalTrackerState());

  ExternalTrackerService get _service =>
      _ref.read(externalTrackerServiceProvider);

  /// Initialize tracker state for a media item.
  Future<void> init(UniversalMedia media) async {
    final anilistMediaId = int.tryParse(media.id);
    if (anilistMediaId == null) return;

    final bindings = await _service.getBindingsForMedia(anilistMediaId);

    final boundIds = <TrackerType, int?>{};
    final loadingMap = <TrackerType, bool>{};

    for (final binding in bindings) {
      boundIds[binding.trackerType] = binding.trackerRemoteId;
    }

    // Also check if IDs are directly available from media metadata
    for (final tracker in TrackerType.values) {
      if (boundIds[tracker] == null) {
        final resolvedId = _service.resolveRemoteId(media, tracker);
        if (resolvedId != null) {
          boundIds[tracker] = resolvedId;
        }
      }
      loadingMap[tracker] = false;
    }

    state = state.copyWith(boundRemoteIds: boundIds, isLoading: loadingMap);

    // Fetch remote state for any bound trackers
    for (final tracker in TrackerType.values) {
      final remoteId = boundIds[tracker];
      if (remoteId != null) {
        _loadRemoteEntry(tracker, remoteId);
      }
    }
  }

  /// Load the remote tracking entry for a specific tracker.
  Future<void> _loadRemoteEntry(TrackerType tracker, int remoteId) async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticatedFor(
      tracker == TrackerType.anilist ? AuthPlatform.anilist : AuthPlatform.mal,
    ))
      return;

    state = state.copyWith(isLoading: {...state.isLoading, tracker: true});

    try {
      final entry = await _service.getTrackerEntry(tracker, remoteId);
      state = state.copyWith(
        entries: {...state.entries, tracker: entry},
        isLoading: {...state.isLoading, tracker: false},
        clearError: true,
      );
    } catch (e, st) {
      AppLogger.e('Failed to load tracker entry', e, st);
      state = state.copyWith(
        isLoading: {...state.isLoading, tracker: false},
        error: 'Failed to load ${tracker.displayName} entry',
      );
    }
  }

  /// Resolve the remote ID for a tracker and media.
  int? resolveRemoteId(UniversalMedia media, TrackerType tracker) {
    final boundId = state.boundRemoteIds[tracker];
    if (boundId != null) return boundId;
    return _service.resolveRemoteId(media, tracker);
  }

  /// Bind a remote ID to a tracker for this media.
  Future<void> bindTracker(
    UniversalMedia media,
    TrackerType tracker,
    int remoteId,
  ) async {
    final anilistMediaId = int.tryParse(media.id);
    if (anilistMediaId == null) return;

    var binding = await _service.getBinding(anilistMediaId, tracker);

    if (binding != null) {
      binding.trackerRemoteId = remoteId;
      binding.updatedAt = DateTime.now().millisecondsSinceEpoch;
    } else {
      binding = ExternalTrackBinding(
        anilistMediaId: anilistMediaId,
        trackerRemoteId: remoteId,
        trackerType: tracker,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }

    await _service.saveBinding(binding);

    state = state.copyWith(
      boundRemoteIds: {...state.boundRemoteIds, tracker: remoteId},
    );

    await _loadRemoteEntry(tracker, remoteId);
  }

  /// Save tracking configuration to the remote tracker.
  Future<bool> saveTrackerEntry(
    UniversalMedia media,
    TrackerType tracker,
    int remoteId, {
    required String status,
    required int progress,
    required double score,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: {...state.isLoading, tracker: true});

    try {
      final success = await _service.updateTrackerEntry(
        tracker,
        remoteId,
        status: status,
        progress: progress,
        score: score,
        startDate: startDate,
        endDate: endDate,
      );

      if (success) {
        final anilistMediaId = int.tryParse(media.id);
        if (anilistMediaId != null) {
          var binding = await _service.getBinding(anilistMediaId, tracker);
          if (binding != null) {
            binding.trackerStatus = status;
            binding.trackerProgress = progress;
            binding.trackerScore = score;
            binding.startDate = startDate?.millisecondsSinceEpoch;
            binding.endDate = endDate?.millisecondsSinceEpoch;
            binding.updatedAt = DateTime.now().millisecondsSinceEpoch;
            await _service.saveBinding(binding);
          }
        }

        final updatedEntry = TrackerEntry(
          tracker: tracker,
          remoteId: remoteId,
          status: status,
          progress: progress,
          score: score,
          startDate: startDate,
          endDate: endDate,
          totalEpisodes: media.episodes,
        );

        state = state.copyWith(
          entries: {...state.entries, tracker: updatedEntry},
          isLoading: {...state.isLoading, tracker: false},
          clearError: true,
        );
      } else {
        state = state.copyWith(
          isLoading: {...state.isLoading, tracker: false},
          error: 'Failed to update ${tracker.displayName}',
        );
      }

      return success;
    } catch (e, st) {
      AppLogger.e('Failed to save tracker entry', e, st);
      state = state.copyWith(
        isLoading: {...state.isLoading, tracker: false},
        error: 'Failed to update ${tracker.displayName}',
      );
      return false;
    }
  }

  /// Remove a tracker binding and optionally the remote entry.
  Future<bool> removeTracker(
    UniversalMedia media,
    TrackerType tracker,
    int remoteId,
  ) async {
    state = state.copyWith(isLoading: {...state.isLoading, tracker: true});

    try {
      await _service.removeTrackerEntry(tracker, remoteId);

      final anilistMediaId = int.tryParse(media.id);
      if (anilistMediaId != null) {
        await _service.deleteBinding(anilistMediaId, tracker);
      }

      final newEntries = Map<TrackerType, TrackerEntry?>.from(state.entries);
      newEntries.remove(tracker);
      final newBoundIds = Map<TrackerType, int?>.from(state.boundRemoteIds);
      newBoundIds.remove(tracker);

      state = state.copyWith(
        entries: newEntries,
        boundRemoteIds: newBoundIds,
        isLoading: {...state.isLoading, tracker: false},
        clearError: true,
      );

      return true;
    } catch (e, st) {
      AppLogger.e('Failed to remove tracker', e, st);
      state = state.copyWith(
        isLoading: {...state.isLoading, tracker: false},
        error: 'Failed to remove from ${tracker.displayName}',
      );
      return false;
    }
  }
}

/// Family provider keyed by media ID string.
/// AutoDispose cleans up when leaving the details screen.
final externalTrackerProvider = StateNotifierProvider.autoDispose
    .family<ExternalTrackerNotifier, ExternalTrackerState, String>(
      (ref, mediaId) => ExternalTrackerNotifier(ref),
    );
