import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/image_headers.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import '../models/card_config.dart';

class CardThumbnail extends StatelessWidget {
  final CardConfig config;
  final double width;
  final double height;
  final double? radiusOverride;

  const CardThumbnail({
    super.key,
    required this.config,
    required this.width,
    required this.height,
    this.radiusOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final radius = radiusOverride ?? GlobalUI.uiRoundness;

    if (config.progress == null) {
      return _buildImage(cs, w: width, h: height, r: radius);
    }

    final strokeW = config.isActive ? 3.5 : 2.8;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(strokeW * 0.5),
          child: _buildImage(
            cs,
            w: width == double.maxFinite ? width : width - strokeW,
            h: height - strokeW,
            r: radius - (strokeW * 0.5),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _ProgressBorderPainter(
              progress: config.progress!.clamp(0.0, 1.0),
              color: cs.primary,
              trackColor: cs.primary.withValues(alpha: 0.22),
              strokeWidth: strokeW,
              radius: radius,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(
    ColorScheme cs, {
    required double w,
    required double h,
    required double r,
  }) {
    if (config.thumbnailBuilder != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: SizedBox(
          width: w,
          height: h,
          child: Builder(
            builder: (context) => config.thumbnailBuilder!(context, cs),
          ),
        ),
      );
    }

    if (config.imageUrl != null && config.imageUrl!.isNotEmpty) {
      Widget img = CachedNetworkImage(
        imageUrl: config.imageUrl!,
        httpHeaders: decodeUrlHeaders(config.imageUrl!),
        width: w,
        height: h,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 220),
        placeholderFadeInDuration: const Duration(milliseconds: 120),
        errorWidget: (_, __, ___) => _buildFallback(cs, w, h),
      );
      if (config.heroTag != null && config.heroTag!.isNotEmpty) {
        img = Hero(tag: config.heroTag!, child: img);
      }
      return ClipRRect(borderRadius: BorderRadius.circular(r), child: img);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: _buildFallback(cs, w, h),
    );
  }

  Widget _buildFallback(ColorScheme cs, double w, double h) {
    return Container(
      width: w,
      height: h,
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(config.fallbackIcon, color: cs.onSurfaceVariant, size: 28),
    );
  }
}

class _ProgressBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double radius;

  _ProgressBorderPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final halfWidth = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        halfWidth,
        halfWidth,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular((radius - halfWidth).clamp(0.0, 999.0)),
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, trackPaint);

    if (progress > 0.0) {
      final path = Path()..addRRect(rrect);
      for (final metric in path.computeMetrics()) {
        final extractLength = metric.length * progress.clamp(0.0, 1.0);
        final subPath = metric.extractPath(0.0, extractLength);

        final progressPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(subPath, progressPaint);
        break;
      }
    }
  }

  @override
  bool shouldRepaint(_ProgressBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
