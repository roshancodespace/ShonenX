import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';

enum ThemeColorSource {
  dynamic,
  wallpaperImageSeed,
  customSeed,
  customPrimary,
  exclusive,
  flexScheme,
}

class ResolvedThemeColors {
  const ResolvedThemeColors({
    required this.source,
    required this.prefs,
    required this.brightness,
    this.colorScheme,
    this.customColors,
    this.exclusive,
  });

  final ThemeColorSource source;
  final ThemePrefsState prefs;
  final Brightness brightness;
  final ColorScheme? colorScheme;
  final FlexSchemeColor? customColors;
  final ExclusiveSchemeData? exclusive;

  Color get primaryKey => _keyColors.primary;
  Color get secondaryKey => _keyColors.secondary;
  Color get tertiaryKey => _keyColors.tertiary;

  bool get usesConfiguredFlexScheme =>
      colorScheme == null && customColors == null && exclusive == null;

  FlexSchemeColor get _keyColors {
    final scheme = colorScheme;
    if (scheme != null) {
      return FlexSchemeColor(
        primary: scheme.primary,
        secondary: scheme.secondary,
        tertiary: scheme.tertiary,
      );
    }
    final custom = customColors;
    if (custom != null) return custom;
    final flex = FlexColor.schemes[prefs.flexScheme] ??
        FlexColor.schemes[FlexScheme.material]!;
    return brightness == Brightness.dark ? flex.dark : flex.light;
  }
}

ResolvedThemeColors resolveThemeColors(
  ThemePrefsState prefs, {
  required Brightness brightness,
  ColorScheme? dynamicColorScheme,
}) {
  final isDark = brightness == Brightness.dark;
  final exclusive = prefs.exclusiveScheme != null
      ? exclusiveSchemes[prefs.exclusiveScheme]
      : null;

  var source = ThemeColorSource.flexScheme;
  ColorScheme? effectiveColorScheme = dynamicColorScheme;
  if (effectiveColorScheme != null) {
    source = ThemeColorSource.dynamic;
  } else if (prefs.useImageColors &&
      prefs.wallpaperSettings?.imageColorSeed != null) {
    effectiveColorScheme = ColorScheme.fromSeed(
      seedColor: Color(prefs.wallpaperSettings!.imageColorSeed!),
      brightness: brightness,
    );
    source = ThemeColorSource.wallpaperImageSeed;
  } else if (prefs.colorSeed != null) {
    effectiveColorScheme = ColorScheme.fromSeed(
      seedColor: Color(prefs.colorSeed!),
      brightness: brightness,
    );
    source = ThemeColorSource.customSeed;
  }

  FlexSchemeColor? customColors;
  if (effectiveColorScheme == null && prefs.primaryColor != null) {
    final primary = Color(prefs.primaryColor!);
    final secondary = prefs.secondaryColor != null
        ? Color(prefs.secondaryColor!)
        : FlexSchemeColor.from(
            primary: primary,
            brightness: brightness,
          ).secondary;
    final tertiary = prefs.tertiaryColor != null
        ? Color(prefs.tertiaryColor!)
        : FlexSchemeColor.from(
            primary: primary,
            brightness: brightness,
          ).tertiary;

    customColors = FlexSchemeColor(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
    );
    source = ThemeColorSource.customPrimary;
  } else if (effectiveColorScheme == null && exclusive != null) {
    customColors = isDark ? exclusive.dark : exclusive.light;
    source = ThemeColorSource.exclusive;
  }

  return ResolvedThemeColors(
    source: source,
    prefs: prefs,
    brightness: brightness,
    colorScheme: effectiveColorScheme,
    customColors: customColors,
    exclusive: exclusive,
  );
}
