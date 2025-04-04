import 'package:flutter/material.dart';
import 'package:shonenx/data/hive/models/subtitle_style_offline_model.dart';

class SubtitleOverlay extends StatelessWidget {
  final String subtitle;
  final SubtitleStyle subtitleStyle;

  const SubtitleOverlay(
      {super.key, required this.subtitle, required this.subtitleStyle});

  @override
  Widget build(BuildContext context) {
    if (subtitle.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: subtitleStyle.backgroundOpacity),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        subtitle,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          color: subtitleStyle.textColor,
          fontSize: subtitleStyle.fontSize,
          shadows: [
            if (subtitleStyle.hasShadow)
              Shadow(
                color: Colors.black.withValues(alpha: 0.8),
                offset: const Offset(0.5, 0.5),
                blurRadius: 2,
              ),
          ],
        ),
      ),
    );
  }
}
