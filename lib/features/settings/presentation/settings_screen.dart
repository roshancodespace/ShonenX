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
                icon: Icons.extension_outlined,
                title: 'Extensions',
                subtitle: 'Aniyomi and Mangayomi extensions',
                onTap: () => context.push('/settings/extensions'),
              ),
              SettingsNavTile(
                icon: Icons.download_outlined,
                title: 'Downloads',
                subtitle: 'Download location, file naming',
                onTap: () => context.push('/settings/downloads'),
              ),
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

          SettingsSection(
            title: 'Misc',
            children: [
              SettingsNavTile(
                icon: Icons.storage_outlined,
                title: 'Cache Manager',
                subtitle: 'Clear cache and thumbnails',
                onTap: () => context.push('/settings/cache'),
              ),
            ],
          ),

          SettingsSection(
            title: 'Advanced',
            children: [
              SettingsNavTile(
                icon: Icons.bug_report_outlined,
                title: 'Debug',
                subtitle: 'Test notifications and UI components',
                onTap: () => context.push('/settings/debug'),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
