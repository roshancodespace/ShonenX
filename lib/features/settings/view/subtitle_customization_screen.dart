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
    final colorScheme = Theme.of(context).colorScheme;
    final hasShadow = watchTheme(ref, (s) => s.hasShadow);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.arrow_left_2)),
        title: const Text('Subtitle Customization'),
        forceMaterialTransparency: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SettingsSection(
            title: 'Text',
            titleColor: colorScheme.primary,
            children: [
              SliderSettingsItem(
                icon: Icon(Iconsax.text, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Font Size',
                description: '${watchTheme(ref, (s) => s.fontSize).round()}px',
                value: watchTheme(ref, (s) => s.fontSize),
                min: 12,
                max: 50,
                divisions: 38,
                suffix: 'px',
                onChanged: (value) => subtitleNotifier.updateSettings(
                  (prev) => prev.copyWith(fontSize: value),
                ),
              ),
              DropdownSettingsItem(
                icon: Icon(Iconsax.text_block, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Font Family',
                description: watchTheme(ref, (s) => s.fontFamily) ?? 'Default',
                layoutType: SettingsItemLayout.horizontal,
                value: watchTheme(ref, (s) => s.fontFamily) ?? 'Default',
                items: const ['Default', 'Roboto', 'OpenSans', 'Montserrat']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) => subtitleNotifier.updateSettings(
                  (prev) => prev.copyWith(fontFamily: value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: 'Style',
            titleColor: colorScheme.primary,
            children: [
              ToggleableSettingsItem(
                icon: Icon(Iconsax.text_bold, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Bold Text',
                description: 'Make subtitle text bold',
                value: watchTheme(ref, (s) => s.boldText),
                onChanged: (value) => subtitleNotifier.updateSettings(
                  (prev) => prev.copyWith(boldText: value),
                ),
              ),
              ToggleableSettingsItem(
                icon: Icon(Iconsax.arrow_up_3, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Force Uppercase',
                description: 'Render all text in capital letters',
                value: watchTheme(ref, (s) => s.forceUppercase),
                onChanged: (value) => subtitleNotifier.updateSettings(
                  (prev) => prev.copyWith(forceUppercase: value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: 'Appearance',
            titleColor: colorScheme.primary,
            children: [
              SliderSettingsItem(
                icon: Icon(Iconsax.square, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Background Opacity',
                description:
                    '${(watchTheme(ref, (s) => s.backgroundOpacity) * 100).round()}%',
                value: watchTheme(ref, (s) => s.backgroundOpacity),
                min: 0,
                max: 1,
                onChanged: (value) => subtitleNotifier.updateSettings(
                  (prev) => prev.copyWith(backgroundOpacity: value),
                ),
              ),
              ToggleableSettingsItem(
                icon: Icon(Iconsax.ghost, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Text Shadow',
                description: 'Add a drop shadow for better visibility',
                value: hasShadow,
                onChanged: (value) => subtitleNotifier.updateSettings(
                  (prev) => prev.copyWith(hasShadow: value),
                ),
              ),
            ],
          ),
          // Conditionally show shadow settings with an animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1.0,
                child: child,
              );
            },
            child: hasShadow
                ? Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: SettingsSection(
                      title: 'Shadow Details',
                      titleColor: colorScheme.primary,
                      children: [
                        SliderSettingsItem(
                          icon: Icon(Iconsax.eye, color: colorScheme.primary),
                          accent: colorScheme.primary,
                          title: 'Shadow Opacity',
                          description:
                              '${(watchTheme(ref, (s) => s.shadowOpacity) * 100).round()}%',
                          value: watchTheme(ref, (s) => s.shadowOpacity),
                          min: 0,
                          max: 1,
                          onChanged: (value) => subtitleNotifier.updateSettings(
                            (prev) => prev.copyWith(shadowOpacity: value),
                          ),
                        ),
                        SliderSettingsItem(
                          icon: Icon(Iconsax.blur, color: colorScheme.primary),
                          accent: colorScheme.primary,
                          title: 'Shadow Blur',
                          description:
                              '${watchTheme(ref, (s) => s.shadowBlur).toStringAsFixed(1)}px',
                          value: watchTheme(ref, (s) => s.shadowBlur),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          suffix: 'px',
                          onChanged: (value) => subtitleNotifier.updateSettings(
                            (prev) => prev.copyWith(shadowBlur: value),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: 'Position',
            titleColor: colorScheme.primary,
            children: [
              SegmentedToggleSettingsItem<int>(
                accent: colorScheme.primary,
                iconColor: colorScheme.primary,
                title: 'Vertical Position',
                description: 'Align subtitles to the top, center, or bottom',
                selectedValue: watchTheme(ref, (s) => s.position),
                onValueChanged: (value) {
                  subtitleNotifier.updateSettings(
                    (prev) => prev.copyWith(position: value),
                  );
                },
                children: const {
                  3: Icon(Iconsax.arrow_up_2),
                  2: Icon(Iconsax.minus),
                  1: Icon(Iconsax.arrow_down_2),
                },
                labels: const {
                  3: 'Top',
                  2: 'Center',
                  1: 'Bottom',
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
