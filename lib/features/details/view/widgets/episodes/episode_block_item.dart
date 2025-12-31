import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';

class EpisodeBlockItem extends StatelessWidget {
  final EpisodeDataModel episode;
  final int index;
  final bool isWatched;
  final double watchProgress;
  final DownloadItem? download;
  final Function() onTap;
  final Function() onLongPress;

  const EpisodeBlockItem({
    super.key,
    required this.episode,
    required this.index,
    required this.isWatched,
    required this.watchProgress,
    this.download,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final episodeNumber = episode.number ?? index + 1;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isWatched
              ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: episode.isFiller == true
              ? Border.all(color: Colors.orange.shade700, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$episodeNumber',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isWatched ? theme.hintColor : theme.colorScheme.onSurface,
                ),
              ),
            ),

            // Download Icon
            if (download != null)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  download!.state == DownloadStatus.downloaded
                      ? Icons.download_done
                      : Icons.downloading,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ),

            // Progress Bar
            if (watchProgress > 0)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: LinearProgressIndicator(
                  value: watchProgress,
                  minHeight: 3,
                  backgroundColor: theme.colorScheme.surfaceDim,
                  color: isWatched
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

            // Watched Checkmark (Subtle)
            if (isWatched)
              Positioned(
                bottom: 4,
                right: 4,
                child: Icon(Icons.check, size: 14, color: theme.hintColor),
              )
          ],
        ),
      ),
    );
  }
}
