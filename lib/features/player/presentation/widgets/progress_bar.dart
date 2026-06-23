import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';

class ProgressBar extends ConsumerWidget {
  final List<AniSkipStamp> aniSkips;
  final VideoEngine engine;
  final double? draggingValue;
  final Function(double) onDragStart;
  final Function(double) onChanged;
  final Function(double) onDragEnd;

  const ProgressBar({
    super.key,
    required this.aniSkips,
    required this.engine,
    required this.draggingValue,
    required this.onDragStart,
    required this.onChanged,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(
      videoEngineStateProvider.select((s) => s.position),
    );
    final duration = ref.watch(
      videoEngineStateProvider.select((s) => s.duration),
    );
    final buffer = ref.watch(videoEngineStateProvider.select((s) => s.buffer));

    return SizedBox(
      height: 40,
      child: Builder(
        builder: (context) {
          final pos = position.inMilliseconds / 1000.0;
          final dur = duration.inMilliseconds / 1000.0;
          final bfr = buffer.inMilliseconds / 1000.0;

          final current = draggingValue ?? pos;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (details) {
              final dx = details.localPosition.dx;
              final value = (dx / context.size!.width) * dur;
              onDragStart(value.clamp(0, dur));
            },
            onHorizontalDragUpdate: (details) {
              final dx = details.localPosition.dx;
              final value = (dx / context.size!.width) * dur;
              onChanged(value.clamp(0, dur));
            },
            onHorizontalDragEnd: (_) {
              final value = draggingValue ?? pos;
              engine
                  .seekTo(Duration(milliseconds: (value * 1000).toInt()))
                  .then((_) => onDragEnd(value));
            },
            child: Consumer(
              builder: (context, ref, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 40),
                  painter: ProgressBarPainter(
                    skipStamps: aniSkips,
                    totalDuration: dur,
                    progress: current,
                    buffer: bfr,
                    thumbColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    progressColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    bufferColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    baseColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.2),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ProgressBarPainter extends CustomPainter {
  final List<AniSkipStamp> skipStamps;
  final double totalDuration;
  final double progress;
  final double buffer;

  final double barHeight;
  final double thumbWidth;
  final double thumbHeight;

  final Color baseColor;
  final Color bufferColor;
  final Color progressColor;
  final Color thumbColor;
  final Color thumbGlowColor;

  final Radius barRadius;
  final Radius thumbRadius;

  final Color Function(SkipType type) skipColorBuilder;

  ProgressBarPainter({
    super.repaint,
    required this.skipStamps,
    required this.totalDuration,
    required this.progress,
    required this.buffer,
    this.barHeight = 3.0,
    this.thumbWidth = 8.0,
    this.thumbHeight = 24.0,
    this.baseColor = const Color(0xFF2A2A2A),
    this.bufferColor = const Color(0xFF555555),
    this.progressColor = const Color(0xFFFFFFFF),
    this.thumbColor = const Color(0xFFFFFFFF),
    this.thumbGlowColor = const Color(0x33FFFFFF),
    this.barRadius = const Radius.circular(3.0),
    this.thumbRadius = const Radius.circular(2.0),
    this.skipColorBuilder = _defaultSkipColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final safeDuration = totalDuration > 0.0 ? totalDuration : 1.0;
    final progressRatio = (progress / safeDuration).clamp(0.0, 1.0);
    final bufferRatio = (buffer / safeDuration).clamp(0.0, 1.0);

    final centerY = size.height / 2;
    final barTop = centerY - barHeight / 2;
    final barRect = Rect.fromLTWH(0, barTop, size.width, barHeight);

    // 1. Base Track
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(barRect, barRadius), basePaint);

    // 2. Skip Stamps
    final skipPaint = Paint()..style = PaintingStyle.fill;
    for (final stamp in skipStamps) {
      final startX = (stamp.startTime / safeDuration) * size.width;
      final endX = (stamp.endTime / safeDuration) * size.width;

      // Skip if completely off-screen
      if (endX <= 0 || startX >= size.width) continue;

      final clampedStart = startX.clamp(0.0, size.width);
      final clampedEnd = endX.clamp(0.0, size.width);
      final stampRect = Rect.fromLTRB(
        clampedStart,
        barTop - 1.0,
        clampedEnd,
        barTop + barHeight + 1.0,
      );

      skipPaint.color = skipColorBuilder(stamp.type);
      canvas.drawRRect(
        RRect.fromRectAndRadius(stampRect, const Radius.circular(2.0)),
        skipPaint,
      );
    }

    // 3. Buffer
    if (bufferRatio > 0.0) {
      final bufferPaint = Paint()
        ..color = bufferColor
        ..style = PaintingStyle.fill;
      final bufferWidth = size.width * bufferRatio;
      final bufferRect = Rect.fromLTWH(0, barTop, bufferWidth, barHeight);

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          bufferRect,
          topLeft: barRadius,
          bottomLeft: barRadius,
          topRight: bufferRatio >= 1.0 ? barRadius : Radius.zero,
          bottomRight: bufferRatio >= 1.0 ? barRadius : Radius.zero,
        ),
        bufferPaint,
      );
    }

    // 4. Progress
    if (progressRatio > 0.0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.fill;
      final progressWidth = size.width * progressRatio;
      final progressRect = Rect.fromLTWH(0, barTop, progressWidth, barHeight);

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          progressRect,
          topLeft: barRadius,
          bottomLeft: barRadius,
          topRight: progressRatio >= 1.0 ? barRadius : Radius.zero,
          bottomRight: progressRatio >= 1.0 ? barRadius : Radius.zero,
        ),
        progressPaint,
      );
    }

    // 5. Thumb & Glow
    final thumbCenterX = (size.width * progressRatio).clamp(
      thumbWidth / 2,
      size.width - thumbWidth / 2,
    );
    final thumbRect = Rect.fromCenter(
      center: Offset(thumbCenterX, centerY),
      width: thumbWidth,
      height: thumbHeight,
    );

    // Soft glow using MaskFilter (GPU accelerated)
    // final glowPaint = Paint()
    //   ..color = thumbGlowColor
    //   ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    // canvas.drawRRect(
    //   RRect.fromRectAndRadius(thumbRect.inflate(3.0), thumbRadius),
    //   glowPaint,
    // );

    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(thumbRect, thumbRadius),
      thumbPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressBarPainter oldDelegate) {
    if (!listEquals(oldDelegate.skipStamps, skipStamps)) return true;
    if (oldDelegate.totalDuration != totalDuration ||
        oldDelegate.progress != progress ||
        oldDelegate.buffer != buffer ||
        oldDelegate.barHeight != barHeight ||
        oldDelegate.thumbWidth != thumbWidth ||
        oldDelegate.thumbHeight != thumbHeight ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.bufferColor != bufferColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.thumbColor != thumbColor ||
        oldDelegate.thumbGlowColor != thumbGlowColor ||
        oldDelegate.barRadius != barRadius ||
        oldDelegate.thumbRadius != thumbRadius) {
      return true;
    }
    return !identical(oldDelegate.skipColorBuilder, skipColorBuilder);
  }

  static Color _defaultSkipColor(SkipType type) {
    switch (type) {
      case SkipType.opening:
        return const Color(0x664CD964);
      case SkipType.ending:
        return const Color(0x66BA68C8);
      case SkipType.mixedOpening:
        return const Color(0x664FC3F7);
      case SkipType.mixedEnding:
        return const Color(0x66FF6B6B);
      case SkipType.recap:
        return const Color(0x66FFD54F);
    }
  }
}
