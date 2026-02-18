import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/shared/ui/glass/shonenx_glass_gradient.dart';
import 'package:shonenx/shared/ui/glass/shonenx_glass_shard.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_components.dart';

class LiquidGlassSpotlight extends StatelessWidget {
  final UniversalMedia? anime;
  final String heroTag;
  final Function(UniversalMedia)? onTap;

  const LiquidGlassSpotlight({
    super.key,
    required this.heroTag,
    this.anime,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (anime == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final imageUrl = anime!.bannerImage?.isNotEmpty == true
        ? anime!.bannerImage!
        : (anime!.coverImage.large ?? anime!.coverImage.medium ?? '');

    final textShadow = Shadow(
      color: Colors.black.withOpacity(0.3),
      offset: const Offset(0, 1),
      blurRadius: 2,
    );
    return GestureDetector(
      onTap: () => onTap?.call(anime!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: 1.05),
              duration: const Duration(seconds: 10),
              builder: (context, scale, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: heroTag,
                      child: Transform.scale(
                        scale: scale,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const AnimeCardShimmer(height: double.infinity),
                          errorWidget: (_, __, ___) =>
                              const AnimeCardShimmer(height: double.infinity),
                        ),
                      ),
                    ),
                    const ShonenXGlassGradient.vignette(),
                    Positioned(
                      top: isMobile ? 16 : 24,
                      left: isMobile ? 16 : 24,
                      child: ShonenXGlassShard.network(
                        isDark: isDark,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        restScale: scale,
                        imageUrl: imageUrl,
                        alignment: Alignment.topLeft,

                        animationDuration: Duration.zero,
                        child: Text(
                          (anime!.status ?? 'AIRING').toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: isMobile ? 8 : 10,
                            shadows: [textShadow],
                          ),
                        ),
                      ),
                    ),
                    if (anime!.averageScore != null)
                      Positioned(
                        top: isMobile ? 16 : 24,
                        right: isMobile ? 16 : 24,
                        child: ShonenXGlassShard.network(
                          isDark: isDark,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          restScale: scale,
                          imageUrl: imageUrl,
                          alignment: Alignment.topRight,
                          animationDuration: Duration.zero,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.star1,
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${anime!.averageScore}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  shadows: [textShadow],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: isMobile ? 16 : 24,
                      left: isMobile ? 16 : 24,
                      right: isMobile ? 16 : 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (anime!.format != null)
                                ShonenXGlassShard.network(
                                  isDark: isDark,
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  restScale: scale,
                                  imageUrl: imageUrl,
                                  alignment: Alignment.bottomLeft,
                                  offset: const Offset(0, -70),
                                  animationDuration: Duration.zero,
                                  borderRadius: 10,
                                  child: Text(
                                    anime!.format!.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w900,
                                      shadows: [textShadow],
                                    ),
                                  ),
                                ),
                              if (anime!.episodes != null)
                                ShonenXGlassShard.network(
                                  isDark: isDark,
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  restScale: scale,
                                  imageUrl: imageUrl,
                                  alignment: Alignment.bottomLeft,
                                  offset: const Offset(60, -70),

                                  animationDuration: Duration.zero,
                                  borderRadius: 10,
                                  child: Text(
                                    '${anime!.episodes} EPISODES',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w900,
                                      shadows: [textShadow],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ShonenXGlassShard.network(
                            isDark: isDark,
                            borderRadius: 24,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 18 : 24,
                              vertical: isMobile ? 14 : 18,
                            ),
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            restScale: scale,
                            imageUrl: imageUrl,
                            alignment: Alignment.bottomLeft,

                            animationDuration: Duration.zero,
                            child: Text(
                              anime!.title.english ??
                                  anime!.title.romaji ??
                                  'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                                fontSize: isMobile ? 20 : 26,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
