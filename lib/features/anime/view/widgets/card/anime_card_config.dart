import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/default_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/minimal_card.dart';

enum AnimeCardMode {
  defaults,
  minimal,
}

typedef ResponsiveSize = ({double small, double large});

// The definition of the expected function signature
typedef AnimeCardBuilder = Widget Function({
  required Media? anime,
  required String tag,
  required bool isHovered,
});

class AnimeCardConfig {
  final ResponsiveSize responsiveWidth;
  final ResponsiveSize responsiveHeight;
  final double radius;
  final AnimeCardBuilder builder;

  const AnimeCardConfig({
    required this.responsiveWidth,
    required this.responsiveHeight,
    required this.radius,
    required this.builder,
  });
}

final Map<AnimeCardMode, AnimeCardConfig> cardConfigs = {
  AnimeCardMode.defaults: AnimeCardConfig(
    responsiveWidth: (small: 140.0, large: 160.0),
    responsiveHeight: (small: 200.0, large: 240.0),
    radius: 15.0,
    builder: ({required anime, required tag, required isHovered}) =>
        DefaultCard(anime: anime, tag: tag, isHovered: isHovered),
  ),
  AnimeCardMode.minimal: AnimeCardConfig(
    responsiveWidth: (small: 130.0, large: 150.0),
    responsiveHeight: (small: 180.0, large: 220.0),
    radius: 10.0,
    builder: ({required anime, required tag, required isHovered}) =>
        MinimalCard(anime: anime, tag: tag, isHovered: isHovered),
  ),
};
