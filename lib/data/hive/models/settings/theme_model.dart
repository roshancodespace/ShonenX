// import 'dart:convert';

// import 'package:flex_color_scheme/flex_color_scheme.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:shonenx/data/hive/hive_type_ids.dart';

// part 'theme_model.g.dart';

// @HiveType(typeId: HiveTypeIds.theme)
// class ThemeSettings {
//   @HiveField(0)
//   final String themeMode;
//   @HiveField(1)
//   final bool amoled;
//   @HiveField(2)
//   final String colorScheme;
//   @HiveField(3)
//   final bool useMaterial3;
//   @HiveField(4)
//   final bool useSubThemes;
//   @HiveField(5)
//   final double surfaceModeLight;
//   @HiveField(6)
//   final double surfaceModeDark;
//   @HiveField(7)
//   final bool useKeyColors;
//   @HiveField(8)
//   final bool useAppbarColors;
//   @HiveField(9)
//   final bool swapLightColors;
//   @HiveField(10)
//   final bool swapDarkColors;
//   @HiveField(11)
//   final bool useTertiary;
//   @HiveField(12)
//   final int blendLevel;
//   @HiveField(13)
//   final double appBarOpacity;
//   @HiveField(14)
//   final bool transparentStatusBar;
//   @HiveField(15)
//   final double tabBarOpacity;
//   @HiveField(16)
//   final double bottomBarOpacity;
//   @HiveField(17)
//   final bool tooltipsMatchBackground;
//   @HiveField(18)
//   final double defaultRadius;
//   @HiveField(19)
//   final bool useTextTheme;
//   @HiveField(20)
//   final String tabBarStyle;

//   ThemeSettings({
//     this.themeMode = 'system',
//     this.amoled = false,
//     this.colorScheme = 'red',
//     this.useMaterial3 = true,
//     this.useSubThemes = true,
//     this.surfaceModeLight = 0,
//     this.surfaceModeDark = 0,
//     this.useKeyColors = true,
//     this.useAppbarColors = false,
//     this.swapLightColors = false,
//     this.swapDarkColors = false,
//     this.useTertiary = true,
//     this.blendLevel = 0,
//     this.appBarOpacity = 1.0,
//     this.transparentStatusBar = false,
//     this.tabBarOpacity = 1.0,
//     this.bottomBarOpacity = 1.0,
//     this.tooltipsMatchBackground = false,
//     this.defaultRadius = 12.0,
//     this.useTextTheme = true,
//     this.tabBarStyle = 'forBackground',
//   });

//   ThemeSettings copyWith({
//     String? themeMode,
//     bool? amoled,
//     String? colorScheme,
//     bool? useMaterial3,
//     bool? useSubThemes,
//     double? surfaceModeLight,
//     double? surfaceModeDark,
//     bool? useKeyColors,
//     bool? useAppbarColors,
//     bool? swapLightColors,
//     bool? swapDarkColors,
//     bool? useTertiary,
//     int? blendLevel,
//     double? appBarOpacity,
//     bool? transparentStatusBar,
//     double? tabBarOpacity,
//     double? bottomBarOpacity,
//     bool? tooltipsMatchBackground,
//     double? defaultRadius,
//     bool? useTextTheme,
//     String? tabBarStyle,
//   }) {
//     return ThemeSettings(
//       themeMode: themeMode ?? this.themeMode,
//       amoled: amoled ?? this.amoled,
//       colorScheme: colorScheme ?? this.colorScheme,
//       useMaterial3: useMaterial3 ?? this.useMaterial3,
//       useSubThemes: useSubThemes ?? this.useSubThemes,
//       surfaceModeLight: surfaceModeLight ?? this.surfaceModeLight,
//       surfaceModeDark: surfaceModeDark ?? this.surfaceModeDark,
//       useKeyColors: useKeyColors ?? this.useKeyColors,
//       useAppbarColors: useAppbarColors ?? this.useAppbarColors,
//       swapLightColors: swapLightColors ?? this.swapLightColors,
//       swapDarkColors: swapDarkColors ?? this.swapDarkColors,
//       useTertiary: useTertiary ?? this.useTertiary,
//       blendLevel: blendLevel ?? this.blendLevel,
//       appBarOpacity: appBarOpacity ?? this.appBarOpacity,
//       transparentStatusBar: transparentStatusBar ?? this.transparentStatusBar,
//       tabBarOpacity: tabBarOpacity ?? this.tabBarOpacity,
//       bottomBarOpacity: bottomBarOpacity ?? this.bottomBarOpacity,
//       tooltipsMatchBackground: tooltipsMatchBackground ?? this.tooltipsMatchBackground,
//       defaultRadius: defaultRadius ?? this.defaultRadius,
//       useTextTheme: useTextTheme ?? this.useTextTheme,
//       tabBarStyle: tabBarStyle ?? this.tabBarStyle,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'themeMode': themeMode,
//       'amoled': amoled,
//       'colorScheme': colorScheme,
//       'useMaterial3': useMaterial3,
//       'useSubThemes': useSubThemes,
//       'surfaceModeLight': surfaceModeLight,
//       'surfaceModeDark': surfaceModeDark,
//       'useKeyColors': useKeyColors,
//       'useAppbarColors': useAppbarColors,
//       'swapLightColors': swapLightColors,
//       'swapDarkColors': swapDarkColors,
//       'useTertiary': useTertiary,
//       'blendLevel': blendLevel,
//       'appBarOpacity': appBarOpacity,
//       'transparentStatusBar': transparentStatusBar,
//       'tabBarOpacity': tabBarOpacity,
//       'bottomBarOpacity': bottomBarOpacity,
//       'tooltipsMatchBackground': tooltipsMatchBackground,
//       'defaultRadius': defaultRadius,
//       'useTextTheme': useTextTheme,
//       'tabBarStyle': tabBarStyle,
//     };
//   }

//   factory ThemeSettings.fromMap(Map<String, dynamic> map) {
//     return ThemeSettings(
//       themeMode: map['themeMode'] as String,
//       amoled: map['amoled'] as bool,
//       colorScheme: map['colorScheme'] as String,
//       useMaterial3: map['useMaterial3'] as bool,
//       useSubThemes: map['useSubThemes'] as bool,
//       surfaceModeLight: map['surfaceModeLight'] as double,
//       surfaceModeDark: map['surfaceModeDark'] as double,
//       useKeyColors: map['useKeyColors'] as bool,
//       useAppbarColors: map['useAppbarColors'] as bool,
//       swapLightColors: map['swapLightColors'] as bool,
//       swapDarkColors: map['swapDarkColors'] as bool,
//       useTertiary: map['useTertiary'] as bool,
//       blendLevel: map['blendLevel'] as int,
//       appBarOpacity: map['appBarOpacity'] as double,
//       transparentStatusBar: map['transparentStatusBar'] as bool,
//       tabBarOpacity: map['tabBarOpacity'] as double,
//       bottomBarOpacity: map['bottomBarOpacity'] as double,
//       tooltipsMatchBackground: map['tooltipsMatchBackground'] as bool,
//       defaultRadius: map['defaultRadius'] as double,
//       useTextTheme: map['useTextTheme'] as bool,
//       tabBarStyle: map['tabBarStyle'] as String,
//     );
//   }

//   String toJson() => json.encode(toMap());

//   factory ThemeSettings.fromJson(String source) => ThemeSettings.fromMap(json.decode(source) as Map<String, dynamic>);

//   @override
//   String toString() {
//     return 'ThemeSettings(themeMode: $themeMode, amoled: $amoled, colorScheme: $colorScheme, useMaterial3: $useMaterial3, useSubThemes: $useSubThemes, surfaceModeLight: $surfaceModeLight, surfaceModeDark: $surfaceModeDark, useKeyColors: $useKeyColors, useAppbarColors: $useAppbarColors, swapLightColors: $swapLightColors, swapDarkColors: $swapDarkColors, useTertiary: $useTertiary, blendLevel: $blendLevel, appBarOpacity: $appBarOpacity, transparentStatusBar: $transparentStatusBar, tabBarOpacity: $tabBarOpacity, bottomBarOpacity: $bottomBarOpacity, tooltipsMatchBackground: $tooltipsMatchBackground, defaultRadius: $defaultRadius, useTextTheme: $useTextTheme, tabBarStyle: $tabBarStyle)';
//   }

//   @override
//   bool operator ==(covariant ThemeSettings other) {
//     if (identical(this, other)) return true;
  
//     return 
//       other.themeMode == themeMode &&
//       other.amoled == amoled &&
//       other.colorScheme == colorScheme &&
//       other.useMaterial3 == useMaterial3 &&
//       other.useSubThemes == useSubThemes &&
//       other.surfaceModeLight == surfaceModeLight &&
//       other.surfaceModeDark == surfaceModeDark &&
//       other.useKeyColors == useKeyColors &&
//       other.useAppbarColors == useAppbarColors &&
//       other.swapLightColors == swapLightColors &&
//       other.swapDarkColors == swapDarkColors &&
//       other.useTertiary == useTertiary &&
//       other.blendLevel == blendLevel &&
//       other.appBarOpacity == appBarOpacity &&
//       other.transparentStatusBar == transparentStatusBar &&
//       other.tabBarOpacity == tabBarOpacity &&
//       other.bottomBarOpacity == bottomBarOpacity &&
//       other.tooltipsMatchBackground == tooltipsMatchBackground &&
//       other.defaultRadius == defaultRadius &&
//       other.useTextTheme == useTextTheme &&
//       other.tabBarStyle == tabBarStyle;
//   }

//   @override
//   int get hashCode {
//     return themeMode.hashCode ^
//       amoled.hashCode ^
//       colorScheme.hashCode ^
//       useMaterial3.hashCode ^
//       useSubThemes.hashCode ^
//       surfaceModeLight.hashCode ^
//       surfaceModeDark.hashCode ^
//       useKeyColors.hashCode ^
//       useAppbarColors.hashCode ^
//       swapLightColors.hashCode ^
//       swapDarkColors.hashCode ^
//       useTertiary.hashCode ^
//       blendLevel.hashCode ^
//       appBarOpacity.hashCode ^
//       transparentStatusBar.hashCode ^
//       tabBarOpacity.hashCode ^
//       bottomBarOpacity.hashCode ^
//       tooltipsMatchBackground.hashCode ^
//       defaultRadius.hashCode ^
//       useTextTheme.hashCode ^
//       tabBarStyle.hashCode;
//   }

//   FlexScheme get flexSchemeEnum => FlexScheme.values.firstWhere(
//         (e) => e.name == colorScheme,
//         orElse: () => FlexScheme.red,
//       );

//   FlexTabBarStyle get flexTabBarStyleEnum => FlexTabBarStyle.values.firstWhere(
//         (e) => e.name == tabBarStyle,
//         orElse: () => FlexTabBarStyle.forBackground,
//       );
// }
