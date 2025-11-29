import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_components.dart';

class CoverOnlyCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const CoverOnlyCard({
    super.key,
    required this.anime,
    required this.tag,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimeImage(anime: anime, tag: tag, height: double.infinity),

          // Title Overlay on Hover
          AnimatedOpacity(
            opacity: isHovered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.5, 0.8, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimeTitle(anime: anime, maxLines: 2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
