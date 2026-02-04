import 'package:flutter/material.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/modes/classic_spotlight.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/modes/compact_spotlight.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/modes/cover_only_spotlight.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/modes/default_spotlight.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/modes/liquid_glass_spotlight.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/modes/manga_spotlight.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/modes/minimal_spotlight.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/modes/neon_spotlight.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/modes/polaroid_spotlight.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/spotlight_card_mode.dart';

typedef SpotlightCardBuilder =
    Widget Function({
      required UniversalMedia? anime,
      required String heroTag,
      required Function(UniversalMedia)? onTap,
    });

class SpotlightCardConfig {
  final ResponsiveSize responsiveHeight;
  final double radius;
  final SpotlightCardBuilder builder;

  const SpotlightCardConfig({
    this.responsiveHeight = const (small: 240.0, large: 400.0),
    required this.radius,
    required this.builder,
  });
}

final Map<SpotlightCardMode, SpotlightCardConfig> spotlightCardConfigs = {
  SpotlightCardMode.defaults: SpotlightCardConfig(
    radius: 16.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        DefaultSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.minimal: SpotlightCardConfig(
    radius: 12.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        MinimalSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.classic: SpotlightCardConfig(
    radius: 14.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        ClassicSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.coverOnly: SpotlightCardConfig(
    radius: 16.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        CoverOnlySpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.liquidGlass: SpotlightCardConfig(
    radius: 20.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        LiquidGlassSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.neon: SpotlightCardConfig(
    radius: 16.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        NeonSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.manga: SpotlightCardConfig(
    radius: 0.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        MangaSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.compact: SpotlightCardConfig(
    radius: 12.0,
    responsiveHeight: (small: 180.0, large: 220.0),
    builder: ({required anime, required heroTag, required onTap}) =>
        CompactSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.polaroid: SpotlightCardConfig(
    radius: 4.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        PolaroidSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
};
