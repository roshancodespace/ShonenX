import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_list_panel.dart';
import 'package:shonenx/shared/models/app_theme_preset.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class BuiltInPresets {
  static final List<AppThemePreset> all = [
    AppThemePreset(
      id: '1',
      name: 'Default ShonenX Theme',
      description: 'Default ShonenX theme configuration.',
      author: '@roshancodespace',
      version: 1,
      previewColors: [4294687744, 4292003727, 4280096006],
      themeMode: ThemeMode.values[0],
      flexScheme: FlexScheme.material,
      themeVariant: FlexSchemeVariant.vivid,
      useAmoled: false,
      useDynamic: false,
      exclusiveScheme: 'golden_hour',
      blendLevel: 10,
      useGradients: true,
      gradientStyle: BackgroundGradientStyle.values.length > 2
          ? BackgroundGradientStyle.values[2]
          : BackgroundGradientStyle.topGlow,
      gradientDirection: BackgroundGradientDirection.values[0],
      gradientColorPair: BackgroundGradientColorPair.values.length > 1
          ? BackgroundGradientColorPair.values[1]
          : BackgroundGradientColorPair.primaryInfused,
      gradientIntensity: 0.65,
      useNoiseOverlay: true,
      customBackgroundImagePath: null,
      noiseOpacity: 0.13,
      backgroundBlur: 0.0,
      backgroundImageOpacity: 0.4,
      uiRoundness: 12.0,
      fontScaleFactor: 1.0,
      uiScaleFactor: 1.0,
      swapColors: false,
      cardStyle: MediaCardStyle.expressive,
      continueWatchingStyle: ContinueWatchingStyle.wideBanner,
      continueReadingStyle: ContinueReadingStyle.wideBanner,
      episodeViewMode: EpisodeViewMode.classic,
    ),
  ];
}
