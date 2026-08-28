import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_focusable.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

class TvEpisodeListPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;
    final isManga =
        media.type == MediaType.MANGA || media.type == MediaType.NOVEL;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisExtent: 210,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        final isCompleted =
            historyWatchedSet.contains(episode.number) ||
            effectiveWatchedProgress >= episode.number;
        final isCurrent = episode.number == currentEpisodeNumber;

        final imageUrl = episode.thumbnailUrl?.isNotEmpty == true
            ? episode.thumbnailUrl!
            : (media.banner?.isNotEmpty == true
                  ? media.banner!
                  : (media.cover ?? ''));

        final epTitle = episode.title?.isNotEmpty == true
            ? episode.title!
            : (isManga
                  ? 'Chapter ${episode.number}'
                  : 'Episode ${episode.number}');

        return TvFocusable(
          onTap: () => onEpisodeTap(episode, source),
          scaleFactor: 1.04,
          builder: (context, isFocused, isHovered) {
            final active = isFocused || isHovered;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF1E2024)
                    : const Color(0xFF121316),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: active
                      ? Colors.white
                      : isCurrent
                      ? cs.primary
                      : isCompleted
                      ? cs.primary.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.08),
                  width: active ? 2 : (isCurrent ? 1.5 : 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: active ? 0.7 : 0.3),
                    blurRadius: active ? 20 : 6,
                    spreadRadius: active ? 2 : 0,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.white10,
                              child: const Icon(
                                Icons.movie_outlined,
                                color: Colors.white24,
                              ),
                            ),
                          )
                        else
                          Container(
                            color: Colors.white10,
                            child: const Icon(
                              Icons.movie_outlined,
                              color: Colors.white24,
                            ),
                          ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.35),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.8),
                                ],
                                stops: const [0.0, 0.4, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(
                                (radius * 0.6).clamp(0.0, radius),
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              isManga
                                  ? 'CH ${episode.number % 1 == 0 ? episode.number.toInt() : episode.number}'
                                  : 'EP ${episode.number % 1 == 0 ? episode.number.toInt() : episode.number}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.black,
                                size: 12,
                              ),
                            ),
                          ),
                        AnimatedOpacity(
                          opacity: active ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withValues(alpha: 0.5),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isManga
                                    ? Icons.menu_book_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          epTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          episode.airDate?.isNotEmpty == true
                              ? (formatAirDate(episode.airDate) ??
                                    episode.airDate!)
                              : (isManga ? 'Chapter' : 'Episode'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
