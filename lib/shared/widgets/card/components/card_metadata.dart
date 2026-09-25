import 'package:flutter/material.dart';

import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/marquee_text.dart';

class PortraitMetadataRow extends StatelessWidget {
  final UnifiedMedia media;
  final bool showRatings;
  final bool showYear;
  final bool showGenres;
  final String? subtitle;

  const PortraitMetadataRow({
    super.key,
    required this.media,
    required this.showRatings,
    required this.showYear,
    required this.showGenres,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final year = showYear ? media.year?.toString() : null;
    final genres = showGenres ? media.genres : null;
    final status = media.status;

    final hasYear = year != null && year.isNotEmpty;
    final hasGenres = genres != null && genres.isNotEmpty;
    final hasStatus = status != null && status.isNotEmpty;

    if (subtitle != null && subtitle!.isNotEmpty) {
      return Text(
        subtitle!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      );
    }

    if (!hasYear && !hasGenres && !hasStatus) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasYear) ...[
          Text(
            year,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          if (hasStatus || hasGenres)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                '•',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
              ),
            ),
        ],
        if (hasStatus && !hasGenres) ...[
          Expanded(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
        ],
        if (hasGenres) ...[
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                genres.first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
                ),
              ),
            ),
          ),
          if (genres.length > 1) ...[
            const SizedBox(width: 2),
            Text(
              '+${genres.length - 1}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class WideMetadataColumn extends StatelessWidget {
  final UnifiedMedia media;
  final bool showRatings;
  final bool showYear;
  final bool showGenres;
  final String? subtitle;
  final Color? textColor;
  final double height;
  final double? progress;
  final String? progressText;
  final Widget? topRightBadge;

  const WideMetadataColumn({
    super.key,
    required this.media,
    required this.showRatings,
    required this.showYear,
    required this.showGenres,
    required this.height,
    this.subtitle,
    this.textColor,
    this.progress,
    this.progressText,
    this.topRightBadge,
  });

  String? _getFormattedScore() {
    if (!showRatings || media.score == null || media.score! <= 0) return null;
    return media.score! > 10
        ? (media.score! / 10).toStringAsFixed(1)
        : media.score!.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final metaItems = <String>[];
    if (showYear && media.year != null) {
      metaItems.add(media.year!.toString());
    }
    if (media.status != null && media.status!.isNotEmpty) {
      metaItems.add(media.status!);
    }
    if (subtitle != null && subtitle!.isNotEmpty) {
      metaItems.add(subtitle!);
    }
    final metaText = metaItems.join(' • ');

    final formattedScore = _getFormattedScore();
    final shouldShowGenres =
        showGenres &&
        media.genres != null &&
        media.genres!.isNotEmpty &&
        height >= 105;

    final effectiveTextColor = textColor ?? cs.onSurface;
    final effectiveSubtextColor =
        textColor?.withValues(alpha: 0.75) ?? cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: MarqueeText(
                text: media.title.getPreferedTitle,
                style:
                    theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: effectiveTextColor,
                      height: 1.2,
                    ) ??
                    TextStyle(color: effectiveTextColor),
              ),
            ),
            if (topRightBadge != null) ...[
              const SizedBox(width: 4),
              Flexible(child: topRightBadge!),
            ],
          ],
        ),
        if (formattedScore != null || metaText.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              if (formattedScore != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB703).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFFFB703).withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: Color(0xFFFFB703),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        formattedScore,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: effectiveTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (metaText.isNotEmpty) const SizedBox(width: 6),
              ],
              if (metaText.isNotEmpty)
                Expanded(
                  child: Text(
                    metaText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: effectiveSubtextColor,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (shouldShowGenres) ...[
          const SizedBox(height: 3),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: media.genres!.take(2).map((g) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  g,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (progress != null || progressText != null) ...[
          const SizedBox(height: 6),
          if (progressText != null)
            Text(
              progressText!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (progressText != null && progress != null)
            const SizedBox(height: 6),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
        ],
      ],
    );
  }
}
