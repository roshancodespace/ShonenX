// ignore_for_file: public_member_api_docs, sort_constructors_first


import 'dart:convert';

import 'package:flutter/material.dart';

class SubtitleStyle {
  final double fontSize;
  final Color textColor;
  final double backgroundOpacity;
  final bool hasShadow;
  final double shadowOpacity;
  final double shadowBlur;
  final String? fontFamily;
  final int position;

  SubtitleStyle({
    required this.fontSize,
    required this.textColor,
    required this.backgroundOpacity,
    required this.hasShadow,
    this.shadowOpacity = 0.5,
    this.shadowBlur = 2.0,
    this.fontFamily,
    this.position = 2,
  });

  SubtitleStyle copyWith({
    double? fontSize,
    Color? textColor,
    double? backgroundOpacity,
    bool? hasShadow,
    double? shadowOpacity,
    double? shadowBlur,
    String? fontFamily,
    int? position,
  }) {
    return SubtitleStyle(
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      hasShadow: hasShadow ?? this.hasShadow,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      fontFamily: fontFamily ?? this.fontFamily,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fontSize': fontSize,
      'textColor': textColor.value,
      'backgroundOpacity': backgroundOpacity,
      'hasShadow': hasShadow,
      'shadowOpacity': shadowOpacity,
      'shadowBlur': shadowBlur,
      'fontFamily': fontFamily,
      'position': position,
    };
  }

  factory SubtitleStyle.fromMap(Map<String, dynamic> map) {
    return SubtitleStyle(
      fontSize: map['fontSize'] as double,
      textColor: Color(map['textColor'] as int),
      backgroundOpacity: map['backgroundOpacity'] as double,
      hasShadow: map['hasShadow'] as bool,
      shadowOpacity: map['shadowOpacity'] as double,
      shadowBlur: map['shadowBlur'] as double,
      fontFamily: map['fontFamily'] != null ? map['fontFamily'] as String : null,
      position: map['position'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory SubtitleStyle.fromJson(String source) => SubtitleStyle.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SubtitleStyle(fontSize: $fontSize, textColor: $textColor, backgroundOpacity: $backgroundOpacity, hasShadow: $hasShadow, shadowOpacity: $shadowOpacity, shadowBlur: $shadowBlur, fontFamily: $fontFamily, position: $position)';
  }

  @override
  bool operator ==(covariant SubtitleStyle other) {
    if (identical(this, other)) return true;
  
    return 
      other.fontSize == fontSize &&
      other.textColor == textColor &&
      other.backgroundOpacity == backgroundOpacity &&
      other.hasShadow == hasShadow &&
      other.shadowOpacity == shadowOpacity &&
      other.shadowBlur == shadowBlur &&
      other.fontFamily == fontFamily &&
      other.position == position;
  }

  @override
  int get hashCode {
    return fontSize.hashCode ^
      textColor.hashCode ^
      backgroundOpacity.hashCode ^
      hasShadow.hashCode ^
      shadowOpacity.hashCode ^
      shadowBlur.hashCode ^
      fontFamily.hashCode ^
      position.hashCode;
  }
}
