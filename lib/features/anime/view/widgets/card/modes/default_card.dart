import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart' as m;
import 'package:shonenx/features/anime/view/widgets/card/anime_card_components.dart';
class DefaultCard extends StatelessWidget {
  final m.Media? anime;
  final String tag;
  final bool isHovered;
  

  const DefaultCard({
    super.key,
    required this.anime,
    required this.tag,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(15); // Use a fixed radius for consistency

    return SizedBox(

      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimeImage(anime: anime, tag: tag, height: double.infinity),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.4, 0.75, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (anime?.averageScore != null) ...[
                    Tag(
                      text: '${anime!.averageScore}',
                      color: theme.colorScheme.primaryContainer,
                      textColor: theme.colorScheme.onPrimaryContainer,
                      icon: Iconsax.star1,
                    ),
                    const SizedBox(height: 8),
                  ],
                  AnimeTitle(anime: anime, maxLines: 2),
                  const SizedBox(height: 6),
                  EpisodesInfo(anime: anime),
                ],
              ),
            ),
            // Animated border for hover effect
            AnimatedOpacity(
              opacity: isHovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.8),
                    width: 2.5,
                  ),
                  borderRadius: borderRadius,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}