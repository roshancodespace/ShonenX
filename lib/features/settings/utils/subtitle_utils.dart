import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shonenx/features/settings/model/subtitle_appearance_model.dart';

class SubtitleUtils {
  static const List<String> availableFonts = [
    'Default',
    'Roboto',
    'Open Sans',
    'Montserrat',
    'Lato',
    'Poppins',
    'Oswald',
    'Raleway',
    'Nunito',
    'Merriweather',
    'Playfair Display',
    'Ubuntu',
  ];

  static TextStyle getSubtitleTextStyle(SubtitleAppearanceModel style) {
    TextStyle baseStyle = TextStyle(
      fontSize: style.fontSize,
      fontWeight: style.boldText ? FontWeight.bold : FontWeight.normal,
      color: Color(style.textColor),
      shadows: style.hasShadow
          ? [
              Shadow(
                color: Colors.black.withOpacity(style.shadowOpacity),
                offset: const Offset(0, 0),
                blurRadius: style.shadowBlur,
              )
            ]
          : [],
    );

    if (style.fontFamily == null || style.fontFamily == 'Default') {
      return baseStyle;
    }

    try {
      return GoogleFonts.getFont(
        style.fontFamily!,
        textStyle: baseStyle,
      );
    } catch (e) {
      // Fallback if font fails to load
      return baseStyle;
    }
  }
}
