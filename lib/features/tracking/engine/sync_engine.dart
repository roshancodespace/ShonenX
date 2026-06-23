import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) => SyncEngine(ref));

class SyncEngine {
  final Ref ref;

  final Set<String> _sessionSyncedCache = {};

  final _log = AppLogger.scope(SyncEngine);

  SyncEngine(this.ref);

  Future<void> processPlayback({
    required UnifiedMedia media,
    required double episodeNumber,
    required Duration position,
    required Duration duration,
  }) async {
    final log = _log.child('processPlayback');

    if (duration.inSeconds == 0) return;

    final sessionKey = '${media.id}_$episodeNumber';
    if (_sessionSyncedCache.contains(sessionKey)) return;

    final progressPercent = position.inSeconds / duration.inSeconds;
    final threshold = ref.read(trackingPrefsProvider).syncThreshold;

    log.v('Progress ${(progressPercent * 100).toStringAsFixed(1)}%');

    if (progressPercent >= threshold) {
      _sessionSyncedCache.add(sessionKey);

      log.i('Threshold hit → syncing');

      await syncEpisodeProgress(
        media: media,
        episodeNumber: episodeNumber,
      );
    }
  }

  Future<void> processReading({
    required UnifiedMedia media,
    required double chapterNumber,
    required int positionPage,
    required int totalPages,
  }) async {
    final log = _log.child('processReading');

    if (totalPages == 0) return;

    final sessionKey = '${media.id}_$chapterNumber';
    if (_sessionSyncedCache.contains(sessionKey)) return;

    final progressPercent = positionPage / totalPages;
    final threshold = ref.read(trackingPrefsProvider).syncThreshold;

    log.v('Progress ${(progressPercent * 100).toStringAsFixed(1)}%');

    if (progressPercent >= threshold) {
      _sessionSyncedCache.add(sessionKey);

      log.i('Threshold hit → syncing');

      await syncEpisodeProgress(
        media: media,
        episodeNumber: chapterNumber,
      );
    }
  }

  Future<void> syncEpisodeProgress({
    required UnifiedMedia media,
    required double episodeNumber,
  }) async {
    final log = _log.child('syncEpisodeProgress');

    final prefs = ref.read(trackingPrefsProvider);

    if (prefs.isIncognito) {
      log.w('Incognito mode → sync skipped');
      return;
    }

    final allTrackers = ref.read(availableTrackersProvider);
    final linkedIds = await ref.read(
      trackerLinkProvider(media.id).future,
    );

    List<Future<void>> syncTasks = [];

    for (final tracker in allTrackers) {
      final isEnabled = prefs.isTrackerEnabled(tracker.type);
      if (!isEnabled) continue;

      if (!(await tracker.isAuthenticated)) {
        log.i('Skip ${tracker.type.displayName} → not authenticated/ready');
        continue;
      }

      String? actualTrackingId = linkedIds[tracker.type]?.trackingId;
      if (tracker.type == TrackerType.local) {
        actualTrackingId = media.id;
      }

      if (actualTrackingId != null) {
        final query = TrackingQuery(tracker.type, media.id, media.type);

        TrackedListItem? currentData;

        try {
          currentData = await ref.read(mediaTrackingProvider(query).future);
        } catch (e, st) {
          log.w(
            'Fetch current data failed (${tracker.type.displayName})',
            e,
            st,
          );
        }

        if (currentData != null && currentData.progress >= episodeNumber) {
          log.i(
            'Skip ${tracker.type.displayName} → ${tracker.type == TrackerType.local ? 'local' : 'cloud'} ahead (${currentData.progress})',
          );
          continue;
        }

        TrackedStatus updateStatus = TrackedStatus.watching;

        if (currentData?.status == TrackedStatus.completed) {
          updateStatus = TrackedStatus.completed;
        }

        syncTasks.add(
          tracker
              .updateListItem(
                media: media,
                trackingId: actualTrackingId,
                progress: episodeNumber,
                status: updateStatus,
              )
              .then((_) {
                ref.invalidate(mediaTrackingProvider(query));

                log.s('${tracker.type.displayName} → Ep $episodeNumber');
              })
              .catchError((e, st) {
                log.e('Sync failed (${tracker.type.displayName})', e, st);

                _sessionSyncedCache.remove('${media.id}_$episodeNumber');
              }),
        );
      }
    }

    if (syncTasks.isNotEmpty) {
      log.d('Waiting for ${syncTasks.length} trackers');
      await Future.wait(syncTasks);
      log.s('Sync batch complete');
    }
  }
}
