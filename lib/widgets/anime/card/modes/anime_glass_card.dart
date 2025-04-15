// Modernized Glass Mode
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/widgets/anime/card/anime_card_image.dart';

class GlassCard extends StatelessWidget {
  final Media? anime;
  final String tag;
  final bool isHovered;

  const GlassCard(
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

          // Blur overlay with better glass effect
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isHovered ? 3.0 : 1.5,
              sigmaY: isHovered ? 3.0 : 1.5,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface
                        .withValues(alpha: isHovered ? 0.2 : 0.15),
                    theme.colorScheme.surface
                        .withValues(alpha: isHovered ? 0.3 : 0.2),
                  ],
                ),
                border: Border.all(
                  color: isHovered
                      ? theme.colorScheme.primary.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.2),
                  width: isHovered ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              height: double.infinity,
              width: double.infinity,
            ),
          ),

          // Content container with improved padding
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with adaptive layout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (anime?.format != null)
                      _GlassTag(
                        text: anime!.format!.split('.').last,
                        primaryColor: theme.colorScheme.primary,
                        textColor: Colors.white,
                      ),
                    if (anime?.averageScore != null)
                      _GlassTag(
                        text: '${anime!.averageScore}%',
                        primaryColor: theme.colorScheme.tertiary,
                        textColor: Colors.white,
                        icon: Iconsax.star1,
                      ),
                  ],
                ),

                const Spacer(),

                // Bottom content with enhanced styling
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with glass-appropriate styling
                    Text(
                      anime?.title?.english ??
                          anime?.title?.romaji ??
                          anime?.title?.native ??
                          'Unknown Title',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Episode information with glass styling
                    if (anime?.episodes != null)
                      _GlassTag(
                        text: '${anime!.episodes} Episodes',
                        primaryColor: theme.colorScheme.secondary,
                        textColor: Colors.white,
                        icon: Iconsax.play,
                        large: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// New Glass-specific Tag Component
class _GlassTag extends StatelessWidget {
  final String text;
  final Color primaryColor;
  final Color textColor;
  final IconData? icon;
  final bool large;

  const _GlassTag({
    required this.text,
    required this.primaryColor,
    required this.textColor,
    this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(large ? 10 : 8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 10 : 8,
            vertical: large ? 6 : 4,
          ),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.3),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.5),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(large ? 10 : 8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: large ? 14 : 12,
                  color: textColor,
                ),
                SizedBox(width: large ? 6 : 4),
              ],
              Text(
                text,
                style: (large
                        ? theme.textTheme.labelMedium
                        : theme.textTheme.labelSmall)
                    ?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}