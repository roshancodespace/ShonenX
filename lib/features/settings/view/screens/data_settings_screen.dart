import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/network/universal_client.dart';
import 'package:shonenx/core/services/backup_service.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';

class DataSettingsScreen extends ConsumerStatefulWidget {
  const DataSettingsScreen({super.key});

  @override
  ConsumerState<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends ConsumerState<DataSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('Data & Storage'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SettingsSection(
            title: 'Cache',
            titleColor: colorScheme.primary,
            onTap: () {},
            children: [
              NormalSettingsItem(
                icon: Icon(Iconsax.image, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Clear Image Cache',
                description: 'Free up space by clearing cached images',
                onTap: () async {
                  await CachedNetworkImage.evictFromCache('');
                  imageCache.clear();
                  imageCache.clearLiveImages();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image cache cleared')),
                    );
                  }
                },
              ),
              NormalSettingsItem(
                icon: Icon(Iconsax.global, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Clear API Cache',
                description: 'Clear cached network responses',
                onTap: () async {
                  await UniversalHttpClient.instance.clearCache();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API cache cleared')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SettingsSection(
            title: 'Backup & Restore',
            titleColor: colorScheme.primary,
            onTap: () {},
            children: [
              NormalSettingsItem(
                icon: Icon(Iconsax.export, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Export Data',
                description: 'Create a backup of your data',
                onTap: () => _showExportDialog(context),
              ),
              NormalSettingsItem(
                icon: Icon(Iconsax.import, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Import Data',
                description: 'Restore data from a backup file',
                onTap: () => _importData(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    bool includeWatchlist = true;
    bool includeSettings = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Export Data'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: includeWatchlist,
                    onChanged: (v) => setState(() => includeWatchlist = v!),
                    title: const Text('Watchlist & Progress'),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  CheckboxListTile(
                    value: includeSettings,
                    onChanged: (v) => setState(() => includeSettings = v!),
                    title: const Text('App Settings'),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _exportData(context, includeWatchlist, includeSettings);
                  },
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportData(
    BuildContext context,
    bool watchlist,
    bool settings,
  ) async {
    try {
      await ref
          .read(backupServiceProvider)
          .exportData(includeWatchlist: watchlist, includeSettings: settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export completed successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      await ref.read(backupServiceProvider).importData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import completed. Please restart app.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
