import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/widgets/card/card_renderer.dart';
import 'package:shonenx/shared/widgets/card/models/card_config.dart';

class ContinueCardLayout extends StatelessWidget {
  final String variant;
  final double width;
  final double height;
  final bool isActive;
  final bool isLoading;
  final String title;
  final String subtitle;
  final double progress;
  final String progressText;
  final String badgeText;
  final String? imageUrl;
  final Widget Function(BuildContext context, ColorScheme cs)? thumbnailBuilder;
  final IconData fallbackIcon;
  final String badgeType;
  final bool isWideMode;

  const ContinueCardLayout({
    super.key,
    required this.variant,
    required this.width,
    required this.height,
    required this.isActive,
    required this.isLoading,
    this.isWideMode = false,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressText,
    required this.badgeText,
    this.imageUrl,
    this.thumbnailBuilder,
    required this.fallbackIcon,
    required this.badgeType,
  });

  @override
  Widget build(BuildContext context) {
    final style = MediaCardStyle.values.firstWhere(
      (s) => s.name == variant,
      orElse: () => MediaCardStyle.classic,
    );

    return CardRenderer(
      style: style,
      config: CardConfig(
        width: width,
        height: height,
        isActive: isActive,
        isLoading: isLoading,
        isWideMode: isWideMode,
        title: title,
        subtitle: subtitle,
        progress: progress,
        progressText: progressText,
        badgeText: badgeText,
        bottomLeftBadgeText: badgeText,
        imageUrl: imageUrl,
        thumbnailBuilder: thumbnailBuilder,
        fallbackIcon: fallbackIcon,
      ),
    );
  }
}
