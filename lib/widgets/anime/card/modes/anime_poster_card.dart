// Modernized Poster Mode
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/widgets/anime/card/anime_card_components.dart';
import 'package:shonenx/widgets/anime/card/anime_card_image.dart';

class PosterCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const PosterCard(
      {super.key, required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isHovered ? 0.3 : 0.2),
            blurRadius: isHovered ? 15 : 10,
            spreadRadius: isHovered ? 2 : 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
                BorderRadius.circular(8),
        child: Stack(
          children: [
            // Base image
            AnimeImage(anime: anime, tag: tag, height: double.infinity),

            // Overlay with enhanced gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.5, 0.75, 1.0],
                ),
              ),
            ),

            // Content container with improved padding
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top section with adaptive opacity based on hover
                  Opacity(
                    opacity: isHovered ? 1.0 : 0.8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Score in top left
                        if (anime?.averageScore != null)
                          Tag(
                            text: '${anime!.averageScore}%',
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.9),
                            textColor: theme.colorScheme.onPrimary,
                            icon: Iconsax.star1,
                            hasShadow: true,
                          ),

                        // Format in top right
                        if (anime?.format != null)
                          Tag(
                            text: anime!.format!.split('.').last,
                            color: theme.colorScheme.tertiaryContainer
                                .withValues(alpha: 0.9),
                            textColor: theme.colorScheme.onTertiaryContainer,
                            hasShadow: true,
                          ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom content with better spacing
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with enhanced styling
                      AnimeTitle(
                        anime: anime,
                        maxLines: 2,
                        enhanced: true,
                      ),

                      const SizedBox(height: 10),

                      // Episodes with improved badge
                      if (anime?.episodes != null)
                        Tag(
                          text: '${anime!.episodes} Episodes',
                          color: theme.colorScheme.secondary
                              .withValues(alpha: 0.9),
                          textColor: theme.colorScheme.onSecondary,
                          icon: Iconsax.play_circle,
                          hasShadow: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Enhanced hover effect with subtle glow
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isHovered
                      ? theme.colorScheme.primary.withValues(alpha: 0.7)
                      : Colors.transparent,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}