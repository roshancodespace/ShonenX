// Modernized Compact Mode
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/widgets/anime/card/anime_card_components.dart';
import 'package:shonenx/widgets/anime/card/anime_card_image.dart';

class CompactCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const CompactCard(
      {super.key, required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius:
          (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
              BorderRadius.circular(8),
      child: Stack(
        children: [
          // Base image
          AnimeImage(anime: anime, tag: tag, height: double.infinity),

          // Overlay gradient with improved colors
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  theme.shadowColor.withValues(alpha: 0.85),
                ],
                stops: const [0.65, 1.0],
              ),
            ),
          ),

          // Content with improved padding
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section with score badge
                if (anime?.averageScore != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tag(
                        text: '${anime!.averageScore}',
                        color: theme.colorScheme.primary.withValues(alpha: 0.9),
                        textColor: theme.colorScheme.onPrimary,
                        icon: Iconsax.star1,
                        hasShadow: true,
                      ),
                    ],
                  ),

                const Spacer(),

                // Bottom content with improved spacing
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with enhanced styling
                    AnimeTitle(
                      anime: anime,
                      maxLines: 1,
                      enhanced: true,
                    ),

                    const SizedBox(height: 4),

                    // Format and episode info in a row
                    Row(
                      children: [
                        if (anime?.format != null)
                          Text(
                            anime!.format!.split('.').last,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                        if (anime?.format != null && anime?.episodes != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),

                        // Episodes with enhanced styling
                        if (anime?.episodes != null)
                          Text(
                            '${anime!.episodes} ep',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Hover effect overlay
          if (isHovered)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
        ],
      ),
    );
  }
}