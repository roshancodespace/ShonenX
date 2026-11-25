import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';

class ThemeEffectsTab extends ConsumerWidget {
  const ThemeEffectsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePrefs = ref.watch(themePrefsProvider);
    final notifier = ref.read(themePrefsProvider.notifier);
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.only(bottom: 50),
      children: [
        // Blend & Gradients
        SettingsSection(
          title: l10n.themeEffectsSurfaceStyling,
          children: [
            SettingsSliderTile(
              icon: Icons.opacity_outlined,
              title: l10n.themeEffectsBlendLevel,
              subtitle: l10n.themeEffectsBlendLevelSubtitle,
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
                title: l10n.themeEffectsGradientSurfaces,
                subtitle: themePrefs.useAmoled
                    ? l10n.themeEffectsDisabledWithPureBlack
                    : l10n.themeEffectsGradientSurfacesSubtitle,
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
                  title: l10n.themeEffectsGradientShape,
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
                    title: l10n.themeEffectsGradientAngle,
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
                  title: l10n.themeEffectsGradientPalette,
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
                  title: l10n.themeEffectsGradientIntensity,
                  subtitle: l10n.themeEffectsGradientIntensitySubtitle,
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
          title: l10n.themeEffectsTextureSection,
          children: [
            SettingsSwitchTile(
              icon: Icons.grain_rounded,
              title: l10n.themeEffectsNoiseOverlay,
              subtitle: themePrefs.useAmoled
                  ? l10n.themeEffectsDisabledWithPureBlack
                  : l10n.themeEffectsNoiseOverlaySubtitle,
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
                title: l10n.themeEffectsNoiseIntensity,
                subtitle: l10n.themeEffectsNoiseIntensitySubtitle,
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
    );
  }
}
