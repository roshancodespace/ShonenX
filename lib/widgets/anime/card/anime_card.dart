import 'package:flutter/material.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/widgets/anime/card/modes/anime_cinematic_card.dart';
import 'package:shonenx/widgets/anime/card/modes/anime_compact_card.dart';
import 'package:shonenx/widgets/anime/card/modes/anime_default_card.dart';
import 'package:shonenx/widgets/anime/card/modes/anime_glass_card.dart';
import 'package:shonenx/widgets/anime/card/modes/anime_minimal_card.dart';
import 'package:shonenx/widgets/anime/card/modes/anime_neon_card.dart';
import 'package:shonenx/widgets/anime/card/modes/anime_poster_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AnimatedAnimeCard extends StatefulWidget {
  final Media? anime;
  final String tag;
  final VoidCallback? onTap;
  final String mode;

  const AnimatedAnimeCard({
    super.key,
    required this.anime,
    required this.tag,
    this.onTap,
    this.mode = 'Card', // Default to your preferred mode
  });

  @override
  State<AnimatedAnimeCard> createState() => _AnimatedAnimeCardState();
}

class _AnimatedAnimeCardState extends State<AnimatedAnimeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final width = _getWidth(widget.mode);
    final height = _getHeight(widget.mode);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: width,
          height: height,
          margin: EdgeInsets.only(
              top: _isHovered ? 0 : 4, bottom: _isHovered ? 4 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_getRadius(widget.mode)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .shadow
                    .withValues(alpha: _isHovered ? 0.25 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _CardBuilder(
            mode: widget.mode,
            anime: widget.anime,
            tag: widget.tag,
            isHovered: _isHovered,
          ),
        ),
      ),
    );
  }

  double _getWidth(String mode) {
    final screenWidth = MediaQuery.of(context).size.width;
    return switch (mode) {
      'Card' => screenWidth < 600 ? 140.0 : 160.0,
      'Compact' => screenWidth < 600 ? 100.0 : 120.0,
      'Poster' => screenWidth < 600 ? 160.0 : 180.0,
      'Glass' => screenWidth < 600 ? 150.0 : 170.0,
      'Neon' => screenWidth < 600 ? 140.0 : 160.0,
      'Minimal' => screenWidth < 600 ? 130.0 : 150.0,
      'Cinematic' => screenWidth < 600 ? 200.0 : 240.0,
      _ => screenWidth < 600 ? 140.0 : 160.0, // Default to Card
    };
  }

  double _getHeight(String mode) {
    final screenWidth = MediaQuery.of(context).size.width;
    return switch (mode) {
      'Card' => screenWidth < 600 ? 200.0 : 240.0,
      'Compact' => screenWidth < 600 ? 150.0 : 180.0,
      'Poster' => screenWidth < 600 ? 260.0 : 300.0,
      'Glass' => screenWidth < 600 ? 220.0 : 260.0,
      'Neon' => screenWidth < 600 ? 200.0 : 240.0,
      'Minimal' => screenWidth < 600 ? 180.0 : 220.0,
      'Cinematic' => screenWidth < 600 ? 140.0 : 160.0,
      _ => screenWidth < 600 ? 200.0 : 240.0, // Default to Card
    };
  }

  double _getRadius(String mode) {
    return switch (mode) {
      'Card' => 15.0,
      'Compact' => 12.0,
      'Poster' => 18.0,
      'Glass' => 20.0,
      'Neon' => 16.0,
      'Minimal' => 10.0,
      'Cinematic' => 14.0,
      _ => 15.0,
    };
  }
}

class _CardBuilder extends StatelessWidget {
  final String mode;
  final Media? anime;
  final String tag;
  final bool isHovered;

  const _CardBuilder({
    required this.mode,
    required this.anime,
    required this.tag,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      'Compact' => CompactCard(anime: anime, tag: tag, isHovered: isHovered),
      'Poster' => PosterCard(anime: anime, tag: tag, isHovered: isHovered),
      'Glass' => GlassCard(anime: anime, tag: tag, isHovered: isHovered),
      'Neon' => NeonCard(anime: anime, tag: tag, isHovered: isHovered),
      'Minimal' => MinimalCard(anime: anime, tag: tag, isHovered: isHovered),
      'Cinematic' =>
        CinematicCard(anime: anime, tag: tag, isHovered: isHovered),
      'Card' || _ => DefaultCard(anime: anime, tag: tag, isHovered: isHovered),
    };
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final double height;

  const _ErrorPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Skeletonizer(child: Bone.square());
  }
}
