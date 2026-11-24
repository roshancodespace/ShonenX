import 'package:material_ui/material_ui.dart';

import 'package:shonenx/shared/models/unified_media.dart';
import 'card_badges.dart';
import 'card_thumbnail.dart';

const Object _unsetValue = Object();

class CardContent {
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

  const CardContent({
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
  });

  // The sentinel separates "not supplied" from an explicit null so a caller
  // can clear a nullable field with copyWith(progress: null).
  CardContent copyWith({
    UnifiedMedia? media,
    double? width,
    double? height,
    bool? isActive,
    bool? isWideMode,
    bool? showRatings,
    bool? showYear,
    bool? showGenres,
    Object? subtitle = _unsetValue,
    Object? progress = _unsetValue,
    Object? progressText = _unsetValue,
    Object? heroTag = _unsetValue,
    Object? topLeftBadge = _unsetValue,
    Object? topRightBadge = _unsetValue,
    Object? bottomLeftBadge = _unsetValue,
    Object? bottomRightBadge = _unsetValue,
  }) {
    return CardContent(
      media: media ?? this.media,
      width: width ?? this.width,
      height: height ?? this.height,
      isActive: isActive ?? this.isActive,
      isWideMode: isWideMode ?? this.isWideMode,
      showRatings: showRatings ?? this.showRatings,
      showYear: showYear ?? this.showYear,
      showGenres: showGenres ?? this.showGenres,
      subtitle: identical(subtitle, _unsetValue)
          ? this.subtitle
          : subtitle as String?,
      progress: identical(progress, _unsetValue)
          ? this.progress
          : progress as double?,
      progressText: identical(progressText, _unsetValue)
          ? this.progressText
          : progressText as String?,
      heroTag: identical(heroTag, _unsetValue)
          ? this.heroTag
          : heroTag as String?,
      topLeftBadge: identical(topLeftBadge, _unsetValue)
          ? this.topLeftBadge
          : topLeftBadge as Widget?,
      topRightBadge: identical(topRightBadge, _unsetValue)
          ? this.topRightBadge
          : topRightBadge as Widget?,
      bottomLeftBadge: identical(bottomLeftBadge, _unsetValue)
          ? this.bottomLeftBadge
          : bottomLeftBadge as Widget?,
      bottomRightBadge: identical(bottomRightBadge, _unsetValue)
          ? this.bottomRightBadge
          : bottomRightBadge as Widget?,
    );
  }

  String? get resolvedSubtitle {
    if (subtitle != null && subtitle!.isNotEmpty) return subtitle;
    final items = <String>[];
    if (showYear && media.year != null) items.add(media.year.toString());
    if (media.status != null && media.status!.isNotEmpty) {
      items.add(media.status!);
    }
    if (showGenres && media.genres != null && media.genres!.isNotEmpty) {
      items.add(media.genres!.first);
    }
    if (items.isEmpty) return null;
    return items.join(' • ');
  }
}

String? resolveCardSubtitle(CardContent content) => content.resolvedSubtitle;

class CardMediaStack extends StatelessWidget {
  final CardContent content;
  final String styleName;
  final double thumbWidth;
  final double thumbHeight;
  final double? radiusOverride;
  final StackFit? fit;
  final Widget? overlayBeforeBadges;

  const CardMediaStack({
    super.key,
    required this.content,
    required this.styleName,
    required this.thumbWidth,
    required this.thumbHeight,
    this.radiusOverride,
    this.fit,
    this.overlayBeforeBadges,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: fit ?? StackFit.loose,
      children: [
        CardThumbnail(
          media: content.media,
          width: thumbWidth,
          height: thumbHeight,
          radiusOverride: radiusOverride,
          isActive: content.isActive,
          progress: content.progress,
          heroTag: content.heroTag,
        ),
        if (overlayBeforeBadges != null) overlayBeforeBadges!,
        CardBadgeOverlay(
          media: content.media,
          styleName: styleName,
          isWideMode: content.isWideMode,
          isActive: content.isActive,
          showRatings: content.showRatings,
          progress: content.progress,
          progressText: content.progressText,
          topLeftBadge: content.topLeftBadge,
          topRightBadge: content.topRightBadge,
          bottomLeftBadge: content.bottomLeftBadge,
          bottomRightBadge: content.bottomRightBadge,
        ),
      ],
    );
  }
}
