import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/notifications/domain/models/notification_subscription.dart';
import 'package:shonenx/features/notifications/providers/notification_subscriptions_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class NotificationSubscriptionSheet extends ConsumerStatefulWidget {
  final UnifiedMedia media;

  const NotificationSubscriptionSheet({super.key, required this.media});

  @override
  ConsumerState<NotificationSubscriptionSheet> createState() =>
      _NotificationSubscriptionSheetState();
}

class _NotificationSubscriptionSheetState
    extends ConsumerState<NotificationSubscriptionSheet> {
  late bool _isEnabled;
  late SubscriptionMode _mode;
  late int _offsetMinutes;

  @override
  void initState() {
    super.initState();
    final subType = widget.media.type == MediaType.MANGA ? SubscriptionType.mangaChapter : SubscriptionType.animeAiring;
    final subscription = ref
        .read(notificationSubscriptionsProvider.notifier)
        .getSubscription(subType, widget.media.id);

    _isEnabled = subscription?.isEnabled ?? false;
    _mode = subscription?.mode ?? SubscriptionMode.nextOnly;
    _offsetMinutes = subscription?.offsetMinutes ?? 0;
  }

  void _save() {
    final provider = ref.read(notificationSubscriptionsProvider.notifier);

    // We only schedule if we have a known airing time.
    final airingAt = widget.media.airingAt;
    final nextEpisode = widget.media.nextEpisode;
    final int? episodeNumber = nextEpisode is int ? nextEpisode : (null);

    final subType = widget.media.type == MediaType.MANGA ? SubscriptionType.mangaChapter : SubscriptionType.animeAiring;
    final existingSub = provider.getSubscription(
      subType,
      widget.media.id,
    );

    final sub = NotificationSubscription()
      ..type = subType
      ..referenceId = widget.media.id
      ..title = widget.media.title.availableTitle
      ..image = widget.media.cover ?? widget.media.banner ?? ''
      ..isEnabled = _isEnabled
      ..mode = _mode
      ..offsetMinutes = _offsetMinutes
      ..upcomingIdentifier = episodeNumber != null ? 'ep_$episodeNumber' : null
      ..upcomingTime = airingAt;

    if (existingSub != null) {
      sub.id = existingSub.id;
      sub.createdAt = existingSub.createdAt;
    }

    provider.saveSubscription(sub);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final scheduledTime = widget.media.airingAt?.subtract(
      Duration(minutes: _offsetMinutes),
    );
    final hasAiringData =
        widget.media.airingAt != null && widget.media.nextEpisode != null;

    return AppBottomSheet(
      title: 'Notifications',
      actions: [
        Switch(
          value: _isEnabled,
          onChanged: (val) {
            if (val && !hasAiringData) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Cannot enable notifications: No upcoming episode scheduled.',
                  ),
                ),
              );
              return;
            }
            setState(() => _isEnabled = val);
          },
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasAiringData) ...[
            const SizedBox(height: 8),
            Text(
              'No upcoming release data available for this ${widget.media.type == MediaType.MANGA ? 'manga' : 'anime'}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),

          Opacity(
            opacity: _isEnabled ? 1.0 : 0.5,
            child: IgnorePointer(
              ignoring: !_isEnabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<SubscriptionMode>(
                    title: const Text('Follow next episode only'),
                    subtitle: const Text(
                      'Reminds you about the immediate next episode.',
                    ),
                    value: SubscriptionMode.nextOnly,
                    groupValue: _mode,
                    onChanged: (val) => setState(() => _mode = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<SubscriptionMode>(
                    title: const Text('Follow entire season'),
                    subtitle: const Text(
                      'Reminds you whenever new episodes are announced.',
                    ),
                    value: SubscriptionMode.entireSeason,
                    groupValue: _mode,
                    onChanged: (val) => setState(() => _mode = val!),
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Reminder Timing',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _offsetMinutes,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('At airing time')),
                      DropdownMenuItem(
                        value: 15,
                        child: Text('15 minutes before'),
                      ),
                      DropdownMenuItem(value: 60, child: Text('1 hour before')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _offsetMinutes = val);
                      }
                    },
                  ),

                  if (_isEnabled && scheduledTime != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Next reminder scheduled for:\n${formatDateWithTime(scheduledTime)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  String formatDateWithTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
