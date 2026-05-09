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
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

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
  static const _contentPadding = 14.0;

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source preference cleared')),
      );
    } else if (value == 'remove_history' && mounted) {
      await ref.read(watchHistoryRepositoryProvider).deleteEntry(entry.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from history')));
      }
    } else if (value == 'fix_match' && mounted) {
      await showModalBottomSheet(
        context: context,
        builder: (_) => ManualMatchSheet(
          mediaTitle: entry.animeTitle,
          type: MediaType.ANIME,
        ),
      );
    }
  }

  void _handleSourceFailure(Object error) {
    if (!mounted) return;

    setState(() => _isLoading = false);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (_) {
        return AppBottomSheet(
          title: 'Source Error',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.9),
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () async {
                        Navigator.pop(context);

                        await ref
                            .read(
                              sourcePreferenceProvider(
                                widget.entry.animeTitle,
                              ).notifier,
                            )
                            .clearPreference();

                        if (mounted) {
                          _handleTap();
                        }
                      },
                      child: const Text('Auto Match'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        final result = await showModalBottomSheet<bool>(
                          context: context,
                          builder: (_) => ManualMatchSheet(
                            mediaTitle: widget.entry.animeTitle,
                            type: MediaType.ANIME,
                          ),
                        );

                        if (result == true && mounted) {
                          _handleTap();
                        }
                      },
                      child: const Text('Manual Match'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final entry = widget.entry;

    try {
      final prefState = await ref.read(
        sourcePreferenceProvider(entry.animeTitle).future,
      );

      final sourceInfo = prefState.sourceInfo;

      UnifiedEpisode? episode;

      if (prefState.manualOverrideId != null) {
        try {
          final args = (
            providerId: prefState.manualOverrideId!,
            sourceId: sourceInfo.id,
          );

          final episodesState = await ref.read(
            sourceEpisodesProvider(args).future,
          );

          episode = episodesState.episodes.firstWhereOrNull(
            (e) => e.number == entry.episodeNumber,
          );

          if (episode == null) {
            throw Exception('Episode not found.');
          }
        } catch (e) {
          _handleSourceFailure(e);
          return;
        }
      } else {
        try {
          final episodesState = await ref.read(
            episodesListProvider(entry.animeTitle).future,
          );

          episode = episodesState.episodes.firstWhereOrNull(
            (e) => e.number == entry.episodeNumber,
          );

          if (episode == null) {
            throw Exception('Episode not found.');
          }
        } catch (e) {
          _handleSourceFailure(e);
          return;
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (mounted) {
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
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    final cs = theme.colorScheme;

    return SizedBox(
      width: widget.style.layout.width,
      child: Padding(
        padding: const EdgeInsets.all(_contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnailStack(
              aspectRatio: 16 / 9,
              borderRadius: 20,
              progressInset: 0,
              layers: [
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'CONTINUE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.entry.animeTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatEpisodeText(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideBanner(ThemeData theme) {
    final cs = theme.colorScheme;

    return Container(
      width: widget.style.layout.width,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_contentPadding),
        child: Row(
          children: [
            SizedBox(
              width: widget.style.layout.width * 0.38,
              child: _buildThumbnailStack(
                aspectRatio: 16 / 10,
                borderRadius: 20,
                progressInset: 0,
                layers: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'EP ${widget.entry.episodeNumber.toInt()}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.entry.animeTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.entry.episodeTitle ?? 'Continue watching',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      width: double.infinity,
                      child: LinearProgressIndicator(
                        value: widget.progress.clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(widget.progress * 100).toInt()}% watched',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    required double progressInset,
    List<Widget>? layers,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                : Container(
                    color: cs.surfaceContainerHighest,
                    child: Icon(
                      Icons.movie_creation_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.45, 1],
                    colors: [
                      Colors.transparent,
                      cs.scrim.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: progressInset,
              right: progressInset,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: widget.progress.clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: Colors.black26,
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                ),
              ),
            ),
            if (layers != null) ...layers,
            if (_isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black45,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
