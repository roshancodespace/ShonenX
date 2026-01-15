import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/widgets/design/glass/shonenx_glass_shard.dart';
import 'package:shonenx/core/widgets/design/glass/shonenx_glass_gradient.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    // Pre-calculate image URL to avoid digging through objects repeatedly
    final imageUrl = anime?.coverImage.large ?? anime?.coverImage.medium ?? '';
    final title = anime?.title.english ?? anime?.title.romaji ?? 'Unknown';

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? 0.4 : 0.2),
                blurRadius: isHovered ? 40 : 20,
                offset: Offset(0, isHovered ? 20 : 10),
                spreadRadius: -12,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Base Background Layer
                AnimatedScale(
                  scale: isHovered ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutExpo,
                  child: AnimeImage(
                    anime: anime,
                    tag: tag,
                    height: double.infinity,
                  ),
                ),

                // Legibility Gradient
                // Legibility Gradient
                const ShonenXGlassGradient.legibility(),

                // Top Right - Score Shard
                if (anime?.averageScore != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ShonenXGlassShard.network(
                      width: w,
                      height: h,
                      alignment: Alignment.topRight,
                      isDark: isDark,
                      isHovered: isHovered,
                      imageUrl: imageUrl,
                      borderRadius: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.star1,
                            color: theme.colorScheme.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${anime!.averageScore}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom Content Cluster
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Format & EPS badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (anime?.format != null)
                            ShonenXGlassShard.network(
                              width: w,
                              height: h,
                              alignment: Alignment.bottomLeft,
                              offset: const Offset(0, -60),
                              isDark: isDark,
                              isHovered: isHovered,
                              imageUrl: imageUrl,
                              borderRadius: 10,
                              child: Text(
                                anime!.format!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          if (anime?.episodes != null)
                            ShonenXGlassShard.network(
                              width: w,
                              height: h,
                              alignment: Alignment.bottomLeft,
                              offset: const Offset(50, -60),
                              isDark: isDark,
                              isHovered: isHovered,
                              imageUrl: imageUrl,
                              borderRadius: 10,
                              child: Text(
                                '${anime!.episodes} EPS',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title Shard
                      ShonenXGlassShard.network(
                        width: w,
                        height: h,
                        alignment: Alignment.bottomLeft,
                        isDark: isDark,
                        isHovered: isHovered,
                        imageUrl: imageUrl,
                        borderRadius: 18,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: -0.4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
