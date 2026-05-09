import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shonenx/core/providers/theme_prefs_provider.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';

class AppTheme {
  static const _buttonMinSize = Size(64, 48);

  static ThemeData light(ThemePrefsState prefs, ColorScheme? colorScheme) {
    final exclusive = prefs.exclusiveScheme != null
        ? exclusiveSchemes[prefs.exclusiveScheme]
        : null;

    final theme = FlexThemeData.light(
      scheme: exclusive == null ? prefs.flexScheme : null,
      colors: exclusive?.light,
      colorScheme: exclusive == null ? colorScheme : null,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 4,
      appBarStyle: FlexAppBarStyle.surface,
      appBarOpacity: 0.95,
      transparentStatusBar: true,
      textTheme: GoogleFonts.montserratTextTheme(),
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      subThemesData: FlexSubThemesData(
        blendOnLevel: 20,
        blendOnColors: true,
        useMaterial3Typography: true,
        buttonMinSize: _buttonMinSize,
        fabUseShape: true,
        fabAlwaysCircular: true,
        interactionEffects: true,
        tintedDisabledControls: true,
        unselectedToggleIsColored: true,
        sliderValueTinted: true,
        switchThumbFixedSize: true,
      ),
    );

    final cs = theme.colorScheme;

    return theme.copyWith(
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: cs.surfaceContainerHigh,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: cs.primary,
      ),
    );
  }

  static ThemeData dark(ThemePrefsState prefs, ColorScheme? colorScheme) {
    final exclusive = prefs.exclusiveScheme != null
        ? exclusiveSchemes[prefs.exclusiveScheme]
        : null;

    final theme = FlexThemeData.dark(
      scheme: exclusive == null ? prefs.flexScheme : null,
      colors: exclusive?.dark,
      colorScheme: exclusive == null ? colorScheme : null,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 4,
      appBarStyle: FlexAppBarStyle.surface,
      appBarOpacity: prefs.useAmoled ? 1.0 : 0.90,
      transparentStatusBar: true,
      darkIsTrueBlack: prefs.useAmoled,
      textTheme: GoogleFonts.montserratTextTheme(),
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      subThemesData: FlexSubThemesData(
        blendOnLevel: 30,
        blendOnColors: true,
        useMaterial3Typography: true,
        buttonMinSize: _buttonMinSize,
        fabUseShape: true,
        fabAlwaysCircular: true,
        interactionEffects: true,
        tintedDisabledControls: true,
        unselectedToggleIsColored: true,
        sliderValueTinted: true,
        switchThumbFixedSize: true,
      ),
    );

    final cs = theme.colorScheme;

    return theme.copyWith(
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: cs.surfaceContainerHigh,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: cs.primary,
      ),
    );
  }
}
