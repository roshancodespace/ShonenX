import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/security_prefs_provider.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) => SyncEngine(ref));

class SyncEngine {
  final Ref ref;

  final Set<String> _sessionSyncedCache = {};

  final _log = AppLogger.scope(SyncEngine);

  SyncEngine(this.ref);

  // Normalize episode/chapter numbers so 1.0 and 1 produce the same session key
  String _sessionKey(String mediaId, double number) {
    final n = number % 1 == 0 ? number.toInt().toString() : number.toString();
    return '${mediaId}_$n';
  }

  Future<void> processPlayback({
    required UnifiedMedia media,
    required double episodeNumber,
    required Duration position,
    required Duration duration,
  }) async {
    final log = _log.child('processPlayback');

    if (duration.inSeconds == 0) return;

    final sessionKey = _sessionKey(media.id, episodeNumber);
    if (_sessionSyncedCache.contains(sessionKey)) return;

    final progressPercent = position.inSeconds / duration.inSeconds;
    final threshold = ref.read(trackingPrefsProvider).syncThreshold;

    log.v(
      'Progress ${(progressPercent * 100).toStringAsFixed(1)}% (Threshold: ${(threshold * 100).toInt()}%)',
    );

    if (progressPercent >= threshold) {
      _sessionSyncedCache.add(sessionKey);

      log.i('Threshold hit → syncing Ep $episodeNumber');

      await syncEpisodeProgress(media: media, episodeNumber: episodeNumber);
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

    final sessionKey = _sessionKey(media.id, chapterNumber);
    if (_sessionSyncedCache.contains(sessionKey)) return;

    final progressPercent = positionPage / totalPages;
    final threshold = ref.read(trackingPrefsProvider).syncThreshold;

    log.v(
      'Progress ${(progressPercent * 100).toStringAsFixed(1)}% (Threshold: ${(threshold * 100).toInt()}%)',
    );

    if (progressPercent >= threshold) {
      _sessionSyncedCache.add(sessionKey);

      log.i('Threshold hit → syncing Ch $chapterNumber');

      await syncEpisodeProgress(media: media, episodeNumber: chapterNumber);
    }
  }

  Future<void> syncEpisodeProgress({
    required UnifiedMedia media,
    required double episodeNumber,
  }) async {
    final log = _log.child('syncEpisodeProgress');

    final prefs = ref.read(trackingPrefsProvider);
    final isIncognito =
        ref.read(securityPrefsProvider).incognitoMode || prefs.isIncognito;

    if (isIncognito) {
      log.w('Incognito mode → sync skipped');
      return;
    }

    final allTrackers = ref.read(availableTrackersProvider);
    final linkedIds = await ref.read(trackerLinkProvider(media.id).future);

    // Pre-filter: collect enabled trackers with valid tracking IDs
    final eligible = <(TrackingService tracker, String trackingId)>[];
    for (final tracker in allTrackers) {
      if (!prefs.isTrackerEnabled(tracker.type)) continue;

      final trackingId = tracker.type == TrackerType.local
          ? media.id
          : linkedIds[tracker.type]?.trackingId;

      if (trackingId == null || trackingId.isEmpty) {
        log.d('Skip ${tracker.type.displayName} → not linked to media');
        continue;
      }

      eligible.add((tracker, trackingId));
    }

    if (eligible.isEmpty) return;

    // Check auth and fetch current data in parallel across all trackers
    final preflightResults = await Future.wait(
      eligible.map((e) async {
        final (tracker, trackingId) = e;

        if (!(await tracker.isAuthenticated)) {
          log.i('Skip ${tracker.type.displayName} → not authenticated/ready');
          return null;
        }

        TrackedListItem? currentData;
        try {
          final query = TrackingQuery(tracker.type, media);
          currentData = await ref.read(mediaTrackingProvider(query).future);
        } catch (err, st) {
          log.w(
            'Fetch current data failed (${tracker.type.displayName})',
            err,
            st,
          );
        }

        return (tracker: tracker, trackingId: trackingId, data: currentData);
      }),
    );

    // Build sync tasks from preflight results
    final syncTasks = <Future<void>>[];

    for (final result in preflightResults) {
      if (result == null) continue;
      final (:tracker, :trackingId, :data) = result;

      if (data != null && data.progress >= episodeNumber) {
        log.i(
          'Skip ${tracker.type.displayName} → ${tracker.type == TrackerType.local ? 'local' : 'cloud'} ahead (${data.progress})',
        );
        continue;
      }

      TrackedStatus updateStatus = TrackedStatus.watching;
      final totalCount = media.episodes;
      final isFinishedAll =
          totalCount != null && totalCount > 0 && episodeNumber >= totalCount;

      if (data?.status == TrackedStatus.completed || isFinishedAll) {
        updateStatus = TrackedStatus.completed;
      }

      final query = TrackingQuery(tracker.type, media);
      syncTasks.add(
        tracker
            .updateListItem(
              media: media,
              trackingId: trackingId,
              progress: episodeNumber,
              status: updateStatus,
            )
            .then((_) {
              ref.invalidate(mediaTrackingProvider(query));

              log.s(
                '${tracker.type.displayName} → Ep $episodeNumber ($updateStatus)',
              );
            })
            .catchError((e, st) {
              log.e('Sync failed (${tracker.type.displayName})', e, st);

              _sessionSyncedCache.remove(_sessionKey(media.id, episodeNumber));
            }),
      );
    }

    if (syncTasks.isNotEmpty) {
      log.d('Waiting for ${syncTasks.length} trackers');
      await Future.wait(syncTasks);
      log.s('Sync batch complete');
    }
  }
}
