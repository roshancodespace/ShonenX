import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubtitlePrefs {
  final bool useCustomSubtitle;
  final double fontSize;
  final int fontColor;
  final int backgroundColor;
  final int outlineColor;
  final double bottomPadding;
  final bool bold;
  final double outlineSize;
  final int shadowColor;
  final double shadowOffsetX;
  final double shadowOffsetY;
  final double shadowBlur;
  final String fontFamily;
  final double letterSpacing;
  final double wordSpacing;
  final double lineHeight;

  const SubtitlePrefs({
    this.useCustomSubtitle = true,
    this.fontSize = 1.0,
    this.fontColor = 0xFFFFFFFF, // White
    this.backgroundColor = 0x80000000, // Semi-transparent black
    this.outlineColor = 0xFF000000, // Black
    this.bottomPadding = 20.0,
    this.bold = true,
    this.outlineSize = 1.5,
    this.shadowColor = 0x00000000, // Transparent
    this.shadowOffsetX = 2.0,
    this.shadowOffsetY = 2.0,
    this.shadowBlur = 4.0,
    this.fontFamily = 'Default',
    this.letterSpacing = 0.0,
    this.wordSpacing = 0.0,
    this.lineHeight = 1.15,
  });

  SubtitlePrefs copyWith({
    bool? useCustomSubtitle,
    double? fontSize,
    int? fontColor,
    int? backgroundColor,
    int? outlineColor,
    double? bottomPadding,
    bool? bold,
    double? outlineSize,
    int? shadowColor,
    double? shadowOffsetX,
    double? shadowOffsetY,
    double? shadowBlur,
    String? fontFamily,
    double? letterSpacing,
    double? wordSpacing,
    double? lineHeight,
  }) {
    return SubtitlePrefs(
      useCustomSubtitle: useCustomSubtitle ?? this.useCustomSubtitle,
      fontSize: fontSize ?? this.fontSize,
      fontColor: fontColor ?? this.fontColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      outlineColor: outlineColor ?? this.outlineColor,
      bottomPadding: bottomPadding ?? this.bottomPadding,
      bold: bold ?? this.bold,
      outlineSize: outlineSize ?? this.outlineSize,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      fontFamily: fontFamily ?? this.fontFamily,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }

  factory SubtitlePrefs.fromMap(Map<String, dynamic> map) {
    double savedFontSize = map['fontSize']?.toDouble() ?? 1.0;
    // Migrate old huge percentage values to 1.0 multiplier
    if (savedFontSize > 5.0) {
      savedFontSize = 1.0;
    }

    return SubtitlePrefs(
      useCustomSubtitle: map['useCustomSubtitle'] ?? true,
      fontSize: savedFontSize.clamp(0.5, 3.0),
      fontColor: map['fontColor'] ?? 0xFFFFFFFF,
      backgroundColor: map['backgroundColor'] ?? 0x80000000,
      outlineColor: map['outlineColor'] ?? 0xFF000000,
      bottomPadding: map['bottomPadding']?.toDouble() ?? 20.0,
      bold: map['bold'] ?? true,
      outlineSize: map['outlineSize']?.toDouble() ?? 1.5,
      shadowColor: map['shadowColor'] ?? 0x00000000,
      shadowOffsetX: map['shadowOffsetX']?.toDouble() ?? 2.0,
      shadowOffsetY: map['shadowOffsetY']?.toDouble() ?? 2.0,
      shadowBlur: map['shadowBlur']?.toDouble() ?? 4.0,
      fontFamily: map['fontFamily'] ?? 'Default',
      letterSpacing: map['letterSpacing']?.toDouble() ?? 0.0,
      wordSpacing: map['wordSpacing']?.toDouble() ?? 0.0,
      lineHeight: map['lineHeight']?.toDouble() ?? 1.15,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'useCustomSubtitle': useCustomSubtitle,
      'fontSize': fontSize,
      'fontColor': fontColor,
      'backgroundColor': backgroundColor,
      'outlineColor': outlineColor,
      'bottomPadding': bottomPadding,
      'bold': bold,
      'outlineSize': outlineSize,
      'shadowColor': shadowColor,
      'shadowOffsetX': shadowOffsetX,
      'shadowOffsetY': shadowOffsetY,
      'shadowBlur': shadowBlur,
      'fontFamily': fontFamily,
      'letterSpacing': letterSpacing,
      'wordSpacing': wordSpacing,
      'lineHeight': lineHeight,
    };
  }

  Color get color => Color(fontColor);
  Color get bg => Color(backgroundColor);
  Color get outline => Color(outlineColor);
  Color get shadow => Color(shadowColor);
}

double getResponsiveSubtitleSize(double screenWidth, double multiplier) {
  // Base size starts at a readable 16px and scales gently with screen width, clamped at 26px for 1.0x scale.
  final baseSize = (14.0 + (screenWidth * 0.012)).clamp(16.0, 26.0);
  return baseSize * multiplier;
}

List<Shadow>? getSubtitleShadows(SubtitlePrefs prefs) {
  final shadows = <Shadow>[];

  // Drop Shadow
  if (prefs.shadowColor != 0x00000000 && (prefs.shadowOffsetX != 0 || prefs.shadowOffsetY != 0 || prefs.shadowBlur != 0)) {
    shadows.add(
      Shadow(
        offset: Offset(prefs.shadowOffsetX, prefs.shadowOffsetY),
        blurRadius: prefs.shadowBlur,
        color: Color(prefs.shadowColor),
      ),
    );
  }

  // Outline (Stroke Effect via 8-directional 0.0 blur offsets)
  if (prefs.outlineColor != 0x00000000 && prefs.outlineSize > 0) {
    final size = prefs.outlineSize;
    final color = Color(prefs.outlineColor);
    shadows.addAll([
      Shadow(offset: Offset(-size, 0), blurRadius: 0.0, color: color),
      Shadow(offset: Offset(size, 0), blurRadius: 0.0, color: color),
      Shadow(offset: Offset(0, -size), blurRadius: 0.0, color: color),
      Shadow(offset: Offset(0, size), blurRadius: 0.0, color: color),
      Shadow(offset: Offset(-size, -size), blurRadius: 0.0, color: color),
      Shadow(offset: Offset(size, -size), blurRadius: 0.0, color: color),
      Shadow(offset: Offset(-size, size), blurRadius: 0.0, color: color),
      Shadow(offset: Offset(size, size), blurRadius: 0.0, color: color),
    ]);
  }

  return shadows.isEmpty ? null : shadows;
}

const kSubtitleFonts = [
  'Default',
  'Roboto',
  'Open Sans',
  'Lato',
  'Oswald',
  'Poppins',
  'Nunito',
  'Inter',
];

TextStyle getSubtitleTextStyle(SubtitlePrefs prefs, double responsiveFontSize) {
  final baseStyle = TextStyle(
    fontSize: responsiveFontSize,
    color: prefs.color,
    backgroundColor: prefs.backgroundColor == 0x00000000 ? null : prefs.bg,
    fontWeight: prefs.bold ? FontWeight.w700 : FontWeight.w500,
    height: prefs.lineHeight,
    letterSpacing: prefs.letterSpacing,
    wordSpacing: prefs.wordSpacing,
    shadows: getSubtitleShadows(prefs),
  );

  if (prefs.fontFamily == 'Default') {
    return baseStyle;
  }
  try {
    return GoogleFonts.getFont(prefs.fontFamily, textStyle: baseStyle);
  } catch (_) {
    return baseStyle;
  }
}
