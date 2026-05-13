import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shonenx/core/providers/theme_prefs_provider.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';

class AppTheme {
  AppTheme._();

  static const _buttonMinSize = Size(64, 48);

  static ThemeData light(ThemePrefsState prefs, ColorScheme? colorScheme) {
    return _buildTheme(
      brightness: Brightness.light,
      prefs: prefs,
      colorScheme: colorScheme,
    );
  }

  static ThemeData dark(ThemePrefsState prefs, ColorScheme? colorScheme) {
    return _buildTheme(
      brightness: Brightness.dark,
      prefs: prefs,
      colorScheme: colorScheme,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ThemePrefsState prefs,
    required ColorScheme? colorScheme,
  }) {
    final isDark = brightness == Brightness.dark;

    final exclusive = prefs.exclusiveScheme != null
        ? exclusiveSchemes[prefs.exclusiveScheme]
        : null;

    final baseTheme = isDark
        ? FlexThemeData.dark(
            scheme: exclusive == null ? prefs.flexScheme : null,
            colors: exclusive?.dark,
            colorScheme: exclusive == null ? colorScheme : null,
            surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
            blendLevel: 5,
            appBarStyle: FlexAppBarStyle.surface,
            appBarOpacity: prefs.useAmoled ? 1.0 : 0.90,
            transparentStatusBar: true,
            darkIsTrueBlack: prefs.useAmoled,
            textTheme: GoogleFonts.montserratTextTheme(),
            useMaterial3: true,
            swapLegacyOnMaterial3: true,
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
            pageTransitionsTheme: _pageTransitionsTheme,
            subThemesData: _subThemesData(blendLevel: 30),
          )
        : FlexThemeData.light(
            scheme: exclusive == null ? prefs.flexScheme : null,
            colors: exclusive?.light,
            colorScheme: exclusive == null ? colorScheme : null,
            surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
            blendLevel: 5,
            appBarStyle: FlexAppBarStyle.surface,
            appBarOpacity: 0.95,
            transparentStatusBar: true,
            textTheme: GoogleFonts.montserratTextTheme(),
            useMaterial3: true,
            swapLegacyOnMaterial3: true,
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
            pageTransitionsTheme: _pageTransitionsTheme,
            subThemesData: _subThemesData(blendLevel: 20),
          );

    return _withSnackBarTheme(baseTheme);
  }

  static ThemeData _withSnackBarTheme(ThemeData theme) {
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

  static FlexSubThemesData _subThemesData({required int blendLevel}) {
    return FlexSubThemesData(
      blendOnLevel: blendLevel,
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
    );
  }

  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: AppPageTransition(),
      TargetPlatform.linux: AppPageTransition(),
      TargetPlatform.windows: AppPageTransition(),
    },
  );
}

class AppPageTransition extends PageTransitionsBuilder {
  const AppPageTransition();

  static const _curve = Curves.easeOutQuart;
  static const _reverseCurve = Curves.easeInQuart;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 360);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: _curve,
      reverseCurve: _reverseCurve,
    );

    final slide = Tween<Offset>(
      begin: const Offset(0.035, 0),
      end: Offset.zero,
    ).animate(fade);

    final scale = Tween<double>(begin: 0.985, end: 1).animate(fade);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(scale: scale, child: child),
      ),
    );
  }
}
