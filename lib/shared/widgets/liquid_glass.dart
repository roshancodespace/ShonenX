import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class LiquidGlass extends StatelessWidget {
  final Widget child;
  final ImageProvider image;

  // Layout & Alignment
  final Alignment alignment;
  final Offset refraction;
  final EdgeInsetsGeometry padding;
  final double radius;

  // Visuals
  final bool isDark;
  final Color? tint;
  final double blur;
  final double rimOpacity;
  final double rimStrokeWidth;

  // Animations (Hover states)
  final bool isHovered;
  final double hoverScale;
  final double restScale;
  final Duration animationDuration;

  const LiquidGlass({
    super.key,
    required this.child,
    required this.image,
    this.alignment = Alignment.center,
    this.refraction = Offset.zero,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.radius = 16.0,
    this.isDark = true,
    this.tint,
    this.blur = 0.0,
    this.rimOpacity = 1.0,
    this.rimStrokeWidth = 0.8,
    this.isHovered = false,
    this.hoverScale = 1.1,
    this.restScale = 1.0,
    this.animationDuration = const Duration(milliseconds: 1400),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _GlassRimPainter(
        radius: radius,
        isDark: isDark,
        opacity: rimOpacity,
        strokeWidth: rimStrokeWidth,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: refraction,
                child: RepaintBoundary(
                  child: AnimatedScale(
                    scale: isHovered ? hoverScale : restScale,
                    duration: animationDuration,
                    curve: Curves.easeOutExpo,
                    child: blur > 0
                        ? ImageFiltered(
                            imageFilter: ui.ImageFilter.blur(
                              sigmaX: blur,
                              sigmaY: blur,
                              tileMode: TileMode.mirror,
                            ),
                            child: Image(
                              image: image,
                              fit: BoxFit.cover,
                              alignment: alignment,
                              gaplessPlayback: true,
                            ),
                          )
                        : Image(
                            image: image,
                            fit: BoxFit.cover,
                            alignment: alignment,
                            gaplessPlayback: true,
                          ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color:
                    tint ?? Colors.black.withValues(alpha: isDark ? 0.6 : 0.4),
              ),
            ),
            Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.15 : 0.25),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassRimPainter extends CustomPainter {
  final double radius;
  final bool isDark;
  final double opacity;
  final double strokeWidth;

  const _GlassRimPainter({
    required this.radius,
    required this.isDark,
    this.opacity = 1.0,
    this.strokeWidth = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: (isDark ? 0.5 : 0.8) * opacity),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassRimPainter oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.radius != radius ||
      oldDelegate.opacity != opacity ||
      oldDelegate.strokeWidth != strokeWidth;
}
