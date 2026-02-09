import 'package:flutter/material.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/utils/ui.dart';
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
    final scale = 1.0;
    final bp = responsiveBreakpoint(context);

    Size s(double w, double h) => Size(w * scale, h * scale);

    double h({
      required double compact,
      required double medium,
      required double expanded,
      required double ultra,
    }) => switch (bp) {
      ResponsiveBreakpoint.compact => compact,
      ResponsiveBreakpoint.medium => medium,
      ResponsiveBreakpoint.expanded => expanded,
      ResponsiveBreakpoint.ultra => ultra,
    };

    return switch (this) {
      SpotlightCardMode.compact => s(
        double.infinity,
        h(compact: 180, medium: 200, expanded: 220, ultra: 240),
      ),

      SpotlightCardMode.defaults => s(
        double.infinity,
        h(compact: 240, medium: 280, expanded: 320, ultra: 360),
      ),

      SpotlightCardMode.minimal => s(
        double.infinity,
        h(compact: 220, medium: 260, expanded: 300, ultra: 340),
      ),

      SpotlightCardMode.classic => s(
        double.infinity,
        h(compact: 260, medium: 300, expanded: 340, ultra: 380),
      ),

      SpotlightCardMode.coverOnly => s(
        double.infinity,
        h(compact: 260, medium: 300, expanded: 340, ultra: 380),
      ),

      SpotlightCardMode.liquidGlass => s(
        double.infinity,
        h(compact: 260, medium: 300, expanded: 360, ultra: 400),
      ),

      SpotlightCardMode.neon => s(
        double.infinity,
        h(compact: 250, medium: 300, expanded: 340, ultra: 380),
      ),

      SpotlightCardMode.manga => s(
        double.infinity,
        h(compact: 260, medium: 300, expanded: 340, ultra: 380),
      ),

      SpotlightCardMode.polaroid => s(
        double.infinity,
        h(compact: 260, medium: 300, expanded: 330, ultra: 370),
      ),
    };
  }

  double radius(BuildContext context) {
    final scale = 1.0;

    double r(double value) => value * scale;

    return switch (this) {
      SpotlightCardMode.defaults => r(16),
      SpotlightCardMode.minimal => r(12),
      SpotlightCardMode.classic => r(14),
      SpotlightCardMode.coverOnly => r(16),
      SpotlightCardMode.liquidGlass => r(20),
      SpotlightCardMode.neon => r(16),
      SpotlightCardMode.manga => 0,
      SpotlightCardMode.compact => r(12),
      SpotlightCardMode.polaroid => r(4),
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
