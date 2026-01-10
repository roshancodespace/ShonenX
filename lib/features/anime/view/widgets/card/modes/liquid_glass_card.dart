import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_components.dart';

class LiquidGlassCard extends StatelessWidget {
  final UniversalMedia? anime;
  final String tag;
  final bool isHovered;

  const LiquidGlassCard({
    super.key,
    required this.anime,
    required this.tag,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          // Scale slightly on hover for effect
          AnimatedScale(
            scale: isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: AnimeImage(anime: anime, tag: tag, height: double.infinity),
          ),

          // Rating Tag (Top Left) - Glass Pill
          if (anime?.averageScore != null)
            Positioned(
              top: 10,
              left: 10,
              child: GlassContainer.frostedGlass(
                height: 28,
                width: 60,
                borderRadius: BorderRadius.circular(14),
                blur: 15,
                borderWidth: 1.0,
                borderColor: Colors.white.withOpacity(0.3),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.1),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.star1,
                      size: 12,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${anime!.averageScore}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Glass Overlay (Bottom Section)
          Align(
            alignment: Alignment.bottomCenter,
            child: GlassContainer.frostedGlass(
              height: 100,
              width: double.infinity,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              borderWidth: 0,
              // Only top border
              borderColor: Colors.transparent,
              blur: 15,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.8),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ))),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimeTitle(
                      anime: anime,
                      maxLines: 2,
                      enhanced: true,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    EpisodesInfo(anime: anime, compact: true),
                  ],
                ),
              ),
            ),
          ),

          // Subtle Shine Effect on Hover
          if (isHovered)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
