import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';
part 'subtitle_appearance_model.g.dart';

@HiveType(typeId: HiveTypeIds.subtitle)
class SubtitleAppearanceModel {
  @HiveField(0, defaultValue: 16.0)
  final double fontSize;
  @HiveField(1, defaultValue: 0xFFFFFFFF)
  final int textColor;
  @HiveField(2, defaultValue: 0.5)
  final double backgroundOpacity;
  @HiveField(3, defaultValue: true)
  final bool hasShadow;
  @HiveField(4, defaultValue: 0.5)
  final double shadowOpacity;
  @HiveField(5, defaultValue: 2.0)
  final double shadowBlur;
  @HiveField(6, defaultValue: null)
  final String? fontFamily;
  @HiveField(7, defaultValue: 1)
  final int position;
  @HiveField(8, defaultValue: true)
  final bool boldText;
  @HiveField(9, defaultValue: false)
  final bool forceUppercase;

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
    );
  }
}
