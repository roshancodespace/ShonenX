import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/services/notification_service.dart';
import 'package:shonenx/features/news/view/news_screen.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/features/settings/view_model/experimental_notifier.dart';
import 'package:shonenx/utils/updater.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('Debug Menu'),
        forceMaterialTransparency: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        children: [
          SettingsSection(
            title: 'Notifications',
            titleColor: colorScheme.primary,
            onTap: () {},
            children: [
              NormalSettingsItem(
                icon: Icon(Iconsax.notification, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Test Notification',
                description: 'Trigger a local notification immediately',
                onTap: () {
                  NotificationService().showNewsNotification(
                    title: 'Debug Notification',
                    body: 'This is a test notification from the debug menu.',
                    payload: 'debug_test_payload',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notification triggered'),
                      action: SnackBarAction(
                        label: 'View',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const NewsScreen(),
                            ),
                          );
                        },
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              NormalSettingsItem(
                title: 'Debug Update',
                icon: Icon(Icons.download_rounded, color: colorScheme.primary),
                accent: colorScheme.primary,
                description: 'Trigger an update immediately',
                onTap: () {
                  final useTest = ref
                      .read(experimentalProvider)
                      .useTestReleases;
                  checkForUpdates(
                    context,
                    debugMode: true,
                    useTestReleases: useTest,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
