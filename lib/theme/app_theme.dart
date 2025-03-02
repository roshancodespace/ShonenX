import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

class AppTheme {
  static ThemeData light(ThemeSettingsModel settings) {
    return FlexThemeData.light(
      scheme: settings.flexSchemeEnum,
      appBarStyle: FlexAppBarStyle.primary,
      appBarElevation: 4.0,
      appBarOpacity: settings.appBarOpacity,
      transparentStatusBar: settings.transparentStatusBar,
      blendLevel: settings.blendLevel,
      useMaterial3: settings.useMaterial3,
      bottomAppBarElevation: 8.0,
      swapColors: settings.swapLightColors,
      tabBarStyle: settings.flexTabBarStyleEnum,
      textTheme: GoogleFonts.montserratTextTheme(),
      subThemesData: settings.useSubThemes
          ? FlexSubThemesData(
              defaultRadius: settings.defaultRadius,
            )
          : null,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
    );
  }

  static ThemeData dark(ThemeSettingsModel settings) {
    return FlexThemeData.dark(
      scheme: settings.flexSchemeEnum,
      appBarStyle: FlexAppBarStyle.material,
      appBarElevation: 4.0,
      appBarOpacity: settings.appBarOpacity,
      transparentStatusBar: settings.transparentStatusBar,
      darkIsTrueBlack: settings.amoled,
      blendLevel: settings.blendLevel,
      useMaterial3: settings.useMaterial3,
      bottomAppBarElevation: 8.0,
      swapColors: settings.swapDarkColors,
      tabBarStyle: settings.flexTabBarStyleEnum,
      textTheme: GoogleFonts.montserratTextTheme(),
      subThemesData: settings.useSubThemes
          ? FlexSubThemesData(
              defaultRadius: settings.defaultRadius,
            )
          : null,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
    );
  }
}
