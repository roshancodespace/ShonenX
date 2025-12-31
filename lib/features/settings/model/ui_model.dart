// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:hive_ce/hive.dart';

import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'ui_model.g.dart';

@HiveType(typeId: HiveTypeIds.ui)
class UiModel {
  @HiveField(2, defaultValue: 'defaults')
  final String cardStyle;

  @HiveField(3, defaultValue: 'defaults')
  final String spotlightCardStyle;

  @HiveField(5, defaultValue: false)
  final bool immersiveMode;

  @HiveField(6, defaultValue: 'list')
  final String episodeViewMode;

  UiModel({
    this.cardStyle = 'defaults',
    this.immersiveMode = false,
    this.spotlightCardStyle = 'defaults',
    this.episodeViewMode = 'list',
  });

  UiModel copyWith({
    String? cardStyle,
    bool? immersiveMode,
    String? spotlightCardStyle,
    String? episodeViewMode,
  }) {
    return UiModel(
      cardStyle: cardStyle ?? this.cardStyle,
      immersiveMode: immersiveMode ?? this.immersiveMode,
      spotlightCardStyle: spotlightCardStyle ?? this.spotlightCardStyle,
      episodeViewMode: episodeViewMode ?? this.episodeViewMode,
    );
  }
}
