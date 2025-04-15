// Cinematic Mode - Wide and dramatic
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/widgets/anime/card/anime_card_components.dart';
import 'package:shonenx/widgets/anime/card/anime_card_image.dart';

class CinematicCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const CinematicCard(
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
          AnimeImage(anime: anime, tag: tag, height: double.infinity),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  theme.shadowColor.withValues(alpha: 0.8),
                  Colors.transparent,
                  theme.shadowColor.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimeTitle(anime: anime, maxLines: 2),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (anime?.episodes != null)
                            Tag(
                              text: '${anime!.episodes} Ep',
                              color: theme.colorScheme.secondary,
                              textColor: Colors.white,
                              icon: Iconsax.play,
                            ),
                          if (anime?.averageScore != null) ...[
                            const SizedBox(width: 6),
                            Tag(
                              text: '${anime!.averageScore}%',
                              color: theme.colorScheme.primary,
                              textColor: Colors.white,
                              icon: Iconsax.star1,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (anime?.format != null)
                  Tag(
                    text: anime!.format!.split('.').last,
                    color: theme.colorScheme.tertiaryContainer,
                    textColor: theme.colorScheme.onTertiaryContainer,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}