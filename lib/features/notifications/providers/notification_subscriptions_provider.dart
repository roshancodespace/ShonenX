import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/core/database/database_provider.dart';
import 'package:shonenx/core/services/notification_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/notifications/domain/models/notification_subscription.dart';

final notificationSubscriptionsProvider = NotifierProvider<
    NotificationSubscriptionsNotifier, List<NotificationSubscription>>(
  NotificationSubscriptionsNotifier.new,
);

class NotificationSubscriptionsNotifier
    extends Notifier<List<NotificationSubscription>> {
  late final Isar _isar;
  late final NotificationService _notificationService;
  final _log = AppLogger.scope('NotificationSubscriptionsNotifier');

  @override
  List<NotificationSubscription> build() {
    _isar = ref.watch(databaseProvider);
    _notificationService = NotificationService.instance;
    _init();
    return [];
  }

  Future<void> _init() async {
    final subscriptions = await _isar.notificationSubscriptions.where().findAll();
    state = subscriptions;
  }

  Future<void> saveSubscription(NotificationSubscription subscription) async {
    await _isar.writeTxn(() async {
      await _isar.notificationSubscriptions.put(subscription);
    });

    final scheduledTime = subscription.upcomingTime?.subtract(Duration(minutes: subscription.offsetMinutes));
    final notifId = NotificationService.generateId(subscription.type.name, subscription.referenceId, subscription.upcomingIdentifier ?? 'unknown');

    if (subscription.isEnabled && scheduledTime != null) {
      final scheduled = await _notificationService.schedule(
        id: notifId,
        title: 'New Update Alert: ${subscription.title}',
        body: 'A new update (${subscription.upcomingIdentifier ?? ''}) is arriving soon!',
        scheduleTime: scheduledTime,
      );
      if (!scheduled) {
        _log.w('Failed to schedule notification for ${subscription.title}');
      }
    } else {
      await _notificationService.cancel(notifId);
    }
    
    await _init();
  }

  Future<void> deleteSubscription(Id id) async {
    final subscription = await _isar.notificationSubscriptions.get(id);
    if (subscription != null) {
      final notifId = NotificationService.generateId(subscription.type.name, subscription.referenceId, subscription.upcomingIdentifier ?? 'unknown');
      await _notificationService.cancel(notifId);
      await _isar.writeTxn(() async {
        await _isar.notificationSubscriptions.delete(id);
      });
      await _init();
    }
  }

  NotificationSubscription? getSubscription(SubscriptionType type, String referenceId) {
    return state.where((e) => e.type == type && e.referenceId == referenceId).firstOrNull;
  }
}
