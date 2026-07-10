import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/core/theme/exclusive_schemes.dart';

typedef ThemeModifier =
    ThemeData Function(ThemeData theme, ThemePrefsState prefs);

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
            colorScheme: colorScheme,
            surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
            blendLevel: prefs.blendLevel,
            swapColors: prefs.swapColors,
            appBarStyle: FlexAppBarStyle.surface,
            appBarOpacity: prefs.useAmoled ? 1.0 : 0.90,
            transparentStatusBar: true,
            darkIsTrueBlack: prefs.useAmoled,
            textTheme: GoogleFonts.montserratTextTheme(),
            useMaterial3: true,
            swapLegacyOnMaterial3: true,
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
            pageTransitionsTheme: _pageTransitionsTheme,
            subThemesData: _subThemesData(prefs),
          )
        : FlexThemeData.light(
            scheme: exclusive == null ? prefs.flexScheme : null,
            colors: exclusive?.light,
            colorScheme: colorScheme,
            surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
            blendLevel: prefs.blendLevel,
            swapColors: prefs.swapColors,
            appBarStyle: FlexAppBarStyle.surface,
            appBarOpacity: 0.95,
            transparentStatusBar: true,
            textTheme: GoogleFonts.montserratTextTheme(),
            useMaterial3: true,
            swapLegacyOnMaterial3: true,
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
            pageTransitionsTheme: _pageTransitionsTheme,
            subThemesData: _subThemesData(prefs),
          );

    return _themeModifiers.fold(
      baseTheme,
      (theme, modifier) => modifier(theme, prefs),
    );
  }

  static final List<ThemeModifier> _themeModifiers = [_widgets, _shadows];

  static ThemeData _widgets(ThemeData theme, ThemePrefsState prefs) {
    final cs = theme.colorScheme;

    return theme.copyWith(
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: cs.surfaceContainerHigh,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(prefs.uiRoundness),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: cs.primary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(prefs.uiRoundness),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(prefs.uiRoundness),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(prefs.uiRoundness),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(prefs.uiRoundness),
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        filled: true,
      ),
    );
  }

  static ThemeData _shadows(ThemeData theme, ThemePrefsState prefs) {
    return theme.copyWith(shadowColor: Colors.transparent);
  }

  static FlexSubThemesData _subThemesData(ThemePrefsState prefs) {
    return FlexSubThemesData(
      blendOnLevel: prefs.blendLevel,
      defaultRadius: prefs.uiRoundness,
      blendOnColors: true,
      useMaterial3Typography: true,
      buttonMinSize: _buttonMinSize,
      fabUseShape: true,
      fabAlwaysCircular: false,
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

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enterCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    final exitCurve = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    final slideIn = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(enterCurve);

    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1, 0),
    ).animate(exitCurve);

    return SlideTransition(
      position: slideOut,
      child: SlideTransition(position: slideIn, child: child),
    );
  }
}
