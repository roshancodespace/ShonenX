import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/models/app_theme_preset.dart';
import 'package:shonenx/shared/models/built_in_presets.dart';
import 'package:shonenx/shared/providers/preset_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class PresetGallerySheet extends ConsumerStatefulWidget {
  const PresetGallerySheet({super.key});

  static void show(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      title: 'Preset Gallery',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InkWell(
              onTap: () => setState(() => _selectedSegment = 0),
              borderRadius: BorderRadius.circular(50),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _selectedSegment == 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: _selectedSegment == 0
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Curated (${BuiltInPresets.all.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedSegment == 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedSegment == 0
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () => setState(() => _selectedSegment = 1),
              borderRadius: BorderRadius.circular(50),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _selectedSegment == 1
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.dashboard_customize_rounded,
                      size: 14,
                      color: _selectedSegment == 1
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Custom (${presetState.customPresets.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedSegment == 1
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedSegment == 1
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDynamicMarketplaceActions(context, ref, theme),
        const SizedBox(height: 14),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (_selectedSegment == 0) ...[
                Text(
                  'BUILT-IN THEMES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                ...BuiltInPresets.all.map(
                  (preset) => _PresetCard(
                    preset: preset,
                    isActive: false,
                    onTap: () {
                      notifier.applyPreset(preset);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Loaded preset: ${preset.name}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onExport: () => _showExportDialog(context, ref, preset),
                  ),
                ),
              ] else ...[
                Text(
                  'YOUR CUSTOM THEMES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                if (presetState.customPresets.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.dashboard_customize_outlined,
                          size: 36,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No custom presets yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use "Create Theme" above or import a .json theme from the community.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...presetState.customPresets.map(
                    (preset) => _PresetCard(
                      preset: preset,
                      isActive: false,
                      isCustom: true,
                      onTap: () {
                        notifier.applyPreset(preset);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Loaded preset: ${preset.name}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onExport: () => _showExportDialog(context, ref, preset),
                      onDelete: () {
                        notifier.deleteCustomPreset(preset.id);
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicMarketplaceActions(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          onTap: () => _showSaveDialog(context, ref),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark_add_rounded,
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Snapshot Current',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () => _showImportDialog(context, ref),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.file_download_outlined,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Import JSON',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () => _showExportDialog(context, ref),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.share_outlined,
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Export',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
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

    AppBottomSheet.show<void>(
      context: context,
      title: targetPreset != null
          ? 'Export Preset JSON'
          : 'Export Current Theme',
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              targetPreset != null
                  ? 'Customize the metadata before exporting "${targetPreset.name}" to clipboard:'
                  : 'Customize the metadata before exporting your current theme settings to clipboard:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                hintText: 'e.g. Neon Horizon',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(
                labelText: 'Author / Creator',
                hintText: 'e.g. @username or Me',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Brief summary of your theme aesthetic',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
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
                          'Copied "$name" JSON by ${exportPreset.author} to clipboard!',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy JSON'),
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
    AppBottomSheet.show<void>(
      context: context,
      title: 'Import Theme (.json)',
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Paste a ShonenX Theme JSON code below:',
                    style: TextStyle(fontSize: 13),
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
                  label: const Text(
                    'Paste Clipboard',
                    style: TextStyle(fontSize: 12),
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
                  child: const Text('Cancel'),
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
                            'Saved "${preset.name}" to Custom Themes (not applied).',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid JSON format: ${e.toString()}'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Only'),
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
                            'Successfully installed & applied "${preset.name}"!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid JSON format: ${e.toString()}'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Install & Apply'),
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

    AppBottomSheet.show<void>(
      context: context,
      title: 'Snapshot Current Theme',
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                hintText: 'e.g. Neon Horizon',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(
                labelText: 'Author / Creator',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
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
                          'Saved "${preset.name}" to your presets!',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Save Snapshot'),
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

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: isActive,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: theme.colorScheme.primary,
              size: 19,
            ),
            tooltip: 'Export / Share JSON',
            onPressed: onExport,
          ),
          if (isCustom && onDelete != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
                size: 19,
              ),
              tooltip: 'Delete Preset',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
