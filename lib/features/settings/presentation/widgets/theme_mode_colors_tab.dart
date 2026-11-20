import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';
import 'package:shonenx/core/theme/theme_color_resolver.dart';
import 'package:shonenx/features/settings/presentation/widgets/preset_gallery_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/settings/presentation/widgets/theme_color_pickers.dart';
import 'package:shonenx/features/settings/presentation/widgets/theme_palette_showcase.dart';
import 'package:shonenx/features/settings/presentation/widgets/theme_variant_swatch_preview.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';

class ThemeModeColorsTab extends ConsumerWidget {
  const ThemeModeColorsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePrefs = ref.watch(themePrefsProvider);
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(themePrefsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolved = resolveThemeColors(
      themePrefs,
      brightness: isDark ? Brightness.dark : Brightness.light,
      dynamicColorScheme: themePrefs.useDynamic
          ? Theme.of(context).colorScheme
          : null,
    );
    final sourceName = switch (resolved.source) {
      ThemeColorSource.dynamic => context.l10n.settingsDynamicColor,
      ThemeColorSource.exclusive =>
        exclusiveSchemes[themePrefs.exclusiveScheme]!.name,
      ThemeColorSource.flexScheme =>
        FlexColor.schemes[themePrefs.flexScheme]!.name,
      ThemeColorSource.wallpaperImageSeed ||
      ThemeColorSource.customSeed ||
      ThemeColorSource.customPrimary =>
        '#${(resolved.primaryKey.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 50),
      children: [
        SettingsSection(
          title: context.l10n.settingsMode,
          children: [
            SettingsSegmentedTile<ThemeMode>(
              title: context.l10n.settingsThemeMode,
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(context.l10n.settingsThemeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(context.l10n.settingsThemeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(context.l10n.settingsThemeDark),
                ),
              ],
              selected: {themePrefs.themeMode},
              onSelectionChanged: (Set<ThemeMode> s) =>
                  notifier.updateTheme((p) => p.copyWith(themeMode: s.first)),
            ),
            SettingsSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: context.l10n.settingsAmoled,
              subtitle: themePrefs.customBackgroundImagePath != null
                  ? context.l10n.settingsAmoledDisabledWithWallpaper
                  : context.l10n.settingsAmoledSubtitle,
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
          ],
        ),

        _buildPresetGalleryBanner(context, ref),

        SettingsSection(
          title: context.l10n.settingsColorSource,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                '${context.l10n.settingsColorSource}: $sourceName',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
            SettingsSwitchTile(
              icon: Icons.palette_outlined,
              title: context.l10n.settingsDynamicColor,
              subtitle: context.l10n.settingsDynamicColorSubtitle,
              value: themePrefs.useDynamic,
              onChanged: (v) => notifier.updateTheme(
                (p) => p.copyWith(useDynamic: v, clearExclusiveScheme: v),
              ),
            ),
            SettingsActionTile(
              icon: Icons.palette_outlined,
              title: context.l10n.settingsThemeVariantTitle,
              subtitle: context.l10n.settingsThemeVariantSubtitle,
              onTap: () => showThemeVariantPicker(
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
                  ThemeVariantSwatchPreview(
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

        if (!themePrefs.useDynamic) ...[
          ThemePaletteShelf(
            title: context.l10n.settingsExclusiveThemes,
            countBadge: '${exclusiveSchemes.length} Themes',
            items: exclusiveSchemes.entries
                .map(
                  (e) => ThemePaletteItem.fromExclusive(
                    key: e.key,
                    data: e.value,
                    isDark: isDark,
                  ),
                )
                .toList(),
            selectedId: themePrefs.exclusiveScheme,
            onSelect: (item) => notifier.setExclusiveScheme(item.id),
            onViewAll: () => showExclusiveSchemePicker(
              context,
              themePrefs.exclusiveScheme,
              (key) => notifier.setExclusiveScheme(key),
              isDark,
            ),
          ),
          const SizedBox(height: 4),
          ThemePaletteShelf(
            title: context.l10n.settingsStandardSchemes,
            countBadge: '${FlexColor.schemes.length - 1} Themes',
            items: FlexColor.schemes.entries
                .where((e) => e.key != FlexScheme.custom)
                .map(
                  (e) => ThemePaletteItem.fromFlexScheme(
                    scheme: e.key,
                    data: e.value,
                    isDark: isDark,
                  ),
                )
                .toList(),
            selectedId:
                themePrefs.exclusiveScheme == null &&
                    !themePrefs.useDynamic &&
                    !themePrefs.useImageColors
                ? themePrefs.flexScheme.name
                : null,
            onSelect: (item) =>
                notifier.setStandardScheme(FlexScheme.values.byName(item.id)),
            onViewAll: () => showStandardSchemePicker(
              context,
              themePrefs.flexScheme,
              (scheme) => notifier.setStandardScheme(scheme),
              isDark,
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              context.l10n.settingsColorSourceDynamicNote,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),

        SettingsSection(
          title: context.l10n.settingsColorTweaks,
          children: [
            SettingsSwitchTile(
              icon: Icons.swap_horiz_rounded,
              title: context.l10n.settingsSwapColors,
              subtitle: context.l10n.settingsSwapColorsSubtitle,
              value: themePrefs.swapColors,
              onChanged: (v) =>
                  notifier.updateTheme((p) => p.copyWith(swapColors: v)),
            ),
          ],
        ),
      ],
    );
  }
}

Widget _buildPresetGalleryBanner(BuildContext context, WidgetRef ref) {
  return SettingsSection(
    title: context.l10n.settingsPresets,
    children: [
      SettingsNavTile(
        icon: Icons.auto_awesome_outlined,
        title: context.l10n.settingsThemePresetsTitle,
        subtitle: context.l10n.settingsThemePresetsSubtitle,
        onTap: () => PresetGallerySheet.show(context),
      ),
    ],
  );
}
