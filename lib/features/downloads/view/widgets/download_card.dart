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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.thumbnail,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surfaceContainerHigh,
                          child: const Icon(Iconsax.image),
                        ),
                      ),
                      if (isCompleted)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.play,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.animeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.episodeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      if (isDownloading || isPaused) ...[
                        LinearProgressIndicator(
                          value: item.size != null && item.size! > 0
                              ? (item.progress / item.size!).clamp(0.0, 1.0)
                              : 0,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Status / Percentage
                            if (item.size != null &&
                                item.progress >= item.size! &&
                                isDownloading)
                              Text(
                                'Merging...',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              Text(
                                '${((item.progress / (item.size ?? 1)) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                            // Details (Size | Speed | ETA)
                            if (isDownloading &&
                                item.size != null &&
                                item.progress < item.size!)
                              Row(
                                children: [
                                  Text(
                                    '${(item.progress / 1024 / 1024).toStringAsFixed(1)} / ${(item.size! / 1024 / 1024).toStringAsFixed(1)} MB',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(fontSize: 10),
                                  ),
                                  if (item.speed > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '•  ${(item.speed / 1024 / 1024).toStringAsFixed(1)} MB/s',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                  ],
                                  if (item.eta != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '•  ${formatDuration(item.eta!)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ] else if (isCompleted) ...[
                        Row(
                          children: [
                            Icon(
                              Iconsax.tick_circle,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Downloaded',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            if (item.size != null)
                              Text(
                                '${(item.size! / 1024 / 1024).toStringAsFixed(1)} MB',
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ] else if (isFailed) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.error,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Failed',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Actions
          if (!isCompleted)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (isDownloading)
                    TextButton.icon(
                      onPressed: () {
                        downloadNotifier.pauseDownload(item);
                      },
                      icon: const Icon(Iconsax.pause, size: 18),
                      label: const Text('Pause'),
                    ),
                  if (isPaused || isFailed)
                    TextButton.icon(
                      onPressed: () {
                        downloadNotifier.resumeDownload(item);
                      },
                      icon: const Icon(Iconsax.play, size: 18),
                      label: const Text('Resume'),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      downloadNotifier.deleteDownload(item);
                    },
                    icon: Icon(Iconsax.trash,
                        size: 18, color: theme.colorScheme.error),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          if (isCompleted)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LocalPlayerScreen(
                            filePath: item.filePath,
                            title: '${item.animeTitle} - ${item.episodeTitle}',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Iconsax.play, size: 18),
                    label: const Text('Play'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(downloadsProvider.notifier).deleteDownload(item);
                    },
                    icon: Icon(Iconsax.trash,
                        size: 18, color: theme.colorScheme.error),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
