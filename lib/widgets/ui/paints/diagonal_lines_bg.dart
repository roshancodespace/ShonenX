import 'package:flutter/material.dart';

class DiagonalLinesPainter extends CustomPainter {
  final Color lineColor;
  final double lineWidth;
  final double spacing;

  DiagonalLinesPainter({
    this.lineColor = Colors.grey,
    this.lineWidth = 1.0,
    this.spacing = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    // Draw diagonal lines from top-left to bottom-right
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, -size.height),
        Offset(x + size.height, size.height * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

