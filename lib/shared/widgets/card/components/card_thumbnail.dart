import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/image_headers.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class CardThumbnail extends StatelessWidget {
  final UnifiedMedia media;
  final double width;
  final double height;
  final double? radiusOverride;
  final bool isActive;
  final double? progress;
  final String? heroTag;

  const CardThumbnail({
    super.key,
    required this.media,
    required this.width,
    required this.height,
    this.radiusOverride,
    required this.isActive,
    this.progress,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final radius = radiusOverride ?? GlobalUI.uiRoundness;

    if (progress == null) {
      return _buildImage(cs, w: width, h: height, r: radius);
    }

    final strokeW = isActive ? 3.5 : 2.8;
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
              progress: progress!.clamp(0.0, 1.0),
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
    final finalW = (w.isFinite && w > 0) ? w : double.infinity;
    final finalH = (h.isFinite && h > 0) ? h : double.infinity;

    if ((media.cover ?? media.banner) != null && (media.cover ?? media.banner)!.isNotEmpty) {
      final cacheW = (w.isFinite && w > 0 && w < 4000)
          ? (w * 2.5).clamp(150.0, 1000.0).toInt()
          : 600;

      final rawUrl = (media.cover ?? media.banner)!.trim();
      Widget img;

      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        img = CachedNetworkImage(
          imageUrl: rawUrl,
          httpHeaders: decodeUrlHeaders(rawUrl),
          width: finalW,
          height: finalH,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          memCacheWidth: cacheW,
          maxWidthDiskCache: 800,
          fadeInDuration: const Duration(milliseconds: 220),
          placeholderFadeInDuration: const Duration(milliseconds: 120),
          placeholder: (_, __) => _buildPlaceholder(cs, finalW, finalH),
          errorWidget: (_, __, ___) => _buildFallback(cs, finalW, finalH),
        );
      } else {
        try {
          final base64String = rawUrl.contains(',')
              ? rawUrl.split(',').last.trim()
              : rawUrl;
          img = Image.memory(
            base64Decode(base64String),
            width: finalW,
            height: finalH,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _buildFallback(cs, finalW, finalH),
          );
        } catch (_) {
          img = _buildFallback(cs, finalW, finalH);
        }
      }

      if (heroTag != null && heroTag!.isNotEmpty) {
        img = Hero(tag: heroTag!, child: img);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(r),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(width: finalW, height: finalH, child: img),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      clipBehavior: Clip.antiAlias,
      child: _buildFallback(cs, finalW, finalH),
    );
  }

  Widget _buildPlaceholder(ColorScheme cs, double w, double h) {
    return Container(
      width: w,
      height: h,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
    );
  }

  Widget _buildFallback(ColorScheme cs, double w, double h) {
    return Container(
      width: w,
      height: h,
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_rounded, color: cs.onSurfaceVariant, size: 28),
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
