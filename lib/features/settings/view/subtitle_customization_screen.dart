import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/settings/view_model/subtitle_notifier.dart';
import 'package:shonenx/features/settings/widgets/settings_item.dart';
import 'package:shonenx/features/settings/widgets/settings_section.dart';

class SubtitleCustomizationScreen extends ConsumerWidget {
  const SubtitleCustomizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitleSettings = ref.watch(subtitleAppearanceProvider);
    final subtitleNotifier = ref.read(subtitleAppearanceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.arrow_left_2)),
        title: const Text('Subtitle Customization'),
        forceMaterialTransparency: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SettingsSection(
                title: 'Text',
                titleColor: Theme.of(context).colorScheme.primary,
                children: [
                  SettingsItem(
                    icon: Icon(Iconsax.text,
                        color: Theme.of(context).colorScheme.primary),
                    accent: Theme.of(context).colorScheme.primary,
                    title: 'Font Size',
                    description: '${subtitleSettings.fontSize.round()}px',
                    type: SettingsItemType.slider,
                    sliderValue: subtitleSettings.fontSize,
                    sliderMin: 12,
                    sliderMax: 50,
                    sliderDivisions: 38,
                    sliderSuffix: 'px',
                    onSliderChanged: (value) => subtitleNotifier.updateSettings(
                      (prev) => prev.copyWith(fontSize: value),
                    ),
                  ),
                  SettingsItem(
                    icon: Icon(Iconsax.text,
                        color: Theme.of(context).colorScheme.primary),
                    accent: Theme.of(context).colorScheme.primary,
                    title: 'Font Family',
                    description: subtitleSettings.fontFamily ?? 'Default',
                    layoutType: SettingsItemLayout.horizontal,
                    type: SettingsItemType.dropdown,
                    dropdownValue: subtitleSettings.fontFamily ?? 'Default',
                    dropdownItems: const [
                      'Default',
                      'Roboto',
                      'OpenSans',
                      'Montserrat'
                    ],
                    onDropdownChanged: (value) =>
                        subtitleNotifier.updateSettings(
                      (prev) => prev.copyWith(fontFamily: value),
                    ),
                  ),
                ]),
            const SizedBox(height: 20),
            SettingsSection(
                title: 'Style',
                titleColor: Theme.of(context).colorScheme.primary,
                children: [
                  SettingsItem(
                    icon: Icon(Iconsax.text_bold,
                        color: Theme.of(context).colorScheme.primary),
                    accent: Theme.of(context).colorScheme.primary,
                    title: 'Bold Text',
                    description: subtitleSettings.boldText ? 'On' : 'Off',
                    type: SettingsItemType.toggleable,
                    toggleValue: subtitleSettings.boldText,
                    onToggleChanged: (value) => subtitleNotifier.updateSettings(
                      (prev) => prev.copyWith(boldText: value),
                    ),
                  ),
                  SettingsItem(
                    icon: Icon(Iconsax.text,
                        color: Theme.of(context).colorScheme.primary),
                    accent: Theme.of(context).colorScheme.primary,
                    title: 'Force Uppercase',
                    description: subtitleSettings.forceUppercase ? 'On' : 'Off',
                    type: SettingsItemType.toggleable,
                    toggleValue: subtitleSettings.forceUppercase,
                    onToggleChanged: (value) => subtitleNotifier.updateSettings(
                      (prev) => prev.copyWith(forceUppercase: value),
                    ),
                  ),
                ]),
            const SizedBox(height: 20),
            SettingsSection(
                title: 'Background',
                titleColor: Theme.of(context).colorScheme.primary,
                children: [
                  SettingsItem(
                    icon: Icon(Iconsax.square,
                        color: Theme.of(context).colorScheme.primary),
                    accent: Theme.of(context).colorScheme.primary,
                    title: 'Opacity',
                    description:
                        '${(subtitleSettings.backgroundOpacity * 100).round()}%',
                    type: SettingsItemType.slider,
                    sliderValue: subtitleSettings.backgroundOpacity,
                    sliderMin: 0,
                    sliderMax: 1,
                    sliderDivisions: 10,
                    sliderSuffix: '%',
                    onSliderChanged: (value) => subtitleNotifier.updateSettings(
                      (prev) => prev.copyWith(backgroundOpacity: value),
                    ),
                  ),
                ]),
            const SizedBox(height: 20),
            SettingsSection(
                title: 'Shadow',
                titleColor: Theme.of(context).colorScheme.primary,
                children: [
                  SettingsItem(
                    icon: Icon(Iconsax.ghost,
                        color: Theme.of(context).colorScheme.primary),
                    accent: Theme.of(context).colorScheme.primary,
                    title: 'Enable Shadow',
                    description: subtitleSettings.hasShadow ? 'On' : 'Off',
                    type: SettingsItemType.toggleable,
                    toggleValue: subtitleSettings.hasShadow,
                    onToggleChanged: (value) => subtitleNotifier.updateSettings(
                      (prev) => prev.copyWith(hasShadow: value),
                    ),
                  ),
                ]),
            if (subtitleSettings.hasShadow) ...[
              const SizedBox(height: 20),
              SettingsSection(
                  title: 'Shadow Settings',
                  titleColor: Theme.of(context).colorScheme.primary,
                  children: [
                    SettingsItem(
                      icon: Icon(Iconsax.ghost,
                          color: Theme.of(context).colorScheme.primary),
                      accent: Theme.of(context).colorScheme.primary,
                      title: 'Opacity',
                      description:
                          '${(subtitleSettings.shadowOpacity * 100).round()}%',
                      type: SettingsItemType.slider,
                      sliderValue: subtitleSettings.shadowOpacity,
                      sliderMin: 0,
                      sliderMax: 1,
                      sliderDivisions: 10,
                      sliderSuffix: '%',
                      onSliderChanged: (value) =>
                          subtitleNotifier.updateSettings(
                        (prev) => prev.copyWith(shadowOpacity: value),
                      ),
                    ),
                    SettingsItem(
                      icon: Icon(Iconsax.ghost,
                          color: Theme.of(context).colorScheme.primary),
                      accent: Theme.of(context).colorScheme.primary,
                      title: 'Blur',
                      description:
                          '${subtitleSettings.shadowBlur.toStringAsFixed(1)}px',
                      type: SettingsItemType.slider,
                      sliderValue: subtitleSettings.shadowBlur,
                      sliderMin: 1,
                      sliderMax: 10,
                      sliderDivisions: 9,
                      sliderSuffix: 'px',
                      onSliderChanged: (value) =>
                          subtitleNotifier.updateSettings(
                        (prev) => prev.copyWith(shadowBlur: value),
                      ),
                    ),
                  ]),
              const SizedBox(height: 20),
              SettingsSection(
                  title: 'Position',
                  titleColor: Theme.of(context).colorScheme.primary,
                  children: [
                    SettingsItem(
                      icon: Icon(Iconsax.arrow_up_1,
                          color: Theme.of(context).colorScheme.primary),
                      accent: Theme.of(context).colorScheme.primary,
                      title: 'Position',
                      description: subtitleSettings.position == 3
                          ? 'Top'
                          : subtitleSettings.position == 2
                              ? 'Center'
                              : 'Bottom',
                      layoutType: SettingsItemLayout.horizontal,
                      type: SettingsItemType.dropdown,
                      dropdownValue: subtitleSettings.position == 3
                          ? 'Top'
                          : subtitleSettings.position == 2
                              ? 'Center'
                              : 'Bottom',
                      dropdownItems: const ['Top', 'Center', 'Bottom'],
                      onDropdownChanged: (value) =>
                          subtitleNotifier.updateSettings(
                        (prev) => prev.copyWith(
                          position: value == 'Top'
                              ? 3
                              : value == 'Center'
                                  ? 2
                                  : 1, // Fixed: Bottom should be 1, not 3
                        ),
                      ),
                    ),
                  ]),
            ],
          ],
        ),
      ),
    );
  }
}
