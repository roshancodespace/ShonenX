import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Settings',
      body: ListView(
        children: [
          SettingsSection(
            title: 'General',
            children: [
              SettingsNavTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: 'Theme, pure black, accent colors',
                onTap: () => context.push('/settings/theme'),
              ),
              SettingsNavTile(
                icon: Icons.video_settings_outlined,
                title: 'Player',
                subtitle: 'Gestures, default quality, skips',
                onTap: () => context.push('/settings/player'),
              ),
              SettingsNavTile(
                icon: Icons.chrome_reader_mode_outlined,
                title: 'Reader',
                subtitle: 'Reading mode, background, scale',
                onTap: () => context.push('/settings/reader'),
              ),
              SettingsNavTile(
                icon: Icons.extension_outlined,
                title: 'Extensions',
                subtitle: 'External runtime engines & native sources',
                onTap: () => context.push('/settings/extensions'),
                onLongPress: () =>
                    context.push('/settings/remote_config_editor'),
              ),
              SettingsNavTile(
                icon: Icons.download_outlined,
                title: 'Downloads',
                subtitle: 'Download location, file naming',
                onTap: () => context.push('/settings/downloads'),
              ),
              SettingsNavTile(
                icon: Icons.filter_alt_outlined,
                title: 'Content',
                subtitle: 'Content filters, 18+ toggle',
                onTap: () => context.push('/settings/content'),
              ),
              if (Platform.isAndroid) ...[
                SettingsNavTile(
                  icon: Icons.security_outlined,
                  title: 'Permissions',
                  subtitle: 'Manage app permissions',
                  onTap: () => context.push('/settings/permissions'),
                ),
              ],
            ],
          ),

          SettingsSection(
            title: 'Data & Sync',
            children: [
              SettingsNavTile(
                icon: Icons.sync_outlined,
                title: 'Tracking',
                subtitle: 'AniList, MyAnimeList connections',
                onTap: () => context.push('/settings/tracking'),
              ),
              SettingsNavTile(
                icon: Icons.import_export_outlined,
                title: 'Backup & Restore',
                subtitle: 'Export or import your data',
                onTap: () => context.push('/settings/backup'),
              ),
            ],
          ),

          SettingsSection(
            title: 'UI',
            children: [
              SettingsNavTile(
                icon: Icons.view_comfortable_outlined,
                title: 'UI',
                subtitle: 'UI settings',
                onTap: () => context.push('/settings/ui'),
              ),
              SettingsNavTile(
                icon: Icons.home_outlined,
                title: 'Home',
                subtitle: 'Home screen settings',
                onTap: () => context.push('/settings/home'),
              ),
            ],
          ),

          if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
            SettingsSection(
              title: 'Notifications',
              children: [
                SettingsNavTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Manage Notifications',
                  subtitle: 'Manage your active subscriptions and reminders',
                  onTap: () => context.push('/settings/notifications'),
                ),
              ],
            ),

          SettingsSection(
            title: 'Misc',
            children: [
              SettingsNavTile(
                icon: Icons.storage_outlined,
                title: 'Cache Manager',
                subtitle: 'Clear cache and thumbnails',
                onTap: () => context.push('/settings/cache'),
              ),
              SettingsNavTile(
                icon: Icons.system_update_outlined,
                title: 'Updates',
                subtitle: 'Check for updates and pre-release preferences',
                onTap: () => context.push('/settings/updates'),
              ),
              SettingsNavTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: 'Version, developer, and links',
                onTap: () => context.push('/settings/about'),
              ),
            ],
          ),

          SettingsSection(
            title: 'Advanced',
            children: [
              SettingsNavTile(
                icon: Icons.auto_fix_high_outlined,
                title: 'Troubleshoot & Repair',
                subtitle: 'Force fix missing episodes and broken matches',
                onTap: () => context.push('/settings/troubleshoot'),
              ),
              SettingsNavTile(
                icon: Icons.bug_report_outlined,
                title: 'Debug',
                subtitle: 'Test notifications and UI components',
                onTap: () => context.push('/settings/debug'),
              ),
              SettingsNavTile(
                icon: Icons.article_outlined,
                title: 'Logs',
                subtitle: 'View, copy, and export app logs',
                onTap: () => context.push('/settings/logs'),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
