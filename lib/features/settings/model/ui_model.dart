// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:hive/hive.dart';

import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'ui_model.g.dart';

@HiveType(typeId: HiveTypeIds.ui)
class UiModel {
  @HiveField(3, defaultValue: 'defaults')
  final String cardStyle;

  @HiveField(5, defaultValue: false)
  final bool immersiveMode;

  UiModel({
    this.cardStyle = 'defaults',
    this.immersiveMode = false,
  });

  UiModel copyWith({
    String? cardStyle,
    bool? immersiveMode,
  }) {
    return UiModel(
      cardStyle: cardStyle ?? this.cardStyle,
      immersiveMode: immersiveMode ?? this.immersiveMode,
    );
  }
}
