import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/widgets/svg_icon.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ColorScheme.of(context);

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 50),
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
          SettingsSection(
            title: 'Support',
            children: [
              SettingsActionTile(
                leading: SvgIcon(
                  '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
                      <path d="M0 0h24v24H0z" fill="none" />
                      <path fill="currentColor" d="M12 8.07v-.01c-.01 0-.03.02-.04.03h.02Zm-.02 12.51h.01s.02-.03.03-.04c-.02 0-.03.02-.05.04Zm.03.12s-.03-.02-.05-.02c.01 0 .03.01.04.02Zm2.25-.66c.23-.21.37-.51.4-.82l.78-8.29c-.35-.12-.7-.2-1.1-.2c-.69 0-1.24.24-1.88.51c-.72.31-1.53.66-2.59.66c-.44 0-.88-.06-1.31-.18l.73 7.5c.03.31.17.61.4.82s.53.33.85.33c0 0 1.04.05 1.38.05c.37 0 1.49-.05 1.49-.05c.31 0 .62-.12.85-.33M12.01 8.05l-.02-.02H12v.02Z" />
                      <path fill="currentColor" d="M18.74 6.79c-.1-.5-.32-.97-.83-1.15c-.16-.06-.35-.08-.48-.2s-.16-.3-.19-.48c-.05-.32-.1-.63-.16-.94c-.05-.27-.09-.57-.21-.82c-.16-.33-.5-.53-.83-.66c-.17-.06-.34-.12-.52-.16c-.83-.22-1.71-.3-2.56-.35c-1.03-.06-2.06-.04-3.08.05c-.76.07-1.57.15-2.29.42c-.27.1-.54.21-.74.42c-.25.25-.33.64-.15.95c.13.22.35.38.58.48c.3.13.61.24.94.3c.9.2 1.82.28 2.74.31c1.01.04 2.03 0 3.04-.1c.25-.03.5-.06.75-.1c.29-.04.48-.43.39-.7c-.1-.32-.38-.44-.7-.39c-.05 0-.09.01-.14.02h-.03c-.11.02-.21.03-.32.04l-.66.06c-.49.03-.99.05-1.49.05c-.49 0-.97-.01-1.46-.05q-.33-.015-.66-.06l-.3-.03h-.1l-.02-.02h-.1l-.6-.12c-.02 0-.04-.02-.05-.03c-.01-.02-.02-.04-.02-.06s0-.04.02-.06c.01-.02.03-.03.05-.03c.17-.04.35-.07.52-.1c.06 0 .12-.02.18-.03c.11 0 .22-.03.33-.04c.95-.1 1.9-.13 2.85-.1c.46.01.92.04 1.39.09l.3.03c.04 0 .08 0 .11.01h.08c.22.04.44.08.66.13c.33.07.75.09.89.45c.05.11.07.24.09.36l.03.15c.08.36.15.72.23 1.08v.08c0 .03-.02.05-.03.07s-.04.04-.06.06c-.02.01-.05.02-.08.03H16l-.05.01c-.15.02-.3.04-.44.05l-.87.09q-.87.075-1.74.09c-.3 0-.59.01-.89.01c-1.18 0-2.36-.07-3.53-.21c-.12-.01-.24-.03-.36-.04c-.02 0-.11-.01-.13-.02c-.08-.01-.16-.02-.24-.04c-.27-.04-.54-.09-.81-.13c-.33-.05-.64-.03-.94.13c-.24.13-.44.34-.56.58c-.13.26-.17.55-.22.83c-.06.28-.15.59-.11.88c.07.63.51 1.14 1.14 1.25a33 33 0 0 0 8.88.37l.58-.06c.06 0 .12 0 .18.02s.11.05.15.09s.08.09.1.15s.03.12.02.18l-.06.58l-.36 3.52c-.13 1.23-.25 2.46-.38 3.7c-.04.35-.07.69-.11 1.04c-.03.34-.04.69-.1 1.03c-.1.53-.46.86-.99.98c-.48.11-.97.17-1.46.17c-.55 0-1.09-.02-1.64-.02c-.58 0-1.3-.05-1.75-.48c-.4-.38-.45-.98-.5-1.49l-.21-2.05l-.4-3.8l-.26-2.46s0-.08-.01-.12c-.03-.29-.24-.58-.57-.57c-.28.01-.6.25-.57.57l.19 1.82l.39 3.77l.33 3.21l.06.62c.12 1.12.98 1.72 2.04 1.89c.62.1 1.25.12 1.88.13c.81.01 1.62.04 2.41-.1c1.17-.22 2.05-1 2.18-2.21c.04-.35.07-.7.11-1.05l.36-3.48l.39-3.79l.18-1.74c0-.09.05-.17.1-.23s.14-.11.22-.12c.34-.07.66-.18.89-.43c.38-.41.46-.94.32-1.47l-.11-.56ZM6.26 7.97s.01 0 .02.02zm11.36.01c-.12.11-.3.17-.48.19c-2.01.3-4.05.45-6.09.38c-1.46-.05-2.9-.21-4.34-.42c-.14-.02-.29-.05-.39-.15c-.06-.06-.08-.14-.1-.23v.01v-.01c-.03-.2.02-.43.05-.6c.04-.22.13-.51.39-.54c.4-.05.87.12 1.27.18c.48.07.96.13 1.45.18c2.07.19 4.17.16 6.23-.12c.38-.05.75-.11 1.12-.18c.33-.06.7-.17.9.17c.14.23.16.55.13.81c0 .12-.06.22-.14.3Z" />
                      <path fill="currentColor" d="M6.22 7.77c0-.02.01-.05 0-.05z" />
                    </svg>
                  ''',
                  color: ColorScheme.of(context).primary,
                  size: 24,
                ),
                title: 'Support Development',
                subtitle:
                    'Buy me a coffee to keep the project alive and ad-free!',
                onTap: () => launchUrl(
                  Uri.parse('https://buymeacoffee.com/roshan.codespace'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
