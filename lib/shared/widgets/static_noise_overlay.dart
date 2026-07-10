import 'dart:math' as math;
import 'dart:typed_data';
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

  static ui.Image? _cachedNoiseImage;
  static double? _cachedOpacity;
  static Color? _cachedColor;
  static ui.ImageShader? _cachedShader;

  static void _generateNoiseShader(Color color, double opacity) {
    if (_cachedNoiseImage != null &&
        _cachedOpacity == opacity &&
        _cachedColor == color) {
      return;
    }

    _cachedNoiseImage?.dispose();
    _cachedNoiseImage = null;

    const int tileW = 128;
    const int tileH = 128;
    final recorder = ui.PictureRecorder();
    final tempCanvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, tileW.toDouble(), tileH.toDouble()),
    );
    final math.Random random = math.Random(1337);

    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Color darkSpecColor = Colors.black;
    final Color lightSpecColor = Colors.white;

    for (int y = 0; y < tileH; y++) {
      for (int x = 0; x < tileW; x++) {
        final double r = random.nextDouble();
        final double factor = (r - 0.5) * 2.0; // [-1.0, 1.0]
        if (factor > 0) {
          final double a = (factor * opacity * 0.6).clamp(0.0, 1.0);
          paint.color = lightSpecColor.withValues(alpha: a);
        } else {
          final double a = (-factor * opacity * 0.6).clamp(0.0, 1.0);
          paint.color = darkSpecColor.withValues(alpha: a);
        }
        tempCanvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1.0, 1.0),
          paint,
        );
      }
    }

    final ui.Picture picture = recorder.endRecording();
    _cachedNoiseImage = picture.toImageSync(tileW, tileH);
    picture.dispose();

    _cachedOpacity = opacity;
    _cachedColor = color;

    _cachedShader = ui.ImageShader(
      _cachedNoiseImage!,
      ui.TileMode.repeated,
      ui.TileMode.repeated,
      Float64List.fromList(Matrix4.identity().storage),
    );
  }

  void dispose() {
    // No-op for static cached shader/image across instances
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    _generateNoiseShader(color, opacity);

    if (_cachedShader != null) {
      final Paint shaderPaint = Paint()..shader = _cachedShader;
      canvas.drawRect(Offset.zero & size, shaderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StaticNoisePainter oldDelegate) {
    return color != oldDelegate.color || opacity != oldDelegate.opacity;
  }
}
