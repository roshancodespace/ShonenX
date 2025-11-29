import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_components.dart';

class NeonCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const NeonCard({
    super.key,
    required this.anime,
    required this.tag,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neonColor = theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHovered ? neonColor : Colors.transparent,
          width: 2,
        ),
        boxShadow: isHovered
            ? [
                BoxShadow(
                  color: neonColor.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimeImage(anime: anime, tag: tag, height: double.infinity),

            // Dark Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                    Colors.black,
                  ],
                  stops: const [0.5, 0.85, 1.0],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime?.title?.english ?? anime?.title?.romaji ?? 'Unknown',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: isHovered
                          ? [
                              Shadow(
                                color: neonColor,
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                  ),
                  if (isHovered) ...[
                    const SizedBox(height: 4),
                    Container(
                      height: 2,
                      width: 40,
                      decoration: BoxDecoration(
                        color: neonColor,
                        boxShadow: [
                          BoxShadow(
                            color: neonColor,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
