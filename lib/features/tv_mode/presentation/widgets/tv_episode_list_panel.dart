import 'package:flutter/material.dart';
import 'package:shonenx/features/tv_mode/presentation/tv_scale.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_smart_image.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

class TvEpisodeListPanel extends StatefulWidget {
  final List<UnifiedEpisode> episodes;
  final UnifiedMedia media;
  final SourceInfo source;
  final double effectiveWatchedProgress;
  final Set<double> historyWatchedSet;
  final double? currentEpisodeNumber;
  final void Function(UnifiedEpisode episode, SourceInfo sourceInfo)
  onEpisodeTap;

  const TvEpisodeListPanel({
    super.key,
    required this.episodes,
    required this.media,
    required this.source,
    required this.effectiveWatchedProgress,
    required this.historyWatchedSet,
    this.currentEpisodeNumber,
    required this.onEpisodeTap,
  });

  @override
  State<TvEpisodeListPanel> createState() => _TvEpisodeListPanelState();
}

class _TvEpisodeListPanelState extends State<TvEpisodeListPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _hasAutoScrolled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentEpisodeNumber != null && !_hasAutoScrolled) {
      _hasAutoScrolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final index = widget.episodes.indexWhere(
          (ep) => ep.number == widget.currentEpisodeNumber,
        );
        if (index != -1) {
          final scale = context.tvScale;
          final itemHeight = (90 * scale).clamp(80.0, 140.0) + (12 * scale);
          final offset = index * itemHeight;
          _scrollController.jumpTo(
            offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          );
        }
      });
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: 120 * context.tvScale),
      itemCount: widget.episodes.length,
      itemBuilder: (context, index) {
        final ep = widget.episodes[index];
        final isCurrent = widget.currentEpisodeNumber == ep.number;
        final isWatched =
            widget.effectiveWatchedProgress >= ep.number ||
            widget.historyWatchedSet.contains(ep.number);

        return _TvEpisodeTile(
          episode: ep,
          mediaType: widget.media.type,
          isCurrent: isCurrent,
          isWatched: isWatched,
          fallbackThumbnailUrl: widget.media.banner ?? widget.media.cover,
          onTap: () => widget.onEpisodeTap(ep, widget.source),
        );
      },
    );
  }
}

class _TvEpisodeTile extends StatefulWidget {
  final UnifiedEpisode episode;
  final MediaType mediaType;
  final bool isCurrent;
  final bool isWatched;
  final String? fallbackThumbnailUrl;
  final VoidCallback onTap;

  const _TvEpisodeTile({
    required this.episode,
    required this.mediaType,
    required this.isCurrent,
    required this.isWatched,
    this.fallbackThumbnailUrl,
    required this.onTap,
  });

  @override
  State<_TvEpisodeTile> createState() => _TvEpisodeTileState();
}

class _TvEpisodeTileState extends State<_TvEpisodeTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scale = context.tvScale;
    final epNumStr = widget.episode.number.toString().contains('.0')
        ? widget.episode.number.toInt().toString()
        : widget.episode.number.toString();

    final label =
        widget.mediaType == MediaType.MANGA ||
            widget.mediaType == MediaType.NOVEL
        ? 'Chapter $epNumStr'
        : 'Episode $epNumStr';

    final thumbnailUrl = widget.episode.thumbnailUrl?.isNotEmpty == true
        ? widget.episode.thumbnailUrl
        : widget.fallbackThumbnailUrl;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: (6 * scale).clamp(4.0, 10.0)),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() => _isFocused = hasFocus);
          if (hasFocus) {
            Scrollable.ensureVisible(
              context,
              alignment: 0.5,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            );
          }
        },
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: (90 * scale).clamp(80.0, 140.0),
            decoration: BoxDecoration(
              color: _isFocused
                  ? Colors.white.withValues(alpha: 0.15)
                  : (widget.isCurrent
                        ? cs.primary.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? Colors.white
                    : (widget.isCurrent
                          ? cs.primary.withValues(alpha: 0.5)
                          : Colors.transparent),
                width: _isFocused ? 2.5 : 1.5,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Thumbnail
                if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10.5),
                      bottomLeft: Radius.circular(10.5),
                    ),
                    child: SizedBox(
                      width: (160 * scale).clamp(140.0, 240.0),
                      height: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          TvSmartImage(
                            imageUrl: thumbnailUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 400,
                          ),
                          if (widget.isWatched)
                            Container(
                              color: Colors.black.withValues(alpha: 0.5),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white70,
                                size: 32,
                              ),
                            ),
                          // Watched Progress Bar (Bottom)
                          if (widget.isWatched || widget.isCurrent)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 4,
                                color: widget.isWatched
                                    ? cs.primary
                                    : cs.primary.withValues(alpha: 0.4),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  // Fallback for no thumbnail
                  Container(
                    width: (160 * scale).clamp(140.0, 240.0),
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10.5),
                        bottomLeft: Radius.circular(10.5),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.white30,
                      ),
                    ),
                  ),

                SizedBox(width: (20 * scale).clamp(16.0, 32.0)),

                // Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: _isFocused || widget.isCurrent
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: FontWeight.w800,
                          fontSize: (15 * scale).clamp(14.0, 22.0),
                        ),
                      ),
                      if (widget.episode.title?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.episode.title!,
                          style: TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                            fontSize: (14 * scale).clamp(13.0, 20.0),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                if (widget.episode.isFiller)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'FILLER',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: (11 * scale).clamp(10.0, 16.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
