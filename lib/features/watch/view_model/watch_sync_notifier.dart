import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:workmanager/workmanager.dart';

import 'package:shonenx/core/models/tracker/tracker_type.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/repositories/local_media_repository.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/providers/settings/sync_settings_notifier.dart';
import 'package:shonenx/shared/providers/tracker/media_tracker_notifier.dart';

part 'watch_sync_notifier.g.dart';

@riverpod
class WatchSyncNotifier extends _$WatchSyncNotifier {
  @override
  void build() {}

  /// Process syncing to Anilist/MAL and local database mirror if criteria are met.
  Future<void> handleTrackingUpdate({
    required String mediaId,
    required int episodeNum,
  }) async {
    final syncSettings = ref.read(syncSettingsProvider);
    final syncNotifier = ref.read(syncSettingsProvider.notifier);

    // Skip manual or prompt-based sync calls (WatchScreen handles prompt if askBeforeSync is true)
    if (syncNotifier.isManualSync || syncSettings.askBeforeSync) return;

    await updateTracking(mediaId: mediaId, episodeNum: episodeNum);
  }

  /// Forces an update to tracking without checking system automated rules
  Future<void> updateTracking({
    required String mediaId,
    required int episodeNum,
  }) async {
    try {
      final syncSettings = ref.read(syncSettingsProvider);
      final syncNotifier = ref.read(syncSettingsProvider.notifier);
      final repo = ref.read(localMediaRepoProvider);
      final watchProgressRepo = ref.read(watchProgressRepositoryProvider);
      final trackerNotifier = ref.read(mediaTrackerProvider(mediaId).notifier);
      final List<Future<void>> tasks = [];

      final bindings = await repo.getBindings(mediaId);

      final activeBindings = bindings
          .where(
            (b) =>
                (b.type == TrackerType.anilist &&
                    syncNotifier.shouldSyncAnilist) ||
                (b.type == TrackerType.mal && syncNotifier.shouldSyncMal),
          )
          .toList();

      if (syncSettings.syncMode == 'background') {
        final inputData = <String, dynamic>{'progress': episodeNum};
        for (final b in activeBindings) {
          if (b.type == TrackerType.anilist) {
            inputData['anilistId'] = b.remoteId;
          }
          if (b.type == TrackerType.mal) inputData['malId'] = b.remoteId;
        }

        if (inputData.containsKey('anilistId') ||
            inputData.containsKey('malId')) {
          Workmanager().registerOneOffTask(
            "sync_tracking_${mediaId}_$episodeNum",
            "sync_tracking_task",
            inputData: inputData,
            initialDelay: Duration(
              minutes: syncSettings.backgroundIntervalMinutes,
            ),
            existingWorkPolicy: ExistingWorkPolicy.replace,
          );
        }
      } else if (activeBindings.isNotEmpty) {
        tasks.add(
          trackerNotifier.syncTrackers(
            bindings: activeBindings,
            status: 'CURRENT',
            progress: episodeNum,
          ),
        );
      }

      if (syncNotifier.shouldSyncLocal) {
        final entry = watchProgressRepo.getProgress(mediaId);
        final localEntry = await trackerNotifier.getLocalEntry();

        tasks.add(
          trackerNotifier.saveLocalEntry(
            UniversalMedia(
              id: mediaId,
              title: UniversalTitle(english: entry?.animeTitle ?? 'Unknown'),
              coverImage: UniversalCoverImage(large: entry?.animeCover),
              status: 'UNKNOWN',
              format: entry?.animeFormat,
              episodes: entry?.totalEpisodes,
            ),
            status: 'CURRENT',
            progress: episodeNum,
            score: localEntry?.score ?? 0.0,
            repeat: localEntry?.repeat ?? 0,
            notes: localEntry?.notes ?? '',
            isPrivate: localEntry?.isPrivate ?? false,
            startedAt: DateTime.now(),
          ),
        );
      }

      if (tasks.isNotEmpty) await Future.wait(tasks);
    } catch (e) {
      AppLogger.e('Tracking update failed', e);
    }
  }
}
