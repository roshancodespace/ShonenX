import 'package:flutter/material.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';

class AnimatedAnimeCard extends StatefulWidget {
  final UniversalMedia anime;
  final String tag;
  final VoidCallback? onTap;
  final AnimeCardMode mode;

  const AnimatedAnimeCard({
    super.key,
    required this.anime,
    required this.tag,
    this.onTap,
    this.mode = AnimeCardMode.defaults,
  });

  @override
  State<AnimatedAnimeCard> createState() => _AnimatedAnimeCardState();
}

class _AnimatedAnimeCardState extends State<AnimatedAnimeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final config = cardConfigs[widget.mode]!;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    final width = isSmallScreen
        ? config.responsiveWidth.small
        : config.responsiveWidth.large;
    final height = isSmallScreen
        ? config.responsiveHeight.small
        : config.responsiveHeight.large;

    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = constraints.hasBoundedWidth && constraints.isTight
            ? constraints.maxWidth
            : width;
        final targetHeight = constraints.hasBoundedHeight && constraints.isTight
            ? constraints.maxHeight
            : height;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: targetWidth,
              height: targetHeight,
              margin: EdgeInsets.only(
                top: _isHovered ? 0 : 4,
                bottom: _isHovered ? 4 : 0,
              ),
              child: config.builder(
                anime: widget.anime.copyWith(
                  averageScore: widget.anime.averageScore == null
                      ? null
                      : widget.anime.averageScore! / 10,
                ),
                tag: widget.tag,
                isHovered: _isHovered,
              ),
            ),
          ),
        );
      },
    );
  }
}
