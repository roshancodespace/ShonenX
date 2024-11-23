import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ThemeType {
  dark,
  darkModernMint,
  darkOceanBreeze,
  darkMidnightPro,
  darkRosePetal,
  darkMonochrome,
  darkTechMinimal,
  darkNordicFrost,
  darkWarmCoffee,
  darkUltraViolet,
  darkNeoTokyo,
  darkEmeraldForest,
  darkSunsetGold,
  darkDigitalLavender,
  darkMaterialGrey,
  darkNightBlue,
  darkForestMoss,
  darkDesertSand,
  darkArcticIce,
  darkDeepSkyBlue,
  darkLushLavender,
  darkEarthyOlive,
  darkVibrantCoral,
  darkSerenityBlue,
  darkLushGreen,
  darkBoldRed,
  darkSoftPink,
  darkPaleYellow,
  darkModernGrey,
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

  static ThemeData getTheme(ThemeType themeType) {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return _createThemeData(
      colorScheme: _getColorScheme(themeType),
      textTheme: textTheme,
    );
  }

  static ThemeData _createThemeData({required ColorScheme colorScheme, required TextTheme textTheme}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
    );
  }

  static ColorScheme _getColorScheme(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.dark:
        return ColorScheme.dark(
          primary: Color(0xFF121212),
          secondary: Color(0xFF616161),
          surface: Color.fromARGB(255, 13, 13, 13),
          onSurface: Colors.white,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
        );
      case ThemeType.darkModernMint:
        return ColorScheme.dark(
          primary: Color(0xFF00BFA5),
          secondary: Color(0xFF1DE9B6),
          surface: Color(0xFF0D0D0D),
        );
      case ThemeType.darkOceanBreeze:
        return ColorScheme.dark(
          primary: Color(0xFF0288D1),
          secondary: Color(0xFF03A9F4),
          surface: Color(0xFF0A0A0A),
        );
      case ThemeType.darkMidnightPro:
        return ColorScheme.dark(
          primary: Color(0xFF3949AB),
          secondary: Color(0xFF5C6BC0),
          surface: Color(0xFF0D0D1A),
        );
      case ThemeType.darkRosePetal:
        return ColorScheme.dark(
          primary: Color(0xFFE91E63),
          secondary: Color(0xFFEC407A),
          surface: Color(0xFF180F16),
        );
      case ThemeType.darkMonochrome:
        return ColorScheme.dark(
          primary: Color(0xFF424242),
          secondary: Color(0xFF616161),
          surface: Color(0xFF0E0E0E),
        );
      case ThemeType.darkTechMinimal:
        return ColorScheme.dark(
          primary: Color(0xFF1976D2),
          secondary: Color(0xFF2196F3),
          surface: Color(0xFF050505),
        );
      case ThemeType.darkNordicFrost:
        return ColorScheme.dark(
          primary: Color(0xFF4FC3F7),
          secondary: Color(0xFF81D4FA),
          surface: Color(0xFF0E1113),
        );
      case ThemeType.darkWarmCoffee:
        return ColorScheme.dark(
          primary: Color(0xFF795548),
          secondary: Color(0xFF8D6E63),
          surface: Color(0xFF120F0E),
        );
      case ThemeType.darkUltraViolet:
        return ColorScheme.dark(
          primary: Color(0xFF6200EA),
          secondary: Color(0xFF7C4DFF),
          surface: Color(0xFF110F16),
        );
      case ThemeType.darkNeoTokyo:
        return ColorScheme.dark(
          primary: Color(0xFFE91E63),
          secondary: Color(0xFF00BCD4),
          surface: Color(0xFF1F1F1F),
        );
      case ThemeType.darkEmeraldForest:
        return ColorScheme.dark(
          primary: Color(0xFF2E7D32),
          secondary: Color(0xFF388E3C),
          surface: Color(0xFF0E1510),
        );
      case ThemeType.darkSunsetGold:
        return ColorScheme.dark(
          primary: Color(0xFFFF6F00),
          secondary: Color(0xFFFF8F00),
          surface: Color(0xFF170F00),
        );
      case ThemeType.darkDigitalLavender:
        return ColorScheme.dark(
          primary: Color(0xFF7B1FA2),
          secondary: Color(0xFF9C27B0),
          surface: Color(0xFF110F15),
        );
      case ThemeType.darkMaterialGrey:
        return ColorScheme.dark(
          primary: Color(0xFF455A64),
          secondary: Color(0xFF546E7A),
          surface: Color(0xFF0E0E0F),
        );
      case ThemeType.darkNightBlue:
        return ColorScheme.dark(
          primary: Color(0xFF1A237E),
          secondary: Color(0xFF283593),
          surface: Color(0xFF040407),
        );
      case ThemeType.darkForestMoss:
        return ColorScheme.dark(
          primary: Color(0xFF33691E),
          secondary: Color(0xFF558B2F),
          surface: Color(0xFF0E1510),
        );
      case ThemeType.darkDesertSand:
        return ColorScheme.dark(
          primary: Color(0xFFBF360C),
          secondary: Color(0xFFD84315),
          surface: Color(0xFF170D07),
        );
      case ThemeType.darkArcticIce:
        return ColorScheme.dark(
          primary: Color(0xFF00ACC1),
          secondary: Color(0xFF00BCD4),
          surface: Color(0xFF0E1113),
        );
      case ThemeType.darkDeepSkyBlue:
        return ColorScheme.dark(
          primary: Color(0xFF00B8D4),
          secondary: Color(0xFF18FFFF),
          surface: Color(0xFF0E1113),
        );
      case ThemeType.darkLushLavender:
        return ColorScheme.dark(
          primary: Color(0xFF9575CD),
          secondary: Color(0xFFBA68C8),
          surface: Color(0xFF110F15),
        );
      case ThemeType.darkEarthyOlive:
        return ColorScheme.dark(
          primary: Color(0xFF689F38),
          secondary: Color(0xFF7CB342),
          surface: Color(0xFF0E1510),
        );
      case ThemeType.darkVibrantCoral:
        return ColorScheme.dark(
          primary: Color(0xFFFF5722),
          secondary: Color(0xFFE64A19),
          surface: Color(0xFF170807),
        );
      case ThemeType.darkSerenityBlue:
        return ColorScheme.dark(
          primary: Color(0xFF42A5F5),
          secondary: Color(0xFF64B5F6),
          surface: Color(0xFF0A0A0A),
        );
      case ThemeType.darkLushGreen:
        return ColorScheme.dark(
          primary: Color(0xFF4CAF50),
          secondary: Color(0xFF66BB6A),
          surface: Color(0xFF0E1510),
        );
      case ThemeType.darkBoldRed:
        return ColorScheme.dark(
          primary: Color(0xFFE53935),
          secondary: Color(0xFFC62828),
          surface: Color(0xFF170708),
        );
      case ThemeType.darkSoftPink:
        return ColorScheme.dark(
          primary: Color(0xFFF06292),
          secondary: Color(0xFFEC407A),
          surface: Color(0xFF180F16),
        );
      case ThemeType.darkPaleYellow:
        return ColorScheme.dark(
          primary: Color(0xFFFFF176),
          secondary: Color(0xFFFFF59D),
          surface: Color(0xFF1A1A13),
        );
      case ThemeType.darkModernGrey:
        return ColorScheme.dark(
          primary: Color(0xFF546E7A),
          secondary: Color(0xFF607D8B),
          surface: Color(0xFF0E0E0F),
        );
      default:
        return ColorScheme.dark(
          primary: Color(0xFF2196F3),
          secondary: Color(0xFF03A9F4),
          surface: Color(0xFF121212),
        );
    }
  }
}