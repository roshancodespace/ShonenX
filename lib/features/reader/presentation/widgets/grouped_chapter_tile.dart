import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/shared/models/unified_episode.dart';

class GroupedChapterTile extends StatefulWidget {
  final String title;
  final List<UnifiedEpisode> episodes;
  final UnifiedEpisode? currentEpisode;
  final String? preferredScanlator;
  final void Function(UnifiedEpisode) onEpisodeTap;
  final bool isCurrentChapterNum;
  final double uiRoundness;

  const GroupedChapterTile({
    super.key,
    required this.title,
    required this.episodes,
    required this.currentEpisode,
    required this.preferredScanlator,
    required this.onEpisodeTap,
    required this.isCurrentChapterNum,
    required this.uiRoundness,
  });

  @override
  State<GroupedChapterTile> createState() => GroupedChapterTileState();
}

class GroupedChapterTileState extends State<GroupedChapterTile> {
  late bool _isExpanded = widget.isCurrentChapterNum;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    UnifiedEpisode target = widget.episodes.first;
    if (widget.preferredScanlator != null) {
      target =
          widget.episodes
              .where((e) => e.scanlator == widget.preferredScanlator)
              .firstOrNull ??
          target;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isCurrentChapterNum
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(widget.uiRoundness),
        border: widget.isCurrentChapterNum
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.uiRoundness),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => widget.onEpisodeTap(target),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontWeight: widget.isCurrentChapterNum
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 14.5,
                                    color: widget.isCurrentChapterNum
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '${widget.episodes.length} Scanlators',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.isCurrentChapterNum) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'CURRENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                      icon: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: _isExpanded
                          ? 'Hide scanlators'
                          : 'Show scanlators',
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Container(
                color: theme.colorScheme.surface.withValues(alpha: 0.4),
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  top: 2,
                ),
                child: Column(
                  children: widget.episodes.map((ep) {
                    final isCurrent = ep.id == widget.currentEpisode?.id;
                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? theme.colorScheme.primaryContainer.withValues(
                                alpha: 0.7,
                              )
                            : theme.colorScheme.surfaceContainer.withValues(
                                alpha: 0.6,
                              ),
                        borderRadius: BorderRadius.circular(
                          (widget.uiRoundness - 4).clamp(
                            0.0,
                            widget.uiRoundness,
                          ),
                        ),
                        border: isCurrent
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 1.2,
                              )
                            : null,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          (widget.uiRoundness - 4).clamp(
                            0.0,
                            widget.uiRoundness,
                          ),
                        ),
                        onTap: () => widget.onEpisodeTap(ep),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.group_rounded,
                                size: 16,
                                color: isCurrent
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ep.scanlator ??
                                          ep.title ??
                                          'Unknown Scanlator',
                                      style: TextStyle(
                                        fontWeight: isCurrent
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 13,
                                        color: isCurrent
                                            ? theme
                                                  .colorScheme
                                                  .onPrimaryContainer
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    if (formatDateString(
                                          ep.uploadDate ?? ep.airDate,
                                        ) !=
                                        null) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 11,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            formatDateString(
                                              ep.uploadDate ?? ep.airDate,
                                            )!,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
