import 'package:flutter/material.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class SeasonSelectorBar extends StatelessWidget {
  final UnifiedMedia currentMedia;

  const SeasonSelectorBar({
    super.key,
    required this.currentMedia,
  });

  @override
  Widget build(BuildContext context) {
    final relations = currentMedia.relations;
    if (relations == null || relations.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Filter relevant relations (anime/manga series, prequels, sequels, movies)
    final relevantRelations = relations.where((r) {
      return r.type == currentMedia.type;
    }).toList();

    if (relevantRelations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Current Season / Media Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: cs.onPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatSeasonLabel(currentMedia, isCurrent: true),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Related Seasons / Prequels / Sequels
            ...relevantRelations.map((relation) {
              final relationLabel = _formatSeasonLabel(relation);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: Icon(
                    _getRelationIcon(relation.relationType),
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  label: Text(relationLabel),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  onPressed: () {
                    context.pushDetails(
                      mediaType: relation.type,
                      media: relation,
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatSeasonLabel(UnifiedMedia media, {bool isCurrent = false}) {
    final title = media.title.availableTitle;
    final relType = media.relationType?.toUpperCase();

    if (isCurrent) {
      return 'Current Season';
    }

    if (relType != null) {
      switch (relType) {
        case 'PREQUEL':
          return 'Prequel: $title';
        case 'SEQUEL':
          return 'Sequel: $title';
        case 'PARENT':
          return 'Main Series: $title';
        case 'SIDE_STORY':
          return 'Side Story: $title';
        case 'SPIN_OFF':
          return 'Spin-off: $title';
        case 'ALTERNATIVE':
          return 'Alt: $title';
        default:
          return title;
      }
    }

    return title;
  }

  IconData _getRelationIcon(String? relationType) {
    switch (relationType?.toUpperCase()) {
      case 'PREQUEL':
        return Icons.skip_previous_rounded;
      case 'SEQUEL':
        return Icons.skip_next_rounded;
      case 'PARENT':
        return Icons.account_tree_rounded;
      case 'SIDE_STORY':
      case 'SPIN_OFF':
        return Icons.alt_route_rounded;
      default:
        return Icons.movie_filter_outlined;
    }
  }
}
