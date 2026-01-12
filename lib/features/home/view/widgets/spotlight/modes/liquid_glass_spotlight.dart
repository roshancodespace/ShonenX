import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_components.dart';
import 'package:shonenx/shared/widgets/focusable_tap.dart';

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

    final radius = BorderRadius.circular(isMobile ? 24 : 32);

    return FocusableTap(
      onTap: () => onTap?.call(anime!),
      borderRadius: radius,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: heroTag,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: 1.05),
                duration: const Duration(seconds: 10),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const AnimeCardShimmer(height: double.infinity),
                      errorWidget: (_, __, ___) =>
                          const AnimeCardShimmer(height: double.infinity),
                    ),
                  );
                },
              ),
            ),
            _SpotlightVignette(isDark: isDark),
            Positioned(
              top: isMobile ? 16 : 24,
              left: isMobile ? 16 : 24,
              right: isMobile ? 16 : 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GlassShard(
                    isDark: isDark,
                    borderRadius: 12,
                    child: Text(
                      (anime!.status ?? 'AIRING').toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: isMobile ? 8 : 10,
                        shadows: [_textShadow],
                      ),
                    ),
                  ),
                  if (anime!.averageScore != null)
                    _GlassShard(
                      isDark: isDark,
                      borderRadius: 14,
                      child: Row(
                        children: [
                          Icon(Iconsax.star1,
                              color: theme.colorScheme.primary, size: 16),
                          const SizedBox(width: 4),
                          Text('${anime!.averageScore}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                shadows: [_textShadow],
                              )),
                        ],
                      ),
                    ),
                ],
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
                        _GlassShard(
                          isDark: isDark,
                          borderRadius: 10,
                          child: Text(
                            anime!.format!.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w900,
                              shadows: [_textShadow],
                            ),
                          ),
                        ),
                      if (anime!.episodes != null)
                        _GlassShard(
                          isDark: isDark,
                          borderRadius: 10,
                          child: Text(
                            '${anime!.episodes} EPISODES',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w900,
                              shadows: [_textShadow],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  _GlassShard(
                    isDark: isDark,
                    borderRadius: 24,
                    padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 18 : 24,
                        vertical: isMobile ? 14 : 18),
                    child: Text(
                      anime!.title.english ?? anime!.title.romaji ?? 'Unknown',
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
        ),
      ),
    );
  }

  // Shared text shadow to prevent cooked visibility
  Shadow get _textShadow => Shadow(
        color: Colors.black.withOpacity(0.3),
        offset: const Offset(0, 1),
        blurRadius: 2,
      );
}

class _GlassShard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isDark;

  const _GlassShard({
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RefractiveRimPainter(radius: borderRadius, isDark: isDark),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(isDark ? 0.15 : 0.25),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RefractiveRimPainter extends CustomPainter {
  final double radius;
  final bool isDark;
  _RefractiveRimPainter({required this.radius, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(isDark ? 0.4 : 0.7),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpotlightVignette extends StatelessWidget {
  final bool isDark;
  const _SpotlightVignette({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 0.6, 1.0],
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.transparent,
            Colors.black.withOpacity(0.2),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
    );
  }
}
