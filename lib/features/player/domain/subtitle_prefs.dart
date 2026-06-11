import 'dart:ui';

class SubtitlePrefs {
  final bool useCustomSubtitle;
  final double fontSize;
  final int fontColor;
  final int backgroundColor;
  final int outlineColor;
  final double bottomPadding;
  final bool bold;
  final double outlineSize;

  const SubtitlePrefs({
    this.useCustomSubtitle = true,
    this.fontSize = 1.0,
    this.fontColor = 0xFFFFFFFF, // White
    this.backgroundColor = 0x80000000, // Semi-transparent black
    this.outlineColor = 0xFF000000, // Black
    this.bottomPadding = 20.0,
    this.bold = true,
    this.outlineSize = 1.5,
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
    };
  }

  Color get color => Color(fontColor);
  Color get bg => Color(backgroundColor);
  Color get outline => Color(outlineColor);
}

double getResponsiveSubtitleSize(double screenWidth, double multiplier) {
  // Base font size is 4.5% of screen width. Multiplier scales this base.
  return (screenWidth * 0.045) * multiplier;
}
