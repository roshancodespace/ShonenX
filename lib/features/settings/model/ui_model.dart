// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:hive_ce/hive.dart';

import 'package:shonenx/data/hive/hive_type_ids.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_mode.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/spotlight_card_mode.dart';

part 'ui_model.g.dart';

@HiveType(typeId: HiveTypeIds.ui)
class UiModel {
  @HiveField(2, defaultValue: AnimeCardMode.defaults)
  final AnimeCardMode cardStyle;

  @HiveField(3, defaultValue: SpotlightCardMode.defaults)
  final SpotlightCardMode spotlightCardStyle;

  @HiveField(5, defaultValue: false)
  final bool immersiveMode;

  @HiveField(6, defaultValue: 'list')
  final String episodeViewMode;

  UiModel({
    this.cardStyle = AnimeCardMode.defaults,
    this.immersiveMode = false,
    this.spotlightCardStyle = SpotlightCardMode.defaults,
    this.episodeViewMode = 'list',
  });

  UiModel copyWith({
    AnimeCardMode? cardStyle,
    bool? immersiveMode,
    SpotlightCardMode? spotlightCardStyle,
    String? episodeViewMode,
  }) {
    return UiModel(
      cardStyle: cardStyle ?? this.cardStyle,
      immersiveMode: immersiveMode ?? this.immersiveMode,
      spotlightCardStyle: spotlightCardStyle ?? this.spotlightCardStyle,
      episodeViewMode: episodeViewMode ?? this.episodeViewMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardStyle': cardStyle.index,
      'immersiveMode': immersiveMode,
      'spotlightCardStyle': spotlightCardStyle.index,
      'episodeViewMode': episodeViewMode,
    };
  }

  factory UiModel.fromMap(Map<String, dynamic> map) {
    return UiModel(
      cardStyle: AnimeCardMode.values[map['cardStyle'] ?? 0],
      immersiveMode: map['immersiveMode'] ?? false,
      spotlightCardStyle:
          SpotlightCardMode.values[map['spotlightCardStyle'] ?? 0],
      episodeViewMode: map['episodeViewMode'] ?? 'list',
    );
  }
}
