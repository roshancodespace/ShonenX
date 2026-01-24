import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_components.dart';

class DefaultCard extends StatelessWidget {
  final UniversalMedia? anime;
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
    final borderRadius = BorderRadius.circular(16.0);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      elevation: isHovered ? 4 : 0,
      animationDuration: const Duration(milliseconds: 300),
      type: MaterialType.card,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedScale(
            scale: isHovered ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: AnimeImage(anime: anime, tag: tag, height: double.infinity),
          ),
          AnimatedOpacity(
            opacity: isHovered ? 0.08 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(color: Colors.white),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.95),
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: _buildScoreBadge(context, anime?.averageScore),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimeTitle(anime: anime, maxLines: 2),
                    const SizedBox(height: 4),
                    Opacity(opacity: 0.9, child: EpisodesInfo(anime: anime)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(BuildContext context, dynamic score) {
    if (score == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onPrimaryContainer.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.star1, size: 14, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
