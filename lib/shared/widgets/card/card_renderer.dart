import 'package:material_ui/material_ui.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';

import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/theme/ui_visual_values.dart';
import 'components/card_content.dart';
import 'styles/cinematic_card.dart';
import 'styles/classic_card.dart';
import 'styles/compact_card.dart';
import 'styles/editorial_card.dart';
import 'styles/expressive_card.dart';
import 'styles/material_card.dart';
import 'styles/minimal_card.dart';
import 'styles/neon_card.dart';
import 'styles/wide_banner_card.dart';

class CardRenderer extends StatelessWidget {
  final MediaCardStyle style;
  final UnifiedMedia media;
  final double width;
  final double height;
  final bool isActive;
  final bool isWideMode;
  final bool showRatings;
  final bool showYear;
  final bool showGenres;
  final String? subtitle;
  final double? progress;
  final String? progressText;
  final String? heroTag;
  final Widget? topLeftBadge;
  final Widget? topRightBadge;
  final Widget? bottomLeftBadge;
  final Widget? bottomRightBadge;

  final bool isLoading;

  const CardRenderer({
    super.key,
    required this.style,
    required this.media,
    required this.width,
    required this.height,
    required this.isActive,
    required this.isWideMode,
    required this.showRatings,
    required this.showYear,
    required this.showGenres,
    this.subtitle,
    this.progress,
    this.progressText,
    this.heroTag,
    this.topLeftBadge,
    this.topRightBadge,
    this.bottomLeftBadge,
    this.bottomRightBadge,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardMedia = media;
    final content = CardContent(
      media: cardMedia,
      width: width,
      height: height,
      isActive: isActive,
      isWideMode: isWideMode,
      showRatings: showRatings,
      showYear: showYear,
      showGenres: showGenres,
      subtitle: subtitle,
      progress: progress,
      progressText: progressText,
      heroTag: heroTag,
      topLeftBadge: topLeftBadge,
      topRightBadge: topRightBadge,
      bottomLeftBadge: bottomLeftBadge,
      bottomRightBadge: bottomRightBadge,
    );

    final Widget card = switch (style) {
      MediaCardStyle.classic => ClassicCard(content: content),
      MediaCardStyle.minimal => MinimalCard(content: content),
      MediaCardStyle.expressive => ExpressiveCard(content: content),
      MediaCardStyle.material => MaterialCard(content: content),
      MediaCardStyle.cinematic => CinematicCard(content: content),
      MediaCardStyle.neon => NeonCard(content: content),
      MediaCardStyle.compact => CompactCard(content: content),
      MediaCardStyle.editorial => EditorialCard(content: content),
      MediaCardStyle.wideBanner => WideBannerCard(content: content),
    };

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          card,
          if (isLoading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UiRadius.card),
                child: Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
