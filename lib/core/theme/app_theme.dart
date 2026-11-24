import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/core/theme/theme_color_resolver.dart';

typedef ThemeModifier =
    ThemeData Function(ThemeData theme, ThemePrefsState prefs);

class AppTheme {
  AppTheme._();

  static const _buttonMinSize = Size(64, 48);

  static const _fontFamilyFallback = <String>[
    'Noto Sans',
    'Noto Sans Arabic',
    'Noto Sans Bengali',
    'Noto Sans Devanagari',
    'Noto Sans JP',
    'Noto Sans TC',
    'Noto Sans HK',
    'sans-serif',
  ];

  static TextTheme _applyFontFallback(TextTheme textTheme) {
    return textTheme.apply(fontFamilyFallback: _fontFamilyFallback);
  }

  static ThemeData light(ThemePrefsState prefs, dynamic colorScheme) {
    return _buildTheme(
      brightness: Brightness.light,
      prefs: prefs,
      colorScheme: colorScheme,
    );
  }

  static ThemeData dark(ThemePrefsState prefs, dynamic colorScheme) {
    return _buildTheme(
      brightness: Brightness.dark,
      prefs: prefs,
      colorScheme: colorScheme,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ThemePrefsState prefs,
    required dynamic colorScheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final resolved = resolveThemeColors(
      prefs,
      brightness: brightness,
      dynamicColorScheme: colorScheme,
    );

    var cs = resolved.colorScheme;
    if (prefs.swapColors) {
      cs = cs.copyWith(
        primary: cs.secondary,
        onPrimary: cs.onSecondary,
        primaryContainer: cs.secondaryContainer,
        onPrimaryContainer: cs.onSecondaryContainer,
        secondary: cs.primary,
        onSecondary: cs.onPrimary,
        secondaryContainer: cs.primaryContainer,
        onSecondaryContainer: cs.onPrimaryContainer,
        primaryFixed: cs.secondaryFixed,
        primaryFixedDim: cs.secondaryFixedDim,
        onPrimaryFixed: cs.onSecondaryFixed,
        onPrimaryFixedVariant: cs.onSecondaryFixedVariant,
        secondaryFixed: cs.primaryFixed,
        secondaryFixedDim: cs.primaryFixedDim,
        onSecondaryFixed: cs.onPrimaryFixed,
        onSecondaryFixedVariant: cs.onPrimaryFixedVariant,
      );
    }

    final blendLevel = prefs.blendLevel.clamp(0, 40);
    if (blendLevel > 0) {
      final blendFactor = (blendLevel / 40.0) * (isDark ? 0.20 : 0.12);
      final tint = cs.primary;
      Color blend(Color surface) =>
          Color.alphaBlend(tint.withValues(alpha: blendFactor), surface);

      cs = cs.copyWith(
        surface: blend(cs.surface),
        surfaceDim: blend(cs.surfaceDim),
        surfaceBright: blend(cs.surfaceBright),
        surfaceContainerLowest: blend(cs.surfaceContainerLowest),
        surfaceContainerLow: blend(cs.surfaceContainerLow),
        surfaceContainer: blend(cs.surfaceContainer),
        surfaceContainerHigh: blend(cs.surfaceContainerHigh),
        surfaceContainerHighest: blend(cs.surfaceContainerHighest),
      );
    }

    if (isDark && prefs.useAmoled) {
      cs = cs.copyWith(surface: const Color(0xFF000000));
    } else if (prefs.surfaceColor != null) {
      final sCol = Color(prefs.surfaceColor!);
      cs = cs.copyWith(surface: sCol);
    }

    final textTheme = _applyFontFallback(
      GoogleFonts.montserratTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
    );

    final scaffoldBg = isDark
        ? (prefs.useAmoled
              ? const Color(0xFF000000)
              : (prefs.surfaceColor != null
                    ? Color(prefs.surfaceColor!)
                    : cs.surface))
        : (prefs.surfaceColor != null
              ? Color(prefs.surfaceColor!)
              : cs.surface);

    ThemeData theme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffoldBg,
      pageTransitionsTheme: _pageTransitionsTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return _themeModifiers.fold(theme, (t, modifier) => modifier(t, prefs));
  }

  static final List<ThemeModifier> _themeModifiers = [_widgets, _shadows];

  static ThemeData _widgets(ThemeData theme, ThemePrefsState prefs) {
    final cs = theme.colorScheme;

    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
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
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: _buttonMinSize,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(prefs.uiRoundness),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: _buttonMinSize,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(prefs.uiRoundness),
          ),
        ),
      ),
    );
  }

  static ThemeData _shadows(ThemeData theme, ThemePrefsState prefs) {
    return theme.copyWith(shadowColor: Colors.transparent);
  }

  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: AppPageTransition(),
      TargetPlatform.linux: AppPageTransition(),
      TargetPlatform.windows: AppPageTransition(),
      TargetPlatform.iOS: AppPageTransition(),
      TargetPlatform.macOS: AppPageTransition(),
      TargetPlatform.fuchsia: AppPageTransition(),
    },
  );
}

class AppPageTransition extends PageTransitionsBuilder {
  const AppPageTransition();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

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
