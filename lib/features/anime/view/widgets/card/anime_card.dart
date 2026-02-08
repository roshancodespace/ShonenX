import 'package:flutter/material.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_mode.dart';

class AnimeCard extends StatefulWidget {
  final UniversalMedia anime;
  final String tag;
  final AnimeCardMode mode;

  const AnimeCard({
    super.key,
    required this.anime,
    required this.tag,
    required this.mode,
  });

  @override
  State<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends State<AnimeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dimensions = widget.mode.getDimensions(context);

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = constraints.hasBoundedWidth && constraints.isTight
              ? constraints.maxWidth
              : dimensions.width;
          final targetHeight =
              constraints.hasBoundedHeight && constraints.isTight
              ? constraints.maxHeight
              : dimensions.height;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: targetWidth,
              height: targetHeight,
              margin: EdgeInsets.only(
                top: _isHovered ? 0 : 4,
                bottom: _isHovered ? 4 : 0,
              ),
              child: widget.mode.build(
                anime: widget.anime.copyWith(
                  averageScore: widget.anime.averageScore == null
                      ? null
                      : widget.anime.averageScore! / 10,
                ),
                tag: widget.tag,
                isHovered: _isHovered,
              ),
            ),
          );
        },
      ),
    );
  }
}
