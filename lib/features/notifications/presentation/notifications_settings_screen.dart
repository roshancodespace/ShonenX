import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/notifications/domain/models/notification_subscription.dart';
import 'package:shonenx/features/notifications/providers/notification_subscriptions_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(notificationSubscriptionsProvider).values.toList();
    final theme = Theme.of(context);

    final upcoming = subscriptions.where((s) {
      final scheduledTime = s.upcomingTime?.subtract(Duration(minutes: s.offsetMinutes));
      return s.isEnabled && scheduledTime != null && scheduledTime.isAfter(DateTime.now());
    }).toList()
      ..sort((a, b) {
        final timeA = a.upcomingTime!.subtract(Duration(minutes: a.offsetMinutes));
        final timeB = b.upcomingTime!.subtract(Duration(minutes: b.offsetMinutes));
        return timeA.compareTo(timeB);
      });

    return AppScaffold(
      title: 'Manage Anime Notifications',
      body: subscriptions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Subscriptions Yet',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can enable notifications for upcoming episodes directly from the anime details page.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  Text(
                    'Upcoming',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...upcoming.map((sub) => _SubscriptionTile(subscription: sub)),
                  const SizedBox(height: 24),
                ],
                Text(
                  'All Subscriptions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...subscriptions.map((sub) => _SubscriptionTile(subscription: sub)),
              ],
            ),
    );
  }
}

class _SubscriptionTile extends ConsumerWidget {
  final NotificationSubscription subscription;

  const _SubscriptionTile({required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final provider = ref.read(notificationSubscriptionsProvider.notifier);
    final scheduledTime = subscription.upcomingTime?.subtract(Duration(minutes: subscription.offsetMinutes));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: subscription.image,
            width: 48,
            height: 72,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(
              width: 48,
              height: 72,
              color: theme.colorScheme.surfaceContainerHigh,
              child: const Icon(Icons.error),
            ),
          ),
        ),
        title: Text(
          subscription.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subscription.mode == SubscriptionMode.entireSeason ? 'Following Season' : 'Following Next Episode',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (subscription.isEnabled && scheduledTime != null && scheduledTime.isAfter(DateTime.now()))
              Text(
                'Next reminder: ${formatDateWithTime(scheduledTime)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: subscription.isEnabled,
              onChanged: (val) {
                subscription.isEnabled = val;
                provider.saveSubscription(subscription);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                provider.deleteSubscription(subscription.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  String formatDateWithTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
