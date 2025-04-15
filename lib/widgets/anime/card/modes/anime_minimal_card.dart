// Minimal Mode - Clean and flat
import 'package:flutter/material.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/widgets/anime/card/anime_card_components.dart';
import 'package:shonenx/widgets/anime/card/anime_card_image.dart';

class MinimalCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const MinimalCard(
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
          AnimeImage(anime: anime, tag: tag, height: double.infinity),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimeTitle(anime: anime, maxLines: 1, minimal: true),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (anime?.episodes != null)
                        Text(
                          '${anime!.episodes} Ep',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (anime?.averageScore != null)
                        Text(
                          '${anime!.averageScore}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
