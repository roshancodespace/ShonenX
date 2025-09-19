import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/settings/model/theme_model.dart';
import 'package:shonenx/features/settings/view_model/theme_notifier.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() =>
      _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  T watchTheme<T>(
    WidgetRef ref,
    T Function(ThemeModel s) selector,
  ) {
    return ref.watch(themeSettingsProvider.select(selector));
  }

  @override
  Widget build(BuildContext context) {
    final themeSettingsNotifier = ref.read(themeSettingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
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
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Section
              SettingsSection(
                  title: 'Theme',
                  titleColor: colorScheme.primary,
                  children: [
                    SettingsItem(
                      icon: const Icon(Icons.palette),
                      accent: colorScheme.primary,
                      title: 'Theme',
                      description: 'Choose your preferred theme',
                      type: SettingsItemType.segmentedToggle,
                      segmentedSelectedIndex:
                          watchTheme(ref, (t) => t.themeMode) == 'light'
                              ? 1
                              : watchTheme(ref, (t) => t.themeMode) == 'dark'
                                  ? 2
                                  : 0,
                      segmentedOptions: const [
                        Icon(Icons.brightness_auto),
                        Icon(Icons.light_mode),
                        Icon(Icons.dark_mode),
                      ],
                      segmentedLabels: const ['System', 'Light', 'Dark'],
                      onSegmentedChanged: (index) {
                        setState(() {
                          themeSettingsNotifier
                              .updateSettings((prev) => prev.copyWith(
                                  themeMode: index == 0
                                      ? 'system'
                                      : index == 1
                                          ? 'light'
                                          : 'dark'));
                        });
                      },
                    ),
                  ]),
              const SizedBox(height: 15),
              SettingsSection(
                  title: 'Advanced',
                  titleColor: colorScheme.primary,
                  children: [
                    if (watchTheme(ref, (t) => t.themeMode) == 'dark' ||
                        (watchTheme(ref, (t) => t.themeMode) == 'system' &&
                            Theme.of(context).brightness ==
                                Brightness.dark)) ...[
                      SettingsItem(
                        icon: Icon(Iconsax.colorfilter,
                            color: colorScheme.primary),
                        accent: colorScheme.primary,
                        title: 'AMOLED Dark',
                        description: 'Use pure black for dark mode',
                        type: SettingsItemType.toggleable,
                        toggleValue: watchTheme(ref, (t) => t.amoled),
                        onToggleChanged: (value) {
                          themeSettingsNotifier.updateSettings(
                              (prev) => prev.copyWith(amoled: value));
                        },
                      )
                    ],
                    SettingsItem(
                      icon:
                          Icon(Iconsax.arrow_swap, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'Swap Colors',
                      description: 'Swap primary and secondary colors',
                      type: SettingsItemType.toggleable,
                      toggleValue: watchTheme(ref, (t) => t.swapColors),
                      onToggleChanged: (value) {
                        themeSettingsNotifier.updateSettings(
                            (prev) => prev.copyWith(swapColors: value));
                      },
                    ),
                    SettingsItem(
                      icon: Icon(Icons.colorize, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'Color Scheme',
                      description: 'Change the color scheme of the app',
                      onTap: () => _showColorSchemeSheet(context, ref),
                    ),
                    SettingsItem(
                      icon: Icon(Icons.blender_outlined,
                          color: colorScheme.primary),
                      accent: colorScheme.primary,
                      sliderValue:
                          watchTheme(ref, (t) => t.blendLevel).toDouble(),
                      sliderMin: 0,
                      sliderMax: 40,
                      sliderDivisions: 40,
                      sliderSuffix: '',
                      type: SettingsItemType.slider,
                      title: 'Blend Level',
                      description: 'Change the color blend level',
                      onSliderChanged: (value) {
                        themeSettingsNotifier.updateSettings(
                            (prev) => prev.copyWith(blendLevel: value.toInt()));
                      },
                    ),
                  ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorSchemeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final themeSettingsNotifier =
                ref.read(themeSettingsProvider.notifier);

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Color Scheme',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),

                  // Schemes list
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shrinkWrap: true,
                      itemCount: FlexScheme.values.length,
                      itemBuilder: (context, index) {
                        final scheme = FlexScheme.values[index];
                        final isSelected =
                            watchTheme(ref, (t) => t.flexScheme) == scheme.name;

                        return ListTile(
                          onTap: () {
                            themeSettingsNotifier.updateSettings(
                              (prev) => prev.copyWith(flexScheme: scheme.name),
                            );
                          },
                          leading: _buildMinimalPreview(scheme),
                          title: Text(_formatSchemeName(scheme.name)),
                          // The trailing icon will now update correctly.
                          trailing: isSelected
                              ? const Icon(Icons.check, size: 20)
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: colors.primary,
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.tertiary,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
  }
}
