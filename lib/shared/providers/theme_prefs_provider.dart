import 'dart:convert';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

class ThemePrefsState {
  final ThemeMode themeMode;
  final FlexScheme flexScheme;
  final bool useAmoled;
  final bool useDynamic;
  final String? exclusiveScheme;
  final int blendLevel;
  final bool useGradients;
  final bool useNoiseOverlay;
  final String? customBackgroundImagePath;
  final double noiseOpacity;
  final double backgroundBlur;
  final double backgroundImageOpacity;
  final double uiRoundness;
  final double fontScaleFactor;
  final double uiScaleFactor;
  final bool swapColors;

  const ThemePrefsState({
    this.themeMode = ThemeMode.system,
    this.flexScheme = FlexScheme.deepBlue,
    this.useAmoled = false,
    this.useDynamic = false,
    this.swapColors = false,
    this.exclusiveScheme,
    this.blendLevel = 10,
    this.useGradients = false,
    this.useNoiseOverlay = false,
    this.customBackgroundImagePath,
    this.noiseOpacity = 0.03,
    this.backgroundBlur = 0.0,
    this.backgroundImageOpacity = 0.4,
    this.uiRoundness = 12.0,
    this.fontScaleFactor = 1.0,
    this.uiScaleFactor = 1.0,
  });

  ThemePrefsState copyWith({
    ThemeMode? themeMode,
    FlexScheme? flexScheme,
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
  }) {
    return ThemePrefsState(
      themeMode: themeMode ?? this.themeMode,
      flexScheme: flexScheme ?? this.flexScheme,
      useAmoled: useAmoled ?? this.useAmoled,
      useDynamic: useDynamic ?? this.useDynamic,
      exclusiveScheme: clearExclusiveScheme
          ? null
          : (exclusiveScheme ?? this.exclusiveScheme),
      blendLevel: blendLevel ?? this.blendLevel,
      useGradients: useGradients ?? this.useGradients,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.index,
      'flexScheme': flexScheme.index,
      'useAmoled': useAmoled,
      'useDynamic': useDynamic,
      'exclusiveScheme': exclusiveScheme,
      'blendLevel': blendLevel,
      'useGradients': useGradients,
      'useNoiseOverlay': useNoiseOverlay,
      'customBackgroundImagePath': customBackgroundImagePath,
      'noiseOpacity': noiseOpacity,
      'backgroundBlur': backgroundBlur,
      'backgroundImageOpacity': backgroundImageOpacity,
      'uiRoundness': uiRoundness,
      'fontScaleFactor': fontScaleFactor,
      'uiScaleFactor': uiScaleFactor,
      'swapColors': swapColors,
    };
  }

  factory ThemePrefsState.fromMap(Map<String, dynamic> map) {
    return ThemePrefsState(
      themeMode: ThemeMode.values[map['themeMode'] ?? ThemeMode.system.index],
      flexScheme:
          FlexScheme.values[map['flexScheme'] ?? FlexScheme.deepBlue.index],
      useAmoled: map['useAmoled'] ?? false,
      useDynamic: map['useDynamic'] ?? false,
      exclusiveScheme: map['exclusiveScheme'],
      blendLevel: map['blendLevel'] ?? 10,
      useGradients: map['useGradients'] ?? false,
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
    );
  }

  String toJson() => json.encode(toMap());

  factory ThemePrefsState.fromJson(String source) =>
      ThemePrefsState.fromMap(json.decode(source));
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
