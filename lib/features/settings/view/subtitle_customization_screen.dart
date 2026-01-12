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

    final List<_SubtitlePreset> presets = [
      _SubtitlePreset(
        name: 'Standard',
        previewText: 'Aa',
        textColor: Colors.white,
        backgroundColor: Colors.black.withOpacity(0.0),
        borderColor: Colors.black,
        borderWidth: 2.0,
        model: SubtitleAppearanceModel(
          fontSize: 20,
          textColor: 0xFFFFFFFF,
          outlineColor: 0xFF000000,
          outlineWidth: 2.0,
          backgroundOpacity: 0.0,
          backgroundColor: 0xFF000000,
          hasShadow: true,
        ),
      ),
      _SubtitlePreset(
        name: 'Boxed',
        previewText: 'Aa',
        textColor: Colors.white,
        backgroundColor: Colors.black.withOpacity(0.6),
        borderColor: Colors.transparent,
        borderWidth: 0,
        model: SubtitleAppearanceModel(
          fontSize: 20,
          textColor: 0xFFFFFFFF,
          outlineWidth: 0.0,
          outlineColor: 0xFF000000,
          backgroundOpacity: 0.5,
          backgroundColor: 0xFF000000,
          hasShadow: false,
        ),
      ),
      _SubtitlePreset(
        name: 'Classic Yellow',
        previewText: 'Aa',
        textColor: Color(0xFFFFD700),
        backgroundColor: Colors.transparent,
        borderColor: Colors.black,
        borderWidth: 2.0,
        model: SubtitleAppearanceModel(
          fontSize: 20,
          textColor: 0xFFFFD700,
          outlineColor: 0xFF000000,
          outlineWidth: 2.0,
          backgroundOpacity: 0.0,
          backgroundColor: 0xFF000000,
          hasShadow: true,
        ),
      ),
      _SubtitlePreset(
        name: 'High Vis',
        previewText: 'HI',
        textColor: Colors.yellow,
        backgroundColor: Colors.black,
        borderColor: Colors.transparent,
        borderWidth: 0,
        model: SubtitleAppearanceModel(
          fontSize: 22,
          textColor: 0xFFFFFF00,
          outlineWidth: 0.0,
          outlineColor: 0xFF000000,
          backgroundOpacity: 1.0,
          backgroundColor: 0xFF000000,
          hasShadow: false,
          boldText: true,
          forceUppercase: true,
        ),
      ),
      _SubtitlePreset(
        name: 'Streaming',
        previewText: 'Aa',
        textColor: Colors.white,
        backgroundColor: Colors.transparent,
        borderColor: Colors.transparent,
        borderWidth: 0,
        model: SubtitleAppearanceModel(
          fontSize: 21,
          textColor: 0xFFFFFFFF,
          outlineWidth: 0.0,
          outlineColor: 0xFF000000,
          backgroundOpacity: 0.0,
          backgroundColor: 0xFF000000,
          hasShadow: true,
          shadowBlur: 4.0,
          shadowOpacity: 0.8,
        ),
      ),
      _SubtitlePreset(
        name: 'Cyber',
        previewText: 'Tx',
        textColor: Colors.cyanAccent,
        backgroundColor: Colors.transparent,
        borderColor: Colors.blue.shade900,
        borderWidth: 2.0,
        model: SubtitleAppearanceModel(
          fontSize: 20,
          textColor: 0xFF00FFFF,
          outlineColor: 0xFF00008B,
          outlineWidth: 2.0,
          backgroundOpacity: 0.0,
          backgroundColor: 0xFF000000,
          hasShadow: true,
          fontFamily: 'Roboto',
        ),
      ),
      _SubtitlePreset(
        name: 'CC',
        previewText: 'CC',
        textColor: Colors.white,
        backgroundColor: Colors.black,
        borderColor: Colors.transparent,
        borderWidth: 0,
        model: SubtitleAppearanceModel(
          fontSize: 18,
          textColor: 0xFFFFFFFF,
          outlineWidth: 0.0,
          outlineColor: 0xFF000000,
          backgroundOpacity: 1.0,
          backgroundColor: 0xFF000000,
          hasShadow: false,
          fontFamily: 'Monospace',
        ),
      ),
      _SubtitlePreset(
        name: 'Paper',
        previewText: 'Aa',
        textColor: Colors.black,
        backgroundColor: Colors.white.withOpacity(0.8),
        borderColor: Colors.transparent,
        borderWidth: 0,
        model: SubtitleAppearanceModel(
          fontSize: 20,
          textColor: 0xFF000000,
          outlineWidth: 0.0,
          outlineColor: 0xFFFFFFFF,
          backgroundOpacity: 0.8,
          backgroundColor: 0xFFFFFFFF,
          hasShadow: false,
          boldText: true,
        ),
      ),
      _SubtitlePreset(
        name: 'Sakura',
        previewText: '✿',
        textColor: Color(0xFFFFB7C5),
        backgroundColor: Colors.transparent,
        borderColor: Colors.white,
        borderWidth: 1.5,
        model: SubtitleAppearanceModel(
          fontSize: 20,
          textColor: 0xFFFFB7C5,
          outlineColor: 0xFFFFFFFF,
          outlineWidth: 1.5,
          backgroundOpacity: 0.0,
          backgroundColor: 0xFF000000,
          hasShadow: true,
          shadowOpacity: 0.8,
          shadowBlur: 2.0,
          boldText: true,
        ),
      ),
      _SubtitlePreset(
        name: 'Terminal',
        previewText: '>_',
        textColor: Color(0xFF00FF00),
        backgroundColor: Colors.black.withOpacity(0.8),
        borderColor: Colors.transparent,
        borderWidth: 0,
        model: SubtitleAppearanceModel(
          fontSize: 18,
          textColor: 0xFF00FF00,
          outlineWidth: 0.0,
          outlineColor: 0xFF000000,
          backgroundOpacity: 0.8,
          backgroundColor: 0xFF000000,
          hasShadow: false,
          fontFamily: 'Monospace',
        ),
      ),
      _SubtitlePreset(
        name: 'IMAX',
        previewText: 'BIG',
        textColor: Colors.white,
        backgroundColor: Colors.transparent,
        borderColor: Colors.black,
        borderWidth: 3.0,
        model: SubtitleAppearanceModel(
          fontSize: 28,
          textColor: 0xFFFFFFFF,
          outlineColor: 0xFF000000,
          outlineWidth: 3.0,
          backgroundOpacity: 0.0,
          backgroundColor: 0xFF000000,
          hasShadow: false,
          boldText: true,
        ),
      ),
      _SubtitlePreset(
        name: 'Minimal',
        previewText: 'Aa',
        textColor: Color(0xFFE0E0E0),
        backgroundColor: Colors.transparent,
        borderColor: Colors.black.withOpacity(0.5),
        borderWidth: 1.0,
        model: SubtitleAppearanceModel(
          fontSize: 16,
          textColor: 0xFFE0E0E0,
          outlineColor: 0xFF000000,
          outlineWidth: 1.0,
          backgroundOpacity: 0.0,
          backgroundColor: 0xFF000000,
          hasShadow: true,
          shadowOpacity: 0.5,
        ),
      ),
      _SubtitlePreset(
        name: 'Warning',
        previewText: '!!',
        textColor: Color(0xFFFF3333),
        backgroundColor: Colors.black.withOpacity(0.7),
        borderColor: Colors.white,
        borderWidth: 1.0,
        model: SubtitleAppearanceModel(
          fontSize: 20,
          textColor: 0xFFFF3333,
          outlineColor: 0xFFFFFFFF,
          outlineWidth: 1.0,
          backgroundOpacity: 0.7,
          backgroundColor: 0xFF000000,
          hasShadow: false,
          boldText: true,
        ),
      ),
      _SubtitlePreset(
        name: 'Ghost',
        previewText: 'Oo',
        textColor: Colors.white.withOpacity(0.9),
        backgroundColor: Colors.transparent,
        borderColor: Colors.transparent,
        borderWidth: 0,
        model: SubtitleAppearanceModel(
          fontSize: 20,
          textColor: 0xE6FFFFFF,
          outlineWidth: 0.0,
          outlineColor: 0xFF000000,
          backgroundOpacity: 0.0,
          backgroundColor: 0xFF000000,
          hasShadow: true,
          shadowBlur: 6.0,
          shadowOpacity: 0.8,
        ),
      ),
    ];

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton.filledTonal(
              onPressed: () => context.pop(),
              icon: const Icon(Iconsax.arrow_left_2)),
          title: const Text('Subtitle Customization'),
          forceMaterialTransparency: true,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Presets'),
              Tab(text: 'Text'),
              Tab(text: 'Background'),
              Tab(text: 'Effects'),
              Tab(text: 'Position'),
            ],
          ),
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
                    _buildSubtitlePreview(ref),
                  ],
                ),
              ),
            ),
            // Settings Controls
            Expanded(
              flex: 2,
              child: TabBarView(
                children: [
                  // --- PRESETS TAB ---
                  ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      SettingsSection(
                        title: 'Quick Styles',
                        titleColor: colorScheme.primary,
                        children: [
                          (() {
                            final screenWidth =
                                MediaQuery.of(context).size.width;
                            final crossAxisCount = screenWidth ~/ 180;
                            final spacing = screenWidth * 0.01;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    crossAxisCount > 0 ? crossAxisCount : 1,
                                childAspectRatio: 1,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                              ),
                              itemCount: presets.length,
                              itemBuilder: (context, index) {
                                return _PresetCard(
                                  preset: presets[index],
                                  onTap: () {
                                    subtitleNotifier.updateSettings((prev) {
                                      final m = presets[index].model;
                                      return prev.copyWith(
                                        fontSize: m.fontSize *
                                            MediaQuery.of(context)
                                                .textScaleFactor,
                                        textColor: m.textColor,
                                        outlineColor: m.outlineColor,
                                        outlineWidth: m.outlineWidth *
                                            (screenWidth /
                                                400), // scale outline
                                        backgroundColor: m.backgroundColor,
                                        backgroundOpacity: m.backgroundOpacity,
                                        hasShadow: m.hasShadow,
                                        boldText: m.boldText,
                                        forceUppercase: m.forceUppercase,
                                        fontFamily: m.fontFamily,
                                      );
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${presets[index].name} Applied',
                                          style: TextStyle(
                                            fontSize: 14 *
                                                MediaQuery.of(context)
                                                    .textScaleFactor,
                                          ),
                                        ),
                                        duration:
                                            const Duration(milliseconds: 800),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          })()
                        ],
                      ),
                    ],
                  ),

                  // --- TEXT TAB ---
                  ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      SettingsSection(
                        title: 'Typography',
                        titleColor: colorScheme.primary,
                        children: [
                          DropdownSettingsItem(
                            icon: Icon(Iconsax.text_block,
                                color: colorScheme.primary),
                            accent: colorScheme.primary,
                            title: 'Font Family',
                            description: watchTheme(ref, (s) => s.fontFamily) ??
                                'Default',
                            layoutType: SettingsItemLayout.horizontal,
                            value: SubtitleUtils.availableFonts.contains(
                                    watchTheme(ref, (s) => s.fontFamily))
                                ? watchTheme(ref, (s) => s.fontFamily)!
                                : 'Default',
                            items: SubtitleUtils.availableFonts
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                subtitleNotifier.updateSettings(
                              (prev) => prev.copyWith(fontFamily: value),
                            ),
                          ),
                          SliderSettingsItem(
                            icon:
                                Icon(Iconsax.text, color: colorScheme.primary),
                            accent: colorScheme.primary,
                            title: 'Font Size',
                            description:
                                '${watchTheme(ref, (s) => s.fontSize).round()}px',
                            value: watchTheme(ref, (s) => s.fontSize),
                            min: 12,
                            max: 50,
                            divisions: 38,
                            suffix: 'px',
                            onChanged: (value) =>
                                subtitleNotifier.updateSettings(
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
                          ToggleableSettingsItem(
                            icon: Icon(Iconsax.text_bold,
                                color: colorScheme.primary),
                            accent: colorScheme.primary,
                            title: 'Bold Text',
                            description: 'Make subtitle text bold',
                            value: watchTheme(ref, (s) => s.boldText),
                            onChanged: (value) =>
                                subtitleNotifier.updateSettings(
                              (prev) => prev.copyWith(boldText: value),
                            ),
                          ),
                          ToggleableSettingsItem(
                            icon: Icon(Iconsax.arrow_up_3,
                                color: colorScheme.primary),
                            accent: colorScheme.primary,
                            title: 'Force Uppercase',
                            description: 'Render all text in capital letters',
                            value: watchTheme(ref, (s) => s.forceUppercase),
                            onChanged: (value) =>
                                subtitleNotifier.updateSettings(
                              (prev) => prev.copyWith(forceUppercase: value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // --- BACKGROUND TAB ---
                  ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      SettingsSection(
                        title: 'Background',
                        titleColor: colorScheme.primary,
                        children: [
                          ColorPickerSettingsItem(
                            accent: colorScheme.primary,
                            title: 'Background Color',
                            description: 'Choose background color',
                            icon: Icon(Iconsax.bucket_square,
                                color: colorScheme.primary),
                            selectedColor:
                                watchTheme(ref, (s) => s.backgroundColor),
                            onColorChanged: (value) =>
                                subtitleNotifier.updateSettings(
                              (prev) => prev.copyWith(backgroundColor: value),
                            ),
                          ),
                          SliderSettingsItem(
                            icon: Icon(Iconsax.square,
                                color: colorScheme.primary),
                            accent: colorScheme.primary,
                            title: 'Background Opacity',
                            description:
                                '${(watchTheme(ref, (s) => s.backgroundOpacity) * 100).round()}%',
                            value: watchTheme(ref, (s) => s.backgroundOpacity),
                            min: 0,
                            max: 1,
                            onChanged: (value) =>
                                subtitleNotifier.updateSettings(
                              (prev) => prev.copyWith(backgroundOpacity: value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // --- EFFECTS TAB ---
                  ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      SettingsSection(
                        title: 'Outline',
                        titleColor: colorScheme.primary,
                        children: [
                          SliderSettingsItem(
                            icon: Icon(Iconsax.edit_2,
                                color: colorScheme.primary),
                            accent: colorScheme.primary,
                            title: 'Outline Width',
                            description:
                                '${watchTheme(ref, (s) => s.outlineWidth).toStringAsFixed(1)}px',
                            value: watchTheme(ref, (s) => s.outlineWidth),
                            min: 0,
                            max: 5,
                            divisions: 10,
                            suffix: 'px',
                            onChanged: (value) =>
                                subtitleNotifier.updateSettings(
                              (prev) => prev.copyWith(outlineWidth: value),
                            ),
                          ),
                          ColorPickerSettingsItem(
                            accent: colorScheme.primary,
                            title: 'Outline Color',
                            description: 'Choose outline color',
                            icon: Icon(Iconsax.colorfilter,
                                color: colorScheme.primary),
                            selectedColor:
                                watchTheme(ref, (s) => s.outlineColor),
                            onColorChanged: (value) =>
                                subtitleNotifier.updateSettings(
                              (prev) => prev.copyWith(outlineColor: value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SettingsSection(
                        title: 'Shadow',
                        titleColor: colorScheme.primary,
                        children: [
                          ToggleableSettingsItem(
                            icon:
                                Icon(Iconsax.ghost, color: colorScheme.primary),
                            accent: colorScheme.primary,
                            title: 'Enable Shadow',
                            description:
                                'Add a drop shadow for better visibility',
                            value: hasShadow,
                            onChanged: (value) =>
                                subtitleNotifier.updateSettings(
                              (prev) => prev.copyWith(hasShadow: value),
                            ),
                          ),
                          if (hasShadow) ...[
                            SliderSettingsItem(
                              icon:
                                  Icon(Iconsax.eye, color: colorScheme.primary),
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
                        ],
                      ),
                    ],
                  ),

                  // --- POSITION TAB ---
                  ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
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
                          SliderSettingsItem(
                            icon: Icon(Iconsax.arrow_bottom,
                                color: colorScheme.primary),
                            accent: colorScheme.primary,
                            title: 'Bottom Margin',
                            description:
                                '${watchTheme(ref, (s) => s.bottomMargin).round()}px',
                            value: watchTheme(ref, (s) => s.bottomMargin),
                            min: 0,
                            max: 100,
                            divisions: 100,
                            suffix: 'px',
                            onChanged: (value) =>
                                subtitleNotifier.updateSettings(
                              (prev) => prev.copyWith(bottomMargin: value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitlePreview(WidgetRef ref) {
    final subtitleStyle = ref.watch(subtitleAppearanceProvider);
    const sampleText = "This is a sample subtitle to preview your changes.";
    final margin = 10.0 + subtitleStyle.bottomMargin;
    return Padding(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        bottom: subtitleStyle.position == 1 ? margin : 10.0,
        top: subtitleStyle.position == 3 ? margin : 10.0,
      ),
      child: Align(
        alignment: subtitleStyle.position == 1
            ? Alignment.bottomCenter
            : subtitleStyle.position == 2
                ? Alignment.center
                : Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(subtitleStyle.backgroundColor)
                .withOpacity(subtitleStyle.backgroundOpacity),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              if (subtitleStyle.outlineWidth > 0)
                Text(
                  subtitleStyle.forceUppercase
                      ? sampleText.toUpperCase()
                      : sampleText,
                  textAlign: TextAlign.center,
                  style: SubtitleUtils.getSubtitleTextStyle(subtitleStyle,
                      stroke: true),
                ),
              Text(
                subtitleStyle.forceUppercase
                    ? sampleText.toUpperCase()
                    : sampleText,
                textAlign: TextAlign.center,
                style: SubtitleUtils.getSubtitleTextStyle(subtitleStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HELPER CLASSES FOR PRESETS ---

class _SubtitlePreset {
  final String name;
  final String previewText;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final SubtitleAppearanceModel model;

  _SubtitlePreset({
    required this.name,
    required this.previewText,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.model,
  });
}

class _PresetCard extends StatelessWidget {
  final _SubtitlePreset preset;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview Box
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      Colors.grey[800], // Dark background to show transparency
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://s4.anilist.co/file/anilistcdn/media/anime/banner/16498-8jpFCOcDmneX.jpg'),
                    fit: BoxFit.cover,
                    opacity: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: preset.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      if (preset.borderWidth > 0)
                        Text(
                          preset.previewText,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = preset.borderWidth
                              ..color = preset.borderColor,
                          ),
                        ),
                      Text(
                        preset.previewText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: preset.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              preset.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
