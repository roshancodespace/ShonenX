import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/services/notification_service.dart';
import 'package:shonenx/features/onboarding/providers/onboarding_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class DebugSettingsScreen extends ConsumerWidget {
  const DebugSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Debug Settings',
      body: ListView(
        children: [
          SettingsSection(
            title: 'App State & Onboarding',
            children: [
              SettingsActionTile(
                icon: Icons.restart_alt_rounded,
                title: 'Reset Onboarding Status',
                subtitle: 'Mark onboarding as incomplete and launch screen',
                onTap: () {
                  ref.read(onboardingProvider.notifier).resetOnboarding();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Onboarding status reset!'),
                      action: SnackBarAction(
                        label: 'Launch Now',
                        onPressed: () => context.go('/onboarding'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          SettingsSection(
            title: 'UI Feedback',
            children: [
              SettingsActionTile(
                icon: Icons.notifications_active_outlined,
                title: 'Trigger Snackbar',
                subtitle: 'Show a floating snackbar with an action',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Debug Snackbar Triggered!'),
                      action: SnackBarAction(
                        label: 'Dismiss',
                        onPressed: () {},
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          SettingsSection(
            title: 'System Notifications',
            children: [
              SettingsActionTile(
                icon: Icons.notification_important_outlined,
                title: 'Immediate Notification',
                subtitle: 'Send a notification that appears now',
                onTap: () {
                  NotificationService.instance.show(
                    id: 999,
                    title: 'Immediate Test',
                    body: 'This notification was triggered manually.',
                  );
                },
              ),
              if (Platform.isAndroid) ...[
                SettingsActionTile(
                  icon: Icons.timer_outlined,
                  title: 'Scheduled Notification (5s)',
                  subtitle: 'Send a notification in 5 seconds',
                  onTap: () async {
                    final success = await NotificationService.instance.schedule(
                      id: 1000,
                      title: 'Scheduled Test',
                      body: 'This notification was scheduled 5 seconds ago.',
                      scheduleTime: DateTime.now().add(
                        const Duration(seconds: 5),
                      ),
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Notification scheduled for 5s from now'
                                : 'Failed to schedule notification',
                          ),
                        ),
                      );
                    }
                  },
                ),
                SettingsActionTile(
                  icon: Icons.notifications_off_outlined,
                  title: 'Cancel Scheduled',
                  subtitle: 'Cancel the 5s test notification',
                  onTap: () {
                    NotificationService.instance.cancel(1000);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Canceled scheduled test notification'),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
