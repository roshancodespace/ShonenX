import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/updates/models/github_release.dart';
import 'package:shonenx/core/updates/services/update_service.dart';
import 'package:shonenx/core/updates/ui/linux_update_widget.dart';
import 'package:shonenx/core/updates/ui/update_ui.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class UpdateSettingsScreen extends ConsumerStatefulWidget {
  const UpdateSettingsScreen({super.key});

  @override
  ConsumerState<UpdateSettingsScreen> createState() =>
      _UpdateSettingsScreenState();
}

class _UpdateSettingsScreenState extends ConsumerState<UpdateSettingsScreen> {
  bool _isChecking = false;

  Future<void> _manualCheck() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final service = ref.read(updateServiceProvider);
      final release = await service.checkForUpdate(force: true);

      if (!mounted) return;

      if (release != null) {
        await UpdateUI.showReleaseUpdateSheet(
          context,
          release: release,
          onDismiss: () => ref
              .read(updatePrefsProvider.notifier)
              .setLastDismissedReleaseId(release.id),
          onDownload: () => ref
              .read(updatePrefsProvider.notifier)
              .setLastSeenReleaseId(release.id),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are using the latest version!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _showReleaseDetails(BuildContext context, GitHubRelease release) {
    UpdateUI.showReleaseSheet(context, release: release);
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(updatePrefsProvider);
    final notifier = ref.read(updatePrefsProvider.notifier);
    final releasesAsync = ref.watch(releasesListProvider);

    return AppScaffold(
      title: 'Updates',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(releasesListProvider);
          await ref.read(releasesListProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 50),
          children: [
            if (Platform.isLinux)
              SettingsSection(
                title: 'Linux Installation & Updater',
                children: [
                  SettingsActionTile(
                    icon: Icons.terminal_rounded,
                    title: 'Open Linux Update Manager',
                    subtitle:
                        'Interactive installer, custom repo/icon config, and live terminal output',
                    onTap: () => LinuxUpdateWidget.show(context),
                  ),
                ],
              ),
            SettingsSection(
              title: 'Check for Updates',
              children: [
                SettingsActionTile(
                  icon: Icons.sync_rounded,
                  title: 'Check now',
                  subtitle: 'Fetch the latest releases directly from GitHub',
                  trailing: _isChecking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : FilledButton.icon(
                          onPressed: _manualCheck,
                          icon: const Icon(Icons.sync_rounded, size: 18),
                          label: const Text('Check'),
                        ),
                  onTap: _manualCheck,
                ),
              ],
            ),
            SettingsSection(
              title: 'Preferences',
              children: [
                SettingsSwitchTile(
                  icon: Icons.new_releases_outlined,
                  title: 'Include Pre-releases',
                  subtitle: 'Receive early alpha, beta, and hotfix builds',
                  value: prefs.includePrerelease,
                  onChanged: (v) => notifier.setIncludePrerelease(v),
                ),
                SettingsSwitchTile(
                  icon: Icons.update_rounded,
                  title: 'Auto Check on Startup',
                  subtitle:
                      'Automatically check for updates when the application launches',
                  value: prefs.autoCheckOnStartup,
                  onChanged: (v) => notifier.setAutoCheckOnStartup(v),
                ),
              ],
            ),
            SettingsSection(
              title: 'Browse Releases',
              subtitle:
                  'Tap a release to view full changelog and download options',
              children: [
                releasesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Failed to load releases.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  data: (releases) {
                    if (releases.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No releases found.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: releases.map((r) {
                        return SettingsActionTile(
                          icon: r.prerelease
                              ? Icons.extension_outlined
                              : Icons.verified_outlined,
                          title: r.name,
                          subtitle:
                              '${r.tagName} • ${_formatDate(r.publishedAt)}',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (r.prerelease)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'PRE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          onTap: () => _showReleaseDetails(context, r),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
