import 'package:flutter/material.dart';
import 'package:shonenx/shared/widgets/universal_card_renderer.dart';

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
    return UniversalCardRenderer(
      styleName: variant,
      width: width,
      height: height,
      isActive: isActive,
      isLoading: isLoading,
      isWideMode: isWideMode,
      title: title,
      subtitle: subtitle,
      progress: progress,
      badgeText: badgeText,
      bottomLeftBadgeText: badgeText,
      imageUrl: imageUrl,
      thumbnailBuilder: thumbnailBuilder,
      fallbackIcon: fallbackIcon,
    );
  }
}
