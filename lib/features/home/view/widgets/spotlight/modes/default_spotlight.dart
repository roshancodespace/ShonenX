import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/utils/html_parser.dart';

class DefaultSpotlight extends StatelessWidget {
  final UniversalMedia? anime;
  final String heroTag;
  final Function(UniversalMedia)? onTap;

  const DefaultSpotlight({
    super.key,
    required this.anime,
    required this.heroTag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (anime == null) return const SizedBox.shrink();

    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final imageUrl = anime!.bannerImage?.isNotEmpty == true
        ? anime!.bannerImage!
        : (anime!.coverImage.large ?? anime!.coverImage.medium ?? '');

    return GestureDetector(
      onTap: () => onTap?.call(anime!),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Hero(
                tag: heroTag,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Score Tag
                      if (anime?.averageScore != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.star1,
                                size: 16,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ((anime!.averageScore ?? 0) / 10)
                                    .toStringAsFixed(1),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Title
                      Text(
                        anime!.title.english ??
                            anime!.title.romaji ??
                            anime!.title.native ??
                            'Unknown Title',
                        maxLines: isSmallScreen ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      if (!isSmallScreen && anime!.description != null) ...[
                        Text(
                          parseHtmlToString(anime!.description!),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Meta Tags Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SpotlightTag(
                            icon: Iconsax.video_play,
                            label: '${anime?.episodes ?? "?"} Episodes',
                            colorScheme: colorScheme,
                          ),
                          if (anime?.duration != null)
                            _SpotlightTag(
                              icon: Iconsax.timer_1,
                              label: '${anime!.duration} min',
                              colorScheme: colorScheme,
                            ),
                          _SpotlightTag(
                            icon: Iconsax.calendar_1,
                            label: anime?.seasonYear?.toString() ??
                                anime?.startDate?.year?.toString() ??
                                'Unknown',
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _SpotlightTag({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
