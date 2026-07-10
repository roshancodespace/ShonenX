import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePrefs = ref.watch(themePrefsProvider);
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(themePrefsProvider.notifier);
    final isDark = themePrefs.themeMode == ThemeMode.dark;

    return AppScaffold(
      title: 'Appearance',
      body: ListView(
        children: [
          SettingsSection(
            title: 'Display & Color',
            children: [
              SettingsSegmentedTile<ThemeMode>(
                title: 'Theme Mode',
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {themePrefs.themeMode},
                onSelectionChanged: (Set<ThemeMode> s) =>
                    notifier.updateTheme((p) => p.copyWith(themeMode: s.first)),
              ),
              SettingsSwitchTile(
                icon: Icons.palette_outlined,
                title: 'Dynamic Color',
                subtitle: 'Uses wallpaper colors',
                value: themePrefs.useDynamic,
                onChanged: (v) => notifier.updateTheme(
                  (p) => p.copyWith(useDynamic: v, clearExclusiveScheme: v),
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
                          // Turn off effects that conflict with pure black
                          useGradients: v ? false : p.useGradients,
                          useNoiseOverlay: v ? false : p.useNoiseOverlay,
                          clearCustomBackgroundImagePath: v,
                        ),
                      ),
              ),
              SettingsSwitchTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Swap Colors',
                subtitle: 'Swap primary and secondary colors',
                value: themePrefs.swapColors,
                onChanged: (v) =>
                    notifier.updateTheme((p) => p.copyWith(swapColors: v)),
              ),
            ],
          ),
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
              if (themePrefs.customBackgroundImagePath == null)
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
            ],
          ),
          SettingsSection(
            title: 'Background Decoration',
            children: [
              SettingsActionTile(
                icon: Icons.image_outlined,
                title: 'Custom Wallpaper',
                subtitle: themePrefs.useAmoled
                    ? 'Disabled with Pure Black'
                    : themePrefs.customBackgroundImagePath != null
                    ? 'Wallpaper active'
                    : 'Select a custom background image',
                onTap: themePrefs.useAmoled
                    ? null
                    : () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );
                        if (result != null &&
                            result.files.single.path != null) {
                          notifier.updateTheme(
                            (p) => p.copyWith(
                              customBackgroundImagePath:
                                  result.files.single.path,
                              // Image replaces gradient
                              useGradients: false,
                            ),
                          );
                        }
                      },
                trailing:
                    themePrefs.customBackgroundImagePath != null &&
                        !themePrefs.useAmoled
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => notifier.updateTheme(
                          (p) =>
                              p.copyWith(clearCustomBackgroundImagePath: true),
                        ),
                      )
                    : null,
              ),
              if (themePrefs.customBackgroundImagePath != null &&
                  !themePrefs.useAmoled) ...[
                SettingsSliderTile(
                  icon: Icons.blur_on_rounded,
                  title: 'Wallpaper Blur',
                  subtitle: 'Softness of background image',
                  value: themePrefs.backgroundBlur,
                  min: 0.0,
                  max: 25.0,
                  divisions: 25,
                  label: '${themePrefs.backgroundBlur.toInt()}px',
                  onChanged: (v) => notifier.updateTheme(
                    (p) => p.copyWith(backgroundBlur: v),
                  ),
                ),
                SettingsSliderTile(
                  icon: Icons.filter_b_and_w_outlined,
                  title: 'Wallpaper Opacity',
                  subtitle: 'Visibility of background image',
                  value: themePrefs.backgroundImageOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label:
                      '${(themePrefs.backgroundImageOpacity * 100).toInt()}%',
                  onChanged: (v) => notifier.updateTheme(
                    (p) => p.copyWith(backgroundImageOpacity: v),
                  ),
                ),
              ],
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
                  value: themePrefs.noiseOpacity,
                  min: 0.0,
                  max: 0.15,
                  divisions: 15,
                  label: '${(themePrefs.noiseOpacity * 100).toInt()}%',
                  onChanged: (v) =>
                      notifier.updateTheme((p) => p.copyWith(noiseOpacity: v)),
                ),
            ],
          ),
          if (!themePrefs.useDynamic) ...[
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
                      ? exclusiveSchemes[themePrefs.exclusiveScheme]?.name ??
                            'Unknown'
                      : 'Not active',
                  onTap: () => _openExclusiveSchemePicker(
                    context,
                    themePrefs.exclusiveScheme,
                    (key) => notifier.updateTheme(
                      (p) => p.copyWith(exclusiveScheme: key),
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
            ),
          ],
          if (themePrefs.useDynamic)
            SettingsSection(
              title: 'Color Scheme',
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(
                    'Color scheme is managed by Dynamic Color.',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
        ],
      ),
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
        final primary = isDark ? data.dark.primary : data.light.primary;
        final secondary = isDark ? data.dark.secondary : data.light.secondary;
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
    final prefs = ref.watch(themePrefsProvider);
    final entries = exclusiveSchemes.entries.toList();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final key = entries[index].key;
        final data = entries[index].value;
        final colors = isDark ? data.dark : data.light;
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
