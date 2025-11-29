import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/settings/model/subtitle_appearance_model.dart';
import 'package:shonenx/features/settings/utils/subtitle_utils.dart';
import 'package:shonenx/features/settings/view_model/subtitle_notifier.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/features/settings/view/widgets/color_picker_item.dart';

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
      body: Column(
        children: [
          // Live Preview Area
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                image: const DecorationImage(
                  image: NetworkImage(
                      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/16498-8jpFCOcDmneX.jpg'),
                  fit: BoxFit.cover,
                  opacity: 0.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Gradient Overlay for better visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  // Subtitle Preview
                  _buildSubtitlePreview(ref),
                ],
              ),
            ),
          ),
          // Settings Controls
          Expanded(
            flex: 2,
            child: ListView(
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
                      description:
                          '${watchTheme(ref, (s) => s.fontSize).round()}px',
                      value: watchTheme(ref, (s) => s.fontSize),
                      min: 12,
                      max: 50,
                      divisions: 38,
                      suffix: 'px',
                      onChanged: (value) => subtitleNotifier.updateSettings(
                        (prev) => prev.copyWith(fontSize: value),
                      ),
                    ),
                    ColorPickerSettingsItem(
                      accent: colorScheme.primary,
                      title: 'Text Color',
                      description: 'Choose subtitle text color',
                      icon: Icon(Iconsax.color_swatch,
                          color: colorScheme.primary),
                      selectedColor: watchTheme(ref, (s) => s.textColor),
                      onColorChanged: (value) =>
                          subtitleNotifier.updateSettings(
                        (prev) => prev.copyWith(textColor: value),
                      ),
                    ),
                    DropdownSettingsItem(
                      icon:
                          Icon(Iconsax.text_block, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'Font Family',
                      description:
                          watchTheme(ref, (s) => s.fontFamily) ?? 'Default',
                      layoutType: SettingsItemLayout.horizontal,
                      value: SubtitleUtils.availableFonts
                              .contains(watchTheme(ref, (s) => s.fontFamily))
                          ? watchTheme(ref, (s) => s.fontFamily)!
                          : 'Default',
                      items: SubtitleUtils.availableFonts
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
                      icon:
                          Icon(Iconsax.arrow_up_3, color: colorScheme.primary),
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
                                icon: Icon(Iconsax.eye,
                                    color: colorScheme.primary),
                                accent: colorScheme.primary,
                                title: 'Shadow Opacity',
                                description:
                                    '${(watchTheme(ref, (s) => s.shadowOpacity) * 100).round()}%',
                                value: watchTheme(ref, (s) => s.shadowOpacity),
                                min: 0,
                                max: 1,
                                onChanged: (value) =>
                                    subtitleNotifier.updateSettings(
                                  (prev) => prev.copyWith(shadowOpacity: value),
                                ),
                              ),
                              SliderSettingsItem(
                                icon: Icon(Iconsax.blur,
                                    color: colorScheme.primary),
                                accent: colorScheme.primary,
                                title: 'Shadow Blur',
                                description:
                                    '${watchTheme(ref, (s) => s.shadowBlur).toStringAsFixed(1)}px',
                                value: watchTheme(ref, (s) => s.shadowBlur),
                                min: 1,
                                max: 10,
                                divisions: 9,
                                suffix: 'px',
                                onChanged: (value) =>
                                    subtitleNotifier.updateSettings(
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
                      description:
                          'Align subtitles to the top, center, or bottom',
                      selectedValue: watchTheme(ref, (s) => s.position),
                      onValueChanged: (value) {
                        subtitleNotifier.updateSettings(
                          (prev) => prev.copyWith(position: value),
                        );
                      },
                      children: const {
                        3: Icon(Iconsax.arrow_up_2),
                        2: Icon(Iconsax.minus),
                        1: Icon(Iconsax.arrow_down_1),
                      },
                      labels: const {
                        3: 'Top',
                        2: 'Center',
                        1: 'Bottom',
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 48), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitlePreview(WidgetRef ref) {
    final subtitleStyle = ref.watch(subtitleAppearanceProvider);
    const sampleText = "This is a sample subtitle to preview your changes.";

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Align(
        alignment: subtitleStyle.position == 1
            ? Alignment.bottomCenter
            : subtitleStyle.position == 2
                ? Alignment.center
                : Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(subtitleStyle.backgroundOpacity),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            subtitleStyle.forceUppercase
                ? sampleText.toUpperCase()
                : sampleText,
            textAlign: TextAlign.center,
            style: SubtitleUtils.getSubtitleTextStyle(subtitleStyle),
          ),
        ),
      ),
    );
  }
}
