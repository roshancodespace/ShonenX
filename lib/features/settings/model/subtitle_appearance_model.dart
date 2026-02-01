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
}
