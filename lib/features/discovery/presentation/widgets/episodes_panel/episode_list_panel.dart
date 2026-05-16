import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_tiles.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

export 'episode_tiles.dart' show EpisodeViewMode, EpisodeImageFadeDirection;

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

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(
      uiPrefsProvider.select((s) => s.episodeViewMode),
    );
    final episodesAsync = widget.media.sourceId != null
        ? ref.watch(
            sourceEpisodesProvider((
              providerId: widget.media.id,
              sourceId: widget.media.sourceId!,
            )),
          )
        : ref.watch(episodesListProvider(widget.media.title.availableTitle));

    return episodesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (state) {
        if (state.episodes.isEmpty) {
          return const Center(child: Text('No episodes found.'));
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
                padding: const EdgeInsets.fromLTRB(10, 0, 4, 5),
                child: Row(
                  children: [
                    Text(
                      '${state.episodes.length} episodes',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),

                    const Spacer(),

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
                  filtered,
                  state.source,
                  viewMode,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEpisodeView(
    BuildContext context,
    List<UnifiedEpisode> episodes,
    SourceInfo source,
    EpisodeViewMode viewMode,
  ) {
    final r = context.responsiveOrNull ?? ResponsiveData.from(context);

    switch (viewMode) {
      case EpisodeViewMode.classic:
        return ListView.builder(
          itemCount: episodes.length,
          itemBuilder: (context, i) {
            final ep = episodes[i];
            final isCurrent = widget.currentEpisodeNumber == ep.number;
            final isWatched = widget.watchedProgress >= ep.number;

            return EpisodeClassicTile(
              episode: ep,
              isCurrent: isCurrent,
              isWatched: isWatched,
              imageFadeDirection: widget.imageFadeDirection,
              imageFadeStops: widget.imageFadeStops,
              imageOpacity: widget.imageOpacity,
              imageBlurSigma: widget.imageBlurSigma,
              isFiller: ep.isFiller,
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
        final gridColumns = r.widthTier.pick(
          compact: 2,
          medium: 3,
          expanded: 4,
          large: 5,
          ultraLarge: 6,
        );
        final gridPad = r.widthTier.pickOrFold(
          compact: 10.0,
          medium: 14.0,
          large: 20.0,
        );
        final gridSpacing = r.widthTier.pickOrFold(
          compact: 10.0,
          medium: 12.0,
          large: 16.0,
        );

        return GridView.builder(
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
              isCurrent: isCurrent,
              isWatched: isWatched,
              isFiller: ep.isFiller,
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
        final boxSize = r.widthTier.pickOrFold(
          compact: 48.0,
          medium: 52.0,
          large: 60.0,
        );
        final boxPad = r.widthTier.pickOrFold(
          compact: 10.0,
          medium: 14.0,
          large: 20.0,
        );
        final boxSpacing = r.widthTier.pickOrFold(
          compact: 8.0,
          medium: 10.0,
          large: 12.0,
        );

        return GridView.builder(
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
              isCurrent: isCurrent,
              isFiller: ep.isFiller,
              isWatched: isWatched,
              onTap: () => widget.onEpisodeTap(ep, source),
            );
          },
        );
    }
  }
}

class _ViewModeToggle extends StatelessWidget {
  final EpisodeViewMode current;
  final ValueChanged<EpisodeViewMode> onChanged;

  const _ViewModeToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleBtn(
          icon: Icons.view_agenda_outlined,
          activeIcon: Icons.view_agenda,
          tooltip: 'Classic',
          active: current == EpisodeViewMode.classic,
          onTap: () => onChanged(EpisodeViewMode.classic),
        ),
        _ToggleBtn(
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view,
          tooltip: 'Grid',
          active: current == EpisodeViewMode.grid,
          onTap: () => onChanged(EpisodeViewMode.grid),
        ),
        _ToggleBtn(
          icon: Icons.tag_outlined,
          activeIcon: Icons.tag,
          tooltip: 'Box',
          active: current == EpisodeViewMode.box,
          onTap: () => onChanged(EpisodeViewMode.box),
        ),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.activeIcon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(active ? activeIcon : icon),
        iconSize: 18,
        color: active ? cs.primary : cs.onSurfaceVariant,
        style: active
            ? IconButton.styleFrom(
                backgroundColor: cs.primary.withValues(alpha: 0.1),
              )
            : null,
      ),
    );
  }
}
