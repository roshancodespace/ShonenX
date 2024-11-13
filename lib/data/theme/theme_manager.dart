import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ThemeType {
  light,
  dark,
  modernMint, // Fresh, clean look
  oceanBreeze, // Calming blue theme
  midnightPro, // Professional dark theme
  rosePetal, // Soft pink theme
  monochrome, // Black and white
  techMinimal, // Minimalist with accent
  nordicFrost, // Scandinavian inspired
  warmCoffee, // Earthy tones
  ultraViolet, // Modern purple
  neoTokyo, // Cyberpunk inspired
}

class ThemeManager {
  static ThemeType? getThemeType(String themeName) {
    // Convert the input string to lowercase for case-insensitive comparison
    String lowerThemeName = themeName.toLowerCase();
    // Iterate through each value in ThemeType
  for (ThemeType type in ThemeType.values) {
    // Check if the name of the enum matches the input
    if (type.toString().split('.').last.toLowerCase() == lowerThemeName) {
      return type;
    }
  }
  return null;
  }

  static ThemeData getTheme(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.light:
        return ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          textTheme: GoogleFonts.poppinsTextTheme(),
        );
      case ThemeType.dark:
        return ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark().copyWith(primary: Colors.black),
          textTheme: GoogleFonts.poppinsTextTheme().apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        );
      case ThemeType.modernMint:
        return ThemeData(
          primarySwatch: Colors.green,
          brightness: Brightness.light,
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: Color(0xFF000000),
            secondary: Color(0xFF44C8A8),
          ),
        );
      case ThemeType.oceanBreeze:
        return ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: Color(0xFF00BCD4),
          ),
        );
      case ThemeType.midnightPro:
        return ThemeData(
          primarySwatch: Colors.indigo,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(),
          textTheme: GoogleFonts.poppinsTextTheme().apply(
            displayColor: Color(0xFF673AB7),
            bodyColor: Color(0xFF673AB7),
          ),
        );
      case ThemeType.rosePetal:
        return ThemeData(
          primarySwatch: Colors.pink,
          brightness: Brightness.light,
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: Color(0xFFE91E63),
          ),
        );
      case ThemeType.monochrome:
        return ThemeData(
          primarySwatch: Colors.grey,
          brightness: Brightness.light,
          textTheme: GoogleFonts.poppinsTextTheme(),
        );
      case ThemeType.techMinimal:
        return ThemeData(
          primarySwatch: Colors.indigo,
          brightness: Brightness.light,
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: Color(0xFF3F51B5),
          ),
        );
      case ThemeType.nordicFrost:
        return ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: Color(0xFF2196F3),
          ),
        );
      case ThemeType.warmCoffee:
        return ThemeData(
          primarySwatch: Colors.brown,
          brightness: Brightness.light,
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: Color(0xFF8D6E63),
          ),
        );
      case ThemeType.ultraViolet:
        return ThemeData(
          primarySwatch: Colors.purple,
          brightness: Brightness.light,
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: Color(0xFF9B59B6),
          ),
        );
      case ThemeType.neoTokyo:
        return ThemeData(
          primarySwatch: Colors.pink,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(),
          textTheme: GoogleFonts.poppinsTextTheme().apply(
            displayColor: Color(0xFFF44336),
            bodyColor: Color(0xFFF44336),
          ),
        );
      default:
        return ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          textTheme: GoogleFonts.poppinsTextTheme(),
        );
    }
  }
}
