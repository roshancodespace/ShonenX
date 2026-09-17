import 'package:flutter/material.dart';

class EpisodeProgressBar extends StatelessWidget {
  final double progress;
  final String? remainingText;
  final bool isCompleted;
  final double height;
  final bool showText;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;

  const EpisodeProgressBar({
    super.key,
    required this.progress,
    this.remainingText,
    this.isCompleted = false,
    this.height = 3.5,
    this.showText = false,
    this.color,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final clampedProgress = progress.clamp(0.0, 1.0);

    final trackColor = backgroundColor ??
        cs.surfaceContainerHighest.withValues(alpha: 0.5);
    final progressColor = color ??
        (isCompleted
            ? cs.secondary.withValues(alpha: 0.85)
            : cs.primary);
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    final barWidget = ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: clampedProgress,
          backgroundColor: trackColor,
          valueColor: AlwaysStoppedAnimation(progressColor),
        ),
      ),
    );

    if (!showText || remainingText == null || remainingText!.isEmpty) {
      return barWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(child: barWidget),
        const SizedBox(width: 8),
        Text(
          remainingText!,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isCompleted
                ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                : cs.primary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
