import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';

class EpisodeListItem extends StatelessWidget {
  final EpisodeDataModel episode;
  final int index;
  final bool isWatched;
  final double watchProgress;
  final DownloadItem? download;
  final EpisodeProgress? episodeProgress;
  final String fallbackCover;
  final Function() onTap;
  final Function() onMoreOptions;

  const EpisodeListItem({
    super.key,
    required this.episode,
    required this.index,
    required this.isWatched,
    required this.watchProgress,
    this.download,
    this.episodeProgress,
    required this.fallbackCover,
    required this.onTap,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            leading: SizedBox(
              width: 90,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildThumbnail(context),
              ),
            ),
            title: Text(
              episode.title ?? 'Episode ${episode.number ?? index + 1}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isWatched ? theme.hintColor : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (episode.isFiller == true)
                  Text(
                    'FILLER',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                if (download != null) ...[
                  const SizedBox(height: 4),
                  _buildDownloadStatus(theme, download!),
                ]
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onPressed: onMoreOptions,
            ),
            onTap: onTap,
          ),
          if (watchProgress > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LinearProgressIndicator(
                value: watchProgress,
                backgroundColor:
                    theme.colorScheme.primaryContainer.withOpacity(0.2),
                color: isWatched
                    ? theme.colorScheme.tertiaryContainer
                    : theme.colorScheme.primaryContainer,
                minHeight: isWatched ? 3 : 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final theme = Theme.of(context);
    final episodeNumber = episode.number ?? index + 1;
    final thumbnail = episodeProgress?.episodeThumbnail;
    final fallbackUrl = episode.thumbnail ?? fallbackCover;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnail != null)
            thumbnail.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: thumbnail,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _buildFallbackIcon(theme),
                  )
                : Image.memory(
                    base64Decode(thumbnail),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackIcon(theme),
                  )
          else if (fallbackUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: fallbackUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _buildFallbackIcon(theme),
            )
          else
            Container(color: theme.colorScheme.surfaceContainer),

          // Ep Number Overlay
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$episodeNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (isWatched)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 30,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image_not_supported, color: theme.colorScheme.outline),
    );
  }

  Widget _buildDownloadStatus(ThemeData theme, DownloadItem download) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (download.state == DownloadStatus.downloading)
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: download.progressPercentage,
            ),
          )
        else if (download.state == DownloadStatus.downloaded)
          Icon(Icons.download_done_rounded,
              size: 14, color: theme.colorScheme.primary)
        else if (download.state == DownloadStatus.paused)
          Icon(Icons.pause_circle_outline,
              size: 14, color: theme.colorScheme.tertiary),
        const SizedBox(width: 6),
        Text(
          download.state == DownloadStatus.downloaded
              ? 'Downloaded'
              : download.state == DownloadStatus.downloading
                  ? '${(download.progressPercentage * 100).toStringAsFixed(0)}%'
                  : download.state.name,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.hintColor, fontSize: 10),
        ),
      ],
    );
  }
}
