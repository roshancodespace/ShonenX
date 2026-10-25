import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/addon_service.dart';
import 'package:shonenx/source_engine/models/addon_info.dart';

class AddonsSettingsScreen extends ConsumerStatefulWidget {
  const AddonsSettingsScreen({super.key});

  @override
  ConsumerState<AddonsSettingsScreen> createState() =>
      _AddonsSettingsScreenState();
}

class _AddonsSettingsScreenState extends ConsumerState<AddonsSettingsScreen> {
  bool _isCheckingUpdates = false;

  Future<void> _checkForUpdates() async {
    if (_isCheckingUpdates) return;
    setState(() => _isCheckingUpdates = true);

    try {
      await ref.read(addonListProvider.notifier).checkForUpdates();
      if (!mounted) return;

      final addons = ref.read(addonListProvider);
      final hasAnyUpdate = addons.any((a) => a.hasUpdate);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasAnyUpdate
                ? 'Updates available for addons.'
                : 'All addons are up to date.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check for updates: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdates = false);
      }
    }
  }

  Future<void> _handleTap(AddonInfo addon) async {
    if (addon.isDownloading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download in progress...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!addon.isInstalled) {
      try {
        await ref.read(addonListProvider.notifier).install(addon.id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to install ${addon.name}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final cs = Theme.of(context).colorScheme;
    final action = await AppDialog.show<String>(
      context: context,
      title: addon.name,
      child: Text(
        addon.hasUpdate
            ? 'An update is available for ${addon.name}.'
            : '${addon.name} is installed and active.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (addon.hasUpdate)
          FilledButton(
            onPressed: () => Navigator.of(context).pop('update'),
            child: const Text('Update'),
          ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
          ),
          onPressed: () => Navigator.of(context).pop('uninstall'),
          child: const Text('Uninstall'),
        ),
      ],
    );

    if (!mounted || action == null) return;

    if (action == 'update') {
      try {
        await ref.read(addonListProvider.notifier).update(addon.id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ${addon.name}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (action == 'uninstall') {
      try {
        await ref.read(addonListProvider.notifier).uninstall(addon.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uninstalled ${addon.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to uninstall ${addon.name}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildTrailing(AddonInfo addon, ColorScheme cs) {
    if (addon.isDownloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: addon.downloadProgress > 0 ? addon.downloadProgress : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(addon.downloadProgress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
        ],
      );
    }

    if (addon.isInstalled) {
      if (addon.hasUpdate) {
        return Text(
          'Update',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        );
      }
      return Text(
        'Installed',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade500,
        ),
      );
    }

    return Text(
      'Install',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: cs.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addons = ref.watch(addonListProvider);
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Addons',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          SettingsSection(
            title: 'Available Addons',
            children: [
              if (addons.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: Text(
                    'No addons registered.',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                )
              else
                ...addons.map(
                  (addon) => SettingsActionTile(
                    icon: addon.icon,
                    title: addon.name,
                    subtitle: addon.description,
                    trailing: _buildTrailing(addon, cs),
                    onTap: () => _handleTap(addon),
                  ),
                ),
            ],
          ),
          SettingsSection(
            title: 'Maintenance',
            children: [
              SettingsActionTile(
                icon: Icons.sync_rounded,
                title: 'Check for Updates',
                subtitle: 'Scan for new versions of installed addons',
                trailing: _isCheckingUpdates
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _isCheckingUpdates ? null : _checkForUpdates,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
