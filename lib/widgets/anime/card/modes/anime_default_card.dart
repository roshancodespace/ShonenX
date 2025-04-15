// Modernized Card Mode
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/widgets/anime/card/anime_card_components.dart';
import 'package:shonenx/widgets/anime/card/anime_card_image.dart';

class DefaultCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const DefaultCard(
      {super.key,
      required this.anime,
      required this.tag,
      required this.isHovered});

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
                  theme.shadowColor.withValues(alpha: 0.5), // Lighter middle
                  theme.shadowColor.withValues(alpha: 0.9), // Darker bottom
                ],
                stops: const [
                  0.4,
                  0.75,
                  1.0
                ], // Adjusted stops for smoother transition
              ),
            ),
          ),

          // Content container with better padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with format badge
                if (anime?.format != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tag(
                        text: anime!.format!.split('.').last,
                        color: theme.colorScheme.tertiaryContainer
                            .withValues(alpha: 0.85),
                        textColor: theme.colorScheme.onTertiaryContainer,
                        hasShadow: true,
                      ),
                    ],
                  ),

                const Spacer(),

                // Bottom content with improved spacing
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score with improved badge
                    if (anime?.averageScore != null)
                      Tag(
                        text: '${anime!.averageScore}',
                        color: theme.colorScheme.primary,
                        textColor: theme.colorScheme.onPrimary,
                        icon: Iconsax.star1,
                        hasShadow: true,
                      ),

                    const SizedBox(height: 8), // Increased spacing

                    // Title with enhanced styling
                    AnimeTitle(
                      anime: anime,
                      maxLines: 2,
                      enhanced: true, // New property for enhanced styling
                    ),

                    const SizedBox(height: 6),

                    // Episode info with enhanced styling
                    _EpisodesInfo(
                      anime: anime,
                      enhanced: true, // New property for enhanced styling
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
                borderRadius: (theme.cardTheme.shape as RoundedRectangleBorder?)
                        ?.borderRadius ??
                    BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }
}

// Enhanced Episodes Info Component
class _EpisodesInfo extends StatelessWidget {
  final Media? anime;
  final bool compact;
  final bool enhanced;

  const _EpisodesInfo({
    required this.anime,
    this.compact = false,
    this.enhanced = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (anime?.episodes == null) return const SizedBox.shrink();

    if (enhanced) {
      return Row(
        children: [
          Icon(
            Iconsax.play_circle,
            size: 14,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            compact ? '${anime!.episodes}ep' : '${anime!.episodes} episodes',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    // Original version
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );

    return Text(
      compact ? '${anime!.episodes}ep' : '${anime!.episodes} eps',
      style: textStyle,
    );
  }
}
