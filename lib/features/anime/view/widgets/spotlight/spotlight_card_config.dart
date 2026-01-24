import 'package:flutter/material.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
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
  final double height;
  final double radius;
  final SpotlightCardBuilder builder;

  const SpotlightCardConfig({
    required this.height,
    required this.radius,
    required this.builder,
  });
}

final Map<SpotlightCardMode, SpotlightCardConfig> spotlightCardConfigs = {
  SpotlightCardMode.defaults: SpotlightCardConfig(
    height: 250.0,
    radius: 16.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        DefaultSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.minimal: SpotlightCardConfig(
    height: 220.0,
    radius: 12.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        MinimalSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.classic: SpotlightCardConfig(
    height: 260.0,
    radius: 14.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        ClassicSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.coverOnly: SpotlightCardConfig(
    height: 240.0,
    radius: 16.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        CoverOnlySpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.liquidGlass: SpotlightCardConfig(
    height: 250.0,
    radius: 20.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        LiquidGlassSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.neon: SpotlightCardConfig(
    height: 250.0,
    radius: 16.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        NeonSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.manga: SpotlightCardConfig(
    height: 240.0,
    radius: 0.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        MangaSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.compact: SpotlightCardConfig(
    height: 180.0,
    radius: 12.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        CompactSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
  SpotlightCardMode.polaroid: SpotlightCardConfig(
    height: 280.0,
    radius: 4.0,
    builder: ({required anime, required heroTag, required onTap}) =>
        PolaroidSpotlight(anime: anime, heroTag: heroTag, onTap: onTap),
  ),
};
