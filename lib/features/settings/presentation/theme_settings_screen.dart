import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/features/settings/presentation/widgets/preset_gallery_sheet.dart';
import 'package:shonenx/shared/providers/preset_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePrefs = ref.watch(themePrefsProvider);
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(themePrefsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        title: 'Appearance',
        barBottom: const PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: TabBar(
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorAnimation: TabIndicatorAnimation.linear,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Themes'),
              Tab(text: 'Effects'),
              Tab(text: 'Wallpaper'),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset to Defaults',
            onPressed: () {
              ref
                  .read(themePrefsProvider.notifier)
                  .updateTheme((_) => const ThemePrefsState());
              ref.read(presetProvider.notifier).clearActivePresetMark();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Theme settings reset to default'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
        body: TabBarView(
          children: [
            // ── Tab 1: Themes ──
            ListView(
              padding: const EdgeInsets.only(bottom: 50),
              children: [
                // Mode selection
                SettingsSection(
                  title: 'Mode',
                  children: [
                    SettingsSegmentedTile<ThemeMode>(
                      title: 'Theme Mode',
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {themePrefs.themeMode},
                      onSelectionChanged: (Set<ThemeMode> s) => notifier
                          .updateTheme((p) => p.copyWith(themeMode: s.first)),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.palette_outlined,
                      title: 'Dynamic Color',
                      subtitle: 'Uses wallpaper colors',
                      value: themePrefs.useDynamic,
                      onChanged: (v) => notifier.updateTheme(
                        (p) =>
                            p.copyWith(useDynamic: v, clearExclusiveScheme: v),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Pure Black',
                      subtitle: themePrefs.customBackgroundImagePath != null
                          ? 'Disabled while background image is set'
                          : 'Saves battery on OLED screens',
                      value: themePrefs.useAmoled,
                      onChanged:
                          themePrefs.themeMode == ThemeMode.light ||
                              themePrefs.customBackgroundImagePath != null
                          ? null
                          : (v) => notifier.updateTheme(
                              (p) => p.copyWith(
                                useAmoled: v,
                                useGradients: v ? false : p.useGradients,
                                useNoiseOverlay: v ? false : p.useNoiseOverlay,
                                clearWallpaperSettings: v,
                              ),
                            ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Swap Colors',
                      subtitle: 'Swap primary and secondary colors',
                      value: themePrefs.swapColors,
                      onChanged: (v) => notifier.updateTheme(
                        (p) => p.copyWith(swapColors: v),
                      ),
                    ),
                  ],
                ),

                // Presets
                _buildPresetGalleryBanner(context, ref),

                // Color Style
                SettingsSection(
                  title: 'Color Style',
                  children: [
                    SettingsActionTile(
                      icon: Icons.palette_outlined,
                      title: 'Theme Variant',
                      subtitle: themePrefs.themeVariant.displayName,
                      onTap: () => _openThemeVariantPicker(
                        context,
                        themePrefs.themeVariant,
                        (variant) => notifier.updateTheme(
                          (p) => p.copyWith(themeVariant: variant),
                        ),
                        isDark,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _VariantSwatchPreview(
                            variant: themePrefs.themeVariant,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Color Schemes
                if (!themePrefs.useDynamic)
                  SettingsSection(
                    title: 'Color Schemes',
                    children: [
                      SettingsActionTile(
                        icon: Icons.colorize,
                        title: 'Standard Color Scheme',
                        subtitle: themePrefs.exclusiveScheme == null
                            ? FlexColor.schemes[themePrefs.flexScheme]?.name ??
                                  'Default'
                            : 'Not active',
                        onTap: () => _openSchemePicker(
                          context,
                          themePrefs.flexScheme,
                          (scheme) => notifier.updateTheme(
                            (p) => p.copyWith(
                              flexScheme: scheme,
                              clearExclusiveScheme: true,
                              clearColorSeed: true,
                              clearPrimaryColor: true,
                              clearSecondaryColor: true,
                              clearTertiaryColor: true,
                              clearSurfaceColor: true,
                            ),
                          ),
                          isDark,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (themePrefs.exclusiveScheme == null)
                              _SwatchStack(
                                colors: [cs.primary, cs.secondary, cs.tertiary],
                              ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                      SettingsActionTile(
                        icon: Icons.auto_awesome,
                        title: 'Exclusive Scheme',
                        subtitle: themePrefs.exclusiveScheme != null
                            ? exclusiveSchemes[themePrefs.exclusiveScheme]
                                      ?.name ??
                                  'Unknown'
                            : 'Not active',
                        onTap: () => _openExclusiveSchemePicker(
                          context,
                          themePrefs.exclusiveScheme,
                          (key) => notifier.updateTheme(
                            (p) => p.copyWith(
                              exclusiveScheme: key,
                              clearColorSeed: true,
                              clearPrimaryColor: true,
                              clearSecondaryColor: true,
                              clearTertiaryColor: true,
                              clearSurfaceColor: true,
                            ),
                          ),
                          isDark,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (themePrefs.exclusiveScheme != null) ...[
                              _ExclusiveSwatchPreview(
                                schemeKey: themePrefs.exclusiveScheme!,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Icon(
                              Icons.chevron_right_rounded,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  SettingsSection(
                    title: 'Color Scheme',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Text(
                          'Color scheme is managed by Dynamic Color.',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // ── Tab 2: Effects ──
            ListView(
              padding: const EdgeInsets.only(bottom: 50),
              children: [
                // Blend & Gradients
                SettingsSection(
                  title: 'Surface Styling',
                  children: [
                    SettingsSliderTile(
                      icon: Icons.opacity_outlined,
                      title: 'Blend Level',
                      subtitle: 'Color infusion intensity',
                      value: themePrefs.blendLevel.toDouble(),
                      min: 0,
                      max: 40,
                      divisions: 40,
                      label: '${(themePrefs.blendLevel / 40 * 100).toInt()}%',
                      onChanged: (v) => notifier.updateTheme(
                        (p) => p.copyWith(blendLevel: v.toInt()),
                      ),
                    ),
                    if (themePrefs.customBackgroundImagePath == null) ...[
                      SettingsSwitchTile(
                        icon: Icons.gradient_outlined,
                        title: 'Gradient Surfaces',
                        subtitle: themePrefs.useAmoled
                            ? 'Disabled with Pure Black'
                            : 'Subtle gradients instead of flat fills',
                        value: themePrefs.useGradients,
                        onChanged: themePrefs.useAmoled
                            ? null
                            : (v) => notifier.updateTheme(
                                (p) => p.copyWith(useGradients: v),
                              ),
                      ),
                      if (themePrefs.useGradients && !themePrefs.useAmoled) ...[
                        SettingsDropdownTile<BackgroundGradientStyle>(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Gradient Shape',
                          value: themePrefs.gradientStyle,
                          items: BackgroundGradientStyle.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              notifier.updateTheme(
                                (p) => p.copyWith(gradientStyle: v),
                              );
                            }
                          },
                        ),
                        if (themePrefs.gradientStyle ==
                            BackgroundGradientStyle.linear)
                          SettingsDropdownTile<BackgroundGradientDirection>(
                            icon: Icons.explore_outlined,
                            title: 'Gradient Angle',
                            value: themePrefs.gradientDirection,
                            items: BackgroundGradientDirection.values
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d.displayName),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                notifier.updateTheme(
                                  (p) => p.copyWith(gradientDirection: v),
                                );
                              }
                            },
                          ),
                        SettingsDropdownTile<BackgroundGradientColorPair>(
                          icon: Icons.color_lens_outlined,
                          title: 'Gradient Palette',
                          value: themePrefs.gradientColorPair,
                          items: BackgroundGradientColorPair.values
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              notifier.updateTheme(
                                (p) => p.copyWith(gradientColorPair: v),
                              );
                            }
                          },
                        ),
                        SettingsSliderTile(
                          icon: Icons.tune_rounded,
                          title: 'Gradient Intensity',
                          subtitle: 'Color vibrancy over background',
                          value: themePrefs.gradientIntensity,
                          min: 0.05,
                          max: 1.0,
                          divisions: 19,
                          label:
                              '${(themePrefs.gradientIntensity * 100).toInt()}%',
                          onChanged: (v) => notifier.updateTheme(
                            (p) => p.copyWith(gradientIntensity: v),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),

                // Noise
                SettingsSection(
                  title: 'Texture',
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.grain_rounded,
                      title: 'Noise Overlay',
                      subtitle: themePrefs.useAmoled
                          ? 'Disabled with Pure Black'
                          : 'Overlay a subtle textured grain grid',
                      value: themePrefs.useNoiseOverlay,
                      onChanged: themePrefs.useAmoled
                          ? null
                          : (v) => notifier.updateTheme(
                              (p) => p.copyWith(useNoiseOverlay: v),
                            ),
                    ),
                    if (themePrefs.useNoiseOverlay && !themePrefs.useAmoled)
                      SettingsSliderTile(
                        icon: Icons.opacity_rounded,
                        title: 'Noise Intensity',
                        subtitle: 'Textured grain strength',
                        value: themePrefs.noiseOpacity > 0.15
                            ? 0.15
                            : themePrefs.noiseOpacity,
                        min: 0.0,
                        max: 0.15,
                        divisions: 15,
                        label: '${(themePrefs.noiseOpacity * 100).toInt()}%',
                        onChanged: (v) => notifier.updateTheme(
                          (p) => p.copyWith(noiseOpacity: v),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // ── Tab 3: Wallpaper ──
            ListView(
              padding: const EdgeInsets.only(bottom: 50),
              children: [
                // Wallpaper
                SettingsSection(
                  title: 'Wallpaper',
                  children: [
                    SettingsActionTile(
                      icon: Icons.image_outlined,
                      title: 'Custom Wallpaper',
                      subtitle: themePrefs.useAmoled
                          ? 'Disabled with Pure Black'
                          : themePrefs.customBackgroundImagePath != null
                          ? 'Change custom background image'
                          : 'Select a custom background image',
                      onTap: themePrefs.useAmoled
                          ? null
                          : () async {
                              final result = await FilePicker.platform
                                  .pickFiles(type: FileType.image);
                              if (result != null &&
                                  result.files.single.path != null) {
                                final selectedPath = result.files.single.path!;

                                final docDir =
                                    await getApplicationDocumentsDirectory();
                                final originalPath =
                                    '${docDir.path}/original_wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';
                                try {
                                  await File(selectedPath).copy(originalPath);
                                } catch (_) {}

                                if (context.mounted) {
                                  _showCustomizationSheet(
                                    context,
                                    imagePath: originalPath,
                                    initialBlur: 0.0,
                                    initialOpacity: 0.4,
                                    initialSaturation: 1.0,
                                    initialBrightness: 1.0,
                                    isNewWallpaper: true,
                                  );
                                }
                              }
                            },
                    ),
                    if (themePrefs.customBackgroundImagePath != null &&
                        !themePrefs.useAmoled &&
                        !themePrefs.customBackgroundImagePath!.startsWith(
                          'http',
                        )) ...[
                      SettingsActionTile(
                        icon: Icons.tune_rounded,
                        title: 'Customize Wallpaper',
                        subtitle:
                            'Adjust blur, opacity, saturation, and brightness',
                        onTap: () {
                          final ws = themePrefs.wallpaperSettings;
                          if (context.mounted &&
                              themePrefs.customBackgroundImagePath != null) {
                            _showCustomizationSheet(
                              context,
                              imagePath: themePrefs.customBackgroundImagePath!,
                              initialBlur: ws?.blur ?? 0.0,
                              initialOpacity: ws?.opacity ?? 0.4,
                              initialSaturation: ws?.saturation ?? 1.0,
                              initialBrightness: ws?.brightness ?? 1.0,
                              isNewWallpaper: false,
                            );
                          }
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.color_lens_outlined,
                        title: 'Use Wallpaper Colors',
                        subtitle: 'Generate theme colors from the wallpaper',
                        value: themePrefs.useImageColors,
                        onChanged: (v) => notifier.updateTheme(
                          (p) => p.copyWith(useImageColors: v),
                        ),
                      ),
                      SettingsActionTile(
                        icon: Icons.delete_outline_rounded,
                        title: 'Remove Wallpaper',
                        subtitle: 'Clear custom background image',
                        isDestructive: true,
                        onTap: () async {
                          notifier.updateTheme(
                            (p) => p.copyWith(
                              clearWallpaperSettings: true,
                              useImageColors: false,
                            ),
                          );
                          final docDir =
                              await getApplicationDocumentsDirectory();
                          final dir = Directory(docDir.path);
                          try {
                            final files = dir.listSync();
                            for (final file in files) {
                              if (file is File &&
                                  (file.path.contains('blurred_wallpaper_') ||
                                      file.path.contains(
                                        'original_wallpaper.png',
                                      ))) {
                                await file.delete();
                              }
                            }
                          } catch (_) {}
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetGalleryBanner(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: 'Presets',
      children: [
        SettingsNavTile(
          icon: Icons.auto_awesome_outlined,
          title: 'Theme Presets & Gallery',
          subtitle: 'Explore themes & import/export JSON presets',
          onTap: () => PresetGallerySheet.show(context),
        ),
      ],
    );
  }

  void _openSchemePicker(
    BuildContext context,
    FlexScheme currentScheme,
    void Function(FlexScheme) onSchemeSelected,
    bool isDark,
  ) {
    AppBottomSheet.show(
      context: context,
      title: 'Standard Color Schemes',
      child: _SchemePicker(
        currentScheme: currentScheme,
        isDark: isDark,
        onSelected: (scheme) {
          onSchemeSelected(scheme);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openExclusiveSchemePicker(
    BuildContext context,
    String? currentKey,
    void Function(String) onSelected,
    bool isDark,
  ) {
    AppBottomSheet.show(
      context: context,
      title: 'Exclusive Color Schemes',
      child: _ExclusiveSchemePicker(
        currentKey: currentKey,
        isDark: isDark,
        onSelected: (key) {
          onSelected(key);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openThemeVariantPicker(
    BuildContext context,
    AppThemeVariant currentVariant,
    void Function(AppThemeVariant) onSelected,
    bool isDark,
  ) {
    AppBottomSheet.show(
      context: context,
      title: 'Theme Style',
      child: _ThemeVariantPicker(
        currentVariant: currentVariant,
        isDark: isDark,
        onSelected: (variant) {
          onSelected(variant);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ExclusiveSwatchPreview extends StatelessWidget {
  const _ExclusiveSwatchPreview({
    required this.schemeKey,
    required this.isDark,
  });
  final String schemeKey;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final data = exclusiveSchemes[schemeKey];
    if (data == null) return const SizedBox.shrink();
    final colors = isDark ? data.dark : data.light;
    return _SwatchStack(
      colors: [colors.primary, colors.secondary, colors.tertiary],
    );
  }
}

class _SwatchStack extends StatelessWidget {
  const _SwatchStack({required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    const size = 18.0;
    const overlap = 10.0;
    final totalWidth = size + (colors.length - 1) * (size - overlap);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List.generate(colors.length, (i) {
          return Positioned(
            left: i * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[i],
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SchemePicker extends ConsumerWidget {
  const _SchemePicker({
    required this.currentScheme,
    required this.isDark,
    required this.onSelected,
  });

  final FlexScheme currentScheme;
  final bool isDark;
  final void Function(FlexScheme) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final activeIsDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(themePrefsProvider);
    final schemes = FlexColor.schemes.keys
        .where((s) => s != FlexScheme.custom)
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: schemes.length,
      itemBuilder: (context, index) {
        final scheme = schemes[index];
        final data = FlexColor.schemes[scheme]!;
        final primary = activeIsDark ? data.dark.primary : data.light.primary;
        final secondary = activeIsDark
            ? data.dark.secondary
            : data.light.secondary;
        final isSelected = currentScheme == scheme;

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: isSelected && prefs.useGradients
                  ? LinearGradient(
                      colors: [cs.secondaryContainer, Colors.transparent],
                    )
                  : null,
            ),
            child: ListTile(
              shape: const StadiumBorder(),
              tileColor: isSelected && !prefs.useGradients
                  ? cs.secondaryContainer
                  : Colors.transparent,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.transparent,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primary, secondary],
                    ),
                  ),
                ),
              ),
              title: Text(
                data.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? cs.onSecondaryContainer : cs.onSurface,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: cs.onSecondaryContainer,
                    )
                  : null,
              onTap: () => onSelected(scheme),
            ),
          ),
        );
      },
    );
  }
}

class _ExclusiveSchemePicker extends ConsumerWidget {
  const _ExclusiveSchemePicker({
    required this.currentKey,
    required this.isDark,
    required this.onSelected,
  });

  final String? currentKey;
  final bool isDark;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final activeIsDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(themePrefsProvider);
    final entries = exclusiveSchemes.entries.toList();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final key = entries[index].key;
        final data = entries[index].value;
        final colors = activeIsDark ? data.dark : data.light;
        final isSelected = currentKey == key;

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: isSelected && prefs.useGradients
                  ? LinearGradient(
                      colors: [cs.secondaryContainer, Colors.transparent],
                    )
                  : null,
            ),
            child: ListTile(
              shape: const StadiumBorder(),
              tileColor: isSelected && !prefs.useGradients
                  ? cs.secondaryContainer
                  : Colors.transparent,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.transparent,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colors.primary, colors.secondary],
                    ),
                  ),
                ),
              ),
              title: Text(
                data.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? cs.onSecondaryContainer : cs.onSurface,
                ),
              ),
              subtitle: Text(
                data.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? cs.onSecondaryContainer.withValues(alpha: 0.7)
                      : cs.onSurfaceVariant,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: cs.onSecondaryContainer,
                    )
                  : null,
              onTap: () => onSelected(key),
            ),
          ),
        );
      },
    );
  }
}

class _VariantSwatchPreview extends ConsumerWidget {
  const _VariantSwatchPreview({required this.variant, required this.isDark});
  final AppThemeVariant variant;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIsDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(themePrefsProvider);
    final Color primaryKey;
    final Color secondaryKey;
    final Color tertiaryKey;

    if (prefs.useDynamic) {
      final activeCs = Theme.of(context).colorScheme;
      primaryKey = activeCs.primary;
      secondaryKey = activeCs.secondary;
      tertiaryKey = activeCs.tertiary;
    } else {
      final exclusive = prefs.exclusiveScheme != null
          ? exclusiveSchemes[prefs.exclusiveScheme]
          : null;
      if (exclusive != null) {
        final schemeColors = activeIsDark ? exclusive.dark : exclusive.light;
        primaryKey = schemeColors.primary;
        secondaryKey = schemeColors.secondary;
        tertiaryKey = schemeColors.tertiary;
      } else if (prefs.primaryColor != null) {
        final primary = Color(prefs.primaryColor!);
        primaryKey = primary;

        if (prefs.secondaryColor != null) {
          secondaryKey = Color(prefs.secondaryColor!);
        } else {
          final brightness = activeIsDark ? Brightness.dark : Brightness.light;
          secondaryKey = FlexSchemeColor.from(
            primary: primary,
            brightness: brightness,
          ).secondary;
        }

        if (prefs.tertiaryColor != null) {
          tertiaryKey = Color(prefs.tertiaryColor!);
        } else {
          final brightness = activeIsDark ? Brightness.dark : Brightness.light;
          tertiaryKey = FlexSchemeColor.from(
            primary: primary,
            brightness: brightness,
          ).tertiary;
        }
      } else if (prefs.colorSeed != null) {
        final seed = Color(prefs.colorSeed!);
        primaryKey = seed;
        secondaryKey = seed;
        tertiaryKey = seed;
      } else {
        final scheme =
            FlexColor.schemes[prefs.flexScheme] ??
            FlexColor.schemes[FlexScheme.material]!;
        final schemeColors = activeIsDark ? scheme.dark : scheme.light;
        primaryKey = schemeColors.primary;
        secondaryKey = schemeColors.secondary;
        tertiaryKey = schemeColors.tertiary;
      }
    }

    final Color previewPrimary;
    final Color previewSecondary;
    final Color previewTertiary;

    if (variant == AppThemeVariant.classic) {
      previewPrimary = primaryKey;
      previewSecondary = secondaryKey;
      previewTertiary = tertiaryKey;
    } else {
      final seededScheme = SeedColorScheme.fromSeeds(
        brightness: activeIsDark ? Brightness.dark : Brightness.light,
        primaryKey: primaryKey,
        secondaryKey: secondaryKey,
        tertiaryKey: tertiaryKey,
        variant: variant.flexVariant,
      );
      previewPrimary = seededScheme.primary;
      previewSecondary = seededScheme.secondary;
      previewTertiary = seededScheme.tertiary;
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [previewPrimary, previewSecondary, previewTertiary],
          ),
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ThemeVariantPicker extends ConsumerWidget {
  const _ThemeVariantPicker({
    required this.currentVariant,
    required this.isDark,
    required this.onSelected,
  });

  final AppThemeVariant currentVariant;
  final bool isDark;
  final void Function(AppThemeVariant) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return ListView.builder(
      shrinkWrap: true,
      itemCount: AppThemeVariant.values.length,
      itemBuilder: (context, index) {
        final variant = AppThemeVariant.values[index];
        final isSelected = currentVariant == variant;

        return ListTile(
          title: Text(variant.displayName),
          subtitle: Text(variant.subtitle),
          leading: _VariantSwatchPreview(
            variant: variant,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          trailing: isSelected ? Icon(Icons.check, color: cs.primary) : null,
          onTap: () => onSelected(variant),
        );
      },
    );
  }
}

void _showCustomizationSheet(
  BuildContext context, {
  required String imagePath,
  required double initialBlur,
  required double initialOpacity,
  required double initialSaturation,
  required double initialBrightness,
  required bool isNewWallpaper,
}) {
  AppBottomSheet.show(
    context: context,
    title: 'Customize Wallpaper',
    child: _WallpaperCustomizationSheet(
      imagePath: imagePath,
      initialBlur: initialBlur,
      initialOpacity: initialOpacity,
      initialSaturation: initialSaturation,
      initialBrightness: initialBrightness,
      isNewWallpaper: isNewWallpaper,
    ),
  );
}

class _WallpaperCustomizationSheet extends ConsumerStatefulWidget {
  const _WallpaperCustomizationSheet({
    required this.imagePath,
    required this.initialBlur,
    required this.initialOpacity,
    required this.initialSaturation,
    required this.initialBrightness,
    required this.isNewWallpaper,
  });

  final String imagePath;
  final double initialBlur;
  final double initialOpacity;
  final double initialSaturation;
  final double initialBrightness;
  final bool isNewWallpaper;

  @override
  ConsumerState<_WallpaperCustomizationSheet> createState() =>
      _WallpaperCustomizationSheetState();
}

class _WallpaperCustomizationSheetState
    extends ConsumerState<_WallpaperCustomizationSheet> {
  late double _currentBlur;
  late double _currentOpacity;
  late double _currentSaturation;
  late double _currentBrightness;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentBlur = widget.initialBlur;
    _currentOpacity = widget.initialOpacity;
    _currentSaturation = widget.initialSaturation;
    _currentBrightness = widget.initialBrightness;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(themePrefsProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    // Standard matrix calculations for color saturation & brightness
    final double r = 0.2126;
    final double g = 0.7152;
    final double b = 0.0722;
    final double invS = 1.0 - _currentSaturation;
    final double R = r * invS;
    final double G = g * invS;
    final double B = b * invS;

    final matrix = [
      (R + _currentSaturation) * _currentBrightness,
      G * _currentBrightness,
      B * _currentBrightness,
      0.0,
      0.0,
      R * _currentBrightness,
      (G + _currentSaturation) * _currentBrightness,
      B * _currentBrightness,
      0.0,
      0.0,
      R * _currentBrightness,
      G * _currentBrightness,
      (B + _currentSaturation) * _currentBrightness,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dynamic live preview container
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black),
                  Opacity(
                    opacity: _currentOpacity,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: _currentBlur,
                        sigmaY: _currentBlur,
                      ),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(matrix),
                        child: Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Live Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Blur Slider
          Text(
            'Blur: ${_currentBlur.toInt()}px',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _currentBlur,
            min: 0.0,
            max: 25.0,
            divisions: 25,
            activeColor: cs.primary,
            inactiveColor: cs.primary.withOpacity(0.2),
            onChanged: (v) {
              setState(() {
                _currentBlur = v;
              });
            },
          ),
          // Opacity Slider
          Text(
            'Opacity: ${(_currentOpacity * 100).toInt()}%',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _currentOpacity,
            min: 0.0,
            max: 1.0,
            activeColor: cs.primary,
            inactiveColor: cs.primary.withOpacity(0.2),
            onChanged: (v) {
              setState(() {
                _currentOpacity = v;
              });
            },
          ),
          // Saturation Slider
          Text(
            'Saturation: ${_currentSaturation.toStringAsFixed(1)}x',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _currentSaturation,
            min: 0.0,
            max: 2.0,
            activeColor: cs.primary,
            inactiveColor: cs.primary.withOpacity(0.2),
            onChanged: (v) {
              setState(() {
                _currentSaturation = v;
              });
            },
          ),
          // Brightness Slider
          Text(
            'Brightness: ${_currentBrightness.toStringAsFixed(1)}x',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _currentBrightness,
            min: 0.5,
            max: 1.5,
            activeColor: cs.primary,
            inactiveColor: cs.primary.withOpacity(0.2),
            onChanged: (v) {
              setState(() {
                _currentBrightness = v;
              });
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isProcessing
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        setState(() {
                          _isProcessing = true;
                        });
                        final result = await notifier.processBackgroundImage(
                          widget.imagePath,
                          _currentBlur,
                          _currentSaturation,
                          _currentBrightness,
                        );
                        notifier.updateTheme(
                          (p) => p.copyWith(
                            wallpaperSettings: WallpaperSettings(
                              imagePath: widget.imagePath,
                              processedPath:
                                  result?.processedPath ?? widget.imagePath,
                              blur: _currentBlur,
                              opacity: _currentOpacity,
                              saturation: _currentSaturation,
                              brightness: _currentBrightness,
                              imageColorSeed: result?.imageColorSeed,
                            ),
                            useGradients: widget.isNewWallpaper
                                ? false
                                : p.useGradients,
                          ),
                        );
                        setState(() {
                          _isProcessing = false;
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                child: _isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
