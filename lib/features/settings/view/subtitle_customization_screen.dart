import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/settings/model/subtitle_appearance_model.dart';
import 'package:shonenx/features/settings/view_model/subtitle_notifier.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';

class SubtitleCustomizationScreen extends ConsumerWidget {
  const SubtitleCustomizationScreen({super.key});

  T watchTheme<T>(
    WidgetRef ref,
    T Function(SubtitleAppearanceModel s) selector,
  ) {
    return ref.watch(subtitleAppearanceProvider.select(selector));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    description:
                        '${ref.watch(subtitleAppearanceProvider.select((s) => s.fontSize)).round()}px',
                    type: SettingsItemType.slider,
                    sliderValue: watchTheme(ref, (s) => s.fontSize),
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
                    description:
                        watchTheme(ref, (s) => s.fontFamily) ?? 'Default',
                    layoutType: SettingsItemLayout.horizontal,
                    type: SettingsItemType.dropdown,
                    dropdownValue:
                        watchTheme(ref, (s) => s.fontFamily) ?? 'Default',
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
                    description:
                        watchTheme(ref, (s) => s.boldText) ? 'On' : 'Off',
                    type: SettingsItemType.toggleable,
                    toggleValue: watchTheme(ref, (s) => s.boldText),
                    onToggleChanged: (value) => subtitleNotifier.updateSettings(
                      (prev) => prev.copyWith(boldText: value),
                    ),
                  ),
                  SettingsItem(
                    icon: Icon(Iconsax.text,
                        color: Theme.of(context).colorScheme.primary),
                    accent: Theme.of(context).colorScheme.primary,
                    title: 'Force Uppercase',
                    description:
                        watchTheme(ref, (s) => s.forceUppercase) ? 'On' : 'Off',
                    type: SettingsItemType.toggleable,
                    toggleValue: watchTheme(ref, (s) => s.forceUppercase),
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
                        '${(watchTheme(ref, (s) => s.backgroundOpacity) * 100).round()}%',
                    type: SettingsItemType.slider,
                    sliderValue: watchTheme(ref, (s) => s.backgroundOpacity),
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
                    description:
                        watchTheme(ref, (s) => s.hasShadow) ? 'On' : 'Off',
                    type: SettingsItemType.toggleable,
                    toggleValue: watchTheme(ref, (s) => s.hasShadow),
                    onToggleChanged: (value) => subtitleNotifier.updateSettings(
                      (prev) => prev.copyWith(hasShadow: value),
                    ),
                  ),
                ]),
            if (watchTheme(ref, (s) => s.hasShadow)) ...[
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
                          '${(watchTheme(ref, (s) => s.shadowOpacity) * 100).round()}%',
                      type: SettingsItemType.slider,
                      sliderValue: watchTheme(ref, (s) => s.shadowOpacity),
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
                          '${watchTheme(ref, (s) => s.shadowBlur).toStringAsFixed(1)}px',
                      type: SettingsItemType.slider,
                      sliderValue: watchTheme(ref, (s) => s.shadowBlur),
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
                      description: watchTheme(ref, (s) => s.position) == 3
                          ? 'Top'
                          : watchTheme(ref, (s) => s.position) == 2
                              ? 'Center'
                              : 'Bottom',
                      layoutType: SettingsItemLayout.horizontal,
                      type: SettingsItemType.dropdown,
                      dropdownValue: watchTheme(ref, (s) => s.position) == 3
                          ? 'Top'
                          : watchTheme(ref, (s) => s.position) == 2
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
