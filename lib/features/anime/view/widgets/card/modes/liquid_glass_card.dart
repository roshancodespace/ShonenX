import 'dart:ui';
import 'package:flutter/material.dart';
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
    final isDark = theme.brightness == Brightness.dark;

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
            AnimatedScale(
              scale: isHovered ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutExpo,
              child:
                  AnimeImage(anime: anime, tag: tag, height: double.infinity),
            ),
            _LegibilityGradient(isDark: isDark),
            if (anime?.averageScore != null)
              Positioned(
                top: 12,
                right: 12,
                child: _GlassShard(
                  isDark: isDark,
                  borderRadius: 12,
                  child: Row(
                    children: [
                      Icon(Iconsax.star1,
                          color: theme.colorScheme.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${anime!.averageScore}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors
                              .white, // Hardcoded white for max contrast on glass
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (anime?.format != null)
                        _GlassShard(
                          isDark: isDark,
                          borderRadius: 10,
                          child: Text(
                            anime!.format!.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      if (anime?.episodes != null)
                        _GlassShard(
                          isDark: isDark,
                          borderRadius: 10,
                          child: Text(
                            '${anime!.episodes} EPS',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _GlassShard(
                    isDark: isDark,
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      anime!.title.english ?? anime!.title.romaji ?? 'Unknown',
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
  }
}

class _GlassShard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isDark;

  const _GlassShard({
    required this.child,
    required this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RefractiveRimPainter(radius: borderRadius, isDark: isDark),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
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

class _LegibilityGradient extends StatelessWidget {
  final bool isDark;
  const _LegibilityGradient({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.4, 0.7, 1.0],
          colors: [
            Colors.black.withOpacity(isDark ? 0.4 : 0.2), // Top vignette
            Colors.transparent,
            Colors.black.withOpacity(0.1),
            Colors.black.withOpacity(isDark ? 0.8 : 0.5), // Bottom anchor
          ],
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
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(isDark ? 0.5 : 0.8),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
