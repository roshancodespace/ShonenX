import 'package:flutter/material.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/utils/ui.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/classic_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/compact_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/cover_only_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/default_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/liquid_glass_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/manga_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/minimal_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/neon_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/modes/polaroid_card.dart';

enum AnimeCardMode {
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

    Size byBp({
      required Size compact,
      required Size medium,
      required Size expanded,
      required Size ultra,
    }) => switch (bp) {
      ResponsiveBreakpoint.compact => compact,
      ResponsiveBreakpoint.medium => medium,
      ResponsiveBreakpoint.expanded => expanded,
      ResponsiveBreakpoint.ultra => ultra,
    };

    return switch (this) {
      AnimeCardMode.defaults => byBp(
        compact: s(130, 200),
        medium: s(150, 220),
        expanded: s(170, 250),
        ultra: s(190, 270),
      ),

      AnimeCardMode.minimal => byBp(
        compact: s(120, 180),
        medium: s(140, 200),
        expanded: s(160, 230),
        ultra: s(180, 270),
      ),

      AnimeCardMode.classic => byBp(
        compact: s(140, 240),
        medium: s(150, 260),
        expanded: s(180, 300),
        ultra: s(200, 340),
      ),

      AnimeCardMode.coverOnly => byBp(
        compact: s(130, 200),
        medium: s(140, 210),
        expanded: s(170, 250),
        ultra: s(190, 270),
      ),

      AnimeCardMode.liquidGlass => byBp(
        compact: s(150, 220),
        medium: s(170, 240),
        expanded: s(200, 280),
        ultra: s(220, 320),
      ),

      AnimeCardMode.neon => byBp(
        compact: s(130, 200),
        medium: s(150, 220),
        expanded: s(170, 250),
        ultra: s(190, 270),
      ),

      AnimeCardMode.manga => byBp(
        compact: s(140, 220),
        medium: s(150, 235),
        expanded: s(180, 270),
        ultra: s(200, 320),
      ),

      AnimeCardMode.compact => byBp(
        compact: s(110, 160),
        medium: s(120, 175),
        expanded: s(140, 200),
        ultra: s(160, 250),
      ),

      AnimeCardMode.polaroid => byBp(
        compact: s(140, 220),
        medium: s(160, 235),
        expanded: s(180, 270),
        ultra: s(200, 320),
      ),
    };
  }

  Widget build({
    required UniversalMedia? anime,
    required String tag,
    required bool isHovered,
  }) {
    return switch (this) {
      AnimeCardMode.defaults => DefaultCard(
        anime: anime,
        tag: tag,
        isHovered: isHovered,
      ),
      AnimeCardMode.minimal => MinimalCard(
        anime: anime,
        tag: tag,
        isHovered: isHovered,
      ),
      AnimeCardMode.classic => ClassicCard(
        anime: anime,
        tag: tag,
        isHovered: isHovered,
      ),
      AnimeCardMode.coverOnly => CoverOnlyCard(
        anime: anime,
        tag: tag,
        isHovered: isHovered,
      ),
      AnimeCardMode.liquidGlass => LiquidGlassCard(
        anime: anime,
        tag: tag,
        isHovered: isHovered,
      ),
      AnimeCardMode.neon => NeonCard(
        anime: anime,
        tag: tag,
        isHovered: isHovered,
      ),
      AnimeCardMode.manga => MangaCard(
        anime: anime,
        tag: tag,
        isHovered: isHovered,
      ),
      AnimeCardMode.compact => CompactCard(
        anime: anime,
        tag: tag,
        isHovered: isHovered,
      ),
      AnimeCardMode.polaroid => PolaroidCard(
        anime: anime,
        tag: tag,
        isHovered: isHovered,
      ),
    };
  }
}
