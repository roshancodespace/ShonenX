import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

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
  final String? customBackgroundImagePath;
  final String? processedBackgroundImagePath;
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
    this.customBackgroundImagePath,
    this.processedBackgroundImagePath,
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
    AppThemeVariant? themeVariant,
    bool? useAmoled,
    bool? useDynamic,
    String? exclusiveScheme,
    bool clearExclusiveScheme = false,
    int? blendLevel,
    bool? useGradients,
    bool? useNoiseOverlay,
    String? customBackgroundImagePath,
    bool clearCustomBackgroundImagePath = false,
    String? processedBackgroundImagePath,
    bool clearProcessedBackgroundImagePath = false,
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
      processedBackgroundImagePath: clearProcessedBackgroundImagePath
          ? null
          : (processedBackgroundImagePath ?? this.processedBackgroundImagePath),
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
      'processedBackgroundImagePath': processedBackgroundImagePath,
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
      customBackgroundImagePath: map['customBackgroundImagePath'],
      processedBackgroundImagePath: map['processedBackgroundImagePath'],
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
        other.processedBackgroundImagePath == processedBackgroundImagePath &&
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
        processedBackgroundImagePath,
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
  Timer? _processingDebounceTimer;

  @override
  ThemePrefsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonString = prefs.getString(_themeDataKey);

    if (jsonString != null) {
      try {
        final loadedState = ThemePrefsState.fromJson(jsonString);
        if (loadedState.customBackgroundImagePath != null &&
            loadedState.processedBackgroundImagePath == null &&
            loadedState.backgroundBlur > 0.0) {
          Future.microtask(() => _processBackgroundImage(loadedState));
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
    final oldState = state;
    final newState = updateFn(state);
    state = newState;
    _saveDb();

    if (newState.customBackgroundImagePath !=
            oldState.customBackgroundImagePath ||
        newState.backgroundBlur != oldState.backgroundBlur) {
      _processBackgroundImage(newState);
    }
  }

  void _processBackgroundImage(ThemePrefsState targetState) {
    _processingDebounceTimer?.cancel();
    _processingDebounceTimer = Timer(
      const Duration(milliseconds: 250),
      () async {
        final originalPath = targetState.customBackgroundImagePath;
        final blurSigma = targetState.backgroundBlur;

        if (originalPath == null) {
          final oldProcessedPath = state.processedBackgroundImagePath;
          if (oldProcessedPath != null) {
            try {
              final file = File(oldProcessedPath);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (_) {}
          }
          updateTheme(
            (p) => p.copyWith(clearProcessedBackgroundImagePath: true),
          );
          return;
        }

        if (blurSigma <= 0.0) {
          updateTheme(
            (p) => p.copyWith(processedBackgroundImagePath: originalPath),
          );
          return;
        }

        try {
          final docDir = await getApplicationDocumentsDirectory();
          final fileName =
              'blurred_wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';
          final outputPath = '${docDir.path}/$fileName';

          final data = await File(originalPath).readAsBytes();
          final codec = await ui.instantiateImageCodec(data);
          final frame = await codec.getNextFrame();
          final originalImage = frame.image;

          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);

          final width = originalImage.width.toDouble();
          final height = originalImage.height.toDouble();

          final paint = Paint()
            ..imageFilter = ui.ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            );

          canvas.drawImage(originalImage, Offset.zero, paint);

          final picture = recorder.endRecording();
          final blurredImage = await picture.toImage(
            width.toInt(),
            height.toInt(),
          );

          final byteData = await blurredImage.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final bytes = byteData!.buffer.asUint8List();

          final blurredFile = File(outputPath);
          await blurredFile.writeAsBytes(bytes);

          originalImage.dispose();
          blurredImage.dispose();

          final oldProcessedPath = state.processedBackgroundImagePath;
          if (oldProcessedPath != null && oldProcessedPath != originalPath) {
            try {
              final oldFile = File(oldProcessedPath);
              if (await oldFile.exists()) {
                await oldFile.delete();
              }
            } catch (_) {}
          }

          updateTheme(
            (p) => p.copyWith(processedBackgroundImagePath: outputPath),
          );
        } catch (e) {
          updateTheme(
            (p) => p.copyWith(processedBackgroundImagePath: originalPath),
          );
        }
      },
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
