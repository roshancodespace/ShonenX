import 'dart:convert';

class SubtitleAppearanceModel {
  final double fontSize;
  final int textColor;
  final double backgroundOpacity;
  final bool hasShadow;
  final double shadowOpacity;
  final double shadowBlur;
  final String? fontFamily;
  final int position;
  final bool boldText;
  final bool forceUppercase;
  final double bottomMargin;
  final int backgroundColor;
  final int outlineColor;
  final double outlineWidth;

  SubtitleAppearanceModel({
    this.fontSize = 16.0,
    this.textColor = 0xFFFFFFFF,
    this.backgroundOpacity = 0.5,
    this.hasShadow = true,
    this.shadowOpacity = 0.5,
    this.shadowBlur = 2.0,
    this.fontFamily,
    this.position = 1,
    this.boldText = true,
    this.forceUppercase = false,
    this.bottomMargin = 20.0,
    this.backgroundColor = 0xFF000000,
    this.outlineColor = 0xFF000000,
    this.outlineWidth = 0.0,
  });

  SubtitleAppearanceModel copyWith({
    double? fontSize,
    int? textColor,
    double? backgroundOpacity,
    bool? hasShadow,
    double? shadowOpacity,
    double? shadowBlur,
    String? fontFamily,
    int? position,
    bool? boldText,
    bool? forceUppercase,
    double? bottomMargin,
    int? backgroundColor,
    int? outlineColor,
    double? outlineWidth,
  }) {
    return SubtitleAppearanceModel(
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      hasShadow: hasShadow ?? this.hasShadow,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      fontFamily: fontFamily ?? this.fontFamily,
      position: position ?? this.position,
      boldText: boldText ?? this.boldText,
      forceUppercase: forceUppercase ?? this.forceUppercase,
      bottomMargin: bottomMargin ?? this.bottomMargin,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      outlineColor: outlineColor ?? this.outlineColor,
      outlineWidth: outlineWidth ?? this.outlineWidth,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fontSize': fontSize,
      'textColor': textColor,
      'backgroundOpacity': backgroundOpacity,
      'hasShadow': hasShadow,
      'shadowOpacity': shadowOpacity,
      'shadowBlur': shadowBlur,
      'fontFamily': fontFamily,
      'position': position,
      'boldText': boldText,
      'forceUppercase': forceUppercase,
      'bottomMargin': bottomMargin,
      'backgroundColor': backgroundColor,
      'outlineColor': outlineColor,
      'outlineWidth': outlineWidth,
    };
  }

  factory SubtitleAppearanceModel.fromMap(Map<String, dynamic> map) {
    return SubtitleAppearanceModel(
      fontSize: map['fontSize']?.toDouble() ?? 16.0,
      textColor: map['textColor']?.toInt() ?? 0xFFFFFFFF,
      backgroundOpacity: map['backgroundOpacity']?.toDouble() ?? 0.5,
      hasShadow: map['hasShadow'] ?? true,
      shadowOpacity: map['shadowOpacity']?.toDouble() ?? 0.5,
      shadowBlur: map['shadowBlur']?.toDouble() ?? 2.0,
      fontFamily: map['fontFamily'],
      position: map['position']?.toInt() ?? 1,
      boldText: map['boldText'] ?? true,
      forceUppercase: map['forceUppercase'] ?? false,
      bottomMargin: map['bottomMargin']?.toDouble() ?? 20.0,
      backgroundColor: map['backgroundColor']?.toInt() ?? 0xFF000000,
      outlineColor: map['outlineColor']?.toInt() ?? 0xFF000000,
      outlineWidth: map['outlineWidth']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory SubtitleAppearanceModel.fromJson(String source) =>
      SubtitleAppearanceModel.fromMap(json.decode(source));
}
