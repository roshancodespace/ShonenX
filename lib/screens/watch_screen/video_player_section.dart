import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anilist_media;
import 'package:shonenx/widgets/player/controls.dart';
import 'package:shonenx/widgets/ui/paints/diagonal_lines_bg.dart';

class VideoPlayerSection extends StatelessWidget {
  final String animeName;
  final List<EpisodeDataModel> episodes;
  final int selectedEpisodeIndex;
  final VideoController controller;
  final List<SubtitleTrack> subtitles;
  final anilist_media.Media animeMedia;

  const VideoPlayerSection({
    super.key,
    required this.animeName,
    required this.episodes,
    required this.selectedEpisodeIndex,
    required this.controller,
    required this.subtitles,
    required this.animeMedia,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: DiagonalLinesPainter(
        lineColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        lineWidth: 1.5,
        spacing: 30
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(animeName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (episodes.isNotEmpty)
                  Text('Episode ${episodes[selectedEpisodeIndex].number}',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Video(
                  controller: controller,
                  controls: (videoState) => CustomControls(
                    animeMedia: animeMedia,
                    state: videoState,
                    subtitles: subtitles,
                    episodes: episodes,
                    currentEpisodeIndex: selectedEpisodeIndex,
                  ),
                  subtitleViewConfiguration: SubtitleViewConfiguration(
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        backgroundColor: Colors.black45,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                              color: Colors.black.withValues(alpha: 0.7),
                              blurRadius: 4,
                              offset: const Offset(1, 1))
                        ]),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
