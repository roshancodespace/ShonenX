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

enum SpotlightCardMode {
  defaults,
  minimal,
  classic,
  coverOnly,
  liquidGlass,
  neon,
  manga,
  compact,
  polaroid;

  Size getDimensions(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isSmall = width < 600;

    // Default height range for most cards
    const defaultSmallHeight = 240.0;
    const defaultLargeHeight = 400.0;

    // Default width is infinity (full width)

    final height = switch (this) {
      SpotlightCardMode.compact => isSmall ? 180.0 : 220.0,
      _ => isSmall ? defaultSmallHeight : defaultLargeHeight,
    };

    return Size(double.infinity, height);
  }

  double get radius {
    return switch (this) {
      SpotlightCardMode.defaults => 16.0,
      SpotlightCardMode.minimal => 12.0,
      SpotlightCardMode.classic => 14.0,
      SpotlightCardMode.coverOnly => 16.0,
      SpotlightCardMode.liquidGlass => 20.0,
      SpotlightCardMode.neon => 16.0,
      SpotlightCardMode.manga => 0.0,
      SpotlightCardMode.compact => 12.0,
      SpotlightCardMode.polaroid => 4.0,
    };
  }

  bool get hasHardShadow => this == SpotlightCardMode.manga;

  Widget build({
    required UniversalMedia? anime,
    required String heroTag,
    required Function(UniversalMedia)? onTap,
  }) {
    return switch (this) {
      SpotlightCardMode.defaults => DefaultSpotlight(
        anime: anime,
        heroTag: heroTag,
        onTap: onTap,
      ),
      SpotlightCardMode.minimal => MinimalSpotlight(
        anime: anime,
        heroTag: heroTag,
        onTap: onTap,
      ),
      SpotlightCardMode.classic => ClassicSpotlight(
        anime: anime,
        heroTag: heroTag,
        onTap: onTap,
      ),
      SpotlightCardMode.coverOnly => CoverOnlySpotlight(
        anime: anime,
        heroTag: heroTag,
        onTap: onTap,
      ),
      SpotlightCardMode.liquidGlass => LiquidGlassSpotlight(
        anime: anime,
        heroTag: heroTag,
        onTap: onTap,
      ),
      SpotlightCardMode.neon => NeonSpotlight(
        anime: anime,
        heroTag: heroTag,
        onTap: onTap,
      ),
      SpotlightCardMode.manga => MangaSpotlight(
        anime: anime,
        heroTag: heroTag,
        onTap: onTap,
      ),
      SpotlightCardMode.compact => CompactSpotlight(
        anime: anime,
        heroTag: heroTag,
        onTap: onTap,
      ),
      SpotlightCardMode.polaroid => PolaroidSpotlight(
        anime: anime,
        heroTag: heroTag,
        onTap: onTap,
      ),
    };
  }
}
