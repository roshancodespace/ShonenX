import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shonenx/core/providers/theme_prefs_provider.dart';

class AppTheme {
  static const _defaultRadius = 28.0;
  static const _buttonMinSize = Size(64, 48);
  static const _blendLevelLight = 8;
  static const _blendLevelDark = 8;

  static ThemeData light(ThemePrefsState prefs, ColorScheme? colorScheme) =>
      FlexThemeData.light(
        scheme: prefs.flexScheme,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: _blendLevelLight,
        appBarStyle: FlexAppBarStyle.primary,
        appBarOpacity: 0.95,
        transparentStatusBar: true,
        textTheme: GoogleFonts.montserratTextTheme(),
        subThemesData: FlexSubThemesData(
          blendOnLevel: 20,
          blendOnColors: true,
          useMaterial3Typography: true,
          buttonMinSize: _buttonMinSize,
          elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
          elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
          fabUseShape: true,
          interactionEffects: true,
          tintedDisabledControls: true,
          unselectedToggleIsColored: true,
          sliderValueTinted: true,
          fabAlwaysCircular: true,
          switchThumbFixedSize: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
      );

  static ThemeData dark(ThemePrefsState prefs, ColorScheme? colorScheme) =>
      FlexThemeData.dark(
        scheme: prefs.flexScheme,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: _blendLevelDark,
        appBarStyle: FlexAppBarStyle.surface,
        appBarOpacity: prefs.useAmoled ? 1.0 : 0.90,
        transparentStatusBar: true,
        darkIsTrueBlack: prefs.useAmoled,
        textTheme: GoogleFonts.montserratTextTheme(),
        subThemesData: FlexSubThemesData(
          blendOnLevel: 30,
          blendOnColors: true,
          useMaterial3Typography: true,
          buttonMinSize: _buttonMinSize,
          elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
          elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
          fabUseShape: true,
          interactionEffects: true,
          tintedDisabledControls: true,
          unselectedToggleIsColored: true,
          sliderValueTinted: true,
          fabAlwaysCircular: true,
          switchThumbFixedSize: true,
          appBarScrolledUnderElevation: 4,
          cardElevation: prefs.useAmoled ? 1 : 2,
          popupMenuElevation: 8,
          dialogElevation: 12,
        ),
        colorScheme: colorScheme,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
      );
}
