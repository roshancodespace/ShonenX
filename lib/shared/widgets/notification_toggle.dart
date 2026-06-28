import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/notification_provider.dart';

class NotificationToggle extends ConsumerWidget {
  final String type;
  final String refId;
  final String variant;
  final String title;
  final String body;
  final DateTime scheduleTime;

  const NotificationToggle({
    super.key,
    required this.type,
    required this.refId,
    required this.variant,
    required this.title,
    required this.body,
    required this.scheduleTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = (
      type: type,
      refId: refId,
      variant: variant,
      title: title,
      body: body,
      scheduleTime: scheduleTime,
    );

    final state = ref.watch(notificationToggleProvider(config));

    return IconButton(
      onPressed: state.isLoading
          ? null
          : () {
              HapticFeedback.lightImpact();
              ref.read(notificationToggleProvider(config).notifier).toggle();
            },
      icon: state.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              state.isScheduled
                  ? Icons.notifications_active
                  : Icons.notifications_outlined,
              color: state.isScheduled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      tooltip: state.isScheduled ? 'Disable reminder' : 'Enable reminder',
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
