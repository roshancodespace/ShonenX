import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class StaticNoiseOverlay extends StatefulWidget {
  final Color color;
  final double opacity;

  const StaticNoiseOverlay({
    super.key,
    required this.color,
    required this.opacity,
  });

  @override
  State<StaticNoiseOverlay> createState() => _StaticNoiseOverlayState();
}

class _StaticNoiseOverlayState extends State<StaticNoiseOverlay> {
  late _StaticNoisePainter _painter;

  @override
  void initState() {
    super.initState();
    _painter = _StaticNoisePainter(widget.color, widget.opacity);
  }

  @override
  void didUpdateWidget(StaticNoiseOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color ||
        widget.opacity != oldWidget.opacity) {
      _painter.dispose();
      _painter = _StaticNoisePainter(widget.color, widget.opacity);
    }
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: _painter, size: Size.infinite),
    );
  }
}

class _StaticNoisePainter extends CustomPainter {
  final Color color;
  final double opacity;

  _StaticNoisePainter(this.color, this.opacity);

  ui.Picture? _cachedPicture;
  Size? _cachedSize;

  void dispose() {
    _cachedPicture?.dispose();
    _cachedPicture = null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    if (_cachedPicture == null || _cachedSize != size) {
      final recorder = ui.PictureRecorder();
      final tempCanvas = Canvas(recorder, Offset.zero & size);
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = 1.5;

      for (double i = -size.height; i < size.width; i += 4) {
        tempCanvas.drawLine(
          Offset(i, 0),
          Offset(i + size.height, size.height),
          paint,
        );
      }
      for (double i = 0; i < size.width + size.height; i += 4) {
        tempCanvas.drawLine(
          Offset(i, 0),
          Offset(i - size.height, size.height),
          paint,
        );
      }

      _cachedPicture?.dispose();
      _cachedPicture = recorder.endRecording();
      _cachedSize = size;
    }

    if (_cachedPicture != null) {
      canvas.drawPicture(_cachedPicture!);
    }
  }

  @override
  bool shouldRepaint(covariant _StaticNoisePainter oldDelegate) {
    return color != oldDelegate.color || opacity != oldDelegate.opacity;
  }
}
