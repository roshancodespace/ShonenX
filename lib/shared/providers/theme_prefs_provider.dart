import 'dart:convert';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

extension FlexSchemeVariantExtension on FlexSchemeVariant {
  String get displayName => switch (this) {
    FlexSchemeVariant.material => 'Material',
    FlexSchemeVariant.material3Legacy => 'M3 Legacy',
    FlexSchemeVariant.tonalSpot => 'Tonal Spot',
    FlexSchemeVariant.fidelity => 'Fidelity',
    FlexSchemeVariant.content => 'Content',
    FlexSchemeVariant.monochrome => 'Monochrome',
    FlexSchemeVariant.neutral => 'Neutral',
    FlexSchemeVariant.soft => 'Soft',
    FlexSchemeVariant.vibrant => 'Vibrant',
    FlexSchemeVariant.expressive => 'Expressive',
    FlexSchemeVariant.rainbow => 'Rainbow',
    FlexSchemeVariant.fruitSalad => 'Fruit Salad',
    FlexSchemeVariant.vivid => 'Vivid',
    FlexSchemeVariant.vividSurfaces => 'Vivid Surfaces',
    FlexSchemeVariant.highContrast => 'High Contrast',
    FlexSchemeVariant.ultraContrast => 'Ultra Contrast',
    FlexSchemeVariant.vividBackground => 'Vivid Background',
    FlexSchemeVariant.oneHue => 'One Hue',
    FlexSchemeVariant.chroma => 'Chroma',
    FlexSchemeVariant.candyPop => 'Candy Pop',
    FlexSchemeVariant.jolly => 'Jolly',
  };

  String get subtitle => switch (this) {
    FlexSchemeVariant.material => 'Standard Material color generation',
    FlexSchemeVariant.material3Legacy => 'Original Material 3 tonal mapping',
    FlexSchemeVariant.tonalSpot => 'Soft Material You style colors',
    FlexSchemeVariant.fidelity => 'Preserves source color character',
    FlexSchemeVariant.content => 'Optimized for content readability',
    FlexSchemeVariant.monochrome => 'Single-hue monochromatic palette',
    FlexSchemeVariant.neutral => 'Muted and understated appearance',
    FlexSchemeVariant.soft => 'Gentle colors with reduced intensity',
    FlexSchemeVariant.vibrant => 'Strong colorful accents',
    FlexSchemeVariant.expressive => 'Playful and colorful tones',
    FlexSchemeVariant.rainbow => 'Maximum hue separation',
    FlexSchemeVariant.fruitSalad => 'Experimental colorful palette',
    FlexSchemeVariant.vivid => 'Highly saturated color palette',
    FlexSchemeVariant.vividSurfaces => 'Vivid colors with stronger surfaces',
    FlexSchemeVariant.highContrast => 'Increased accessibility contrast',
    FlexSchemeVariant.ultraContrast => 'Maximum contrast and separation',
    FlexSchemeVariant.vividBackground => 'More colorful background surfaces',
    FlexSchemeVariant.oneHue => 'All colors derived from a single hue',
    FlexSchemeVariant.chroma => 'Maximizes colorfulness from seed',
    FlexSchemeVariant.candyPop => 'Bright candy-inspired colors',
    FlexSchemeVariant.jolly => 'Cheerful and energetic palette',
  };
}

enum BackgroundGradientStyle {
  linear,
  radial,
  topGlow,
  sweep;

  String get displayName => switch (this) {
    BackgroundGradientStyle.linear => 'Linear',
    BackgroundGradientStyle.radial => 'Radial Glow',
    BackgroundGradientStyle.topGlow => 'Top Spotlight',
    BackgroundGradientStyle.sweep => 'Sweep',
  };
}

enum BackgroundGradientDirection {
  diagonalUp,
  diagonalDown,
  vertical,
  horizontal;

  String get displayName => switch (this) {
    BackgroundGradientDirection.diagonalUp => 'Diagonal Up',
    BackgroundGradientDirection.diagonalDown => 'Diagonal Down',
    BackgroundGradientDirection.vertical => 'Vertical',
    BackgroundGradientDirection.horizontal => 'Horizontal',
  };
}

enum BackgroundGradientColorPair {
  surfaceContainer,
  primaryInfused,
  secondaryInfused,
  vibrantMix;

  String get displayName => switch (this) {
    BackgroundGradientColorPair.surfaceContainer => 'Subtle Surface',
    BackgroundGradientColorPair.primaryInfused => 'Primary Glow',
    BackgroundGradientColorPair.secondaryInfused => 'Secondary Glow',
    BackgroundGradientColorPair.vibrantMix => 'Vibrant Two-Tone',
  };
}

class ThemePrefsState {
  final ThemeMode themeMode;
  final FlexScheme flexScheme;
  final FlexSchemeVariant themeVariant;
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

  const ThemePrefsState({
    this.themeMode = ThemeMode.system,
    this.flexScheme = FlexScheme.deepBlue,
    this.themeVariant = FlexSchemeVariant.tonalSpot,
    this.useAmoled = false,
    this.useDynamic = false,
    this.swapColors = false,
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
    this.colorSeed,
    this.primaryColor,
    this.secondaryColor,
    this.tertiaryColor,
    this.surfaceColor,
  });

  ThemePrefsState copyWith({
    ThemeMode? themeMode,
    FlexScheme? flexScheme,
    FlexSchemeVariant? themeVariant,
    bool? useAmoled,
    bool? useDynamic,
    String? exclusiveScheme,
    bool clearExclusiveScheme = false,
    int? blendLevel,
    bool? useGradients,
    bool? useNoiseOverlay,
    String? customBackgroundImagePath,
    bool clearCustomBackgroundImagePath = false,
    double? noiseOpacity,
    double? backgroundBlur,
    double? backgroundImageOpacity,
    double? uiRoundness,
    double? fontScaleFactor,
    double? uiScaleFactor,
    bool? swapColors,
    BackgroundGradientStyle? gradientStyle,
    BackgroundGradientDirection? gradientDirection,
    BackgroundGradientColorPair? gradientColorPair,
    double? gradientIntensity,
    int? colorSeed,
    bool clearColorSeed = false,
    int? primaryColor,
    bool clearPrimaryColor = false,
    int? secondaryColor,
    bool clearSecondaryColor = false,
    int? tertiaryColor,
    bool clearTertiaryColor = false,
    int? surfaceColor,
    bool clearSurfaceColor = false,
  }) {
    return ThemePrefsState(
      themeMode: themeMode ?? this.themeMode,
      flexScheme: flexScheme ?? this.flexScheme,
      themeVariant: themeVariant ?? this.themeVariant,
      useAmoled: useAmoled ?? this.useAmoled,
      useDynamic: useDynamic ?? this.useDynamic,
      exclusiveScheme: clearExclusiveScheme
          ? null
          : (exclusiveScheme ?? this.exclusiveScheme),
      blendLevel: blendLevel ?? this.blendLevel,
      useGradients: useGradients ?? this.useGradients,
      gradientStyle: gradientStyle ?? this.gradientStyle,
      gradientDirection: gradientDirection ?? this.gradientDirection,
      gradientColorPair: gradientColorPair ?? this.gradientColorPair,
      gradientIntensity: gradientIntensity ?? this.gradientIntensity,
      useNoiseOverlay: useNoiseOverlay ?? this.useNoiseOverlay,
      customBackgroundImagePath: clearCustomBackgroundImagePath
          ? null
          : (customBackgroundImagePath ?? this.customBackgroundImagePath),
      noiseOpacity: noiseOpacity ?? this.noiseOpacity,
      backgroundBlur: backgroundBlur ?? this.backgroundBlur,
      backgroundImageOpacity:
          backgroundImageOpacity ?? this.backgroundImageOpacity,
      uiRoundness: uiRoundness ?? this.uiRoundness,
      fontScaleFactor: fontScaleFactor ?? this.fontScaleFactor,
      uiScaleFactor: uiScaleFactor ?? this.uiScaleFactor,
      swapColors: swapColors ?? this.swapColors,
      colorSeed: clearColorSeed ? null : (colorSeed ?? this.colorSeed),
      primaryColor: clearPrimaryColor
          ? null
          : (primaryColor ?? this.primaryColor),
      secondaryColor: clearSecondaryColor
          ? null
          : (secondaryColor ?? this.secondaryColor),
      tertiaryColor: clearTertiaryColor
          ? null
          : (tertiaryColor ?? this.tertiaryColor),
      surfaceColor: clearSurfaceColor
          ? null
          : (surfaceColor ?? this.surfaceColor),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.index,
      'flexScheme': flexScheme.index,
      'themeVariant': themeVariant.index,
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

  factory ThemePrefsState.fromMap(Map<String, dynamic> map) {
    return ThemePrefsState(
      themeMode: ThemeMode.values[map['themeMode'] ?? ThemeMode.system.index],
      flexScheme:
          FlexScheme.values[map['flexScheme'] ?? FlexScheme.deepBlue.index],
      themeVariant:
          (map['themeVariant'] is int &&
              map['themeVariant'] >= 0 &&
              map['themeVariant'] < FlexSchemeVariant.values.length)
          ? FlexSchemeVariant.values[map['themeVariant']]
          : FlexSchemeVariant.vibrant,
      useAmoled: map['useAmoled'] ?? false,
      useDynamic: map['useDynamic'] ?? false,
      exclusiveScheme: map['exclusiveScheme'],
      blendLevel: map['blendLevel'] ?? 10,
      useGradients: map['useGradients'] ?? false,
      gradientStyle:
          (map['gradientStyle'] is int &&
              map['gradientStyle'] >= 0 &&
              map['gradientStyle'] < BackgroundGradientStyle.values.length)
          ? BackgroundGradientStyle.values[map['gradientStyle']]
          : BackgroundGradientStyle.linear,
      gradientDirection:
          (map['gradientDirection'] is int &&
              map['gradientDirection'] >= 0 &&
              map['gradientDirection'] <
                  BackgroundGradientDirection.values.length)
          ? BackgroundGradientDirection.values[map['gradientDirection']]
          : BackgroundGradientDirection.diagonalUp,
      gradientColorPair:
          (map['gradientColorPair'] is int &&
              map['gradientColorPair'] >= 0 &&
              map['gradientColorPair'] <
                  BackgroundGradientColorPair.values.length)
          ? BackgroundGradientColorPair.values[map['gradientColorPair']]
          : BackgroundGradientColorPair.surfaceContainer,
      gradientIntensity: (map['gradientIntensity'] as num?)?.toDouble() ?? 0.35,
      useNoiseOverlay: map['useNoiseOverlay'] ?? false,
      customBackgroundImagePath: map['customBackgroundImagePath'],
      noiseOpacity: (map['noiseOpacity'] as num?)?.toDouble() ?? 0.03,
      backgroundBlur: (map['backgroundBlur'] as num?)?.toDouble() ?? 0.0,
      backgroundImageOpacity:
          (map['backgroundImageOpacity'] as num?)?.toDouble() ?? 0.4,
      uiRoundness: (map['uiRoundness'] as num?)?.toDouble() ?? 12.0,
      fontScaleFactor: (map['fontScaleFactor'] as num?)?.toDouble() ?? 1.0,
      uiScaleFactor: (map['uiScaleFactor'] as num?)?.toDouble() ?? 1.0,
      swapColors: map['swapColors'] ?? false,
      colorSeed: _parseColor(map['colorSeed'] ?? map['seedColor']),
      primaryColor: _parseColor(map['primaryColor'] ?? map['primary']),
      secondaryColor: _parseColor(map['secondaryColor'] ?? map['secondary']),
      tertiaryColor: _parseColor(map['tertiaryColor'] ?? map['tertiary']),
      surfaceColor: _parseColor(map['surfaceColor'] ?? map['surface']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ThemePrefsState.fromJson(String source) =>
      ThemePrefsState.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemePrefsState &&
        other.themeMode == themeMode &&
        other.flexScheme == flexScheme &&
        other.themeVariant == themeVariant &&
        other.useAmoled == useAmoled &&
        other.useDynamic == useDynamic &&
        other.exclusiveScheme == exclusiveScheme &&
        other.blendLevel == blendLevel &&
        other.useGradients == useGradients &&
        other.gradientStyle == gradientStyle &&
        other.gradientDirection == gradientDirection &&
        other.gradientColorPair == gradientColorPair &&
        other.gradientIntensity == gradientIntensity &&
        other.useNoiseOverlay == useNoiseOverlay &&
        other.customBackgroundImagePath == customBackgroundImagePath &&
        other.noiseOpacity == noiseOpacity &&
        other.backgroundBlur == backgroundBlur &&
        other.backgroundImageOpacity == backgroundImageOpacity &&
        other.uiRoundness == uiRoundness &&
        other.fontScaleFactor == fontScaleFactor &&
        other.uiScaleFactor == uiScaleFactor &&
        other.swapColors == swapColors &&
        other.colorSeed == colorSeed &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        other.tertiaryColor == tertiaryColor &&
        other.surfaceColor == surfaceColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      themeMode,
      flexScheme,
      themeVariant,
      useAmoled,
      useDynamic,
      exclusiveScheme,
      blendLevel,
      useGradients,
      gradientStyle,
      gradientDirection,
      Object.hash(
        gradientColorPair,
        gradientIntensity,
        useNoiseOverlay,
        customBackgroundImagePath,
        noiseOpacity,
        backgroundBlur,
        backgroundImageOpacity,
        uiRoundness,
        fontScaleFactor,
        uiScaleFactor,
        swapColors,
        colorSeed,
        primaryColor,
        secondaryColor,
        tertiaryColor,
        surfaceColor,
      ),
    );
  }
}

class ThemePrefsNotifier extends Notifier<ThemePrefsState> {
  static const _themeDataKey = 'app_theme_data';

  @override
  ThemePrefsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonString = prefs.getString(_themeDataKey);

    if (jsonString != null) {
      try {
        return ThemePrefsState.fromJson(jsonString);
      } catch (e) {
        return const ThemePrefsState();
      }
    }

    return const ThemePrefsState();
  }

  void updateTheme(
    ThemePrefsState Function(ThemePrefsState currentState) updateFn,
  ) {
    final newState = updateFn(state);
    state = newState;
    _saveDb();
  }

  void _saveDb() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_themeDataKey, state.toJson());
  }
}

final themePrefsProvider =
    NotifierProvider<ThemePrefsNotifier, ThemePrefsState>(
      ThemePrefsNotifier.new,
    );
