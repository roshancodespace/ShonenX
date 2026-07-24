import 'package:flutter/material.dart';
import 'package:shonenx/shared/widgets/marquee_text.dart';
import '../models/card_config.dart';

class PortraitMetadataRow extends StatelessWidget {
  final CardConfig config;

  const PortraitMetadataRow({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final year = config.year;
    final genres = config.genres;
    final status = config.status;

    final hasYear = year != null && year.isNotEmpty;
    final hasGenres = genres != null && genres.isNotEmpty;
    final hasStatus = status != null && status.isNotEmpty;

    if (config.subtitle != null && config.subtitle!.isNotEmpty) {
      return Text(
        config.subtitle!,
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
  final CardConfig config;

  const WideMetadataColumn({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final metaItems = <String>[];
    if (config.year != null && config.year!.isNotEmpty) {
      metaItems.add(config.year!);
    }
    if (config.status != null && config.status!.isNotEmpty) {
      metaItems.add(config.status!);
    }
    if (config.subtitle != null && config.subtitle!.isNotEmpty) {
      metaItems.add(config.subtitle!);
    }
    final metaText = metaItems.join(' • ');

    final formattedScore = config.formattedScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: MarqueeText(
                text: config.title,
                style:
                    theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      height: 1.2,
                    ) ??
                    const TextStyle(),
              ),
            ),
            if (config.topRightBadge != null) config.topRightBadge!,
          ],
        ),
        if (formattedScore != null || metaText.isNotEmpty) ...[
          const SizedBox(height: 4),
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
                          color: cs.onSurface,
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
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (config.genres != null && config.genres!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: config.genres!.take(2).map((g) {
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
        if (config.progress != null || config.progressText != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (config.progress != null)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: config.progress!.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                ),
              if (config.progressText != null) ...[
                const SizedBox(width: 6),
                Text(
                  config.progressText!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
