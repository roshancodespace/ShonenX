import 'package:shonenx/features/anime/view/widgets/card/anime_card_mode.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/spotlight_card_mode.dart';

class UiModel {
  final AnimeCardMode cardStyle;
  final SpotlightCardMode spotlightCardStyle;
  final bool immersiveMode;
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
