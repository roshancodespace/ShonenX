import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/focus_hover_detector.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_smart_image.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class TvContinueCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final double progress;
  final String? progressText;
  final String? thumbnailUrl;
  final String? bannerUrl;
  final String? coverUrl;
  final MediaType mediaType;
  final VoidCallback? onTap;
  final VoidCallback? onFocused;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final FocusNode? focusNode;
  final double? width;
  final double? height;

  const TvContinueCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.progress = 0.0,
    this.progressText,
    this.thumbnailUrl,
    this.bannerUrl,
    this.coverUrl,
    this.mediaType = MediaType.ANIME,
    this.onTap,
    this.onFocused,
    this.onLongPress,
    this.onFocusChange,
    this.autofocus = false,
    this.focusNode,
    this.width,
    this.height,
  });

  factory TvContinueCard.fromWatchEntry({
    Key? key,
    required WatchHistoryEntry entry,
    VoidCallback? onTap,
    VoidCallback? onFocused,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onFocusChange,
    bool autofocus = false,
    FocusNode? focusNode,
    double? width,
    double? height,
  }) {
    final progress = entry.durationInMilliseconds == 0
        ? 0.0
        : (entry.positionInMilliseconds / entry.durationInMilliseconds).clamp(
            0.0,
            1.0,
          );

    final epNum = entry.episodeNumber;
    final cleanEpNum = epNum % 1 == 0 ? epNum.toInt() : epNum;
    final epTitle = entry.episodeTitle;
    final subtitle = epTitle != null && epTitle.isNotEmpty
        ? 'EP $cleanEpNum • $epTitle'
        : 'Episode $cleanEpNum';

    final remainingMs =
        entry.durationInMilliseconds - entry.positionInMilliseconds;
    final progressText = remainingMs > 0
        ? formatTimeRemaining(remainingMs)
        : '${(progress * 100).toInt()}%';

    return TvContinueCard(
      key: key,
      title: entry.animeTitle,
      subtitle: subtitle,
      badgeText: 'EP $cleanEpNum',
      progress: progress,
      progressText: progressText,
      thumbnailUrl: entry.thumbnailUrl,
      bannerUrl: entry.banner,
      coverUrl: entry.cover,
      mediaType: MediaType.ANIME,
      onTap: onTap,
      onFocused: onFocused,
      onLongPress: onLongPress,
      onFocusChange: onFocusChange,
      autofocus: autofocus,
      focusNode: focusNode,
      width: width,
      height: height,
    );
  }

  factory TvContinueCard.fromReadEntry({
    Key? key,
    required ReadHistoryEntry entry,
    VoidCallback? onTap,
    VoidCallback? onFocused,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onFocusChange,
    bool autofocus = false,
    FocusNode? focusNode,
    double? width,
    double? height,
  }) {
    final progress = entry.totalPages == 0
        ? 0.0
        : (entry.positionPage / entry.totalPages).clamp(0.0, 1.0);

    final chNum = entry.chapterNumber;
    final cleanChNum = chNum % 1 == 0 ? chNum.toInt() : chNum;
    final chTitle = entry.chapterTitle;
    final subtitle = chTitle != null && chTitle.isNotEmpty
        ? 'CH $cleanChNum • $chTitle'
        : 'Chapter $cleanChNum';

    final progressText = entry.totalPages > 0
        ? 'Page ${entry.positionPage}/${entry.totalPages}'
        : '${(progress * 100).toInt()}% read';

    return TvContinueCard(
      key: key,
      title: entry.mangaTitle,
      subtitle: subtitle,
      badgeText: 'CH $cleanChNum',
      progress: progress,
      progressText: progressText,
      bannerUrl: entry.banner,
      coverUrl: entry.cover,
      mediaType: MediaType.MANGA,
      onTap: onTap,
      onFocused: onFocused,
      onLongPress: onLongPress,
      onFocusChange: onFocusChange,
      autofocus: autofocus,
      focusNode: focusNode,
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final radius = GlobalUI.uiRoundness;

    final bgImage = (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
        ? thumbnailUrl!
        : (bannerUrl != null && bannerUrl!.isNotEmpty)
        ? bannerUrl!
        : (coverUrl ?? '');

    return AppFocusHover(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: onTap,
      onLongPress: onLongPress,
      scaleFactor: 1.0,
      onFocusChange: (focused) {
        if (focused) onFocused?.call();
        onFocusChange?.call(focused);
      },
      onHoverChange: (hovered) {
        if (hovered) onFocused?.call();
      },
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;
        final cardWidth = width ?? (active ? 420.0 : 340.0);
        final cardHeight = height ?? (active ? 220.0 : 210.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: active ? 0.65 : 0.35),
                blurRadius: active ? 24 : 8,
                spreadRadius: active ? 2 : 0,
                offset: const Offset(0, 4),
              ),
              if (active)
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.25),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: TvSmartImage(
                  imageUrl: bgImage,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        mediaType == MediaType.MANGA
                            ? Icons.menu_book_rounded
                            : Icons.movie_creation_outlined,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.40),
                        Colors.black.withValues(alpha: active ? 0.95 : 0.88),
                      ],
                      stops: const [0.0, 0.28, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (badgeText != null && badgeText!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(
                            (radius * 0.45).clamp(4.0, 8.0),
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badgeText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (progressText != null && progressText!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(
                            (radius * 0.45).clamp(4.0, 8.0),
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5.5,
                              height: 5.5,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5.5),
                            Text(
                              progressText!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: active ? 1.0 : 0.0,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.55),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      mediaType == MediaType.MANGA
                          ? Icons.menu_book_rounded
                          : Icons.play_arrow_rounded,
                      color: cs.onPrimary,
                      size: 30,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: active ? 14.5 : 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: active ? 12 : 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (progress > 0.0)
                      Container(
                        height: 3.5,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.2),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(2),
                                bottomRight: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: active
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
