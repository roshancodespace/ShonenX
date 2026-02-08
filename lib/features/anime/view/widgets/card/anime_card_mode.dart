import 'package:flutter/material.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
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
    final width = MediaQuery.sizeOf(context).width;
    final isSmall = width < 600;

    return switch (this) {
      AnimeCardMode.defaults =>
        isSmall ? const Size(140.0, 200.0) : const Size(160.0, 240.0),
      AnimeCardMode.minimal =>
        isSmall ? const Size(130.0, 180.0) : const Size(150.0, 220.0),
      AnimeCardMode.classic =>
        isSmall ? const Size(140.0, 240.0) : const Size(160.0, 280.0),
      AnimeCardMode.coverOnly =>
        isSmall ? const Size(130.0, 190.0) : const Size(150.0, 230.0),
      AnimeCardMode.liquidGlass =>
        isSmall ? const Size(150.0, 220.0) : const Size(180.0, 260.0),
      AnimeCardMode.neon =>
        isSmall ? const Size(140.0, 200.0) : const Size(160.0, 240.0),
      AnimeCardMode.manga =>
        isSmall ? const Size(140.0, 210.0) : const Size(160.0, 250.0),
      AnimeCardMode.compact =>
        isSmall ? const Size(110.0, 160.0) : const Size(130.0, 190.0),
      AnimeCardMode.polaroid =>
        isSmall ? const Size(150.0, 220.0) : const Size(170.0, 250.0),
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
