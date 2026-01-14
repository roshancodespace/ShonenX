import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/view/local_player_screen.dart';
import 'package:shonenx/features/downloads/view_model/downloads_notifier.dart';
import 'package:shonenx/utils/formatter.dart';

class DownloadCard extends ConsumerWidget {
  final DownloadItem item;

  const DownloadCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final downloadNotifier = ref.read(downloadsProvider.notifier);

    final isDownloading = item.state == DownloadStatus.downloading;
    final isPaused = item.state == DownloadStatus.paused;
    final isCompleted = item.state == DownloadStatus.downloaded;
    final isFailed = item.state == DownloadStatus.failed;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isCompleted
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LocalPlayerScreen(
                    filePath: item.filePath,
                    title: '${item.animeTitle} - ${item.episodeTitle}',
                  ),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              _buildThumbnail(theme, isCompleted),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoSection(
                  theme,
                  isDownloading,
                  isPaused,
                  isCompleted,
                  isFailed,
                ),
              ),
              _buildActionButtons(
                theme,
                downloadNotifier,
                isDownloading,
                isPaused,
                isCompleted,
                isFailed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme, bool isCompleted) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: item.thumbnail,
            height: 64,
            width: 64,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(color: theme.colorScheme.surfaceContainerHigh),
            errorWidget: (_, __, ___) => const Icon(Iconsax.image),
          ),
        ),
        if (isCompleted)
          Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4),
            child: const Icon(Iconsax.play5, color: Colors.white, size: 20),
          ),
      ],
    );
  }

  Widget _buildInfoSection(
    ThemeData theme,
    bool isDownloading,
    bool isPaused,
    bool isCompleted,
    bool isFailed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          item.animeTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.episodeTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        if (isCompleted)
          _buildCompletedStatus(theme)
        else if (isFailed)
          _buildFailedStatus(theme)
        else if (isPaused)
          _buildPausedStatus(theme)
        else if (isDownloading)
          _buildProgressSection(theme),
      ],
    );
  }

  Widget _buildCompletedStatus(ThemeData theme) {
    final sizeMB = ((item.size ?? 0) / 1024 / 1024).toStringAsFixed(1);
    return Text(
      '$sizeMB MB • Downloaded',
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildFailedStatus(ThemeData theme) {
    return Text(
      'Download Failed',
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }

  Widget _buildPausedStatus(ThemeData theme) {
    return Text(
      'Paused • ${item.getProgressText()}',
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    final progressValue = item.progressPercentage;
    final isIndeterminate = !item.hasByteSize && !item.hasSegmentCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: isIndeterminate ? null : progressValue,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _buildStatusText(theme)),
            Text(
              '${(progressValue * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusText(ThemeData theme) {
    // Check if we're in stitching phase
    if (item.hasSegmentCount &&
        item.progress >= item.totalSegments! &&
        item.state == DownloadStatus.downloading) {
      return Text(
        'Merging segments...',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Show speed and ETA for byte-based downloads
    if (item.hasByteSize && item.speed > 0) {
      final speedMB = (item.speed / 1024 / 1024).toStringAsFixed(1);
      final etaText = item.eta != null ? formatDuration(item.eta!) : '--:--';
      return Text(
        '$speedMB MB/s • $etaText',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.secondary,
          fontSize: 10,
        ),
      );
    }

    // Show progress text for segment-based or unknown
    return Text(
      item.getProgressText(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.secondary,
        fontSize: 10,
      ),
    );
  }

  Widget _buildActionButtons(
    ThemeData theme,
    DownloadsNotifier downloadNotifier,
    bool isDownloading,
    bool isPaused,
    bool isCompleted,
    bool isFailed,
  ) {
    if (isCompleted) {
      return IconButton(
        onPressed: () => downloadNotifier.deleteDownload(item),
        icon: Icon(Iconsax.trash, color: theme.colorScheme.onSurfaceVariant),
        iconSize: 18,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
        tooltip: 'Delete',
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDownloading)
          IconButton(
            onPressed: () => downloadNotifier.pauseDownload(item),
            icon: const Icon(Iconsax.pause),
            iconSize: 20,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            tooltip: 'Pause',
          )
        else if (isPaused || isFailed)
          IconButton(
            onPressed: () => downloadNotifier.resumeDownload(item),
            icon: const Icon(Iconsax.play),
            iconSize: 20,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            tooltip: 'Resume',
          ),
        IconButton(
          onPressed: () => downloadNotifier.deleteDownload(item),
          icon: Icon(Iconsax.close_circle, color: theme.colorScheme.error),
          iconSize: 20,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
          tooltip: 'Cancel',
        ),
      ],
    );
  }
}
