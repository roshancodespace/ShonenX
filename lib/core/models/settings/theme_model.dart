import 'dart:convert';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class ThemeModel {
  final String themeMode;
  final bool amoled;
  final String? flexScheme;
  final int blendLevel;
  final bool swapColors;
  final bool useMaterial3;
  final bool useDynamicColors;

  ThemeModel({
    this.themeMode = 'system',
    this.amoled = false,
    this.flexScheme,
    this.blendLevel = 11,
    this.swapColors = false,
    this.useMaterial3 = true,
    this.useDynamicColors = false,
  });

  ThemeModel copyWith({
    String? themeMode,
    bool? amoled,
    String? flexScheme,
    int? blendLevel,
    bool? swapColors,
    bool? useMaterial3,
    bool? useDynamicColors,
  }) {
    return ThemeModel(
      themeMode: themeMode ?? this.themeMode,
      amoled: amoled ?? this.amoled,
      flexScheme: flexScheme ?? this.flexScheme,
      blendLevel: blendLevel ?? this.blendLevel,
      swapColors: swapColors ?? this.swapColors,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      useDynamicColors: useDynamicColors ?? this.useDynamicColors,
    );
  }

  FlexScheme get flexSchemeEnum => FlexScheme.values.firstWhere(
    (e) => e.name == flexScheme,
    orElse: () => FlexScheme.red,
  );
  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'amoled': amoled,
      'flexScheme': flexScheme,
      'blendLevel': blendLevel,
      'swapColors': swapColors,
      'useMaterial3': useMaterial3,
      'useDynamicColors': useDynamicColors,
    };
  }

  factory ThemeModel.fromMap(Map<String, dynamic> map) {
    return ThemeModel(
      themeMode: map['themeMode'] ?? 'system',
      amoled: map['amoled'] ?? false,
      flexScheme: map['flexScheme'],
      blendLevel: map['blendLevel']?.toInt() ?? 11,
      swapColors: map['swapColors'] ?? false,
      useMaterial3: map['useMaterial3'] ?? true,
      useDynamicColors: map['useDynamicColors'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ThemeModel.fromJson(String source) =>
      ThemeModel.fromMap(json.decode(source));
}
