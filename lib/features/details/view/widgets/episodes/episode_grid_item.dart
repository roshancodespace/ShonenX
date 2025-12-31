import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/details/view/widgets/episodes/episode_thumbnail.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';

class EpisodeGridItem extends StatelessWidget {
  final EpisodeDataModel episode;
  final int index;
  final bool isWatched;
  final double watchProgress;
  final DownloadItem? download;
  final EpisodeProgress? episodeProgress;
  final String fallbackCover;
  final Function() onTap;
  final Function() onLongPress;

  const EpisodeGridItem({
    super.key,
    required this.episode,
    required this.index,
    required this.isWatched,
    required this.watchProgress,
    this.download,
    this.episodeProgress,
    required this.fallbackCover,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final episodeNumber = episode.number ?? index + 1;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors
          .transparent, // We handle background manually if needed or just use column
      child: InkWell(
        onLongPress: onLongPress,
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EpisodeThumbnail(
                    episodeThumbnail: episodeProgress?.episodeThumbnail,
                    fallbackUrl: episode.thumbnail ?? fallbackCover,
                    episodeNumber: episodeNumber,
                    isWatched: isWatched,
                    aspectRatio: 16 /
                        9, // Let parent constraint handle it but default typical video ratio
                  ),
                  if (download != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          download!.state == DownloadStatus.downloaded
                              ? Icons.download_done
                              : Icons.downloading,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (watchProgress > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: watchProgress,
                        minHeight: 3,
                        backgroundColor: Colors.transparent,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Episode $episodeNumber',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isWatched ? theme.hintColor : null),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    episode.title ?? 'Episode $episodeNumber',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: isWatched
                            ? theme.hintColor
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.1),
                  ),
                  if (episode.isFiller == true)
                    Text(
                      'FILLER',
                      style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
