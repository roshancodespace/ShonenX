import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(downloadTasksProvider);
    final managerAsync = ref.watch(downloadManagerProvider);

    return AppScaffold(
      title: 'Downloads',
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Text(
                'No downloads',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: tasks.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) => _DownloadTile(task: tasks[index]),
          );
        },
      ),
      floatingActionButton: managerAsync.isLoading
          ? null
          : FloatingActionButton(
              elevation: 0,
              onPressed: () => _addTestDownload(context, ref),
              child: const Icon(Icons.add),
            ),
    );
  }

  Future<void> _addTestDownload(BuildContext context, WidgetRef ref) async {
    final dir = await getApplicationDocumentsDirectory();
    final saveDir = Directory('${dir.path}/ShonenX/Downloads');
    if (!await saveDir.exists()) await saveDir.create(recursive: true);

    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'TestVideo_$ts.mp4';

    final task = DownloadTask()
      ..url =
          'https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_1/segments/bigbuck_bunny_8bit_15000kbps_1080p_60.0fps_h264.mp4'
      ..mediaId = 'test_media'
      ..episodeNumber = 1.0
      ..fileName = fileName
      ..savePath = '${saveDir.path}/$fileName';

    await ref.read(downloadManagerProvider.notifier).startDownload(task);
  }
}

class _DownloadTile extends ConsumerWidget {
  final DownloadTask task;

  const _DownloadTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final status = task.status;
    final isDone = status == DownloadStatus.completed;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        task.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isDone && status != DownloadStatus.canceled) ...[
              LinearProgressIndicator(
                value: task.progress,
                minHeight: 2,
                backgroundColor: colors.surfaceContainerHighest,
                color: _progressColor(status, colors),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              _buildStatusText(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      trailing: isDone
          ? Icon(Icons.check, color: colors.primary)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == DownloadStatus.downloading ||
                    status == DownloadStatus.pending)
                  IconButton(
                    icon: const Icon(Icons.pause),
                    iconSize: 20,
                    onPressed: () => ref
                        .read(downloadManagerProvider.notifier)
                        .pauseDownload(task.id),
                  ),
                if (status == DownloadStatus.paused ||
                    status == DownloadStatus.failed)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    iconSize: 20,
                    onPressed: () => ref
                        .read(downloadManagerProvider.notifier)
                        .startDownload(task),
                  ),
                if (status != DownloadStatus.canceled)
                  IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    onPressed: () => ref
                        .read(downloadManagerProvider.notifier)
                        .cancelDownload(task.id),
                  ),
              ],
            ),
    );
  }

  String _buildStatusText() {
    final statusText =
        task.status.name[0].toUpperCase() + task.status.name.substring(1);
    if (task.status == DownloadStatus.completed ||
        task.status == DownloadStatus.canceled) {
      return statusText;
    }

    final percent = (task.progress * 100).toStringAsFixed(0);
    if (task.totalBytes > 0) {
      return '$statusText • $percent% • ${_mb(task.downloadedBytes)} / ${_mb(task.totalBytes)} MB';
    }
    return '$statusText • $percent%';
  }

  Color _progressColor(DownloadStatus status, ColorScheme colors) {
    return switch (status) {
      DownloadStatus.failed => colors.error,
      DownloadStatus.paused => colors.outline,
      _ => colors.primary,
    };
  }

  String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
}
