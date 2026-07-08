import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_tiles.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';
import 'package:shonenx/features/reader/providers/preferred_scanlator_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/batch_download_sheet.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

export 'episode_tiles.dart';

class _Chunk {
  final String label;
  final double? min;
  final double? max;
  _Chunk(this.label, this.min, this.max);
}

class EpisodeListPanel extends ConsumerStatefulWidget {
  final UnifiedMedia media;

  final double? currentEpisodeNumber;
  final double watchedProgress;

  final bool useScrollController;

  final void Function(UnifiedEpisode episode, SourceInfo sourceInfo)
  onEpisodeTap;

  final List<Widget> Function(
    BuildContext context,
    UnifiedEpisode episode,
    bool isCurrent,
    bool isWatched,
  )?
  episodeActionsBuilder;

  final EpisodeImageFadeDirection imageFadeDirection;
  final List<double>? imageFadeStops;
  final double imageOpacity;
  final double imageBlurSigma;

  const EpisodeListPanel({
    super.key,
    required this.media,
    required this.onEpisodeTap,
    this.currentEpisodeNumber,
    this.watchedProgress = 0,
    this.episodeActionsBuilder,
    this.imageFadeDirection = EpisodeImageFadeDirection.left,
    this.useScrollController = true,
    this.imageFadeStops,
    this.imageOpacity = 0.3,
    this.imageBlurSigma = 0,
  });

  @override
  ConsumerState<EpisodeListPanel> createState() => _EpisodeListPanelState();
}

class _EpisodeListPanelState extends ConsumerState<EpisodeListPanel> {
  bool _descending = false;
  int _chunkIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _hasAutoScrolled = false;
  bool _isRetrying = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerRetry(MatchArgs matchArgs) {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
    });
    ref.invalidate(matchedMediaProvider(matchArgs));
    ref.invalidate(episodesListProvider(matchArgs));
    if (widget.media.sourceId != null) {
      ref.invalidate(
        sourceEpisodesProvider((
          providerId: widget.media.providerId ?? widget.media.id,
          sourceId: widget.media.sourceId!,
          type: widget.media.type,
        )),
      );
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(
      uiPrefsProvider.select((s) => s.episodeViewMode),
    );
    final matchArgs = MatchArgs.fromMedia(widget.media);
    final episodesAsync = ref.watch(episodesListProvider(matchArgs));
    final isBusy =
        _isRetrying || episodesAsync.isRefreshing || episodesAsync.isLoading;

    return episodesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                e.toString().contains('Cloudflare')
                    ? 'Cloudflare verification failed. Please try turning off "In-app Cloudflare Bypass" in settings to use the proxy, or perform a manual match.'
                    : 'Failed to fetch episodes: $e',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isBusy ? null : () => _triggerRetry(matchArgs),
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(isBusy ? 'Fetching...' : 'Retry Search'),
              ),
            ],
          ),
        ),
      ),
      data: (state) {
        if (state.episodes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 48,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.media.type == MediaType.MANGA
                        ? 'No chapters found for this source.'
                        : 'No episodes found for this source.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The provider may still be indexing, or the match might need to be retried.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: isBusy ? null : () => _triggerRetry(matchArgs),
                    icon: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(isBusy ? 'Fetching...' : 'Retry Fetching'),
                  ),
                ],
              ),
            ),
          );
        }

        final nums = state.episodes.map((e) => e.number).toList()..sort();

        final chunks = <_Chunk>[_Chunk('All', null, null)];

        if (nums.length > 100) {
          for (int i = 0; i < nums.length; i += 100) {
            final endIdx = (i + 99 < nums.length) ? i + 99 : nums.length - 1;
            final mn = nums[i];
            final mx = nums[endIdx];
            final mnS = mn % 1 == 0 ? mn.toInt().toString() : mn.toString();
            final mxS = mx % 1 == 0 ? mx.toInt().toString() : mx.toString();
            chunks.add(_Chunk('$mnS – $mxS', mn, mx));
          }
        }

        final safeIdx = _chunkIndex < chunks.length ? _chunkIndex : 0;
        final active = chunks[safeIdx];

        var filtered = state.episodes.where((e) {
          if (active.min == null) return true;
          return e.number >= active.min! && e.number <= active.max!;
        }).toList();

        final prefScanlator = ref.read(
          preferredScanlatorProvider(widget.media.id),
        );
        final Map<double, List<UnifiedEpisode>> grouped = {};
        for (final ep in filtered) {
          grouped.putIfAbsent(ep.number, () => []).add(ep);
        }

        filtered = grouped.values.map((eps) {
          UnifiedEpisode target = eps.first;
          if (prefScanlator != null) {
            target =
                eps.where((e) => e.scanlator == prefScanlator).firstOrNull ??
                target;
          }
          return target;
        }).toList();

        filtered.sort(
          (a, b) => _descending
              ? b.number.compareTo(a.number)
              : a.number.compareTo(b.number),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeIn(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
                child: Row(
                  children: [
                    Text(
                      '${state.episodes.length} ${widget.media.type == MediaType.MANGA ? 'chapters' : 'episodes'}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),

                    const Spacer(),

                    if (widget.media.type == MediaType.ANIME &&
                        filtered.isNotEmpty)
                      Tooltip(
                        message: 'Batch Download',
                        child: IconButton(
                          onPressed: () => BatchDownloadSheet.show(
                            context,
                            filtered,
                            widget.watchedProgress,
                            state.source,
                            widget.media,
                          ),
                          icon: const Icon(Icons.download_for_offline_outlined),
                          iconSize: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),

                    // View mode toggle
                    _ViewModeToggle(
                      current: viewMode,
                      onChanged: (m) => ref
                          .read(uiPrefsProvider.notifier)
                          .updateEpisodeViewMode(m),
                    ),

                    // Sort toggle
                    IconButton(
                      onPressed: () =>
                          setState(() => _descending = !_descending),
                      icon: Icon(
                        _descending ? Icons.arrow_downward : Icons.arrow_upward,
                      ),
                      iconSize: 18,
                      tooltip: _descending
                          ? 'Sort Ascending'
                          : 'Sort Descending',
                    ),
                  ],
                ),
              ),
            ),

            if (chunks.length > 1) ...[
              StaggeredFadeIn(
                index: 3,
                child: SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: chunks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final isSelected = safeIdx == i;
                      final theme = Theme.of(context);

                      return GestureDetector(
                        onTap: () => setState(() => _chunkIndex = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceBright,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            chunks[i].label,
                            style: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            StaggeredFadeIn(
              index: chunks.length > 1 ? 4 : 3,
              child: const Divider(height: 1),
            ),

            Expanded(
              child: StaggeredFadeIn(
                index: chunks.length > 1 ? 5 : 4,
                child: _buildEpisodeView(
                  context,
                  episodes: filtered,
                  source: state.source,
                  viewMode: viewMode,
                  currentIndex: filtered.indexWhere(
                    (ep) => ep.number == widget.currentEpisodeNumber,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEpisodeView(
    BuildContext context, {
    required List<UnifiedEpisode> episodes,
    required SourceInfo source,
    required EpisodeViewMode viewMode,
    int currentIndex = -1,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = constraints.maxWidth;

        final WidthTier panelTier;
        if (panelWidth >= 1600) {
          panelTier = WidthTier.ultraLarge;
        } else if (panelWidth >= 1200) {
          panelTier = WidthTier.large;
        } else if (panelWidth >= 640) {
          panelTier = WidthTier.expanded;
        } else if (panelWidth >= 500) {
          panelTier = WidthTier.medium;
        } else {
          panelTier = WidthTier.compact;
        }

        if (currentIndex >= 0 && !_hasAutoScrolled) {
          _hasAutoScrolled = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            if (!_scrollController.hasClients) return;
            final maxExt = _scrollController.position.maxScrollExtent;
            if (maxExt <= 0) return;

            double offset;
            switch (viewMode) {
              case EpisodeViewMode.classic:
                offset = currentIndex * 72.0;
              case EpisodeViewMode.compact:
                offset = currentIndex * 52.0;
              case EpisodeViewMode.cover:
                offset = currentIndex * 140.0;
              case EpisodeViewMode.grid:
                final cols = panelTier.pick(
                  compact: 2,
                  medium: 3,
                  expanded: 4,
                  large: 5,
                  ultraLarge: 6,
                );
                final pad = panelTier.pickOrFold(
                  compact: 8.0,
                  medium: 12.0,
                  large: 16.0,
                );
                final spacing = panelTier.pickOrFold(
                  compact: 8.0,
                  medium: 10.0,
                  large: 14.0,
                );
                final cellW =
                    (panelWidth - pad * 2 - spacing * (cols - 1)) / cols;
                final cellH = cellW * (10 / 16);
                final row = currentIndex ~/ cols;
                offset = pad + row * (cellH + spacing);
              case EpisodeViewMode.box:
                final boxSize = panelTier.pickOrFold(
                  compact: 46.0,
                  medium: 50.0,
                  large: 58.0,
                );
                final boxPad = panelTier.pickOrFold(
                  compact: 8.0,
                  medium: 12.0,
                  large: 16.0,
                );
                final boxSpacing = panelTier.pickOrFold(
                  compact: 6.0,
                  medium: 8.0,
                  large: 10.0,
                );
                final cols = (panelWidth / boxSize).floor().clamp(1, 50);
                final row = currentIndex ~/ cols;
                offset = boxPad + row * (boxSize + boxSpacing);
            }

            _scrollController.animateTo(
              offset.clamp(0.0, maxExt),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
            );
          });
        }

        final fallbackThumbnailUrl = widget.media.banner ?? widget.media.cover;

        switch (viewMode) {
          case EpisodeViewMode.classic:
            return ListView.builder(
              controller: widget.useScrollController ? _scrollController : null,
              itemCount: episodes.length,
              itemBuilder: (context, i) {
                final ep = episodes[i];
                final isCurrent = widget.currentEpisodeNumber == ep.number;
                final isWatched = widget.watchedProgress >= ep.number;

                return EpisodeClassicTile(
                  episode: ep,
                  mediaType: widget.media.type,
                  isCurrent: isCurrent,
                  isWatched: isWatched,
                  imageFadeDirection: widget.imageFadeDirection,
                  imageFadeStops: widget.imageFadeStops,
                  imageOpacity: widget.imageOpacity,
                  imageBlurSigma: widget.imageBlurSigma,
                  isFiller: ep.isFiller,
                  fallbackThumbnailUrl: fallbackThumbnailUrl,
                  actions:
                      widget.episodeActionsBuilder?.call(
                        context,
                        ep,
                        isCurrent,
                        isWatched,
                      ) ??
                      const [],
                  onTap: () => widget.onEpisodeTap(ep, source),
                );
              },
            );

          case EpisodeViewMode.compact:
            return ListView.builder(
              controller: widget.useScrollController ? _scrollController : null,
              itemCount: episodes.length,
              itemBuilder: (context, i) {
                final ep = episodes[i];
                final isCurrent = widget.currentEpisodeNumber == ep.number;
                final isWatched = widget.watchedProgress >= ep.number;

                return EpisodeCompactTile(
                  episode: ep,
                  mediaType: widget.media.type,
                  isCurrent: isCurrent,
                  isWatched: isWatched,
                  isFiller: ep.isFiller,
                  fallbackThumbnailUrl: fallbackThumbnailUrl,
                  actions:
                      widget.episodeActionsBuilder?.call(
                        context,
                        ep,
                        isCurrent,
                        isWatched,
                      ) ??
                      const [],
                  onTap: () => widget.onEpisodeTap(ep, source),
                );
              },
            );

          case EpisodeViewMode.cover:
            final coverColumns = panelTier.pick(
              compact: 2,
              medium: 3,
              expanded: 4,
              large: 5,
              ultraLarge: 6,
            );
            final coverPad = panelTier.pickOrFold(
              compact: 8.0,
              medium: 12.0,
              large: 16.0,
            );
            final coverSpacing = panelTier.pickOrFold(
              compact: 8.0,
              medium: 10.0,
              large: 14.0,
            );

            return GridView.builder(
              controller: widget.useScrollController ? _scrollController : null,
              padding: EdgeInsets.all(coverPad),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: coverColumns,
                crossAxisSpacing: coverSpacing,
                mainAxisSpacing: coverSpacing,
                childAspectRatio: 16 / 10,
              ),
              itemCount: episodes.length,
              itemBuilder: (context, i) {
                final ep = episodes[i];
                final isCurrent = widget.currentEpisodeNumber == ep.number;
                final isWatched = widget.watchedProgress >= ep.number;

                return EpisodeCoverTile(
                  episode: ep,
                  mediaType: widget.media.type,
                  isCurrent: isCurrent,
                  isWatched: isWatched,
                  isFiller: ep.isFiller,
                  fallbackThumbnailUrl: fallbackThumbnailUrl,
                  actions:
                      widget.episodeActionsBuilder?.call(
                        context,
                        ep,
                        isCurrent,
                        isWatched,
                      ) ??
                      const [],
                  onTap: () => widget.onEpisodeTap(ep, source),
                );
              },
            );

          case EpisodeViewMode.grid:
            final gridColumns = panelTier.pick(
              compact: 2,
              medium: 3,
              expanded: 4,
              large: 5,
              ultraLarge: 6,
            );
            final gridPad = panelTier.pickOrFold(
              compact: 8.0,
              medium: 12.0,
              large: 16.0,
            );
            final gridSpacing = panelTier.pickOrFold(
              compact: 8.0,
              medium: 10.0,
              large: 14.0,
            );

            return GridView.builder(
              controller: widget.useScrollController ? _scrollController : null,
              padding: EdgeInsets.all(gridPad),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridColumns,
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing: gridSpacing,
                childAspectRatio: 16 / 10,
              ),
              itemCount: episodes.length,
              itemBuilder: (context, i) {
                final ep = episodes[i];
                final isCurrent = widget.currentEpisodeNumber == ep.number;
                final isWatched = widget.watchedProgress >= ep.number;

                return EpisodeGridTile(
                  episode: ep,
                  mediaType: widget.media.type,
                  isCurrent: isCurrent,
                  isWatched: isWatched,
                  isFiller: ep.isFiller,
                  fallbackThumbnailUrl: fallbackThumbnailUrl,
                  actions:
                      widget.episodeActionsBuilder?.call(
                        context,
                        ep,
                        isCurrent,
                        isWatched,
                      ) ??
                      const [],
                  onTap: () => widget.onEpisodeTap(ep, source),
                );
              },
            );

          case EpisodeViewMode.box:
            final boxSize = panelTier.pickOrFold(
              compact: 46.0,
              medium: 50.0,
              large: 58.0,
            );
            final boxPad = panelTier.pickOrFold(
              compact: 8.0,
              medium: 12.0,
              large: 16.0,
            );
            final boxSpacing = panelTier.pickOrFold(
              compact: 6.0,
              medium: 8.0,
              large: 10.0,
            );

            return GridView.builder(
              controller: widget.useScrollController ? _scrollController : null,
              padding: EdgeInsets.all(boxPad),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: boxSize,
                crossAxisSpacing: boxSpacing,
                mainAxisSpacing: boxSpacing,
                childAspectRatio: 1,
              ),
              itemCount: episodes.length,
              itemBuilder: (context, i) {
                final ep = episodes[i];
                final isCurrent = widget.currentEpisodeNumber == ep.number;
                final isWatched = widget.watchedProgress >= ep.number;

                return EpisodeBoxTile(
                  episode: ep,
                  mediaType: widget.media.type,
                  isCurrent: isCurrent,
                  isFiller: ep.isFiller,
                  isWatched: isWatched,
                  fallbackThumbnailUrl: fallbackThumbnailUrl,
                  onTap: () => widget.onEpisodeTap(ep, source),
                );
              },
            );
        }
      },
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  final EpisodeViewMode current;
  final ValueChanged<EpisodeViewMode> onChanged;

  const _ViewModeToggle({required this.current, required this.onChanged});

  static IconData _iconForMode(EpisodeViewMode mode) => switch (mode) {
    EpisodeViewMode.classic => Icons.view_agenda_outlined,
    EpisodeViewMode.grid => Icons.grid_view_outlined,
    EpisodeViewMode.box => Icons.tag_outlined,
    EpisodeViewMode.compact => Icons.format_list_bulleted_rounded,
    EpisodeViewMode.cover => Icons.movie_creation_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: PopupMenuButton<EpisodeViewMode>(
        initialValue: current,
        onSelected: onChanged,
        tooltip: 'Episode View Mode',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        ),
        color: cs.surfaceContainerHigh,
        position: PopupMenuPosition.under,
        itemBuilder: (context) {
          return EpisodeViewMode.values.map((mode) {
            final isSelected = mode == current;
            return PopupMenuItem<EpisodeViewMode>(
              value: mode,
              child: Row(
                children: [
                  Icon(
                    _iconForMode(mode),
                    size: 20,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    mode.displayName,
                    style: TextStyle(
                      color: isSelected ? cs.primary : cs.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded, size: 18, color: cs.primary),
                  ],
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconForMode(current), size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                current.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
