import 'package:material_ui/material_ui.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';
import 'package:shonenx/core/theme/standard_schemes.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';

enum ThemeColorSource {
  dynamic,
  wallpaperImageSeed,
  customSeed,
  customPrimary,
  exclusive,
  appScheme,
}

class ResolvedThemeColors {
  const ResolvedThemeColors({
    required this.source,
    required this.prefs,
    required this.brightness,
    required this.colorScheme,
    required this.primaryKey,
    required this.secondaryKey,
    required this.tertiaryKey,
    this.exclusive,
  });

  final ThemeColorSource source;
  final ThemePrefsState prefs;
  final Brightness brightness;
  final ColorScheme colorScheme;
  final Color primaryKey;
  final Color secondaryKey;
  final Color tertiaryKey;
  final ExclusiveSchemeData? exclusive;
}

ResolvedThemeColors resolveThemeColors(
  ThemePrefsState prefs, {
  required Brightness brightness,
  dynamic dynamicColorScheme,
}) {
  final isDark = brightness == Brightness.dark;
  final exclusive = prefs.exclusiveScheme != null
      ? exclusiveSchemes[prefs.exclusiveScheme]
      : null;

  var source = ThemeColorSource.appScheme;
  Color primaryKey;
  Color? secondaryKey;
  Color? tertiaryKey;
  ColorScheme? effectiveColorScheme;

  if (dynamicColorScheme != null) {
    try {
      final dynamic dyn = dynamicColorScheme;
      primaryKey = dyn.primary as Color;
      secondaryKey = dyn.secondary as Color?;
      tertiaryKey = dyn.tertiary as Color?;
      if (dynamicColorScheme is ColorScheme) {
        effectiveColorScheme = dynamicColorScheme;
      } else {
        effectiveColorScheme = ColorScheme.fromSeed(
          seedColor: primaryKey,
          brightness: brightness,
        );
      }
      source = ThemeColorSource.dynamic;
    } catch (_) {
      primaryKey = prefs.flexScheme.seedColor;
    }
  } else if (prefs.useImageColors &&
      prefs.wallpaperSettings?.imageColorSeed != null) {
    final seed = Color(prefs.wallpaperSettings!.imageColorSeed!);
    effectiveColorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    primaryKey = effectiveColorScheme.primary;
    secondaryKey = effectiveColorScheme.secondary;
    tertiaryKey = effectiveColorScheme.tertiary;
    source = ThemeColorSource.wallpaperImageSeed;
  } else if (prefs.colorSeed != null) {
    final seed = Color(prefs.colorSeed!);
    effectiveColorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    primaryKey = effectiveColorScheme.primary;
    secondaryKey = effectiveColorScheme.secondary;
    tertiaryKey = effectiveColorScheme.tertiary;
    source = ThemeColorSource.customSeed;
  } else if (prefs.primaryColor != null) {
    primaryKey = Color(prefs.primaryColor!);
    secondaryKey = prefs.secondaryColor != null
        ? Color(prefs.secondaryColor!)
        : null;
    tertiaryKey = prefs.tertiaryColor != null
        ? Color(prefs.tertiaryColor!)
        : null;
    effectiveColorScheme = ColorScheme.fromSeed(
      seedColor: primaryKey,
      brightness: brightness,
      primary: primaryKey,
      secondary: secondaryKey,
      tertiary: tertiaryKey,
    );
    source = ThemeColorSource.customPrimary;
  } else if (exclusive != null) {
    final colors = isDark ? exclusive.dark : exclusive.light;
    primaryKey = colors.primary;
    secondaryKey = colors.secondary;
    tertiaryKey = colors.tertiary;
    effectiveColorScheme = ColorScheme.fromSeed(
      seedColor: primaryKey,
      brightness: brightness,
      primary: colors.primary,
      primaryContainer: colors.primaryContainer,
      secondary: colors.secondary,
      secondaryContainer: colors.secondaryContainer,
      tertiary: colors.tertiary,
      tertiaryContainer: colors.tertiaryContainer,
    );
    source = ThemeColorSource.exclusive;
  } else {
    final schemeData = standardSchemes[prefs.flexScheme] ??
        standardSchemes[AppScheme.deepBlue]!;
    final colors = isDark ? schemeData.dark : schemeData.light;
    primaryKey = colors.primary;
    secondaryKey = colors.secondary;
    tertiaryKey = colors.tertiary;
    effectiveColorScheme = ColorScheme.fromSeed(
      seedColor: primaryKey,
      brightness: brightness,
      primary: colors.primary,
      primaryContainer: colors.primaryContainer,
      secondary: colors.secondary,
      secondaryContainer: colors.secondaryContainer,
      tertiary: colors.tertiary,
      tertiaryContainer: colors.tertiaryContainer,
    );
    source = ThemeColorSource.appScheme;
  }

  final finalScheme = effectiveColorScheme ??
      ColorScheme.fromSeed(
        seedColor: primaryKey,
        brightness: brightness,
      );

  return ResolvedThemeColors(
    source: source,
    prefs: prefs,
    brightness: brightness,
    colorScheme: finalScheme,
    primaryKey: primaryKey,
    secondaryKey: secondaryKey ?? finalScheme.secondary,
    tertiaryKey: tertiaryKey ?? finalScheme.tertiary,
    exclusive: exclusive,
  );
}
