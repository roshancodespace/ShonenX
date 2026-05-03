import 'dart:convert';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/providers/storage_provider.dart';

class ThemePrefsState {
  final ThemeMode themeMode;
  final FlexScheme flexScheme;
  final bool useAmoled;
  final bool useDynamic;

  const ThemePrefsState({
    this.themeMode = ThemeMode.system,
    this.flexScheme = FlexScheme.deepBlue,
    this.useAmoled = false,
    this.useDynamic = false,
  });

  ThemePrefsState copyWith({
    ThemeMode? themeMode,
    FlexScheme? flexScheme,
    bool? useAmoled,
    bool? useDynamic,
  }) {
    return ThemePrefsState(
      themeMode: themeMode ?? this.themeMode,
      flexScheme: flexScheme ?? this.flexScheme,
      useAmoled: useAmoled ?? this.useAmoled,
      useDynamic: useDynamic ?? this.useDynamic,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.index,
      'flexScheme': flexScheme.index,
      'useAmoled': useAmoled,
      'useDynamic': useDynamic,
    };
  }

  factory ThemePrefsState.fromMap(Map<String, dynamic> map) {
    return ThemePrefsState(
      themeMode: ThemeMode.values[map['themeMode'] ?? ThemeMode.system.index],
      flexScheme:
          FlexScheme.values[map['flexScheme'] ?? FlexScheme.deepBlue.index],
      useAmoled: map['useAmoled'] ?? false,
      useDynamic: map['useDynamic'] ?? false,
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
