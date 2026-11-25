import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
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
                ? context.l10n.addonsUpdatesAvailable
                : context.l10n.addonsUpToDate,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.addonsCheckFailed(e.toString())),
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
        SnackBar(
          content: Text(context.l10n.addonsDownloadInProgress),
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
            content: Text(
              context.l10n.addonsInstallFailed(addon.name, e.toString()),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final action = await AppDialog.show<String>(
      context: context,
      title: addon.name,
      child: Text(
        addon.hasUpdate
            ? l10n.addonsUpdateAvailableDialog(addon.name)
            : l10n.addonsInstalledActiveDialog(addon.name),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        if (addon.hasUpdate)
          FilledButton(
            onPressed: () => Navigator.of(context).pop('update'),
            child: Text(l10n.addonsActionUpdate),
          ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
          ),
          onPressed: () => Navigator.of(context).pop('uninstall'),
          child: Text(l10n.addonsActionUninstall),
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
            content: Text(
              context.l10n.addonsUpdateFailed(addon.name, e.toString()),
            ),
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
            content: Text(context.l10n.addonsUninstalled(addon.name)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.addonsUninstallFailed(addon.name, e.toString()),
            ),
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
          context.l10n.addonsActionUpdate,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        );
      }
      return Text(
        context.l10n.addonsActionInstalled,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade500,
        ),
      );
    }

    return Text(
      context.l10n.addonsActionInstall,
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
    final l10n = context.l10n;

    return AppScaffold(
      title: l10n.settingsAddons,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          SettingsSection(
            title: l10n.addonsAvailableSection,
            children: [
              if (addons.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: Text(
                    l10n.addonsNoneRegistered,
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
            title: l10n.addonsMaintenanceSection,
            children: [
              SettingsActionTile(
                icon: Icons.sync_rounded,
                title: l10n.settingsCheckUpdates,
                subtitle: l10n.addonsCheckUpdatesSubtitle,
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
