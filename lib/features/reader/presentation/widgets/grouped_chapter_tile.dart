import 'package:material_ui/material_ui.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/widgets/app_card_group.dart';
import 'package:shonenx/shared/widgets/app_chip.dart';

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCardSurface(
        color: widget.isCurrentChapterNum
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
            : null,
        padding: EdgeInsets.zero,
        onTap: () => widget.onEpisodeTap(target),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
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
                            AppChip(
                              label: '${widget.episodes.length} Scanlators',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                            ),
                          ],
                        ),
                        if (widget.isCurrentChapterNum) ...[
                          const SizedBox(height: 6),
                          const AppChip(
                            label: 'CURRENT',
                            selected: true,
                            showCheckmark: false,
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
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
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 2),
                child: AppCardGroup(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: widget.episodes.map((ep) {
                    final isCurrent = ep.id == widget.currentEpisode?.id;
                    return AppCardSurface(
                      color: isCurrent
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.7,
                            )
                          : theme.colorScheme.surfaceContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      onTap: () => widget.onEpisodeTap(ep),
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
                                        ? theme.colorScheme.onPrimaryContainer
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
