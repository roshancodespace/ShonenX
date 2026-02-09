import 'dart:convert';

import 'package:shonenx/features/anime/view/widgets/card/anime_card_mode.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/spotlight_card_mode.dart';

class UiSettings {
  final AnimeCardMode cardStyle;
  final SpotlightCardMode spotlightCardStyle;
  final bool immersiveMode;
  final String episodeViewMode;
  final double scale;

  UiSettings({
    this.cardStyle = AnimeCardMode.defaults,
    this.immersiveMode = false,
    this.spotlightCardStyle = SpotlightCardMode.defaults,
    this.episodeViewMode = 'list',
    this.scale = 1.0,
  });

  UiSettings copyWith({
    AnimeCardMode? cardStyle,
    bool? immersiveMode,
    SpotlightCardMode? spotlightCardStyle,
    String? episodeViewMode,
    double? scale,
  }) {
    return UiSettings(
      cardStyle: cardStyle ?? this.cardStyle,
      immersiveMode: immersiveMode ?? this.immersiveMode,
      spotlightCardStyle: spotlightCardStyle ?? this.spotlightCardStyle,
      episodeViewMode: episodeViewMode ?? this.episodeViewMode,
      scale: scale ?? this.scale,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardStyle': cardStyle.index,
      'immersiveMode': immersiveMode,
      'spotlightCardStyle': spotlightCardStyle.index,
      'episodeViewMode': episodeViewMode,
      'scale': scale,
    };
  }

  factory UiSettings.fromMap(Map<String, dynamic> map) {
    return UiSettings(
      cardStyle: AnimeCardMode.values[map['cardStyle'] ?? 0],
      immersiveMode: map['immersiveMode'] ?? false,
      spotlightCardStyle:
          SpotlightCardMode.values[map['spotlightCardStyle'] ?? 0],
      episodeViewMode: map['episodeViewMode'] ?? 'list',
      scale: map['scale'] ?? 1.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory UiSettings.fromJson(String source) =>
      UiSettings.fromMap(json.decode(source));
}
