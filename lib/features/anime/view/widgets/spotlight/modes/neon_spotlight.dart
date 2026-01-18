import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';

class NeonSpotlight extends StatelessWidget {
  final UniversalMedia? anime;
  final String heroTag;
  final Function(UniversalMedia)? onTap;
  final bool isHovered;

  const NeonSpotlight({
    super.key,
    required this.anime,
    required this.heroTag,
    this.onTap,
    this.isHovered = false,
  });

  @override
  Widget build(BuildContext context) {
    if (anime == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final neonColor = theme.colorScheme.primary;
    final isMobile = Platform.isAndroid || Platform.isIOS;
    final imageUrl = anime!.bannerImage?.isNotEmpty == true
        ? anime!.bannerImage!
        : (anime!.coverImage.large ?? anime!.coverImage.medium ?? '');

    return GestureDetector(
      onTap: () => onTap?.call(anime!),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMobile
                ? neonColor
                : isHovered
                    ? neonColor
                    : neonColor.withOpacity(0.5),
            width: isMobile ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: neonColor.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: heroTag,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                ),
              ),

              // Dark Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        anime!.title.english ??
                            anime!.title.romaji ??
                            'Unknown Title',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: neonColor,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (anime!.averageScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: neonColor.withOpacity(0.6)),
                          boxShadow: [
                            BoxShadow(
                              color: neonColor.withOpacity(0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.star1, size: 14, color: neonColor),
                            const SizedBox(width: 4),
                            Text(
                              '${anime!.averageScore}',
                              style: TextStyle(
                                color: neonColor,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: neonColor, blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
