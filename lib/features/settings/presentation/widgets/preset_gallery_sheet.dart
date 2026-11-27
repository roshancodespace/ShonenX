import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/shared/models/app_theme_preset.dart';
import 'package:shonenx/shared/models/built_in_presets.dart';
import 'package:shonenx/shared/providers/preset_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_button_group.dart';
import 'package:shonenx/shared/widgets/app_card_group.dart';
import 'package:shonenx/shared/widgets/app_chip.dart';
import 'package:shonenx/shared/widgets/app_empty_state.dart';

class PresetGallerySheet extends ConsumerStatefulWidget {
  const PresetGallerySheet({super.key});

  static void show(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      title: context.l10n.presetsGalleryTitle,
      child: const PresetGallerySheet(),
    );
  }

  @override
  ConsumerState<PresetGallerySheet> createState() => _PresetGallerySheetState();
}

class _PresetGallerySheetState extends ConsumerState<PresetGallerySheet> {
  int _selectedSegment = 0; // 0: Curated, 1: Custom & Marketplace

  @override
  Widget build(BuildContext context) {
    final presetState = ref.watch(presetProvider);
    final notifier = ref.read(presetProvider.notifier);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButtonGroup<int>(
          segments: [
            ButtonSegment(
              value: 0,
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(
                l10n.presetsCuratedCount(BuiltInPresets.all.length.toString()),
              ),
            ),
            ButtonSegment(
              value: 1,
              icon: const Icon(Icons.dashboard_customize_rounded, size: 16),
              label: Text(
                l10n.presetsCustomCount(
                  presetState.customPresets.length.toString(),
                ),
              ),
            ),
          ],
          selected: {_selectedSegment},
          onSelectionChanged: (set) =>
              setState(() => _selectedSegment = set.first),
          expandSegments: true,
          height: 40,
        ),
        const SizedBox(height: 12),
        _buildDynamicMarketplaceActions(context, ref),
        const SizedBox(height: 14),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (_selectedSegment == 0) ...[
                Text(
                  l10n.presetsBuiltInHeader,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                AppCardGroup(
                  padding: EdgeInsets.zero,
                  children: BuiltInPresets.all
                      .map(
                        (preset) => _PresetCard(
                          preset: preset,
                          isActive: presetState.activePresetId == preset.id,
                          onTap: () {
                            notifier.applyPreset(preset);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.presetsLoadedSnack(preset.name),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          onExport: () =>
                              _showExportDialog(context, ref, preset),
                        ),
                      )
                      .toList(),
                ),
              ] else ...[
                Text(
                  l10n.presetsCustomHeader,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                if (presetState.customPresets.isEmpty)
                  AppEmptyState(
                    icon: Icons.dashboard_customize_outlined,
                    title: l10n.presetsNoCustomTitle,
                    subtitle: l10n.presetsNoCustomSubtitle,
                  )
                else
                  AppCardGroup(
                    padding: EdgeInsets.zero,
                    children: presetState.customPresets
                        .map(
                          (preset) => _PresetCard(
                            preset: preset,
                            isActive: presetState.activePresetId == preset.id,
                            isCustom: true,
                            onTap: () {
                              notifier.applyPreset(preset);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.presetsLoadedSnack(preset.name),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            onExport: () =>
                                _showExportDialog(context, ref, preset),
                            onDelete: () {
                              notifier.deleteCustomPreset(preset.id);
                            },
                          ),
                        )
                        .toList(),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicMarketplaceActions(BuildContext context, WidgetRef ref) {
    return AppChipGroup(
      children: [
        AppChip(
          icon: Icons.bookmark_add_rounded,
          label: context.l10n.presetsSnapshotCurrent,
          onTap: () => _showSaveDialog(context, ref),
        ),
        AppChip(
          icon: Icons.file_download_outlined,
          label: context.l10n.presetsImportJson,
          onTap: () => _showImportDialog(context, ref),
        ),
        AppChip(
          icon: Icons.share_outlined,
          label: context.l10n.presetsExport,
          onTap: () => _showExportDialog(context, ref),
        ),
      ],
    );
  }

  void _showExportDialog(
    BuildContext context,
    WidgetRef ref, [
    AppThemePreset? targetPreset,
  ]) {
    final nameController = TextEditingController(
      text: targetPreset?.name ?? 'My ShonenX Theme',
    );
    final authorController = TextEditingController(
      text: targetPreset?.author ?? '@roshancodespace',
    );
    final descController = TextEditingController(
      text: targetPreset?.description ?? 'Exported custom theme configuration.',
    );
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    AppBottomSheet.show<void>(
      context: context,
      title: targetPreset != null
          ? l10n.presetsExportPresetTitle
          : l10n.presetsExportCurrentTitle,
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              targetPreset != null
                  ? l10n.presetsExportPresetPrompt(targetPreset.name)
                  : l10n.presetsExportCurrentPrompt,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.presetsPresetName,
                hintText: 'e.g. Neon Horizon',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: authorController,
              decoration: InputDecoration(
                labelText: l10n.presetsAuthorCreator,
                hintText: 'e.g. @username or Me',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: l10n.presetsDescription,
                hintText: 'Brief summary of your theme aesthetic',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.commonCancel),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final author = authorController.text.trim();
                    final desc = descController.text.trim();
                    if (name.isEmpty) return;

                    AppThemePreset exportPreset;
                    if (targetPreset != null) {
                      final map = targetPreset.toMap();
                      map['name'] = name;
                      map['author'] = author.isEmpty ? 'Community' : author;
                      map['description'] = desc.isEmpty
                          ? 'A ShonenX theme.'
                          : desc;
                      exportPreset = AppThemePreset.fromMap(map);
                    } else {
                      final themePrefs = ref.read(themePrefsProvider);
                      final uiPrefs = ref.read(uiPrefsProvider);
                      exportPreset = AppThemePreset.fromStates(
                        id: 'custom_export_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        description: desc.isEmpty
                            ? 'Exported custom theme.'
                            : desc,
                        author: author.isEmpty ? 'Community' : author,
                        previewColors: [
                          cs.primary.toARGB32(),
                          cs.secondary.toARGB32(),
                          cs.surface.toARGB32(),
                        ],
                        themePrefs: themePrefs,
                        uiPrefs: uiPrefs,
                      );
                    }

                    Clipboard.setData(
                      ClipboardData(text: exportPreset.toJsonString()),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.presetsCopiedSnack(name, exportPreset.author),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(l10n.presetsCopyJson),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final l10n = context.l10n;
    AppBottomSheet.show<void>(
      context: context,
      title: l10n.presetsImportTitle,
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.presetsPasteBelow,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data != null && data.text != null) {
                      controller.text = data.text!;
                    }
                  },
                  icon: const Icon(Icons.content_paste_rounded, size: 15),
                  label: Text(
                    l10n.presetsPasteClipboard,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText:
                    '{\n  "name": "Marketplace Theme",\n  "author": "@username",\n  ...\n}',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.commonCancel),
                ),
                OutlinedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    try {
                      final preset = ref
                          .read(presetProvider.notifier)
                          .importPresetFromJson(text, apply: false);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.presetsSavedNotApplied(preset.name),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.presetsInvalidJson(e.toString()),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  },
                  child: Text(l10n.presetsSaveOnly),
                ),
                FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    try {
                      final preset = ref
                          .read(presetProvider.notifier)
                          .importPresetFromJson(text, apply: true);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.presetsInstalledApplied(preset.name),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.presetsInvalidJson(e.toString()),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  },
                  child: Text(l10n.presetsInstallApply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final authorController = TextEditingController(text: 'Me');
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    AppBottomSheet.show<void>(
      context: context,
      title: l10n.presetsSnapshotTitle,
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.presetsPresetName,
                hintText: 'e.g. Neon Horizon',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: authorController,
              decoration: InputDecoration(
                labelText: l10n.presetsAuthorCreator,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.commonCancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final preset = ref
                        .read(presetProvider.notifier)
                        .saveCustomPreset(
                          name: name,
                          author: authorController.text.trim().isEmpty
                              ? 'Me'
                              : authorController.text.trim(),
                          description: 'Custom user-saved theme preset.',
                          previewColors: [
                            cs.primary.toARGB32(),
                            cs.secondary.toARGB32(),
                            cs.surface.toARGB32(),
                          ],
                        );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.presetsSavedSnapshotSnack(preset.name),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(l10n.presetsSaveSnapshot),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final AppThemePreset preset;
  final bool isActive;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback onExport;
  final VoidCallback? onDelete;

  const _PresetCard({
    required this.preset,
    required this.isActive,
    this.isCustom = false,
    required this.onTap,
    required this.onExport,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCardSurface(
      color: isActive
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: preset.previewColors.take(3).map((c) {
            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        title: Text(
          preset.name,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? theme.colorScheme.primary : null,
          ),
        ),
        subtitle: Text(
          '${preset.cardStyle.displayName} • ${preset.author}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: AppActionButtonGroup(
          height: 34,
          items: [
            AppActionItem(
              icon: Icons.share_outlined,
              tooltip: context.l10n.presetsExportShareTooltip,
              onTap: onExport,
            ),
            if (isCustom && onDelete != null)
              AppActionItem(
                icon: Icons.delete_outline_rounded,
                tooltip: context.l10n.presetsDeleteTooltip,
                onTap: onDelete!,
              ),
          ],
        ),
      ),
    );
  }
}
