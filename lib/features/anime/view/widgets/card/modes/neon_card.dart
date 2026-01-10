import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_components.dart';

class NeonCard extends StatelessWidget {
  final UniversalMedia? anime;
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
    final isMobile = Platform.isAndroid || Platform.isIOS;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMobile
              ? neonColor
              : isHovered
                  ? neonColor
                  : neonColor.withOpacity(0.5),
          width: isMobile ? 1 : 2,
        ),
        boxShadow: isHovered
            ? [
                BoxShadow(
                  color: neonColor.withOpacity(0.8),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: neonColor.withOpacity(0.4),
                  blurRadius: 32,
                  spreadRadius: 8,
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

            // Rating Tag (Top Right)
            if (anime?.averageScore != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: neonColor.withOpacity(0.8),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: neonColor.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.star1,
                        size: 10,
                        color: neonColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${anime!.averageScore}',
                        style: TextStyle(
                          color: neonColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: neonColor,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime?.title.english ?? anime?.title.romaji ?? 'Unknown',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: isHovered
                          ? [
                              Shadow(
                                color: neonColor,
                                blurRadius: 12,
                              ),
                            ]
                          : [],
                    ),
                  ),
                  if (isHovered) ...[
                    const SizedBox(height: 6),
                    Container(
                      height: 2,
                      width: 60,
                      decoration: BoxDecoration(
                        color: neonColor,
                        boxShadow: [
                          BoxShadow(
                            color: neonColor,
                            blurRadius: 6,
                            spreadRadius: 1,
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
