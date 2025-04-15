// Neon Mode - Glowing neon borders
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/widgets/anime/card/anime_card_components.dart';
import 'package:shonenx/widgets/anime/card/anime_card_image.dart';

class NeonCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const NeonCard(
      {required this.anime, required this.tag, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
                BorderRadius.circular(8),
        border: Border.all(
          color: isHovered
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
          width: isHovered ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isHovered)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            (theme.cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ??
                BorderRadius.circular(8),
        child: Stack(
          children: [
            AnimeImage(anime: anime, tag: tag, height: double.infinity),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    theme.shadowColor.withValues(alpha: 0.8),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimeTitle(anime: anime, maxLines: 2),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (anime?.episodes != null)
                        Tag(
                          text: '${anime!.episodes} Ep',
                          color: Colors.transparent,
                          textColor: Colors.white,
                          icon: Iconsax.play,
                        ),
                      if (anime?.format != null) ...[
                        const SizedBox(width: 6),
                        Tag(
                          text: anime!.format!.split('.').last,
                          color: Colors.transparent,
                          textColor: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
