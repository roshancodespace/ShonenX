import 'package:flutter/material.dart';

class SubtitleStyle {
  final double fontSize;
  final Color textColor;
  final double backgroundOpacity;
  final bool hasShadow;

  SubtitleStyle({
    this.fontSize = 16.0,
    this.textColor = Colors.white,
    this.backgroundOpacity = 0.6,
    this.hasShadow = true,
  });

  SubtitleStyle copyWith({
    double? fontSize,
    Color? textColor,
    double? backgroundOpacity,
    bool? hasShadow,
  }) {
    return SubtitleStyle(
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      hasShadow: hasShadow ?? this.hasShadow,
    );
  }
}