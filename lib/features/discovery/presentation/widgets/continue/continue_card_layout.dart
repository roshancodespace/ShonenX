import 'package:flutter/material.dart';

import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/card/card_renderer.dart';

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
    required this.fallbackIcon,
    required this.badgeType,
  });

  @override
  Widget build(BuildContext context) {
    final style = MediaCardStyle.values.firstWhere(
      (s) => s.name == variant,
      orElse: () => MediaCardStyle.classic,
    );

    final card = CardRenderer(
      style: style,
      media: UnifiedMedia(
        id: 'continue_card',
        type: MediaType.ANIME,
        title: MediaTitle(english: title),
        cover: imageUrl,
      ),
      width: width,
      height: height,
      isActive: isActive,
      isWideMode: isWideMode,
      showRatings: false,
      showYear: false,
      showGenres: false,
      subtitle: subtitle,
      progress: progress,
      progressText: progressText,
      bottomLeftBadge: Text(badgeText),
    );

    if (!isLoading) return card;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
            ),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
