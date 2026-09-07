import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/services/notification_service.dart';
import 'package:shonenx/core/updates/models/github_release.dart';
import 'package:shonenx/core/updates/ui/android_update_widget.dart';
import 'package:shonenx/core/updates/ui/linux_update_widget.dart';
import 'package:shonenx/core/updates/ui/update_ui.dart';
import 'package:shonenx/core/updates/ui/windows_update_widget.dart';
import 'package:shonenx/features/discord/presentation/discord_login_page.dart';
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
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          SettingsSection(
            title: 'Web & Webview Debug',
            children: [
              SettingsActionTile(
                icon: Icons.discord,
                title: 'Test Discord Webview Login',
                subtitle: 'Launch Discord login webview directly',
                onTap: () {
                  context.showDiscordLogin((token) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Token Extracted: ${token.substring(0, 10)}...',
                        ),
                      ),
                    );
                  });
                },
              ),
            ],
          ),

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
                        onPressed: () => context.goOnboarding(),
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
          SettingsSection(
            title: 'Updater UI Previews (Debug)',
            children: [
              SettingsActionTile(
                icon: Icons.window_rounded,
                title: 'Preview Windows Updater UI',
                subtitle:
                    'Simulate Windows in-app installer download, progress, and auto-launch',
                onTap: () {
                  WindowsUpdateWidget.show(
                    context,
                    release: _mockRelease,
                    isPreview: true,
                  );
                },
              ),
              SettingsActionTile(
                icon: Icons.terminal_rounded,
                title: 'Preview Linux Updater UI',
                subtitle:
                    'Simulate Linux 1-click update, download progress, and restart',
                onTap: () {
                  LinuxUpdateWidget.show(
                    context,
                    release: _mockRelease,
                    autoStart: false,
                    isPreview: true,
                  );
                },
              ),
              SettingsActionTile(
                icon: Icons.install_mobile_rounded,
                title: 'Preview Android Updater UI',
                subtitle: 'Open Android APK download and install sheet',
                onTap: () {
                  AndroidUpdateWidget.show(context, release: _mockRelease);
                },
              ),
              SettingsActionTile(
                icon: Icons.system_update_rounded,
                title: 'Preview Update Available Sheet',
                subtitle:
                    'Open the full release announcement sheet with markdown changelog',
                onTap: () {
                  UpdateUI.showReleaseSheet(
                    context,
                    release: _mockRelease,
                    onDismiss: () {},
                    onDownload: () {},
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  static final _mockRelease = GitHubRelease(
    id: 999999,
    tagName: 'v2.2.0-preview',
    name: 'ShonenX v2.2.0 (Preview Release)',
    body:
        '### What\'s New in v2.2.0\n'
        '- **Windows In-App Updater**: Direct .exe download and auto-launch\n'
        '- **Linux Live Terminal**: Real-time installation logs and 1-click restart\n'
        '- **Performance**: Optimized startup time and extensions bridge\n'
        '- **Bug Fixes**: Clean uninstallation and cache purging',
    prerelease: true,
    draft: false,
    publishedAt: DateTime(2026, 9, 8),
    htmlUrl: 'https://github.com/roshancodespace/ShonenX/releases',
    assets: const [
      ReleaseAsset(
        name: 'ShonenX-x86_64-2.2.0-Installer.exe',
        downloadUrl:
            'https://github.com/roshancodespace/ShonenX/releases/download/v2.2.0/ShonenX-x86_64-2.2.0-Installer.exe',
        size: 50855936,
      ),
      ReleaseAsset(
        name: 'ShonenX-linux.zip',
        downloadUrl:
            'https://github.com/roshancodespace/ShonenX/releases/download/v2.2.0/ShonenX-linux.zip',
        size: 54525952,
      ),
      ReleaseAsset(
        name: 'ShonenX-arm64-v8a-release.apk',
        downloadUrl:
            'https://github.com/roshancodespace/ShonenX/releases/download/v2.2.0/ShonenX-arm64-v8a-release.apk',
        size: 33554432,
      ),
    ],
  );
}
