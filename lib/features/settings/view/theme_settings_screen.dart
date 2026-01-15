import 'dart:io';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/settings/view_model/theme_notifier.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to rebuild the UI on state changes.
    final theme = ref.watch(themeSettingsProvider);
    final themeNotifier = ref.read(themeSettingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrentlyDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('Theme Settings'),
        forceMaterialTransparency: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSection(
                title: 'Appearance',
                titleColor: colorScheme.primary,
                children: [
                  SegmentedToggleSettingsItem<int>(
                    accent: colorScheme.primary,
                    iconColor: colorScheme.primary,
                    title: 'Theme Mode',
                    description: 'Choose your preferred theme',
                    selectedValue: theme.themeMode == 'light'
                        ? 1
                        : theme.themeMode == 'dark'
                        ? 2
                        : 0,
                    onValueChanged: (index) {
                      final newMode = index == 0
                          ? 'system'
                          : index == 1
                          ? 'light'
                          : 'dark';
                      themeNotifier.updateSettings(
                        (prev) => prev.copyWith(themeMode: newMode),
                      );
                    },
                    children: const {
                      0: Icon(Iconsax.monitor),
                      1: Icon(Iconsax.sun_1),
                      2: Icon(Iconsax.moon),
                    },
                    labels: const {0: 'System', 1: 'Light', 2: 'Dark'},
                    icon: const Icon(Iconsax.color_swatch),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: 'Colors',
                titleColor: colorScheme.primary,
                children: [
                  NormalSettingsItem(
                    icon: Icon(
                      Iconsax.colors_square,
                      color: colorScheme.primary,
                    ),
                    accent: colorScheme.primary,
                    title: 'Color Scheme',
                    description: _formatSchemeName(theme.flexScheme ?? ''),
                    onTap: () =>
                        _showColorSchemeSheet(context, ref, themeNotifier),
                  ),
                  if (theme.themeMode == 'dark' ||
                      (theme.themeMode == 'system' && isCurrentlyDark))
                    ToggleableSettingsItem(
                      icon: Icon(
                        Iconsax.colorfilter,
                        color: colorScheme.primary,
                      ),
                      accent: colorScheme.primary,
                      title: 'AMOLED Dark',
                      description: 'Use pure black for dark backgrounds',
                      value: theme.amoled,
                      onChanged: (value) {
                        themeNotifier.updateSettings(
                          (prev) => prev.copyWith(amoled: value),
                        );
                      },
                    ),
                  ToggleableSettingsItem(
                    icon: Icon(Iconsax.arrow_swap, color: colorScheme.primary),
                    accent: colorScheme.primary,
                    title: 'Swap Colors',
                    description: 'Swap primary and secondary colors',
                    value: theme.swapColors,
                    onChanged: (value) {
                      themeNotifier.updateSettings(
                        (prev) => prev.copyWith(swapColors: value),
                      );
                    },
                  ),
                  ToggleableSettingsItem(
                    icon: Icon(
                      Iconsax.color_swatch,
                      color: colorScheme.primary,
                    ),
                    accent: colorScheme.primary,
                    title:
                        'System Colors ${Platform.isAndroid ? '(A12+)' : ''}',
                    description: 'Use colors from your wallpaper',
                    value: theme.useDynamicColors,
                    onChanged: (value) async {
                      themeNotifier.updateSettings(
                        (prev) => prev.copyWith(useDynamicColors: value),
                      );
                    },
                  ),
                  ToggleableSettingsItem(
                    icon: Icon(Iconsax.magicpen, color: colorScheme.primary),
                    accent: colorScheme.primary,
                    title: 'Material 3',
                    description: 'Use the latest Material 3 design system',
                    value: theme.useMaterial3,
                    onChanged: (value) {
                      themeNotifier.updateSettings(
                        (prev) => prev.copyWith(useMaterial3: value),
                      );
                    },
                  ),
                  SliderSettingsItem(
                    icon: Icon(
                      Icons.blender_outlined,
                      color: colorScheme.primary,
                    ),
                    accent: colorScheme.primary,
                    value: theme.blendLevel.toDouble(),
                    min: 0,
                    max: 40,
                    divisions: 40,
                    title: 'Blend Level',
                    description: 'Adjust the color blend intensity',
                    onChanged: (value) {
                      themeNotifier.updateSettings(
                        (prev) => prev.copyWith(blendLevel: value.toInt()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorSchemeSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeSettingsNotifier themeNotifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = ref.watch(themeSettingsProvider);

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Color Scheme',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: FlexScheme.values.length,
                      itemBuilder: (context, index) {
                        final scheme = FlexScheme.values[index];
                        final isSelected = theme.flexScheme == scheme.name;

                        return ListTile(
                          onTap: () {
                            themeNotifier.updateSettings(
                              (prev) => prev.copyWith(flexScheme: scheme.name),
                            );
                          },
                          leading: _buildMinimalPreview(scheme),
                          title: Text(_formatSchemeName(scheme.name)),
                          trailing: isSelected
                              ? Icon(
                                  Iconsax.tick_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMinimalPreview(FlexScheme scheme) {
    final colors = FlexThemeData.light(scheme: scheme).colorScheme;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Row(
          children: [
            Expanded(flex: 2, child: Container(color: colors.primary)),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: Container(color: colors.secondary)),
                  Expanded(child: Container(color: colors.tertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSchemeName(String name) {
    return name
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : word,
        )
        .join(' ');
  }
}
