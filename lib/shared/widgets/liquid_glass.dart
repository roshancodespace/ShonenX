import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class LiquidGlass extends StatefulWidget {
  final Widget child;
  final double radius;
  final double strength; // 0..1 how much refraction/lens vs plain blur
  final double blurSigma;
  final EdgeInsetsGeometry padding;
  final bool interactive;
  final VoidCallback? onTap;

  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = 24,
    this.strength = 1.0,
    this.blurSigma = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.interactive = true,
    this.onTap,
  });

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _Ripple {
  final Offset center;
  final double start;
  _Ripple(this.center, this.start);
}

double _breathingCornerRadius(int i, double radius, double t, double strength) {
  final amp = 1.2 + 2.0 * strength;
  return (radius + math.sin(t * 2 * math.pi + i * math.pi / 2) * amp).clamp(
    0.0,
    radius + amp,
  );
}

RRect breathingRRect(Rect rect, double radius, double t, double strength) {
  return RRect.fromRectAndCorners(
    rect,
    topLeft: Radius.circular(_breathingCornerRadius(0, radius, t, strength)),
    topRight: Radius.circular(_breathingCornerRadius(1, radius, t, strength)),
    bottomRight: Radius.circular(
      _breathingCornerRadius(2, radius, t, strength),
    ),
    bottomLeft: Radius.circular(_breathingCornerRadius(3, radius, t, strength)),
  );
}

class _BreathingClipper extends CustomClipper<RRect> {
  final double radius;
  final double strength;
  final ValueGetter<double> getT;

  _BreathingClipper({
    required Listenable repaint,
    required this.radius,
    required this.strength,
    required this.getT,
  }) : super(reclip: repaint);

  @override
  RRect getClip(Size size) =>
      breathingRRect(Offset.zero & size, radius, getT(), strength);

  @override
  bool shouldReclip(covariant _BreathingClipper oldClipper) => true;
}

class _ShaderCache {
  static ui.FragmentProgram? program;
  static Future<ui.FragmentProgram>? loading;

  static Future<ui.FragmentProgram> load() {
    if (program != null) return Future.value(program);
    loading ??= ui.FragmentProgram.fromAsset(
      'assets/shaders/liquid_glass.frag',
    ).then((p) => program = p);
    return loading!;
  }
}

class _LiquidGlassState extends State<LiquidGlass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow;
  final GlobalKey _boxKey = GlobalKey();
  ui.FragmentProgram? _program;
  Offset _target = const Offset(0.5, 0.4);
  Offset _pointer = const Offset(0.5, 0.4);
  final List<_Ripple> _ripples = [];
  double _pressScale = 1.0;

  double get _now => (_flow.lastElapsedDuration?.inMilliseconds ?? 0) / 1000;

  @override
  void initState() {
    super.initState();
    _flow =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(_tick)
          ..repeat();
    _ShaderCache.load().then((p) {
      if (mounted) setState(() => _program = p);
    });
  }

  void _tick() {
    final next = Offset.lerp(_pointer, _target, 0.08)!;
    final dirty =
        (next - _pointer).distanceSquared > 1e-7 || _ripples.isNotEmpty;
    _pointer = next;
    _ripples.removeWhere((r) => _now - r.start > 1.1);
    if (dirty) setState(() {});
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  Size _sizeOf() {
    final box = _boxKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) return box.size;
    return Size.zero;
  }

  void _updatePointer(Offset local) {
    if (!widget.interactive) return;
    final size = _sizeOf();
    if (size.width == 0 || size.height == 0) return;
    _target = Offset(
      (local.dx / size.width).clamp(0.0, 1.0),
      (local.dy / size.height).clamp(0.0, 1.0),
    );
  }

  void _addRipple(Offset local) =>
      setState(() => _ripples.add(_Ripple(local, _now)));

  ui.ImageFilter _buildFilter(Size size) {
    if (_program == null || size.isEmpty) {
      return ui.ImageFilter.blur(
        sigmaX: widget.blurSigma,
        sigmaY: widget.blurSigma,
      );
    }
    final liveRadius =
        (List.generate(
          4,
          (i) => _breathingCornerRadius(
            i,
            widget.radius,
            _flow.value,
            widget.strength,
          ),
        ).reduce((a, b) => a + b)) /
        4;
    final shader = _program!.fragmentShader()
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, liveRadius)
      ..setFloat(3, _flow.value * 2 * math.pi)
      ..setFloat(4, _pointer.dx * size.width)
      ..setFloat(5, _pointer.dy * size.height)
      ..setFloat(6, widget.strength.clamp(0.0, 1.0))
      ..setFloat(7, 22.0)
      ..setFloat(8, 3.0);
    final blur = ui.ImageFilter.blur(
      sigmaX: widget.blurSigma,
      sigmaY: widget.blurSigma,
    );
    try {
      final lens = ui.ImageFilter.shader(shader);
      return ui.ImageFilter.compose(outer: lens, inner: blur);
    } catch (_) {
      return blur;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) => _updatePointer(e.localPosition),
      child: GestureDetector(
        onTapDown: (d) {
          _pressScale = 0.97;
          _addRipple(d.localPosition);
        },
        onTapUp: (_) => setState(() => _pressScale = 1.0),
        onTapCancel: () => setState(() => _pressScale = 1.0),
        onTap: widget.onTap,
        onPanUpdate: widget.interactive
            ? (d) => _updatePointer(d.localPosition)
            : null,
        child: AnimatedScale(
          scale: _pressScale,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: ClipRRect(
            key: _boxKey,
            clipper: _BreathingClipper(
              repaint: _flow,
              radius: widget.radius,
              strength: widget.strength,
              getT: () => _flow.value,
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _flow,
                  builder: (context, _) {
                    final size = _sizeOf();
                    return BackdropFilter(
                      filter: _buildFilter(size),
                      child: const SizedBox(),
                    );
                  },
                ),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _LiquidOverlayPainter(
                        radius: widget.radius,
                        strength: widget.strength,
                        t: _flow.value,
                        ripples: List.unmodifiable(_ripples),
                        now: _now,
                      ),
                    ),
                  ),
                ),
                Padding(padding: widget.padding, child: widget.child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidOverlayPainter extends CustomPainter {
  final double radius;
  final double strength;
  final double t;
  final List<_Ripple> ripples;
  final double now;

  _LiquidOverlayPainter({
    required this.radius,
    required this.strength,
    required this.t,
    required this.ripples,
    required this.now,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = breathingRRect(rect, radius, t, strength);

    canvas.save();
    canvas.clipRRect(rrect);
    for (final r in ripples) {
      final progress = ((now - r.start) / 1.1).clamp(0.0, 1.0);
      canvas.drawCircle(
        r.center,
        size.longestSide * 0.9 * progress,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - progress) + 0.4
          ..color = Colors.white.withValues(alpha: (1 - progress) * 0.28),
      );
    }
    canvas.restore();

    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.32 + 0.25 * strength),
            Colors.white.withValues(alpha: 0.05 + 0.08 * strength),
            Colors.transparent,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidOverlayPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.ripples.length != ripples.length;
  }
}
