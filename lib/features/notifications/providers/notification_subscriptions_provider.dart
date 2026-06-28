import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/core/services/notification_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/discovery/domain/media_preference.dart';
import 'package:shonenx/features/notifications/domain/models/notification_subscription.dart';
import 'package:shonenx/features/notifications/providers/airing_data_repository_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_media.dart';

final notificationSubscriptionsProvider =
    NotifierProvider<
      NotificationSubscriptionsNotifier,
      Map<String, NotificationSubscription>
    >(NotificationSubscriptionsNotifier.new);

class NotificationSubscriptionsNotifier
    extends Notifier<Map<String, NotificationSubscription>> {
  late final Isar _isar;
  late final NotificationService _notificationService;
  final _log = AppLogger.scope('NotificationSubscriptionsNotifier');

  @override
  Map<String, NotificationSubscription> build() {
    _isar = ref.watch(databaseProvider);
    _notificationService = NotificationService.instance;
    _init();
    return {};
  }

  String _mapKey(SubscriptionType type, String referenceId) =>
      '${type.name}_$referenceId';

  Future<void> _init() async {
    final subscriptions = await _isar.notificationSubscriptions
        .where()
        .findAll();
    final map = <String, NotificationSubscription>{};

    for (var sub in subscriptions) {
      map[_mapKey(sub.type, sub.referenceId)] = sub;

      // App Start Sync: Check if entireSeason and the latest scheduled is in the past
      if (sub.isEnabled && sub.mode == SubscriptionMode.entireSeason) {
        if (sub.upcomingTime != null &&
            sub.upcomingTime!.isBefore(DateTime.now())) {
          _syncSubscription(sub);
        }
      }
    }
    state = map;
  }

  Future<void> _syncSubscription(NotificationSubscription sub) async {
    final pref = await _isar.mediaPreferences.getByMediaTitle(sub.title);
    final tracker = pref?.preferredAiringTracker ?? TrackerType.anilist.id;
    final targetTrackerType =
        TrackerType.tryFromId(tracker) ?? TrackerType.anilist;

    // Resolve the target ID if there is a tracker mismatch
    String targetId = sub.referenceId;
    final primaryTrackerType = ref.read(primaryTrackerProvider).type;

    if (targetTrackerType != primaryTrackerType) {
      final targetTrackerService = targetTrackerType.getTracker(ref);
      if (targetTrackerService is RemoteTracker) {
        try {
          final results = await targetTrackerService.searchMedia(
            sub.title,
            type: sub.type == SubscriptionType.mangaChapter
                ? MediaType.MANGA
                : MediaType.ANIME,
          );
          if (results.isNotEmpty) {
            targetId = results.first.id;
            _log.i(
              'Auto-matched ID for ${sub.title}: ${sub.referenceId} -> $targetId on ${targetTrackerType.displayName}',
            );
          }
        } catch (e) {
          _log.w(
            'Failed to auto-match ID for ${sub.title} on ${targetTrackerType.displayName}',
          );
        }
      }
    }

    final repo = ref.read(airingDataRepositoryProvider(targetTrackerType));

    try {
      final schedules = await repo.getAiringSchedule(targetId);
      final upcoming = schedules
          .where((s) => s.airingAt.isAfter(DateTime.now()))
          .toList();

      if (upcoming.isNotEmpty) {
        // Schedule all found future episodes
        for (final schedule in upcoming) {
          final scheduledTime = schedule.airingAt.subtract(
            Duration(minutes: sub.offsetMinutes),
          );
          final notifId = NotificationService.generateId(
            sub.type.name,
            sub.referenceId,
            'ep_${schedule.episode}',
          );

          if (scheduledTime.isAfter(DateTime.now())) {
            await _notificationService.schedule(
              id: notifId,
              title: 'New Episode Alert: ${sub.title}',
              body: 'Episode ${schedule.episode} is arriving soon!',
              scheduleTime: scheduledTime,
            );
          }
        }

        // Update the subscription's immediate next target so we don't sync again until it passes
        final nextTarget = upcoming.reduce(
          (a, b) => a.airingAt.isBefore(b.airingAt) ? a : b,
        );
        sub.upcomingTime = nextTarget.airingAt;
        sub.upcomingIdentifier = 'ep_${nextTarget.episode}';

        await _isar.writeTxn(() async {
          await _isar.notificationSubscriptions.put(sub);
        });

        // Update local state map
        state = {...state, _mapKey(sub.type, sub.referenceId): sub};
      } else {
        _log.w(
          'Sync: Could not find next episode for ${sub.title}. Try opening the app later.',
        );
      }
    } catch (e) {
      _log.e('Failed to sync schedule for ${sub.title}', e);
    }
  }

  NotificationSubscription? getSubscription(
    SubscriptionType type,
    String referenceId,
  ) {
    return state[_mapKey(type, referenceId)];
  }

  Future<void> toggleSubscription(UnifiedMedia media) async {
    final subType = media.type == MediaType.MANGA
        ? SubscriptionType.mangaChapter
        : SubscriptionType.animeAiring;

    final existing = getSubscription(subType, media.id);

    if (existing != null && existing.isEnabled) {
      // Fast disable
      await deleteSubscription(existing.id);
      return;
    }

    // Fast enable: default to nextOnly
    final nextEpisode = media.nextEpisode;
    final episodeNumber = nextEpisode is int ? nextEpisode : null;

    final sub = NotificationSubscription()
      ..type = subType
      ..referenceId = media.id
      ..title = media.title.availableTitle
      ..image = media.cover ?? media.banner ?? ''
      ..isEnabled = true
      ..mode = SubscriptionMode.nextOnly
      ..offsetMinutes = 0
      ..upcomingIdentifier = episodeNumber != null ? 'ep_$episodeNumber' : null
      ..upcomingTime = media.airingAt;

    if (existing != null) {
      sub.id = existing.id;
      sub.createdAt = existing.createdAt;
      sub.mode = existing.mode; // Preserve mode if re-enabling
      sub.offsetMinutes = existing.offsetMinutes;
    }

    await saveSubscription(sub);
  }

  Future<void> saveSubscription(NotificationSubscription subscription) async {
    // If entireSeason is enabled, we could fetch from repository here
    if (subscription.mode == SubscriptionMode.entireSeason &&
        subscription.isEnabled) {
      final pref = await _isar.mediaPreferences.getByMediaTitle(
        subscription.title,
      );
      final tracker = pref?.preferredAiringTracker ?? TrackerType.anilist.id;
      final targetTrackerType =
          TrackerType.tryFromId(tracker) ?? TrackerType.anilist;

      // Resolve ID
      String targetId = subscription.referenceId;
      final primaryTrackerType = ref.read(primaryTrackerProvider).type;

      if (targetTrackerType != primaryTrackerType) {
        final targetTrackerService = targetTrackerType.getTracker(ref);
        if (targetTrackerService is RemoteTracker) {
          try {
            final results = await targetTrackerService.searchMedia(
              subscription.title,
              type: subscription.type == SubscriptionType.mangaChapter
                  ? MediaType.MANGA
                  : MediaType.ANIME,
            );
            if (results.isNotEmpty) {
              targetId = results.first.id;
              _log.i(
                'Auto-matched ID for ${subscription.title}: ${subscription.referenceId} -> $targetId on ${targetTrackerType.displayName}',
              );
            }
          } catch (_) {}
        }
      }

      final repo = ref.read(airingDataRepositoryProvider(targetTrackerType));
      final schedules = await repo.getAiringSchedule(targetId);

      // Schedule multiple local notifications
      for (final schedule in schedules) {
        final scheduledTime = schedule.airingAt.subtract(
          Duration(minutes: subscription.offsetMinutes),
        );
        final notifId = NotificationService.generateId(
          subscription.type.name,
          subscription.referenceId,
          'ep_${schedule.episode}',
        );

        if (scheduledTime.isAfter(DateTime.now())) {
          await _notificationService.schedule(
            id: notifId,
            title: 'New Episode Alert: ${subscription.title}',
            body: 'Episode ${schedule.episode} is arriving soon!',
            scheduleTime: scheduledTime,
          );
        }
      }

      // Also update the upcomingTime so the sync loop knows when to trigger next
      final upcoming = schedules
          .where((s) => s.airingAt.isAfter(DateTime.now()))
          .toList();
      if (upcoming.isNotEmpty) {
        final nextTarget = upcoming.reduce(
          (a, b) => a.airingAt.isBefore(b.airingAt) ? a : b,
        );
        subscription.upcomingTime = nextTarget.airingAt;
        subscription.upcomingIdentifier = 'ep_${nextTarget.episode}';
      }
    } else if (subscription.isEnabled) {
      // Next Only mode
      final scheduledTime = subscription.upcomingTime?.subtract(
        Duration(minutes: subscription.offsetMinutes),
      );
      final notifId = NotificationService.generateId(
        subscription.type.name,
        subscription.referenceId,
        subscription.upcomingIdentifier ?? 'unknown',
      );

      if (scheduledTime != null) {
        final scheduled = await _notificationService.schedule(
          id: notifId,
          title: 'New Update Alert: ${subscription.title}',
          body:
              'A new update (${subscription.upcomingIdentifier ?? ''}) is arriving soon!',
          scheduleTime: scheduledTime,
        );
        if (!scheduled) {
          _log.w('Failed to schedule notification for ${subscription.title}');
        }
      }
    } else {
      // Is disabled
      final notifId = NotificationService.generateId(
        subscription.type.name,
        subscription.referenceId,
        subscription.upcomingIdentifier ?? 'unknown',
      );
      await _notificationService.cancel(notifId);
    }

    await _isar.writeTxn(() async {
      await _isar.notificationSubscriptions.put(subscription);
    });

    await _init();
  }

  Future<void> deleteSubscription(Id id) async {
    final subscription = await _isar.notificationSubscriptions.get(id);
    if (subscription != null) {
      // Cancel "Next Only"
      final notifId = NotificationService.generateId(
        subscription.type.name,
        subscription.referenceId,
        subscription.upcomingIdentifier ?? 'unknown',
      );
      await _notificationService.cancel(notifId);

      await _isar.writeTxn(() async {
        await _isar.notificationSubscriptions.delete(id);
      });
      await _init();
    }
  }
}
