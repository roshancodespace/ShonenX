import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';

class EpisodeCompactItem extends StatelessWidget {
  final EpisodeDataModel episode;
  final int index;
  final bool isWatched;
  final double watchProgress;
  final DownloadItem? download;
  final EpisodeProgress? episodeProgress;
  final Function() onTap;
  final Function() onMoreOptions;

  const EpisodeCompactItem({
    super.key,
    required this.episode,
    required this.index,
    required this.isWatched,
    required this.watchProgress,
    this.download,
    this.episodeProgress,
    required this.onTap,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          leading: SizedBox(
            width: 40,
            child: Center(
              child: Text(
                '${episode.number ?? index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      isWatched ? theme.hintColor : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          title: Text(
            episode.title ?? 'Episode ${episode.number ?? index + 1}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWatched ? theme.hintColor : null,
            ),
          ),
          subtitle: (download != null || episode.isFiller == true)
              ? Row(
                  children: [
                    if (episode.isFiller == true)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text('FILLER',
                            style: TextStyle(
                                color: Colors.orange.shade700, fontSize: 10)),
                      ),
                    if (download != null)
                      _buildDownloadStatus(theme, download!),
                  ],
                )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: onMoreOptions,
          ),
          onTap: onTap,
        ),
        if (watchProgress > 0)
          LinearProgressIndicator(
            value: watchProgress,
            backgroundColor: Colors.transparent,
            color: theme.colorScheme.primary.withOpacity(0.5),
            minHeight: 1,
          ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildDownloadStatus(ThemeData theme, DownloadItem download) {
    if (download.state == DownloadStatus.downloading) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: download.progressPercentage,
        ),
      );
    } else if (download.state == DownloadStatus.downloaded) {
      return Icon(Icons.download_done_rounded,
          size: 14, color: theme.colorScheme.primary);
    } else {
      return Icon(Icons.downloading,
          size: 14, color: theme.colorScheme.tertiary);
    }
  }
}
