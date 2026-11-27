import 'package:material_ui/material_ui.dart';

import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/theme/ui_visual_values.dart';
import 'package:shonenx/shared/widgets/card/card_renderer.dart';
import 'package:shonenx/shared/widgets/app_progress_indicator.dart';

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = MediaCardStyle.values.firstWhere(
      (s) => s.name == variant,
      orElse: () => MediaCardStyle.classic,
    );

    final topLeftPill = badgeText.isNotEmpty
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: UiAlpha.solidMid),
              borderRadius: BorderRadius.circular(
                style == MediaCardStyle.expressive ? UiRadius.wide : UiRadius.sm,
              ),
            ),
            child: Text(
              badgeText.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                fontSize: 9.5,
                height: 1.1,
              ),
            ),
          )
        : null;

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
      topLeftBadge: topLeftPill,
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
                child: AppProgressIndicator(type: AppProgressType.circular, strokeWidth: 3, color: Theme.of(context).colorScheme.primary,),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
