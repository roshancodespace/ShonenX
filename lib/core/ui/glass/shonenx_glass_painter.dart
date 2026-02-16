import 'package:flutter/material.dart';

class ShonenXGlassRimPainter extends CustomPainter {
  final double radius;
  final bool isDark;
  final double opacity;
  final double strokeWidth;

  const ShonenXGlassRimPainter({
    required this.radius,
    required this.isDark,
    this.opacity = 1.0,
    this.strokeWidth = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Refractive rim shader
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
  bool shouldRepaint(covariant ShonenXGlassRimPainter oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.radius != radius ||
      oldDelegate.opacity != opacity;
}
