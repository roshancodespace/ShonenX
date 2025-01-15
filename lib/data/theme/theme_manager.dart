import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ThemeType {
  midnightNebula,
  crimsonAnime,
  etherealPurple,
  deepOceanStream,
  neonTokyo,
  twilightCosmos,
  shadowRealm,
  cyberAnime,
  moonlitSilver,
  darkChroma,
   // Dark Modes
  dark,
   
  // Light Modes
  softAnimeGlow,
  light,
}

class ThemeManager {
  static ThemeType? getThemeType(String themeName) {
    String lowerThemeName = themeName.toLowerCase();
    for (ThemeType type in ThemeType.values) {
      if (type.toString().split('.').last.toLowerCase() == lowerThemeName) {
        return type;
      }
    }
    return null;
  }

  // Custom gradient color class for more complex color handling
  static LinearGradient createLinearGradient(
      {required Color begin,
      required Color end,
      Alignment startAlignment = Alignment.centerLeft,
      Alignment endAlignment = Alignment.centerRight}) {
    return LinearGradient(
      colors: [begin, end],
      begin: startAlignment,
      end: endAlignment,
    );
  }

  static ThemeData getTheme(ThemeType themeType) {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return _createThemeData(
      colorScheme: _getColorScheme(themeType),
      textTheme: textTheme,
    );
  }

  static ThemeData _createThemeData(
      {required ColorScheme colorScheme, required TextTheme textTheme}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      extensions: [_createGradientExtension(colorScheme)],
    );
  }

  // Create a custom theme extension for gradients
  static ThemeExtension<GradientColors> _createGradientExtension(
      ColorScheme colorScheme) {
    return GradientColors(
      primaryGradient: createLinearGradient(
          begin: colorScheme.primary, end: colorScheme.secondary),
      secondaryGradient: createLinearGradient(
          begin: colorScheme.secondary, end: colorScheme.tertiary),
      tertiaryGradient: createLinearGradient(
          begin: colorScheme.tertiary, end: colorScheme.primary),
    );
  }

  static ColorScheme _getColorScheme(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.midnightNebula:
        return ColorScheme.dark(
          primary: Color(0xFF6A5ACD),      // Slate Blue
          secondary: Color(0xFF483D8B),    // Dark Slate Blue
          tertiary: Color(0xFF4B0082),     // Indigo
          surface: Color(0xFF121026),      // Deep Dark Blue-Purple
          onSurface: Color(0xFFE6E6FA),    // Lavender
        );
      case ThemeType.crimsonAnime:
        return ColorScheme.dark(
          primary: Color(0xFFDC143C),      // Crimson
          secondary: Color(0xFF8B0000),    // Dark Red
          tertiary: Color(0xFF4B0082),     // Indigo
          surface: Color(0xFF1A0A0A),      // Very Dark Red-Black
          onSurface: Color(0xFFF5F5F5),    // White Smoke
        );
      case ThemeType.etherealPurple:
        return ColorScheme.dark(
          primary: Color(0xFF8A2BE2),      // Blue Violet
          secondary: Color(0xFF9400D3),    // Dark Violet
          tertiary: Color(0xFF4B0082),     // Indigo
          surface: Color(0xFF1A0A1E),      // Very Dark Purple
          onSurface: Color(0xFFE6E6FA),    // Lavender
        );
      case ThemeType.deepOceanStream:
        return ColorScheme.dark(
          primary: Color(0xFF00CED1),      // Dark Turquoise
          secondary: Color(0xFF008B8B),    // Dark Cyan
          tertiary: Color(0xFF1E90FF),     // Dodger Blue
          surface: Color(0xFF0A1828),      // Very Dark Blue
          onSurface: Color(0xFFF0FFFF),    // Azure
        );
      case ThemeType.neonTokyo:
        return ColorScheme.dark(
          primary: Color(0xFF00FFFF),      // Cyan
          secondary: Color(0xFF1E90FF),    // Dodger Blue
          tertiary: Color(0xFF00FF00),     // Lime Green
          surface: Color(0xFF0A1A2A),      // Dark Cyber Blue
          onSurface: Color(0xFFF0F8FF),    // Alice Blue
        );
      case ThemeType.twilightCosmos:
        return ColorScheme.dark(
          primary: Color(0xFF9932CC),      // Dark Orchid
          secondary: Color(0xFF8A2BE2),    // Blue Violet
          tertiary: Color(0xFF4B0082),     // Indigo
          surface: Color(0xFF121212),      // Almost Black
          onSurface: Color(0xFFE6E6FA),    // Lavender
        );
      case ThemeType.shadowRealm:
        return ColorScheme.dark(
          primary: Color(0xFF2F4F4F),      // Dark Slate Gray
          secondary: Color(0xFF708090),    // Slate Gray
          tertiary: Color(0xFF3A3A3A),     // Dark Gray
          surface: Color(0xFF121212),      // Almost Black
          onSurface: Color(0xFFF5F5F5),    // White Smoke
        );
      case ThemeType.cyberAnime:
        return ColorScheme.dark(
          primary: Color(0xFF00FFFF),      // Cyan
          secondary: Color(0xFF1E90FF),    // Dodger Blue
          tertiary: Color(0xFF00FF00),     // Lime Green
          surface: Color(0xFF0A1A2A),      // Dark Cyber Blue
          onSurface: Color(0xFFF0F8FF),    // Alice Blue
        );
      case ThemeType.moonlitSilver:
        return ColorScheme.dark(
          primary: Color(0xFF708090),      // Slate Gray
          secondary: Color(0xFF4682B4),    // Steel Blue
          tertiary: Color(0xFF483D8B),     // Dark Slate Blue
          surface: Color(0xFF121212),      // Almost Black
          onSurface: Color(0xFFD3D3D3),    // Light Gray
        );
      case ThemeType.darkChroma:
        return ColorScheme.dark(
          primary: Color(0xFF8B008B),      // Dark Magenta
          secondary: Color(0xFF4B0082),    // Indigo
          tertiary: Color(0xFF9932CC),     // Dark Orchid
          surface: Color(0xFF1A0A1E),      // Very Dark Purple
          onSurface: Color(0xFFE6E6FA),    // Lavender
        );
      // Dark Modes
      case ThemeType.dark:
        return ColorScheme.dark(
          primary: Color(0xFF1A1A1A),      // Almost Black
          secondary: Color(0xFF505050),    // Ultra Dark Gray
          tertiary: Color(0xFF0A0A0A),     // Deepest Black
          surface: Color(0xFF0C0C0C),      // Pitch Black
          onSurface: Color(0xFFE0E0E0),    // Light Gray
        );
            
      // Light Modes
      case ThemeType.softAnimeGlow:
        return ColorScheme.light(
          primary: Color(0xFFFF69B4),      // Hot Pink
          secondary: Color(0xFFFFC0CB),    // Pink
          tertiary: Color(0xFFFFB6C1),     // Light Pink
          surface: Color(0xFFFFF0F5),      // Lavender Blush
          onSurface: Color(0xFF333333),    // Dark Gray
        );
      
      case ThemeType.light:
        return ColorScheme.light(
          primary: Color(0xFF8A2BE2),      // Blue Violet
          secondary: Color(0xFF9370DB),    // Medium Purple
          tertiary: Color(0xFFBA55D3),     // Medium Orchid
          surface: Color(0xFFFFFAF0),      // Ivory
          onSurface: Color(0xFF2F4F4F),    // Dark Slate Gray
        );
      
      default:
        return ColorScheme.dark(
          primary: Color(0xFF1A1A1A),      // Almost Black
          secondary: Color(0xFF121212),    // Ultra Dark Gray
          tertiary: Color(0xFF0A0A0A),     // Deepest Black
          surface: Color(0xFF0C0C0C),      // Pitch Black
          onSurface: Color(0xFFE0E0E0),    // Light Gray
        );
    }
  }
}

// Custom theme extension for gradients (unchanged from previous version)
class GradientColors extends ThemeExtension<GradientColors> {
  final LinearGradient primaryGradient;
  final LinearGradient secondaryGradient;
  final LinearGradient tertiaryGradient;

  GradientColors({
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.tertiaryGradient,
  });

  @override
  ThemeExtension<GradientColors> copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? secondaryGradient,
    LinearGradient? tertiaryGradient,
  }) {
    return GradientColors(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      secondaryGradient: secondaryGradient ?? this.secondaryGradient,
      tertiaryGradient: tertiaryGradient ?? this.tertiaryGradient,
    );
  }

  @override
  ThemeExtension<GradientColors> lerp(
    ThemeExtension<GradientColors>? other,
    double t,
  ) {
    if (other is! GradientColors) {
      return this;
    }
    return GradientColors(
      primaryGradient:
          LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      secondaryGradient:
          LinearGradient.lerp(secondaryGradient, other.secondaryGradient, t)!,
      tertiaryGradient:
          LinearGradient.lerp(tertiaryGradient, other.tertiaryGradient, t)!,
    );
  }
}