import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/unified_episode.dart';

class GroupedChapterTile extends StatefulWidget {
  final String title;
  final List<UnifiedEpisode> episodes;
  final UnifiedEpisode? currentEpisode;
  final String? preferredScanlator;
  final void Function(UnifiedEpisode) onEpisodeTap;
  final bool isCurrentChapterNum;

  const GroupedChapterTile({
    super.key,
    required this.title,
    required this.episodes,
    required this.currentEpisode,
    required this.preferredScanlator,
    required this.onEpisodeTap,
    required this.isCurrentChapterNum,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(
            widget.title,
            style: TextStyle(
              fontWeight: widget.isCurrentChapterNum
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          selected: widget.isCurrentChapterNum,
          selectedTileColor: theme.colorScheme.primaryContainer.withValues(
            alpha: 0.5,
          ),
          onTap: () => widget.onEpisodeTap(target),
          trailing: IconButton(
            icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
        ),
        if (_isExpanded)
          ...widget.episodes.map((ep) {
            final isCurrent = ep.id == widget.currentEpisode?.id;
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 32, right: 16),
              title: Text(
                ep.scanlator ?? ep.title ?? 'Unknown Scanlator',
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isCurrent,
              selectedTileColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.5,
              ),
              onTap: () => widget.onEpisodeTap(ep),
            );
          }),
      ],
    );
  }
}
