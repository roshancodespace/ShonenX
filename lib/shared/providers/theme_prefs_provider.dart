// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/wallpaper_processor.dart';

import 'package:shonenx/shared/providers/storage_provider.dart';

enum AppThemeVariant {
  classic,
  tonalSpot,
  fidelity,
  vibrant,
  vivid;

  String get displayName => switch (this) {
    AppThemeVariant.classic => 'Classic',
    AppThemeVariant.tonalSpot => 'Tonal Spot',
    AppThemeVariant.fidelity => 'Fidelity',
    AppThemeVariant.vibrant => 'Vibrant',
    AppThemeVariant.vivid => 'Vivid',
  };

  String get subtitle => switch (this) {
    AppThemeVariant.classic => 'Classic color scheme styling',
    AppThemeVariant.tonalSpot => 'Soft Material You style colors',
    AppThemeVariant.fidelity => 'Preserves source color character',
    AppThemeVariant.vibrant => 'Strong colorful accents',
    AppThemeVariant.vivid => 'Highly saturated color palette',
  };

  FlexSchemeVariant get flexVariant => switch (this) {
    AppThemeVariant.classic =>
      FlexSchemeVariant.tonalSpot, // Fallback/default when not classic
    AppThemeVariant.tonalSpot => FlexSchemeVariant.tonalSpot,
    AppThemeVariant.fidelity => FlexSchemeVariant.fidelity,
    AppThemeVariant.vibrant => FlexSchemeVariant.vibrant,
    AppThemeVariant.vivid => FlexSchemeVariant.vivid,
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

class WallpaperSettings {
  final String imagePath;
  final String? processedPath;
  final double blur;
  final double opacity;
  final double saturation;
  final double brightness;
  final int? imageColorSeed;

  const WallpaperSettings({
    required this.imagePath,
    this.processedPath,
    this.blur = 0.0,
    this.opacity = 0.4,
    this.saturation = 1.0,
    this.brightness = 1.0,
    this.imageColorSeed,
  });

  WallpaperSettings copyWith({
    String? imagePath,
    String? processedPath,
    bool clearProcessedPath = false,
    double? blur,
    double? opacity,
    double? saturation,
    double? brightness,
    int? imageColorSeed,
    bool clearImageColorSeed = false,
  }) {
    return WallpaperSettings(
      imagePath: imagePath ?? this.imagePath,
      processedPath: clearProcessedPath
          ? null
          : (processedPath ?? this.processedPath),
      blur: blur ?? this.blur,
      opacity: opacity ?? this.opacity,
      saturation: saturation ?? this.saturation,
      brightness: brightness ?? this.brightness,
      imageColorSeed: clearImageColorSeed
          ? null
          : (imageColorSeed ?? this.imageColorSeed),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'processedPath': processedPath,
      'blur': blur,
      'opacity': opacity,
      'saturation': saturation,
      'brightness': brightness,
      'imageColorSeed': imageColorSeed,
    };
  }

  factory WallpaperSettings.fromMap(Map<String, dynamic> map) {
    return WallpaperSettings(
      imagePath: map['imagePath'] ?? '',
      processedPath: map['processedPath'],
      blur: (map['blur'] as num?)?.toDouble() ?? 0.0,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 0.4,
      saturation: (map['saturation'] as num?)?.toDouble() ?? 1.0,
      brightness: (map['brightness'] as num?)?.toDouble() ?? 1.0,
      imageColorSeed: map['imageColorSeed'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory WallpaperSettings.fromJson(String source) =>
      WallpaperSettings.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WallpaperSettings &&
        other.imagePath == imagePath &&
        other.processedPath == processedPath &&
        other.blur == blur &&
        other.opacity == opacity &&
        other.saturation == saturation &&
        other.brightness == brightness &&
        other.imageColorSeed == imageColorSeed;
  }

  @override
  int get hashCode => Object.hash(
    imagePath,
    processedPath,
    blur,
    opacity,
    saturation,
    brightness,
    imageColorSeed,
  );
}

class ThemePrefsState {
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
  final WallpaperSettings? wallpaperSettings;
  final bool useImageColors;
  final double noiseOpacity;
  final double uiRoundness;
  final double fontScaleFactor;
  final double uiScaleFactor;
  final bool swapColors;
  final int? colorSeed;
  final int? primaryColor;
  final int? secondaryColor;
  final int? tertiaryColor;
  final int? surfaceColor;

  String? get customBackgroundImagePath => wallpaperSettings?.imagePath;
  double get backgroundImageOpacity => wallpaperSettings?.opacity ?? 0.4;

  const ThemePrefsState({
    this.themeMode = ThemeMode.system,
    this.flexScheme = FlexScheme.deepBlue,
    this.themeVariant = AppThemeVariant.classic,
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
    this.wallpaperSettings,
    this.useImageColors = false,
    this.noiseOpacity = 0.03,
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
    AppThemeVariant? themeVariant,
    bool? useAmoled,
    bool? useDynamic,
    String? exclusiveScheme,
    bool clearExclusiveScheme = false,
    int? blendLevel,
    bool? useGradients,
    bool? useNoiseOverlay,
    WallpaperSettings? wallpaperSettings,
    bool clearWallpaperSettings = false,
    bool? useImageColors,
    double? noiseOpacity,
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
      wallpaperSettings: clearWallpaperSettings
          ? null
          : (wallpaperSettings ?? this.wallpaperSettings),
      useImageColors: useImageColors ?? this.useImageColors,
      noiseOpacity: noiseOpacity ?? this.noiseOpacity,
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
      if (wallpaperSettings != null)
        'wallpaperSettings': wallpaperSettings!.toMap(),
      'useImageColors': useImageColors,
      'noiseOpacity': noiseOpacity,
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
    AppThemeVariant resolvedVariant = AppThemeVariant.classic;
    final variantVal = map['themeVariant'];
    if (variantVal is int) {
      if (variantVal >= 0 && variantVal < AppThemeVariant.values.length) {
        resolvedVariant = AppThemeVariant.values[variantVal];
      } else {
        if (variantVal == 2) {
          resolvedVariant = AppThemeVariant.tonalSpot;
        } else if (variantVal == 3)
          resolvedVariant = AppThemeVariant.fidelity;
        else if (variantVal == 8)
          resolvedVariant = AppThemeVariant.vibrant;
        else if (variantVal == 12)
          resolvedVariant = AppThemeVariant.vivid;
      }
    } else if (variantVal is String) {
      resolvedVariant = AppThemeVariant.values.firstWhere(
        (v) => v.name == variantVal,
        orElse: () => AppThemeVariant.classic,
      );
    }

    final legacyPath = map['customBackgroundImagePath'];
    final legacyOpacity = map['backgroundImageOpacity'];
    final WallpaperSettings? resolvedWallpaper;
    if (map['wallpaperSettings'] != null) {
      resolvedWallpaper = WallpaperSettings.fromMap(map['wallpaperSettings']);
    } else if (legacyPath != null) {
      resolvedWallpaper = WallpaperSettings(
        imagePath: legacyPath,
        processedPath: map['processedBackgroundImagePath'],
        blur: (map['backgroundBlur'] as num?)?.toDouble() ?? 0.0,
        opacity: (legacyOpacity as num?)?.toDouble() ?? 0.4,
      );
    } else {
      resolvedWallpaper = null;
    }

    return ThemePrefsState(
      themeMode: ThemeMode.values[map['themeMode'] ?? ThemeMode.system.index],
      flexScheme:
          FlexScheme.values[map['flexScheme'] ?? FlexScheme.deepBlue.index],
      themeVariant: resolvedVariant,
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
      wallpaperSettings: resolvedWallpaper,
      useImageColors: map['useImageColors'] ?? false,
      noiseOpacity: (map['noiseOpacity'] as num?)?.toDouble() ?? 0.03,
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
        other.wallpaperSettings == wallpaperSettings &&
        other.useImageColors == useImageColors &&
        other.noiseOpacity == noiseOpacity &&
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
        wallpaperSettings,
        useImageColors,
        noiseOpacity,
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
        final loadedState = ThemePrefsState.fromJson(jsonString);
        if (loadedState.wallpaperSettings != null) {
          final settings = loadedState.wallpaperSettings!;
          final needsProcessing =
              settings.processedPath == null &&
              (settings.blur > 0.0 ||
                  settings.saturation != 1.0 ||
                  settings.brightness != 1.0);
          final processedFileExists =
              settings.processedPath != null &&
              File(settings.processedPath!).existsSync();

          if (needsProcessing ||
              (settings.processedPath != null && !processedFileExists)) {
            Future.microtask(() async {
              final result = await processBackgroundImage(
                settings.imagePath,
                settings.blur,
                settings.saturation,
                settings.brightness,
              );
              if (result != null) {
                updateTheme(
                  (p) => p.copyWith(
                    wallpaperSettings: p.wallpaperSettings?.copyWith(
                      processedPath: result.processedPath,
                      imageColorSeed: result.imageColorSeed,
                      clearImageColorSeed: result.imageColorSeed == null,
                    ),
                  ),
                );
              }
            });
          }
        }
        return loadedState;
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

  Future<({String processedPath, int? imageColorSeed})?> processBackgroundImage(
    String originalPath,
    double blurSigma,
    double saturation,
    double brightness,
  ) async {
    return WallpaperProcessor.process(
      originalPath: originalPath,
      blurSigma: blurSigma,
      saturation: saturation,
      brightness: brightness,
    );
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
