import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(downloadTasksProvider);
    final managerAsync = ref.watch(downloadManagerProvider);

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Downloads',
        barBottom: const TabBar(
          tabs: [
            Tab(text: 'Queue'),
            Tab(text: 'Files'),
          ],
        ),
        body: TabBarView(
          children: [
            // Queue Tab
            tasksAsync.when(
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
                  itemBuilder: (context, index) =>
                      _DownloadTile(task: tasks[index]),
                );
              },
            ),
            // Files Tab
            const _DownloadedFilesTab(),
          ],
        ),
        floatingActionButton: managerAsync.isLoading || kDebugMode
            ? null
            : FloatingActionButton(
                elevation: 0,
                onPressed: () => _addTestDownload(context, ref),
                child: const Icon(Icons.add),
              ),
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
                value: task.totalBytes > 0 ? task.progress : null,
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

    final isM3U8 = task.url.contains('.m3u8');

    if (isM3U8) {
      final percent = (task.progress * 100).toStringAsFixed(0);
      if (task.totalBytes > 0) {
        return '$statusText • $percent% • ${task.downloadedBytes} / ${task.totalBytes} Segments';
      }
      return '$statusText • ${task.downloadedBytes} Segments';
    }

    if (task.totalBytes > 0) {
      final percent = (task.progress * 100).toStringAsFixed(0);
      return '$statusText • $percent% • ${_mb(task.downloadedBytes)} / ${_mb(task.totalBytes)} MB';
    }

    return '$statusText • ${_mb(task.downloadedBytes)} MB';
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

class _DownloadedFilesTab extends ConsumerStatefulWidget {
  const _DownloadedFilesTab();

  @override
  ConsumerState<_DownloadedFilesTab> createState() =>
      _DownloadedFilesTabState();
}

class _DownloadedFilesTabState extends ConsumerState<_DownloadedFilesTab> {
  late Future<List<File>> _filesFuture;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    _filesFuture = _getFiles();
  }

  Future<List<File>> _getFiles() async {
    final prefs = await ref.read(downloadPrefsProvider.future);
    final dir = Directory(prefs.downloadPath);
    if (!await dir.exists()) return [];

    final List<File> files = [];
    final entities = await dir.list(recursive: true).toList();
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.mp4')) {
        files.add(entity);
      }
    }
    // Sort by modified time, newest first
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      setState(() {
        _loadFiles();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete file: $e')));
      }
    }
  }

  void _openFile(File file) {
    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'action_view',
          data: 'file://${file.path}',
          type: 'video/*',
          flags: <int>[1], // FLAG_GRANT_READ_URI_PERMISSION
        );
        intent.launch();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to open video: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<File>>(
      future: _filesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final files = snapshot.data ?? [];
        if (files.isEmpty) {
          return Center(
            child: Text(
              'No downloaded files',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: files.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            final file = files[index];
            final sizeStr = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(
              1,
            );
            return ListTile(
              onTap: () => _openFile(file),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: const Icon(Icons.video_file, size: 36),
              title: Text(
                file.path.split('/').last,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('$sizeStr MB'),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete File?'),
                      content: const Text(
                        'Are you sure you want to delete this file?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteFile(file);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
