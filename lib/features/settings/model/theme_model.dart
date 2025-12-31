// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:hive_ce/hive.dart';

import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'theme_model.g.dart';

@HiveType(typeId: HiveTypeIds.theme)
class ThemeModel {
  @HiveField(0, defaultValue: 'system')
  final String themeMode;
  @HiveField(1, defaultValue: false)
  final bool amoled;
  @HiveField(2)
  final String? flexScheme;
  @HiveField(3, defaultValue: 11)
  final int blendLevel;
  @HiveField(4, defaultValue: false)
  final bool swapColors;
  @HiveField(5, defaultValue: true)
  final bool useMaterial3;
  @HiveField(6, defaultValue: false)
  final bool useDynamicColors;

  ThemeModel({
    this.themeMode = 'system',
    this.amoled = false,
    this.flexScheme,
    this.blendLevel = 11,
    this.swapColors = false,
    this.useMaterial3 = true,
    this.useDynamicColors = false,
  });

  ThemeModel copyWith({
    String? themeMode,
    bool? amoled,
    String? flexScheme,
    int? blendLevel,
    bool? swapColors,
    bool? useMaterial3,
    bool? useDynamicColors,
  }) {
    return ThemeModel(
      themeMode: themeMode ?? this.themeMode,
      amoled: amoled ?? this.amoled,
      flexScheme: flexScheme ?? this.flexScheme,
      blendLevel: blendLevel ?? this.blendLevel,
      swapColors: swapColors ?? this.swapColors,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      useDynamicColors: useDynamicColors ?? this.useDynamicColors,
    );
  }

  FlexScheme get flexSchemeEnum => FlexScheme.values.firstWhere(
        (e) => e.name == flexScheme,
        orElse: () => FlexScheme.red,
      );
}
