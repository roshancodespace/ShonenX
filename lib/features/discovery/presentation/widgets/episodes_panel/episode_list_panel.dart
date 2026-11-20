import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_tiles.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/batch_download/batch_download_sheet.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/manual_match_sheet.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/reader/providers/preferred_scanlator_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_focus_hover.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

import 'package:shonenx/features/history/providers/history_provider.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/features/episode_metadata/providers/episode_metadata_providers.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_episode_list_panel.dart';

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
  final bool isTv;

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
    this.isTv = false,
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
  int? _selectedSeason;
  final ScrollController _scrollController = ScrollController();
  bool _hasAutoScrolled = false;
  bool _isRetrying = false;
  int? _lastAutoChunkEpisode;
  bool _hasInitializedSort = false;

  @override
  void didUpdateWidget(covariant EpisodeListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentEpisodeNumber != widget.currentEpisodeNumber ||
        oldWidget.media.id != widget.media.id) {
      _hasAutoScrolled = false;
      _lastAutoChunkEpisode = null;
      _hasInitializedSort = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _triggerRetry(MediaArgs matchArgs) async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
    });

    ref.invalidate(matchedMediaProvider(matchArgs));
    await ref.read(episodesListProvider(matchArgs).notifier).refreshEpisodes();

    if (mounted) {
      setState(() {
        _isRetrying = false;
      });
    }
  }

  void _openManualMatch(BuildContext context, MediaArgs matchArgs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ManualMatchSheet(
        mediaTitle: widget.media.title.getPreferedTitle,
        type: widget.media.type,
        matchArgs: matchArgs,
      ),
    );
  }

  Widget _buildStatusView(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool isError = false,
    List<Widget> actions = const [],
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isError ? cs.errorContainer : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: isError ? cs.onErrorContainer : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context, {String? message}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(14),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                color: cs.primary,
              ),
            ),
            if (message != null && message.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton({
    required bool isBusy,
    required VoidCallback onPressed,
    required String label,
    required String busyLabel,
  }) {
    return FilledButton.tonalIcon(
      onPressed: isBusy ? null : onPressed,
      style: FilledButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: const StadiumBorder(),
      ),
      icon: isBusy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded, size: 18),
      label: Text(isBusy ? busyLabel : label),
    );
  }

  Widget _buildManualMatchButton(BuildContext context, MediaArgs matchArgs) {
    return FilledButton.icon(
      onPressed: () => _openManualMatch(context, matchArgs),
      style: FilledButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: const StadiumBorder(),
      ),
      icon: const Icon(Icons.tune_rounded, size: 18),
      label: const Text('Manual Match'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(
      uiPrefsProvider.select((s) => s.episodeViewMode),
    );
    final matchArgs = MediaArgs.fromMedia(widget.media);
    final matchedMediaState = ref.watch(matchedMediaProvider(matchArgs));
    final episodesAsync = ref.watch(episodesListProvider(matchArgs));

    final isMatching =
        matchedMediaState.isLoading ||
        (matchedMediaState.value?.isLoading ?? false);
    final isSourceMismatch =
        matchedMediaState.value != null &&
        episodesAsync.value != null &&
        matchedMediaState.value!.sourceInfo.id !=
            episodesAsync.value!.source.id;
    final isBusy =
        _isRetrying ||
        episodesAsync.isRefreshing ||
        episodesAsync.isLoading ||
        isMatching ||
        isSourceMismatch;

    final primaryTracker = ref.watch(primaryTrackerProvider);
    final trackingState = ref.watch(
      mediaTrackingProvider(TrackingQuery(primaryTracker.type, widget.media)),
    );
    final trackedProgress = trackingState.value?.progress.toDouble() ?? 0;

    final historyEntries =
        ref.watch(historyForMediaProvider(widget.media.id)).value ?? [];

    final syncThreshold = ref.watch(trackingPrefsProvider).syncThreshold;

    final historyWatchedSet = widget.media.type == MediaType.ANIME
        ? historyEntries
              .where(
                (e) => e.total > 0 && e.progress >= e.total * syncThreshold,
              )
              .map((e) => e.itemNumber)
              .toSet()
        : historyEntries
              .where(
                (e) =>
                    e.total > 0 &&
                    e.progress >= (e.total * syncThreshold).ceil(),
              )
              .map((e) => e.itemNumber)
              .toSet();

    final maxHistoryEp = historyWatchedSet.fold<double>(
      0.0,
      (max, epNum) => epNum > max ? epNum : max,
    );

    final effectiveWatchedProgress = [
      widget.watchedProgress,
      trackedProgress,
      maxHistoryEp,
    ].reduce((a, b) => a > b ? a : b);

    final effectiveCurrentEpisodeNumber =
        widget.currentEpisodeNumber ?? historyEntries.firstOrNull?.itemNumber;

    if (matchedMediaState.hasError) {
      final error = matchedMediaState.error;
      return _buildStatusView(
        context,
        icon: Icons.error_outline_rounded,
        isError: true,
        title: 'Match Failed',
        subtitle: error.toString().contains('Cloudflare')
            ? 'Cloudflare verification failed. Try turning off "In-app Cloudflare Bypass" in settings to use the proxy, or perform a manual match.'
            : 'Failed to match media: $error',
        actions: [
          _buildRetryButton(
            isBusy: isBusy,
            onPressed: () => _triggerRetry(matchArgs),
            label: 'Retry Search',
            busyLabel: 'Fetching...',
          ),
          _buildManualMatchButton(context, matchArgs),
        ],
      );
    }

    if (isMatching || isSourceMismatch) {
      final sourceName = matchedMediaState.value?.sourceInfo.name;
      return _buildLoadingView(
        context,
        message: isMatching
            ? (sourceName != null
                  ? 'Searching match on $sourceName...'
                  : 'Searching match...')
            : (sourceName != null
                  ? 'Fetching episodes from $sourceName...'
                  : 'Fetching episodes...'),
      );
    }

    if (!isMatching &&
        matchedMediaState.value != null &&
        matchedMediaState.value!.matchedMedia == null) {
      final sourceName = matchedMediaState.value!.sourceInfo.name;
      return _buildStatusView(
        context,
        icon: Icons.folder_open_rounded,
        title: 'No match found on $sourceName',
        subtitle:
            'Try performing a manual match for "${widget.media.title.getPreferedTitle}"',
        actions: [
          _buildRetryButton(
            isBusy: isBusy,
            onPressed: () => _triggerRetry(matchArgs),
            label: 'Retry Search',
            busyLabel: 'Retrying...',
          ),
          _buildManualMatchButton(context, matchArgs),
        ],
      );
    }

    return episodesAsync.when(
      skipLoadingOnReload: false,
      loading: () {
        final progressMsg = ref.watch(episodeMetadataProgressProvider).value;
        return _buildLoadingView(context, message: progressMsg);
      },
      error: (e, _) => _buildStatusView(
        context,
        icon: Icons.error_outline_rounded,
        isError: true,
        title: 'Unable to Load Episodes',
        subtitle: e.toString().contains('Cloudflare')
            ? 'Cloudflare verification failed. Try turning off "In-app Cloudflare Bypass" in settings to use the proxy, or perform a manual match.'
            : 'Failed to fetch episodes: $e',
        actions: [
          _buildRetryButton(
            isBusy: isBusy,
            onPressed: () => _triggerRetry(matchArgs),
            label: 'Retry Search',
            busyLabel: 'Fetching...',
          ),
          _buildManualMatchButton(context, matchArgs),
        ],
      ),
      data: (state) {
        if (state.episodes.isEmpty) {
          if (isBusy) {
            return _buildLoadingView(context);
          }
          return _buildStatusView(
            context,
            icon: Icons.folder_open_rounded,
            title: widget.media.type == MediaType.MANGA
                ? 'No chapters found'
                : 'No episodes found',
            subtitle:
                'The provider may still be indexing, or the match might need to be retried.',
            actions: [
              _buildRetryButton(
                isBusy: isBusy,
                onPressed: () => _triggerRetry(matchArgs),
                label: 'Retry Fetching',
                busyLabel: 'Fetching...',
              ),
              _buildManualMatchButton(context, matchArgs),
            ],
          );
        }

        final uniqueSeasons = state.episodes
            .map((e) => e.season)
            .toSet()
            .toList();
        uniqueSeasons.sort((a, b) {
          if (a == null && b == null) return 0;
          if (a == null) return 1;
          if (b == null) return -1;
          return a.compareTo(b);
        });

        int? activeSeason = _selectedSeason;
        if (!uniqueSeasons.contains(activeSeason)) {
          activeSeason = uniqueSeasons.firstOrNull;
        }

        final seasonEpisodes = state.episodes
            .where((e) => e.season == activeSeason)
            .toList();

        final uniqueNums = seasonEpisodes.map((e) => e.number).toSet().toList()
          ..sort();

        if (!_hasInitializedSort && uniqueNums.isNotEmpty) {
          _hasInitializedSort = true;
          final maxEpNum = uniqueNums.last;
          final currentProgress =
              effectiveCurrentEpisodeNumber ?? effectiveWatchedProgress;
          if (maxEpNum > 0 && currentProgress >= maxEpNum * 0.5) {
            _descending = true;
          }
        }

        final chunks = <_Chunk>[_Chunk('All', null, null)];

        if (uniqueNums.length > 100) {
          String fmt(num n) => n % 1 == 0 ? n.toInt().toString() : n.toString();
          final rawChunks = <_Chunk>[];
          for (int i = 0; i < uniqueNums.length; i += 100) {
            final min = uniqueNums[i];
            final max = uniqueNums[(i + 99).clamp(0, uniqueNums.length - 1)];
            rawChunks.add(_Chunk('${fmt(min)} – ${fmt(max)}', min, max));
          }
          if (_descending) {
            chunks.addAll(rawChunks.reversed);
          } else {
            chunks.addAll(rawChunks);
          }
        }

        if (chunks.length > 1 &&
            effectiveCurrentEpisodeNumber != null &&
            _lastAutoChunkEpisode != effectiveCurrentEpisodeNumber.toInt()) {
          _lastAutoChunkEpisode = effectiveCurrentEpisodeNumber.toInt();
          final target = effectiveCurrentEpisodeNumber;
          final autoIdx = chunks.indexWhere(
            (c) =>
                c.min != null &&
                c.max != null &&
                target >= c.min! &&
                target <= c.max!,
          );
          if (autoIdx > 0) {
            _chunkIndex = autoIdx;
          }
        }

        final safeIdx = _chunkIndex < chunks.length ? _chunkIndex : 0;
        final activeChunk = chunks[safeIdx];
        final prefScanlator = ref.read(
          preferredScanlatorProvider(widget.media.id),
        );

        final dedupedMap = <double, UnifiedEpisode>{};

        for (final ep in seasonEpisodes) {
          if (activeChunk.min != null &&
              (ep.number < activeChunk.min! || ep.number > activeChunk.max!)) {
            continue;
          }
          if (!dedupedMap.containsKey(ep.number) ||
              ep.scanlator == prefScanlator) {
            dedupedMap[ep.number] = ep;
          }
        }

        final finalEpisodes = dedupedMap.values.toList()
          ..sort(
            (a, b) => _descending
                ? b.number.compareTo(a.number)
                : a.number.compareTo(b.number),
          );

        int staggerIndex = 2;
        final cs = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeIn(
              index: staggerIndex++,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (uniqueSeasons.length > 1) ...[
                              _FilterMenuButton<int?>(
                                current: activeSeason,
                                items: uniqueSeasons,
                                labelBuilder: (s) =>
                                    s == null ? 'Specials' : 'S$s',
                                icon: Icons.layers_rounded,
                                highlighted: activeSeason != null,
                                onSelected: (s) => setState(() {
                                  _selectedSeason = s;
                                  _chunkIndex = 0;
                                }),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (chunks.length > 1) ...[
                              _FilterMenuButton<int>(
                                current: safeIdx,
                                items: List.generate(chunks.length, (i) => i),
                                labelBuilder: (i) => chunks[i].label,
                                icon: Icons.tag_rounded,
                                highlighted: safeIdx > 0,
                                onSelected: (i) =>
                                    setState(() => _chunkIndex = i),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              alignment: Alignment.center,
                              decoration: ShapeDecoration(
                                color: cs.surfaceContainer,
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                '${finalEpisodes.length} ${widget.media.type == MediaType.MANGA ? 'ch' : 'ep'}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!widget.isTv) ...[
                          if (widget.media.type == MediaType.ANIME &&
                              finalEpisodes.isNotEmpty) ...[
                            _ToolbarButton(
                              icon: Icons.download_for_offline_outlined,
                              tooltip: 'Batch Download',
                              onTap: () => BatchDownloadSheet.show(
                                context,
                                finalEpisodes,
                                effectiveWatchedProgress,
                                state.source,
                                widget.media,
                                watchedEpisodeNumbers: historyWatchedSet,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          _ToolbarButton(
                            icon: Icons.refresh_rounded,
                            tooltip: 'Refresh Episodes',
                            onTap: () => _triggerRetry(matchArgs),
                          ),
                          const SizedBox(width: 6),
                          _ViewModeToggle(
                            current: viewMode,
                            onChanged: (m) => ref
                                .read(uiPrefsProvider.notifier)
                                .updateEpisodeViewMode(m),
                          ),
                          const SizedBox(width: 6),
                        ],
                        _ToolbarButton(
                          icon: _descending
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          tooltip: _descending
                              ? 'Sorted Newest First'
                              : 'Sorted Oldest First',
                          selected: _descending,
                          onTap: () {
                            setState(() {
                              _descending = !_descending;
                              _chunkIndex = 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            StaggeredFadeIn(
              index: staggerIndex++,
              child: Divider(
                height: 1,
                thickness: 1,
                color: cs.surfaceContainerHighest,
              ),
            ),
            Expanded(
              child: StaggeredFadeIn(
                index: staggerIndex++,
                child: RefreshIndicator(
                  elevation: 0,
                  backgroundColor: cs.surfaceContainerHigh,
                  color: cs.primary,
                  onRefresh: () =>
                      _triggerRetry(MediaArgs.fromMedia(widget.media)),
                  child: _buildEpisodeView(
                    context,
                    episodes: finalEpisodes,
                    source: state.source,
                    viewMode: viewMode,
                    effectiveWatchedProgress: effectiveWatchedProgress,
                    historyWatchedSet: historyWatchedSet,
                    currentIndex: finalEpisodes.indexWhere(
                      (ep) => ep.number == effectiveCurrentEpisodeNumber,
                    ),
                    currentEpisodeNumber: effectiveCurrentEpisodeNumber,
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
    required double effectiveWatchedProgress,
    required Set<double> historyWatchedSet,
    int currentIndex = -1,
    double? currentEpisodeNumber,
  }) {
    if (widget.isTv) {
      return TvEpisodeListPanel(
        episodes: episodes,
        media: widget.media,
        source: source,
        effectiveWatchedProgress: effectiveWatchedProgress,
        historyWatchedSet: historyWatchedSet,
        currentEpisodeNumber: currentEpisodeNumber,
        onEpisodeTap: widget.onEpisodeTap,
      );
    }

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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final activeScrollController = widget.useScrollController
                ? _scrollController
                : (PrimaryScrollController.maybeOf(context) ??
                      _scrollController);

            if (!activeScrollController.hasClients) return;
            final position = activeScrollController.positions.lastOrNull;
            if (position == null) return;
            final maxExt = position.maxScrollExtent;
            if (maxExt <= 0) return;

            double offset;
            switch (viewMode) {
              case EpisodeViewMode.classic:
                offset = currentIndex * 72.0;
              case EpisodeViewMode.compact:
                offset = 8.0 + currentIndex * 60.0;
              case EpisodeViewMode.cover:
                final cols = panelTier.pick(
                  compact: 1,
                  medium: 1,
                  expanded: 2,
                  large: 2,
                  ultraLarge: 3,
                );
                final pad = panelTier.pickOrFold(
                  compact: 10.0,
                  medium: 12.0,
                  large: 16.0,
                );
                final spacing = panelTier.pickOrFold(
                  compact: 8.0,
                  medium: 10.0,
                  large: 12.0,
                );
                final row = currentIndex ~/ cols;
                offset = pad + row * (94.0 + spacing);
              case EpisodeViewMode.grid:
                final cols = panelTier.pick(
                  compact: 2,
                  medium: 3,
                  expanded: 4,
                  large: 5,
                  ultraLarge: 6,
                );
                final pad = panelTier.pickOrFold(
                  compact: 10.0,
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
                  compact: 48.0,
                  medium: 52.0,
                  large: 58.0,
                );
                final boxPad = panelTier.pickOrFold(
                  compact: 10.0,
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

            final targetOffset = offset.clamp(0.0, maxExt);
            final delta = (targetOffset - position.pixels).abs();

            if (delta > 200) {
              final preOffset = (targetOffset - 60.0).clamp(0.0, maxExt);
              position.jumpTo(preOffset);
              position.animateTo(
                targetOffset,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
              );
            } else if (delta > 0) {
              position.animateTo(
                targetOffset,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }

        final fallbackThumbnailUrl = widget.media.banner ?? widget.media.cover;

        Widget buildItem(BuildContext context, int i) {
          final ep = episodes[i];
          final isCurrent = currentEpisodeNumber == ep.number;
          final isWatched =
              effectiveWatchedProgress >= ep.number ||
              historyWatchedSet.contains(ep.number);
          final actions =
              widget.episodeActionsBuilder?.call(
                context,
                ep,
                isCurrent,
                isWatched,
              ) ??
              const [];

          switch (viewMode) {
            case EpisodeViewMode.classic:
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
                actions: actions,
                onTap: () => widget.onEpisodeTap(ep, source),
              );
            case EpisodeViewMode.compact:
              return EpisodeCompactTile(
                episode: ep,
                mediaType: widget.media.type,
                isCurrent: isCurrent,
                isWatched: isWatched,
                isFiller: ep.isFiller,
                fallbackThumbnailUrl: fallbackThumbnailUrl,
                actions: actions,
                onTap: () => widget.onEpisodeTap(ep, source),
              );
            case EpisodeViewMode.cover:
              return EpisodeCoverTile(
                episode: ep,
                mediaType: widget.media.type,
                isCurrent: isCurrent,
                isWatched: isWatched,
                isFiller: ep.isFiller,
                fallbackThumbnailUrl: fallbackThumbnailUrl,
                actions: actions,
                onTap: () => widget.onEpisodeTap(ep, source),
              );
            case EpisodeViewMode.grid:
              return EpisodeGridTile(
                episode: ep,
                mediaType: widget.media.type,
                isCurrent: isCurrent,
                isWatched: isWatched,
                isFiller: ep.isFiller,
                fallbackThumbnailUrl: fallbackThumbnailUrl,
                actions: actions,
                onTap: () => widget.onEpisodeTap(ep, source),
              );
            case EpisodeViewMode.box:
              return EpisodeBoxTile(
                episode: ep,
                mediaType: widget.media.type,
                isCurrent: isCurrent,
                isFiller: ep.isFiller,
                isWatched: isWatched,
                fallbackThumbnailUrl: fallbackThumbnailUrl,
                onTap: () => widget.onEpisodeTap(ep, source),
              );
          }
        }

        switch (viewMode) {
          case EpisodeViewMode.classic:
            return ListView.builder(
              controller: widget.useScrollController ? _scrollController : null,
              itemCount: episodes.length,
              itemBuilder: buildItem,
            );

          case EpisodeViewMode.compact:
            return ListView.separated(
              controller: widget.useScrollController ? _scrollController : null,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: episodes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: buildItem,
            );

          case EpisodeViewMode.cover:
            final coverColumns = panelTier.pick(
              compact: 1,
              medium: 1,
              expanded: 2,
              large: 2,
              ultraLarge: 3,
            );
            final coverPad = panelTier.pickOrFold(
              compact: 10.0,
              medium: 12.0,
              large: 16.0,
            );
            final coverSpacing = panelTier.pickOrFold(
              compact: 8.0,
              medium: 10.0,
              large: 12.0,
            );

            return GridView.builder(
              controller: widget.useScrollController ? _scrollController : null,
              padding: EdgeInsets.all(coverPad),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: coverColumns,
                crossAxisSpacing: coverSpacing,
                mainAxisSpacing: coverSpacing,
                mainAxisExtent: 94.0,
              ),
              itemCount: episodes.length,
              itemBuilder: buildItem,
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
              compact: 10.0,
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
              itemBuilder: buildItem,
            );

          case EpisodeViewMode.box:
            final boxSize = panelTier.pickOrFold(
              compact: 48.0,
              medium: 52.0,
              large: 58.0,
            );
            final boxPad = panelTier.pickOrFold(
              compact: 10.0,
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
              itemBuilder: buildItem,
            );
        }
      },
    );
  }
}

class _FilterMenuButton<T> extends StatefulWidget {
  final T current;
  final List<T> items;
  final String Function(T) labelBuilder;
  final void Function(T) onSelected;
  final IconData icon;
  final bool highlighted;

  const _FilterMenuButton({
    required this.current,
    required this.items,
    required this.labelBuilder,
    required this.onSelected,
    required this.icon,
    this.highlighted = false,
  });

  @override
  State<_FilterMenuButton<T>> createState() => _FilterMenuButtonState<T>();
}

class _FilterMenuButtonState<T> extends State<_FilterMenuButton<T>> {
  final GlobalKey<PopupMenuButtonState<T>> _menuKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(GlobalUI.uiRoundness);

    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: PopupMenuButton<T>(
        key: _menuKey,
        initialValue: widget.current,
        onSelected: widget.onSelected,
        tooltip: '',
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
        ),
        color: cs.surfaceContainerHigh,
        position: PopupMenuPosition.under,
        itemBuilder: (context) {
          return widget.items.map((item) {
            final isSelected = item == widget.current;
            return PopupMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  Text(
                    widget.labelBuilder(item),
                    style: TextStyle(
                      color: isSelected ? cs.primary : cs.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13.5,
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
        child: AppFocusHover(
          onTap: () => _menuKey.currentState?.showButtonMenu(),
          scaleFactor: 1.05,
          builder: (context, isFocused, isHovered) {
            final active = isFocused || isHovered;
            final bg = active
                ? cs.primary
                : widget.highlighted
                ? cs.secondaryContainer
                : cs.surfaceContainerHighest;
            final fg = active
                ? cs.onPrimary
                : widget.highlighted
                ? cs.onSecondaryContainer
                : cs.onSurfaceVariant;
            final iconFg = active
                ? cs.onPrimary
                : widget.highlighted
                ? cs.onSecondaryContainer
                : cs.primary;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: ShapeDecoration(
                color: bg,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 15, color: iconFg),
                  const SizedBox(width: 6),
                  Text(
                    widget.labelBuilder(widget.current),
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: fg),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool selected;
  final Color? iconColor;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: AppFocusHover(
        onTap: onTap,
        scaleFactor: 1.05,
        builder: (context, isFocused, isHovered) {
          final active = isFocused || isHovered;
          final bg = active
              ? cs.primary
              : selected
              ? cs.primaryContainer
              : cs.surfaceContainerHighest;
          final fg = active
              ? cs.onPrimary
              : selected
              ? cs.onPrimaryContainer
              : (iconColor ?? cs.onSurfaceVariant);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: 34,
            height: 34,
            decoration: ShapeDecoration(
              color: bg,
              shape: const StadiumBorder(),
            ),
            child: Icon(icon, size: 18, color: fg),
          );
        },
      ),
    );
  }
}

class _ViewModeToggle extends ConsumerWidget {
  final EpisodeViewMode current;
  final ValueChanged<EpisodeViewMode> onChanged;

  const _ViewModeToggle({required this.current, required this.onChanged});

  static IconData _iconForMode(EpisodeViewMode mode) => switch (mode) {
    EpisodeViewMode.classic => Icons.view_list_rounded,
    EpisodeViewMode.grid => Icons.grid_view_rounded,
    EpisodeViewMode.box => Icons.apps_rounded,
    EpisodeViewMode.compact => Icons.format_list_bulleted_rounded,
    EpisodeViewMode.cover => Icons.photo_library_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return _ToolbarButton(
      icon: _iconForMode(current),
      tooltip: 'View: ${current.displayName}',
      iconColor: cs.primary,
      onTap: () {
        final values = EpisodeViewMode.values;
        final nextIndex = (values.indexOf(current) + 1) % values.length;
        onChanged(values[nextIndex]);
      },
    );
  }
}
