import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tv_mode/presentation/tv_scale.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_smart_image.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TvEpisodeShelf extends ConsumerStatefulWidget {
  final UnifiedMedia media;
  final VoidCallback? onOpenSourceSelector;

  const TvEpisodeShelf({
    super.key,
    required this.media,
    this.onOpenSourceSelector,
  });

  @override
  ConsumerState<TvEpisodeShelf> createState() => _TvEpisodeShelfState();
}

class _TvEpisodeShelfState extends ConsumerState<TvEpisodeShelf> {
  int? _selectedSeason;
  int _selectedChunkIndex = 0;
  bool _initializedChunk = false;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _rangeScrollController = ScrollController();

  static const int _chunkSize = 50;

  void _handleEpisodeTap(
    BuildContext context,
    UnifiedEpisode episode,
    SourceInfo sourceInfo,
    List<dynamic> readHistoryEntries,
  ) {
    if (widget.media.type == MediaType.MANGA ||
        widget.media.type == MediaType.NOVEL) {
      final historyEntry = readHistoryEntries
          .where((e) => e.chapterNumber == episode.number)
          .firstOrNull;

      final int startPosition;
      if (historyEntry != null &&
          historyEntry.positionPage > 0 &&
          historyEntry.positionPage <= historyEntry.totalPages) {
        startPosition = historyEntry.positionPage;
      } else {
        startPosition = 1;
      }

      context.pushReader(
        ReaderModeOnline(
          media: widget.media,
          episode: episode,
          sourceInfo: sourceInfo,
          startPosition: startPosition,
        ),
      );
    } else {
      context.pushPlayer(
        PlayerModeOnline(
          media: widget.media,
          episode: episode,
          sourceInfo: sourceInfo,
        ),
      );
    }
  }

  void _showQuickJumpDialog(
    BuildContext context,
    List<UnifiedEpisode> allEpisodes,
    SourceInfo source,
    List<dynamic> readHistoryEntries,
    double uiRoundness,
  ) {
    final scale = context.tvScale;
    final isManga =
        widget.media.type == MediaType.MANGA ||
        widget.media.type == MediaType.NOVEL;
    final typeLabel = isManga ? 'Chapter' : 'Episode';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogContext) {
        return _TvQuickJumpDialog(
          typeLabel: typeLabel,
          allEpisodes: allEpisodes,
          scale: scale,
          uiRoundness: uiRoundness,
          onEpisodeSelected: (ep) {
            Navigator.of(dialogContext).pop();
            _handleEpisodeTap(context, ep, source, readHistoryEntries);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rangeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scale = context.tvScale;
    final uiRoundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
    );

    final matchArgs = MediaArgs.fromMedia(widget.media);
    final episodesAsync = ref.watch(episodesListProvider(matchArgs));

    final primaryTracker = ref.watch(primaryTrackerProvider);
    final trackingState = ref.watch(
      mediaTrackingProvider(
        TrackingQuery(primaryTracker.type, widget.media.id, widget.media.type),
      ),
    );
    final trackedProgress = trackingState.value?.progress.toDouble() ?? 0;

    final watchHistoryEntries =
        ref.watch(historyEpisodesProvider(widget.media.id)).value ?? [];
    final readHistoryEntries =
        ref.watch(historyChaptersProvider(widget.media.id)).value ?? [];

    final historyWatchedSet = widget.media.type == MediaType.ANIME
        ? watchHistoryEntries.map((e) => e.episodeNumber).toSet()
        : readHistoryEntries.map((e) => e.chapterNumber).toSet();

    final maxHistoryEp = historyWatchedSet.fold<double>(
      0.0,
      (max, epNum) => epNum > max ? epNum : max,
    );

    final effectiveWatchedProgress = trackedProgress > 0
        ? trackedProgress
        : maxHistoryEp;

    final currentEpisodeNumber = widget.media.type == MediaType.ANIME
        ? watchHistoryEntries.firstOrNull?.episodeNumber
        : readHistoryEntries.firstOrNull?.chapterNumber;

    ref.watch(widget.media.type.availableSourcesProvider);

    final chipRadius = BorderRadius.circular(
      (uiRoundness * 0.5).clamp(4.0, 12.0),
    );

    final isBusy = episodesAsync.isLoading || episodesAsync.isRefreshing;

    if (isBusy && !episodesAsync.hasValue) {
      return _buildLoading(scale, uiRoundness, cs, theme);
    }

    return episodesAsync.when(
      loading: () => _buildLoading(scale, uiRoundness, cs, theme),
      error: (e, _) => _buildErrorState(e, matchArgs, scale, uiRoundness, cs),
      data: (episodesList) {
        if (isBusy) {
          return _buildLoading(scale, uiRoundness, cs, theme);
        }

        final allEpisodes = episodesList.episodes;
        final source = episodesList.source;

        if (allEpisodes.isEmpty) {
          return _buildEmptyState(matchArgs, scale, uiRoundness, cs);
        }

        final seasons =
            allEpisodes.map((e) => e.season).whereType<int>().toSet().toList()
              ..sort();

        final hasMultipleSeasons = seasons.length > 1;
        final currentSeason =
            _selectedSeason ?? (hasMultipleSeasons ? seasons.first : null);

        final seasonEpisodes = hasMultipleSeasons && currentSeason != null
            ? allEpisodes.where((e) => e.season == currentSeason).toList()
            : allEpisodes;

        final hasChunks = seasonEpisodes.length > _chunkSize;
        final totalChunks = hasChunks
            ? (seasonEpisodes.length / _chunkSize).ceil()
            : 1;

        if (!_initializedChunk && currentEpisodeNumber != null) {
          final targetIndex = seasonEpisodes.indexWhere(
            (e) => e.number == currentEpisodeNumber,
          );
          if (targetIndex >= 0) {
            _selectedChunkIndex = (targetIndex / _chunkSize).floor();
          }
          _initializedChunk = true;
        }

        final safeChunkIndex = _selectedChunkIndex.clamp(0, totalChunks - 1);
        final startIndex = safeChunkIndex * _chunkSize;
        final endIndex = (startIndex + _chunkSize).clamp(
          0,
          seasonEpisodes.length,
        );
        final displayedEpisodes = hasChunks
            ? seasonEpisodes.sublist(startIndex, endIndex)
            : seasonEpisodes;

        final cardWidth = (240.0 * scale).clamp(200.0, 320.0);
        final thumbHeight = cardWidth * 9 / 16;
        final shelfHeight = thumbHeight + (60.0 * scale) + 12.0;

        return HorizontalSection<UnifiedEpisode>(
          height: shelfHeight,
          gap: 0.0,
          headerPadding: EdgeInsets.only(
            bottom: (14.0 * scale).clamp(10.0, 18.0),
          ),
          listPadding: const EdgeInsets.symmetric(vertical: 4),
          controller: _scrollController,
          data: AsyncData(displayedEpisodes),
          titleWidget: Wrap(
            spacing: (12.0 * scale).clamp(8.0, 16.0),
            runSpacing: (8.0 * scale).clamp(6.0, 12.0),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${seasonEpisodes.length} ${widget.media.type == MediaType.MANGA || widget.media.type == MediaType.NOVEL ? 'Chapters' : 'Episodes'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  fontSize: (18.0 * scale).clamp(16.0, 24.0),
                ),
              ),

              _TvQuickJumpButton(
                scale: scale,
                borderRadius: chipRadius,
                onTap: () => _showQuickJumpDialog(
                  context,
                  seasonEpisodes,
                  source,
                  readHistoryEntries,
                  uiRoundness,
                ),
              ),

              if (hasMultipleSeasons) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: seasons.map((seasonNum) {
                      final isSelected = seasonNum == currentSeason;
                      return _TvSeasonPill(
                        label: 'Season $seasonNum',
                        isSelected: isSelected,
                        borderRadius: chipRadius,
                        scale: scale,
                        onTap: () {
                          setState(() {
                            _selectedSeason = seasonNum;
                            _selectedChunkIndex = 0;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],

              if (hasChunks) ...[
                SingleChildScrollView(
                  controller: _rangeScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(totalChunks, (index) {
                      final startEpNum = index * _chunkSize + 1;
                      final endEpNum = ((index + 1) * _chunkSize).clamp(
                        1,
                        seasonEpisodes.length,
                      );
                      final isSelected = index == safeChunkIndex;

                      return _TvSeasonPill(
                        label: '$startEpNum - $endEpNum',
                        isSelected: isSelected,
                        borderRadius: chipRadius,
                        scale: scale,
                        onTap: () {
                          setState(() {
                            _selectedChunkIndex = index;
                          });
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(0);
                          }
                        },
                      );
                    }),
                  ),
                ),
              ],
            ],
          ),
          itemBuilder: (context, ep) {
            final isCurrent = currentEpisodeNumber == ep.number;
            final isWatched =
                effectiveWatchedProgress >= ep.number ||
                historyWatchedSet.contains(ep.number);

            return _TvEpisodeCard(
              episode: ep,
              cardWidth: cardWidth,
              thumbHeight: thumbHeight,
              isCurrent: isCurrent,
              isWatched: isWatched,
              media: widget.media,
              uiRoundness: uiRoundness,
              onTap: () {
                _handleEpisodeTap(context, ep, source, readHistoryEntries);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(
    MediaArgs matchArgs,
    double scale,
    double uiRoundness,
    ColorScheme cs,
  ) {
    final cardRadius = BorderRadius.circular(uiRoundness);
    final buttonRadius = BorderRadius.circular(
      (uiRoundness * 0.6).clamp(6.0, 14.0),
    );
    final isManga =
        widget.media.type == MediaType.MANGA ||
        widget.media.type == MediaType.NOVEL;
    final itemType = isManga ? 'chapters' : 'episodes';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((24.0 * scale).clamp(18.0, 36.0)),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: cardRadius,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.video_collection_outlined,
                size: (24.0 * scale).clamp(20.0, 32.0),
                color: cs.primary,
              ),
              SizedBox(width: (10.0 * scale).clamp(8.0, 14.0)),
              Text(
                'No $itemType available',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: (16.0 * scale).clamp(14.5, 20.0),
                ),
              ),
            ],
          ),
          SizedBox(height: (8.0 * scale).clamp(6.0, 12.0)),
          Text(
            'No $itemType were found for this title from the active source. You can switch to a different source/extension or retry fetching.',
            style: TextStyle(
              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
              fontSize: (13.0 * scale).clamp(11.5, 16.0),
              height: 1.35,
            ),
          ),
          SizedBox(height: (16.0 * scale).clamp(12.0, 22.0)),
          Row(
            children: [
              if (widget.onOpenSourceSelector != null) ...[
                _TvStateButton(
                  icon: Icons.tune_rounded,
                  label: 'Switch Source',
                  isPrimary: true,
                  scale: scale,
                  borderRadius: buttonRadius,
                  onTap: widget.onOpenSourceSelector!,
                ),
                SizedBox(width: (12.0 * scale).clamp(8.0, 16.0)),
              ],
              _TvStateButton(
                icon: Icons.refresh_rounded,
                label: 'Retry',
                isPrimary: widget.onOpenSourceSelector == null,
                scale: scale,
                borderRadius: buttonRadius,
                onTap: () => ref.invalidate(episodesListProvider(matchArgs)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    Object error,
    MediaArgs matchArgs,
    double scale,
    double uiRoundness,
    ColorScheme cs,
  ) {
    final cardRadius = BorderRadius.circular(uiRoundness);
    final buttonRadius = BorderRadius.circular(
      (uiRoundness * 0.6).clamp(6.0, 14.0),
    );

    final isNoSources =
        error.toString().contains('no-sources') ||
        error.toString().contains('No element') ||
        error.toString().contains('Source') &&
            error.toString().contains('not found');

    final titleText = isNoSources
        ? 'No Extension or Source Found'
        : 'Unable to load content';

    final messageText = isNoSources
        ? 'No streaming extensions or sources are currently available for ${widget.media.type.displayName}. Please install an Anime/Video extension or select another source.'
        : 'Could not retrieve content ($error). Please check your network connection or switch to a different source.';

    final iconData = isNoSources
        ? Icons.extension_off_rounded
        : Icons.cloud_off_rounded;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((24.0 * scale).clamp(18.0, 36.0)),
      decoration: BoxDecoration(
        color: isNoSources
            ? cs.surfaceContainerHighest.withValues(alpha: 0.35)
            : cs.errorContainer.withValues(alpha: 0.15),
        borderRadius: cardRadius,
        border: Border.all(
          color: isNoSources
              ? cs.outlineVariant.withValues(alpha: 0.3)
              : cs.error.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                iconData,
                size: (24.0 * scale).clamp(20.0, 32.0),
                color: isNoSources ? cs.primary : cs.error,
              ),
              SizedBox(width: (10.0 * scale).clamp(8.0, 14.0)),
              Text(
                titleText,
                style: TextStyle(
                  color: isNoSources ? cs.onSurface : cs.error,
                  fontWeight: FontWeight.w900,
                  fontSize: (16.0 * scale).clamp(14.5, 20.0),
                ),
              ),
            ],
          ),
          SizedBox(height: (8.0 * scale).clamp(6.0, 12.0)),
          Text(
            messageText,
            style: TextStyle(
              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
              fontSize: (13.0 * scale).clamp(11.5, 16.0),
              height: 1.35,
            ),
          ),
          SizedBox(height: (16.0 * scale).clamp(12.0, 22.0)),
          Row(
            children: [
              if (widget.onOpenSourceSelector != null) ...[
                _TvStateButton(
                  icon: Icons.tune_rounded,
                  label: 'Switch Source',
                  isPrimary: true,
                  scale: scale,
                  borderRadius: buttonRadius,
                  onTap: widget.onOpenSourceSelector!,
                ),
                SizedBox(width: (12.0 * scale).clamp(8.0, 16.0)),
              ],
              _TvStateButton(
                icon: Icons.refresh_rounded,
                label: 'Retry Fetch',
                isPrimary: widget.onOpenSourceSelector == null,
                scale: scale,
                borderRadius: buttonRadius,
                onTap: () => ref.invalidate(episodesListProvider(matchArgs)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(
    double scale,
    double uiRoundness,
    ColorScheme cs,
    ThemeData theme,
  ) {
    final cardRadius = BorderRadius.circular(uiRoundness);
    final cardWidth = (240.0 * scale).clamp(200.0, 320.0);
    final thumbHeight = cardWidth * 9 / 16;
    final shelfHeight = thumbHeight + (60.0 * scale) + 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.media.type == MediaType.MANGA ||
                      widget.media.type == MediaType.NOVEL
                  ? 'Chapters'
                  : 'Episodes',
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                fontSize: (18.0 * scale).clamp(16.0, 24.0),
              ),
            ),
            SizedBox(width: (8.0 * scale).clamp(6.0, 12.0)),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: cs.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: shelfHeight,
          child: Skeletonizer(
            enabled: true,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: 6,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 14),
                child: SizedBox(
                  width: cardWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: thumbHeight,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: cardRadius,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Episode Title Preview Goes Right Here',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Available to Stream HD',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TvStateButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final double scale;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  const _TvStateButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.scale,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  State<_TvStateButton> createState() => _TvStateButtonState();
}

class _TvStateButtonState extends State<_TvStateButton> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bgColor = widget.isPrimary
        ? (_isFocused ? cs.primary.withValues(alpha: 0.9) : cs.primary)
        : (_isFocused
              ? cs.surfaceContainerHighest.withValues(alpha: 0.95)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5));

    final fgColor = widget.isPrimary ? cs.onPrimary : cs.onSurface;

    return FocusableActionDetector(
      focusNode: _focusNode,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: AnimatedScale(
        scale: _isFocused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: InkWell(
          canRequestFocus: false,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
            _focusNode.requestFocus();
            widget.onTap();
          },
          borderRadius: widget.borderRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.symmetric(
              horizontal: (16.0 * widget.scale).clamp(12.0, 22.0),
              vertical: (9.0 * widget.scale).clamp(7.0, 13.0),
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: _isFocused
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: widget.isPrimary
                            ? cs.primary.withValues(alpha: 0.45)
                            : cs.onSurface.withValues(alpha: 0.15),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: (17.0 * widget.scale).clamp(15.0, 22.0),
                  color: fgColor,
                ),
                SizedBox(width: (6.0 * widget.scale).clamp(4.0, 8.0)),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: (12.5 * widget.scale).clamp(11.5, 15.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TvQuickJumpButton extends StatefulWidget {
  final double scale;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  const _TvQuickJumpButton({
    required this.scale,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  State<_TvQuickJumpButton> createState() => _TvQuickJumpButtonState();
}

class _TvQuickJumpButtonState extends State<_TvQuickJumpButton> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (3.0 * widget.scale).clamp(2.0, 6.0),
      ),
      child: FocusableActionDetector(
        focusNode: _focusNode,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: InkWell(
          canRequestFocus: false,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
            _focusNode.requestFocus();
            widget.onTap();
          },
          borderRadius: widget.borderRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.symmetric(
              horizontal: (12.0 * widget.scale).clamp(10.0, 18.0),
              vertical: (6.5 * widget.scale).clamp(5.5, 11.0),
            ),
            decoration: BoxDecoration(
              color: _isFocused
                  ? cs.primary
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: _isFocused
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.3),
                width: _isFocused ? 2.0 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.dialpad_rounded,
                  size: (15.0 * widget.scale).clamp(13.0, 19.0),
                  color: _isFocused ? cs.onPrimary : cs.primary,
                ),
                SizedBox(width: (6.0 * widget.scale).clamp(4.0, 8.0)),
                Text(
                  'Jump to #',
                  style: TextStyle(
                    color: _isFocused ? cs.onPrimary : cs.onSurface,
                    fontSize: (12.5 * widget.scale).clamp(11.5, 16.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TvQuickJumpDialog extends StatefulWidget {
  final String typeLabel;
  final List<UnifiedEpisode> allEpisodes;
  final double scale;
  final double uiRoundness;
  final ValueChanged<UnifiedEpisode> onEpisodeSelected;

  const _TvQuickJumpDialog({
    required this.typeLabel,
    required this.allEpisodes,
    required this.scale,
    required this.uiRoundness,
    required this.onEpisodeSelected,
  });

  @override
  State<_TvQuickJumpDialog> createState() => _TvQuickJumpDialogState();
}

class _TvQuickJumpDialogState extends State<_TvQuickJumpDialog> {
  String _inputDigits = '';
  String? _errorMessage;
  final FocusNode _keyboardFocusNode = FocusNode();

  void _appendDigit(String digit) {
    if (_inputDigits.length >= 5) return;
    setState(() {
      _inputDigits += digit;
      _errorMessage = null;
    });
  }

  void _backspace() {
    if (_inputDigits.isEmpty) return;
    setState(() {
      _inputDigits = _inputDigits.substring(0, _inputDigits.length - 1);
      _errorMessage = null;
    });
  }

  void _clear() {
    setState(() {
      _inputDigits = '';
      _errorMessage = null;
    });
  }

  void _submit() {
    if (_inputDigits.isEmpty) return;
    final numVal = double.tryParse(_inputDigits);
    if (numVal == null) return;

    final matchedEp = widget.allEpisodes
        .where((e) => e.number == numVal)
        .firstOrNull;
    if (matchedEp != null) {
      widget.onEpisodeSelected(matchedEp);
    } else {
      final maxEp = widget.allEpisodes.fold<double>(
        0.0,
        (max, ep) => ep.number > max ? ep.number : max,
      );
      setState(() {
        _errorMessage =
            '${widget.typeLabel} $numVal not found (Max: ${maxEp.toInt()})';
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      _appendDigit('0');
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit1 ||
        key == LogicalKeyboardKey.numpad1) {
      _appendDigit('1');
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit2 ||
        key == LogicalKeyboardKey.numpad2) {
      _appendDigit('2');
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit3 ||
        key == LogicalKeyboardKey.numpad3) {
      _appendDigit('3');
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit4 ||
        key == LogicalKeyboardKey.numpad4) {
      _appendDigit('4');
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit5 ||
        key == LogicalKeyboardKey.numpad5) {
      _appendDigit('5');
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit6 ||
        key == LogicalKeyboardKey.numpad6) {
      _appendDigit('6');
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit7 ||
        key == LogicalKeyboardKey.numpad7) {
      _appendDigit('7');
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit8 ||
        key == LogicalKeyboardKey.numpad8) {
      _appendDigit('8');
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.digit9 ||
        key == LogicalKeyboardKey.numpad9) {
      _appendDigit('9');
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _backspace();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _submit();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dialogRadius = BorderRadius.circular(widget.uiRoundness);
    final keyRadius = BorderRadius.circular(
      (widget.uiRoundness * 0.6).clamp(6.0, 14.0),
    );

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: (380.0 * widget.scale).clamp(320.0, 480.0),
            padding: EdgeInsets.all((24.0 * widget.scale).clamp(18.0, 32.0)),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: dialogRadius,
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Play ${widget.typeLabel}',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: (18.0 * widget.scale).clamp(16.0, 22.0),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: cs.onSurfaceVariant,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: (12.0 * widget.scale).clamp(8.0, 16.0)),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: (14.0 * widget.scale).clamp(10.0, 20.0),
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.8),
                    borderRadius: keyRadius,
                    border: Border.all(
                      color: _errorMessage != null
                          ? cs.error
                          : cs.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _inputDigits.isEmpty
                          ? 'Type ${widget.typeLabel} #'
                          : '${widget.typeLabel} $_inputDigits',
                      style: TextStyle(
                        color: _inputDigits.isEmpty
                            ? cs.onSurfaceVariant.withValues(alpha: 0.5)
                            : cs.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: (24.0 * widget.scale).clamp(20.0, 32.0),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  SizedBox(height: (8.0 * widget.scale).clamp(6.0, 12.0)),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: cs.error,
                      fontSize: (12.0 * widget.scale).clamp(11.0, 14.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                SizedBox(height: (18.0 * widget.scale).clamp(14.0, 24.0)),

                // 3x4 Number Keypad Grid
                Column(
                  children: [
                    _buildKeyRow(['1', '2', '3'], keyRadius),
                    SizedBox(height: (10.0 * widget.scale).clamp(6.0, 14.0)),
                    _buildKeyRow(['4', '5', '6'], keyRadius),
                    SizedBox(height: (10.0 * widget.scale).clamp(6.0, 14.0)),
                    _buildKeyRow(['7', '8', '9'], keyRadius),
                    SizedBox(height: (10.0 * widget.scale).clamp(6.0, 14.0)),
                    Row(
                      children: [
                        Expanded(
                          child: _TvDialKey(
                            label: '⌫',
                            scale: widget.scale,
                            borderRadius: keyRadius,
                            onTap: _backspace,
                            onLongPress: _clear,
                          ),
                        ),
                        SizedBox(width: (10.0 * widget.scale).clamp(6.0, 14.0)),
                        Expanded(
                          child: _TvDialKey(
                            label: '0',
                            scale: widget.scale,
                            borderRadius: keyRadius,
                            onTap: () => _appendDigit('0'),
                          ),
                        ),
                        SizedBox(width: (10.0 * widget.scale).clamp(6.0, 14.0)),
                        Expanded(
                          child: _TvDialKey(
                            label: '▶ Play',
                            isPrimary: true,
                            scale: widget.scale,
                            borderRadius: keyRadius,
                            onTap: _submit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> digits, BorderRadius radius) {
    return Row(
      children: digits.map((digit) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (5.0 * widget.scale).clamp(3.0, 7.0),
            ),
            child: _TvDialKey(
              label: digit,
              scale: widget.scale,
              borderRadius: radius,
              onTap: () => _appendDigit(digit),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TvDialKey extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final double scale;
  final BorderRadius borderRadius;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _TvDialKey({
    required this.label,
    this.isPrimary = false,
    required this.scale,
    required this.borderRadius,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_TvDialKey> createState() => _TvDialKeyState();
}

class _TvDialKeyState extends State<_TvDialKey> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bgColor = widget.isPrimary
        ? (_isFocused ? cs.primary.withValues(alpha: 0.9) : cs.primary)
        : (_isFocused
              ? cs.surfaceContainerHighest.withValues(alpha: 0.95)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5));

    final fgColor = widget.isPrimary ? cs.onPrimary : cs.onSurface;

    return FocusableActionDetector(
      focusNode: _focusNode,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: AnimatedScale(
        scale: _isFocused ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: InkWell(
          canRequestFocus: false,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
            _focusNode.requestFocus();
            widget.onTap();
          },
          onLongPress: widget.onLongPress,
          borderRadius: widget.borderRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: EdgeInsets.symmetric(
              vertical: (12.0 * widget.scale).clamp(10.0, 18.0),
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: _isFocused
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.3),
                width: _isFocused ? 2.0 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: widget.isPrimary
                            ? cs.primary.withValues(alpha: 0.45)
                            : cs.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: (16.0 * widget.scale).clamp(14.0, 20.0),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TvEpisodeCard extends StatefulWidget {
  final UnifiedEpisode episode;
  final double cardWidth;
  final double thumbHeight;
  final bool isCurrent;
  final bool isWatched;
  final UnifiedMedia media;
  final double uiRoundness;
  final VoidCallback onTap;

  const _TvEpisodeCard({
    required this.episode,
    required this.cardWidth,
    required this.thumbHeight,
    required this.isCurrent,
    required this.isWatched,
    required this.media,
    required this.uiRoundness,
    required this.onTap,
  });

  @override
  State<_TvEpisodeCard> createState() => _TvEpisodeCardState();
}

class _TvEpisodeCardState extends State<_TvEpisodeCard> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
        if (_focusNode.hasFocus) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scale = context.tvScale;
    final ep = widget.episode;
    final epNum = ep.number.toString().contains('.0')
        ? ep.number.toInt().toString()
        : ep.number.toString();

    final thumbUrl =
        ep.thumbnailUrl ?? widget.media.banner ?? widget.media.cover ?? '';

    final cardRadius = BorderRadius.circular(widget.uiRoundness);
    final badgeRadius = BorderRadius.circular(
      (widget.uiRoundness * 0.35).clamp(3.0, 6.0),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: FocusableActionDetector(
        focusNode: _focusNode,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: AnimatedScale(
          scale: _isFocused ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: InkWell(
            canRequestFocus: false,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: () {
              _focusNode.requestFocus();
              widget.onTap();
            },
            borderRadius: cardRadius,
            child: SizedBox(
              width: widget.cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    height: widget.thumbHeight,
                    decoration: BoxDecoration(
                      borderRadius: cardRadius,
                      border: Border.all(
                        color: _isFocused
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: 0.2),
                        width: _isFocused ? 2.2 : 1.0,
                      ),
                      boxShadow: _isFocused
                          ? [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: cardRadius,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (thumbUrl.isNotEmpty)
                            TvSmartImage(
                              imageUrl: thumbUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 600,
                              memCacheHeight: 350,
                            )
                          else
                            Container(color: cs.surfaceContainerHighest),

                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.75),
                                ],
                              ),
                            ),
                          ),

                          if (widget.isCurrent ||
                              widget.isWatched ||
                              ep.isFiller)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.isCurrent || widget.isWatched)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.isWatched
                                            ? Colors.green.shade700
                                            : cs.primary,
                                        borderRadius: badgeRadius,
                                      ),
                                      child: Text(
                                        widget.isWatched
                                            ? 'WATCHED'
                                            : 'WATCHING',
                                        style: TextStyle(
                                          color: widget.isWatched
                                              ? Colors.white
                                              : cs.onPrimary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  if (ep.isFiller) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade900,
                                        borderRadius: badgeRadius,
                                      ),
                                      child: const Text(
                                        'FILLER',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          Positioned(
                            bottom: 6,
                            left: 8,
                            child: Text(
                              epNum,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (18.0 * scale).clamp(16.0, 24.0),
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.9),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (ep.airDate?.isNotEmpty == true)
                            Positioned(
                              bottom: 6,
                              right: 8,
                              child: Text(
                                ep.airDate!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    ep.title?.isNotEmpty == true
                        ? '$epNum. ${ep.title!}'
                        : (widget.media.type == MediaType.MANGA ||
                                  widget.media.type == MediaType.NOVEL
                              ? 'Chapter $epNum'
                              : 'Episode $epNum'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _isFocused
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.9),
                      fontWeight: _isFocused
                          ? FontWeight.w800
                          : FontWeight.w700,
                      fontSize: (12.5 * scale).clamp(11.5, 15.5),
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 3),

                  Row(
                    children: [
                      if (ep.scanlator?.isNotEmpty == true) ...[
                        Text(
                          ep.scanlator!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '•',
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        ep.airDate?.isNotEmpty == true
                            ? ep.airDate!
                            : 'Stream HD',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.isWatched) ...[
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: Colors.greenAccent,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TvSeasonPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final BorderRadius borderRadius;
  final double scale;
  final VoidCallback onTap;

  const _TvSeasonPill({
    required this.label,
    required this.isSelected,
    required this.borderRadius,
    required this.scale,
    required this.onTap,
  });

  @override
  State<_TvSeasonPill> createState() => _TvSeasonPillState();
}

class _TvSeasonPillState extends State<_TvSeasonPill> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (3.0 * widget.scale).clamp(2.0, 6.0),
      ),
      child: FocusableActionDetector(
        focusNode: _focusNode,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: InkWell(
          canRequestFocus: false,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
            _focusNode.requestFocus();
            widget.onTap();
          },
          borderRadius: widget.borderRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.symmetric(
              horizontal: (14.0 * widget.scale).clamp(12.0, 20.0),
              vertical: (7.0 * widget.scale).clamp(6.0, 12.0),
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? cs.primary
                  : (_isFocused
                        ? cs.surfaceContainerHighest.withValues(alpha: 0.9)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.45)),
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: _isFocused ? cs.primary : Colors.transparent,
                width: _isFocused ? 2.0 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isSelected ? cs.onPrimary : cs.onSurface,
                fontSize: (13.0 * widget.scale).clamp(12.0, 17.0),
                fontWeight: widget.isSelected || _isFocused
                    ? FontWeight.bold
                    : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
