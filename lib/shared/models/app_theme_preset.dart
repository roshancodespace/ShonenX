import 'dart:convert';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_list_panel.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class AppThemePreset {
  final String id;
  final String name;
  final String description;
  final String author;
  final int version;
  final List<int> previewColors;

  final ThemeMode themeMode;
  final FlexScheme flexScheme;
  final AppThemeVariant themeVariant;
  final bool useAmoled;
  final bool useDynamic;
  final String? exclusiveScheme;
  final int blendLevel;
  final bool useGradients;
  final BackgroundGradientStyle gradientStyle;
  final BackgroundGradientDirection gradientDirection;
  final BackgroundGradientColorPair gradientColorPair;
  final double gradientIntensity;
  final bool useNoiseOverlay;
  final String? customBackgroundImagePath;
  final double noiseOpacity;
  final double backgroundBlur;
  final double backgroundImageOpacity;
  final double uiRoundness;
  final double fontScaleFactor;
  final double uiScaleFactor;
  final bool swapColors;
  final int? colorSeed;
  final int? primaryColor;
  final int? secondaryColor;
  final int? tertiaryColor;
  final int? surfaceColor;

  final MediaCardStyle cardStyle;
  final ContinueWatchingStyle continueWatchingStyle;
  final ContinueReadingStyle continueReadingStyle;
  final EpisodeViewMode episodeViewMode;
  final NavBarStyle navBarStyle;
  final Map<String, dynamic> experimentalConfig;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    this.version = 1,
    required this.previewColors,
    this.themeMode = ThemeMode.system,
    this.flexScheme = FlexScheme.deepBlue,
    this.themeVariant = AppThemeVariant.classic,
    this.useAmoled = false,
    this.useDynamic = false,
    this.exclusiveScheme,
    this.blendLevel = 10,
    this.useGradients = false,
    this.gradientStyle = BackgroundGradientStyle.linear,
    this.gradientDirection = BackgroundGradientDirection.diagonalUp,
    this.gradientColorPair = BackgroundGradientColorPair.surfaceContainer,
    this.gradientIntensity = 0.35,
    this.useNoiseOverlay = false,
    this.customBackgroundImagePath,
    this.noiseOpacity = 0.03,
    this.backgroundBlur = 0.0,
    this.backgroundImageOpacity = 0.4,
    this.uiRoundness = 12.0,
    this.fontScaleFactor = 1.0,
    this.uiScaleFactor = 1.0,
    this.swapColors = false,
    this.colorSeed,
    this.primaryColor,
    this.secondaryColor,
    this.tertiaryColor,
    this.surfaceColor,
    this.cardStyle = MediaCardStyle.classic,
    this.continueWatchingStyle = ContinueWatchingStyle.classic,
    this.continueReadingStyle = ContinueReadingStyle.classic,
    this.episodeViewMode = EpisodeViewMode.classic,
    this.navBarStyle = NavBarStyle.classic,
    this.experimentalConfig = UiPrefState.defaultExperimentalConfig,
  });

  factory AppThemePreset.fromStates({
    required String id,
    required String name,
    required String description,
    required String author,
    required List<int> previewColors,
    required ThemePrefsState themePrefs,
    required UiPrefState uiPrefs,
  }) {
    return AppThemePreset(
      id: id,
      name: name,
      description: description,
      author: author,
      previewColors: previewColors,
      themeMode: themePrefs.themeMode,
      flexScheme: themePrefs.flexScheme,
      themeVariant: themePrefs.themeVariant,
      useAmoled: themePrefs.useAmoled,
      useDynamic: themePrefs.useDynamic,
      exclusiveScheme: themePrefs.exclusiveScheme,
      blendLevel: themePrefs.blendLevel,
      useGradients: themePrefs.useGradients,
      gradientStyle: themePrefs.gradientStyle,
      gradientDirection: themePrefs.gradientDirection,
      gradientColorPair: themePrefs.gradientColorPair,
      gradientIntensity: themePrefs.gradientIntensity,
      useNoiseOverlay: themePrefs.useNoiseOverlay,
      customBackgroundImagePath: themePrefs.customBackgroundImagePath,
      noiseOpacity: themePrefs.noiseOpacity,
      backgroundBlur: themePrefs.backgroundBlur,
      backgroundImageOpacity: themePrefs.backgroundImageOpacity,
      uiRoundness: themePrefs.uiRoundness,
      fontScaleFactor: themePrefs.fontScaleFactor,
      uiScaleFactor: themePrefs.uiScaleFactor,
      swapColors: themePrefs.swapColors,
      colorSeed: themePrefs.colorSeed,
      primaryColor: themePrefs.primaryColor,
      secondaryColor: themePrefs.secondaryColor,
      tertiaryColor: themePrefs.tertiaryColor,
      surfaceColor: themePrefs.surfaceColor,
      cardStyle: uiPrefs.cardStyle,
      continueWatchingStyle: uiPrefs.continueWatchingStyle,
      continueReadingStyle: uiPrefs.continueReadingStyle,
      episodeViewMode: uiPrefs.episodeViewMode,
      navBarStyle: uiPrefs.navBarStyle,
      experimentalConfig: uiPrefs.experimentalConfig,
    );
  }

  ThemePrefsState applyToThemePrefs(ThemePrefsState current) {
    return current.copyWith(
      themeMode: themeMode,
      flexScheme: flexScheme,
      themeVariant: themeVariant,
      useAmoled: useAmoled,
      useDynamic: useDynamic,
      exclusiveScheme: exclusiveScheme,
      clearExclusiveScheme: exclusiveScheme == null,
      blendLevel: blendLevel,
      useGradients: useGradients,
      gradientStyle: gradientStyle,
      gradientDirection: gradientDirection,
      gradientColorPair: gradientColorPair,
      gradientIntensity: gradientIntensity,
      useNoiseOverlay: useNoiseOverlay,
      customBackgroundImagePath: customBackgroundImagePath,
      clearCustomBackgroundImagePath: customBackgroundImagePath == null,
      noiseOpacity: noiseOpacity,
      backgroundBlur: backgroundBlur,
      backgroundImageOpacity: backgroundImageOpacity,
      uiRoundness: uiRoundness,
      fontScaleFactor: fontScaleFactor,
      uiScaleFactor: uiScaleFactor,
      swapColors: swapColors,
      colorSeed: colorSeed,
      clearColorSeed: colorSeed == null,
      primaryColor: primaryColor,
      clearPrimaryColor: primaryColor == null,
      secondaryColor: secondaryColor,
      clearSecondaryColor: secondaryColor == null,
      tertiaryColor: tertiaryColor,
      clearTertiaryColor: tertiaryColor == null,
      surfaceColor: surfaceColor,
      clearSurfaceColor: surfaceColor == null,
    );
  }

  UiPrefState applyToUiPrefs(UiPrefState current) {
    return current.copyWith(
      cardStyle: cardStyle,
      continueWatchingStyle: continueWatchingStyle,
      continueReadingStyle: continueReadingStyle,
      episodeViewMode: episodeViewMode,
      navBarStyle: navBarStyle,
      experimentalConfig: {
        ...current.experimentalConfig,
        ...experimentalConfig,
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'author': author,
      'version': version,
      'previewColors': previewColors,
      'themeMode': themeMode.index,
      'flexScheme': flexScheme.name,
      'themeVariant': themeVariant.name,
      'useAmoled': useAmoled,
      'useDynamic': useDynamic,
      'exclusiveScheme': exclusiveScheme,
      'blendLevel': blendLevel,
      'useGradients': useGradients,
      'gradientStyle': gradientStyle.index,
      'gradientDirection': gradientDirection.index,
      'gradientColorPair': gradientColorPair.index,
      'gradientIntensity': gradientIntensity,
      'useNoiseOverlay': useNoiseOverlay,
      'customBackgroundImagePath': customBackgroundImagePath,
      'noiseOpacity': noiseOpacity,
      'backgroundBlur': backgroundBlur,
      'backgroundImageOpacity': backgroundImageOpacity,
      'uiRoundness': uiRoundness,
      'fontScaleFactor': fontScaleFactor,
      'uiScaleFactor': uiScaleFactor,
      'swapColors': swapColors,
      if (colorSeed != null) 'colorSeed': colorSeed,
      if (primaryColor != null) 'primaryColor': primaryColor,
      if (secondaryColor != null) 'secondaryColor': secondaryColor,
      if (tertiaryColor != null) 'tertiaryColor': tertiaryColor,
      if (surfaceColor != null) 'surfaceColor': surfaceColor,
      'cardStyle': cardStyle.name,
      'continueWatchingStyle': continueWatchingStyle.name,
      'continueReadingStyle': continueReadingStyle.name,
      'episodeViewMode': episodeViewMode.name,
      'navBarStyle': navBarStyle.name,
      'experimentalConfig': experimentalConfig,
    };
  }

  static int? _parseColor(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      String hex = val.trim().replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return int.tryParse(hex, radix: 16);
    }
    return null;
  }

  factory AppThemePreset.fromMap(Map<String, dynamic> map) {
    return AppThemePreset(
      id:
          map['id']?.toString() ??
          'custom_theme_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name']?.toString() ?? 'Imported Preset',
      description:
          map['description']?.toString() ?? 'An imported theme preset.',
      author: map['author']?.toString() ?? 'Community',
      version: (map['version'] as num?)?.toInt() ?? 1,
      previewColors:
          (map['previewColors'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [0xFF3D5AFE, 0xFF00E676, 0xFF1E1E2E],
      themeMode:
          ThemeMode.values[(map['themeMode'] as num?)?.toInt().clamp(
                0,
                ThemeMode.values.length - 1,
              ) ??
              ThemeMode.system.index],
      flexScheme: FlexScheme.values.firstWhere(
        (e) => e.name == map['flexScheme'] || e.index == map['flexScheme'],
        orElse: () => FlexScheme.custom,
      ),
      themeVariant: () {
        final val = map['themeVariant'];
        if (val is int) {
          if (val >= 0 && val < AppThemeVariant.values.length) {
            return AppThemeVariant.values[val];
          }
          if (val == 2) return AppThemeVariant.tonalSpot;
          if (val == 3) return AppThemeVariant.fidelity;
          if (val == 8) return AppThemeVariant.vibrant;
          if (val == 12) return AppThemeVariant.vivid;
        } else if (val is String) {
          return AppThemeVariant.values.firstWhere(
            (e) => e.name == val,
            orElse: () => AppThemeVariant.classic,
          );
        }
        return AppThemeVariant.classic;
      }(),
      useAmoled: map['useAmoled'] == true,
      useDynamic: map['useDynamic'] == true,
      exclusiveScheme: map['exclusiveScheme']?.toString(),
      blendLevel: (map['blendLevel'] as num?)?.toInt() ?? 10,
      useGradients: map['useGradients'] == true,
      gradientStyle:
          BackgroundGradientStyle.values[(map['gradientStyle'] as num?)
                  ?.toInt()
                  .clamp(0, BackgroundGradientStyle.values.length - 1) ??
              BackgroundGradientStyle.linear.index],
      gradientDirection:
          BackgroundGradientDirection.values[(map['gradientDirection'] as num?)
                  ?.toInt()
                  .clamp(0, BackgroundGradientDirection.values.length - 1) ??
              BackgroundGradientDirection.diagonalUp.index],
      gradientColorPair:
          BackgroundGradientColorPair.values[(map['gradientColorPair'] as num?)
                  ?.toInt()
                  .clamp(0, BackgroundGradientColorPair.values.length - 1) ??
              BackgroundGradientColorPair.surfaceContainer.index],
      gradientIntensity: (map['gradientIntensity'] as num?)?.toDouble() ?? 0.35,
      useNoiseOverlay: map['useNoiseOverlay'] == true,
      customBackgroundImagePath: map['customBackgroundImagePath']?.toString(),
      noiseOpacity: (map['noiseOpacity'] as num?)?.toDouble() ?? 0.03,
      backgroundBlur: (map['backgroundBlur'] as num?)?.toDouble() ?? 0.0,
      backgroundImageOpacity:
          (map['backgroundImageOpacity'] as num?)?.toDouble() ?? 0.4,
      uiRoundness: (map['uiRoundness'] as num?)?.toDouble() ?? 12.0,
      fontScaleFactor: (map['fontScaleFactor'] as num?)?.toDouble() ?? 1.0,
      uiScaleFactor: (map['uiScaleFactor'] as num?)?.toDouble() ?? 1.0,
      swapColors: map['swapColors'] == true,
      colorSeed: _parseColor(map['colorSeed'] ?? map['seedColor']),
      primaryColor: _parseColor(map['primaryColor'] ?? map['primary']),
      secondaryColor: _parseColor(map['secondaryColor'] ?? map['secondary']),
      tertiaryColor: _parseColor(map['tertiaryColor'] ?? map['tertiary']),
      surfaceColor: _parseColor(map['surfaceColor'] ?? map['surface']),
      cardStyle: MediaCardStyle.values.firstWhere(
        (e) => e.name == map['cardStyle'],
        orElse: () => MediaCardStyle.classic,
      ),
      continueWatchingStyle: ContinueWatchingStyle.values.firstWhere(
        (e) => e.name == map['continueWatchingStyle'],
        orElse: () => ContinueWatchingStyle.classic,
      ),
      continueReadingStyle: ContinueReadingStyle.values.firstWhere(
        (e) => e.name == map['continueReadingStyle'],
        orElse: () => ContinueReadingStyle.classic,
      ),
      episodeViewMode: EpisodeViewMode.values.firstWhere(
        (e) => e.name == map['episodeViewMode'],
        orElse: () => EpisodeViewMode.classic,
      ),
      navBarStyle: NavBarStyle.values.firstWhere(
        (e) => e.name == map['navBarStyle'],
        orElse: () => NavBarStyle.classic,
      ),
      experimentalConfig: (map['experimentalConfig'] is Map)
          ? {
              ...UiPrefState.defaultExperimentalConfig,
              ...Map<String, dynamic>.from(map['experimentalConfig'] as Map),
            }
          : UiPrefState.defaultExperimentalConfig,
    );
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toMap());

  factory AppThemePreset.fromJsonString(String source) =>
      AppThemePreset.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
