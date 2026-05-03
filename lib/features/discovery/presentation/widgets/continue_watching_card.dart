import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/utils/extensions.dart';
import 'package:shonenx/features/discovery/presentation/widgets/manual_match_sheet.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/source_preference_provider.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/player/presentation/player_screen.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class ContinueWatchingItem extends ConsumerStatefulWidget {
  final WatchHistoryEntry entry;
  final double progress;
  final ContinueWatchingStyle style;

  const ContinueWatchingItem({
    super.key,
    required this.entry,
    required this.progress,
    required this.style,
  });

  @override
  ConsumerState<ContinueWatchingItem> createState() =>
      ContinueWatchingItemState();
}

class ContinueWatchingItemState extends ConsumerState<ContinueWatchingItem> {
  bool _isLoading = false;

  void _showItemContextMenu(Offset position) async {
    final entry = widget.entry;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final value = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(value: 'clear', child: Text('Clear Source Preference')),
        PopupMenuItem(
          value: 'remove_history',
          child: Text('Remove from History'),
        ),
        PopupMenuItem(value: 'fix_match', child: Text('Fix Match')),
      ],
    );

    if (value == 'clear' && mounted) {
      ref
          .read(sourcePreferenceProvider(entry.animeTitle).notifier)
          .clearPreference();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source preference cleared')),
      );
    } else if (value == 'remove_history' && mounted) {
      await ref.read(watchHistoryRepositoryProvider).deleteEntry(entry.id);

      if (context.mounted) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from history')));
      }
    } else if (value == 'fix_match' && mounted) {
      await showModalBottomSheet(
        context: context,
        builder: (context) => ManualMatchSheet(
          mediaTitle: entry.animeTitle,
          type: MediaType.ANIME,
        ),
      );
    }
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final entry = widget.entry;
    final prefState = await ref.read(
      sourcePreferenceProvider(entry.animeTitle).future,
    );

    final sourceInfo = prefState.sourceInfo;

    UnifiedEpisode? episode = ref
        .read(episodesListProvider(entry.animeTitle))
        .value
        ?.episodes
        .firstWhereOrNull((e) => e.number == entry.episodeNumber);

    if (episode == null && mounted) {
      if (mounted) {
        await ref.read(episodesListProvider(entry.animeTitle).future);

        episode = ref
            .read(episodesListProvider(entry.animeTitle))
            .value
            ?.episodes
            .firstWhereOrNull((e) => e.number == entry.episodeNumber);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (episode != null && mounted) {
      context.push(
        '/player',
        extra: PlayerParams(
          media: UnifiedMedia(
            id: entry.animeId,
            idMal: entry.animeIdMal,
            type: MediaType.ANIME,
            title: MediaTitle(english: entry.animeTitle),
          ),
          episode: episode,
          sourceInfo: sourceInfo,
          startPosition: Duration(milliseconds: entry.positionInMilliseconds),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onSecondaryTapDown: (details) =>
            _showItemContextMenu(details.globalPosition),
        onLongPressStart: (details) =>
            _showItemContextMenu(details.globalPosition),
        onTap: _handleTap,
        child: _buildStyledContent(widget.style, theme),
      ),
    );
  }

  Widget _buildStyledContent(ContinueWatchingStyle style, ThemeData theme) {
    switch (style) {
      case ContinueWatchingStyle.wideBanner:
        return _buildWideBanner(theme);
      case ContinueWatchingStyle.classic:
        return _buildClassic(theme);
    }
  }

  Widget _buildClassic(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: widget.style.layout.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnailStack(aspectRatio: 16 / 9, borderRadius: 8),
            const SizedBox(height: 6),
            Text(
              widget.entry.animeTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge,
            ),
            Text(
              _formatEpisodeText(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideBanner(ThemeData theme) {
    return Container(
      width: widget.style.layout.width,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceTint.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: widget.style.layout.width / 2.5,
            height: double.infinity,
            child: _buildThumbnailStack(aspectRatio: 16 / 9, borderRadius: 16),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry.animeTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatEpisodeText(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEpisodeText() {
    final epNum = widget.entry.episodeNumber;
    final cleanNum = epNum.toString().contains('.0') ? epNum.toInt() : epNum;
    final epTitle = widget.entry.episodeTitle;
    return 'EP $cleanNum${epTitle != null ? ' • $epTitle' : ''}';
  }

  Widget _buildThumbnailStack({
    required double aspectRatio,
    required double borderRadius,
    List<Widget>? layers,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.entry.thumbnailUrl != null
                ? widget.entry.thumbnailUrl!.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: widget.entry.thumbnailUrl!.split('#').first,
                          httpHeaders: {
                            'Referer': widget.entry.thumbnailUrl!
                                .split('#')
                                .last,
                          },
                          fit: BoxFit.cover,
                        )
                      : Image.memory(
                          base64Decode(widget.entry.thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                : Container(color: Colors.grey.shade800),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: widget.progress.clamp(0, 1),
                minHeight: 3,
                backgroundColor: Colors.black26,
              ),
            ),
            if (layers != null) ...layers,
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
