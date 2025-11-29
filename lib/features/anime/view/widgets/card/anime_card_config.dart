import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/classic_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/compact_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/cover_only_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/default_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/liquid_glass_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/manga_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/minimal_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/neon_card.dart';

enum AnimeCardMode {
  defaults,
  minimal,
  classic,
  coverOnly,
  liquidGlass,
  neon,
  manga,
  compact,
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
  AnimeCardMode.classic: AnimeCardConfig(
    responsiveWidth: (small: 140.0, large: 160.0),
    responsiveHeight: (small: 240.0, large: 280.0),
    radius: 12.0,
    builder: ({required anime, required tag, required isHovered}) =>
        ClassicCard(anime: anime, tag: tag, isHovered: isHovered),
  ),
  AnimeCardMode.coverOnly: AnimeCardConfig(
    responsiveWidth: (small: 130.0, large: 150.0),
    responsiveHeight: (small: 190.0, large: 230.0),
    radius: 12.0,
    builder: ({required anime, required tag, required isHovered}) =>
        CoverOnlyCard(anime: anime, tag: tag, isHovered: isHovered),
  ),
  AnimeCardMode.liquidGlass: AnimeCardConfig(
    responsiveWidth: (small: 150.0, large: 180.0),
    responsiveHeight: (small: 220.0, large: 260.0),
    radius: 16.0,
    builder: ({required anime, required tag, required isHovered}) =>
        LiquidGlassCard(anime: anime, tag: tag, isHovered: isHovered),
  ),
  AnimeCardMode.neon: AnimeCardConfig(
    responsiveWidth: (small: 140.0, large: 160.0),
    responsiveHeight: (small: 200.0, large: 240.0),
    radius: 12.0,
    builder: ({required anime, required tag, required isHovered}) =>
        NeonCard(anime: anime, tag: tag, isHovered: isHovered),
  ),
  AnimeCardMode.manga: AnimeCardConfig(
    responsiveWidth: (small: 140.0, large: 160.0),
    responsiveHeight: (small: 210.0, large: 250.0),
    radius: 0.0, // Sharp corners
    builder: ({required anime, required tag, required isHovered}) =>
        MangaCard(anime: anime, tag: tag, isHovered: isHovered),
  ),
  AnimeCardMode.compact: AnimeCardConfig(
    responsiveWidth: (small: 110.0, large: 130.0),
    responsiveHeight: (small: 160.0, large: 190.0),
    radius: 8.0,
    builder: ({required anime, required tag, required isHovered}) =>
        CompactCard(anime: anime, tag: tag, isHovered: isHovered),
  ),
};
