import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Downloads',
        barBottom: TabBar(
          indicatorColor: colors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurfaceVariant,
          dividerColor: colors.outlineVariant.withValues(alpha: 0.4),
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.labelLarge,
          tabs: const [
            Tab(text: 'Queue'),
            Tab(text: 'Offline Files'),
          ],
        ),
        body: TabBarView(
          children: [
            // Queue Tab
            tasksAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.download_for_offline_outlined,
                    title: 'Queue is empty',
                    subtitle: 'Active downloads will appear here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, i) => _DownloadTile(task: tasks[i]),
                );
              },
            ),
            // Files Tab
            const _DownloadedFilesTab(),
          ],
        ),
        floatingActionButton: managerAsync.isLoading || !kDebugMode
            ? null
            : FloatingActionButton(
                elevation: 0,
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: const CircleBorder(),
                onPressed: () => _addTestDownload(context, ref),
                child: const Icon(Icons.add_rounded),
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

// ─── Download Queue Tile ──────────────────────────────────────────────────────

class _DownloadTile extends ConsumerWidget {
  final DownloadTask task;
  const _DownloadTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = task.status;
    final isDone = status == DownloadStatus.completed;
    final isCanceled = status == DownloadStatus.canceled;

    return InkWell(
      onTap: null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status icon
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (status == DownloadStatus.downloading)
                    CircularProgressIndicator(
                      value: task.totalBytes > 0 ? task.progress : null,
                      strokeWidth: 2.5,
                      color: colors.primary,
                      backgroundColor: colors.primary.withValues(alpha: 0.12),
                    ),
                  Icon(
                    _statusIcon(status),
                    size: 20,
                    color: _statusColor(status, colors),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _buildStatusText(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (!isDone && !isCanceled) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: task.totalBytes > 0 ? task.progress : null,
                      minHeight: 2,
                      borderRadius: BorderRadius.circular(2),
                      backgroundColor: colors.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      color: _progressColor(status, colors),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action buttons
            if (isDone)
              Icon(Icons.check_rounded, size: 20, color: Colors.green)
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status == DownloadStatus.downloading ||
                      status == DownloadStatus.pending)
                    _IconBtn(
                      icon: Icons.pause_rounded,
                      onPressed: () => ref
                          .read(downloadManagerProvider.notifier)
                          .pauseDownload(task.id),
                    ),
                  if (status == DownloadStatus.paused ||
                      status == DownloadStatus.failed)
                    _IconBtn(
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => ref
                          .read(downloadManagerProvider.notifier)
                          .startDownload(task),
                    ),
                  if (!isCanceled) ...[
                    const SizedBox(width: 4),
                    _IconBtn(
                      icon: Icons.close_rounded,
                      color: colors.error,
                      onPressed: () => ref
                          .read(downloadManagerProvider.notifier)
                          .cancelDownload(task.id),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(DownloadStatus s) => switch (s) {
    DownloadStatus.completed => Icons.check_circle_outline_rounded,
    DownloadStatus.failed => Icons.error_outline_rounded,
    DownloadStatus.paused => Icons.pause_circle_outline_rounded,
    DownloadStatus.canceled => Icons.cancel_outlined,
    _ => Icons.downloading_rounded,
  };

  Color _statusColor(DownloadStatus s, ColorScheme c) => switch (s) {
    DownloadStatus.completed => Colors.green,
    DownloadStatus.failed => c.error,
    DownloadStatus.paused => Colors.orange,
    DownloadStatus.canceled => c.outline,
    _ => c.primary,
  };

  Color _progressColor(DownloadStatus s, ColorScheme c) => switch (s) {
    DownloadStatus.failed => c.error,
    DownloadStatus.paused => Colors.orange,
    _ => c.primary,
  };

  String _buildStatusText() {
    final name =
        task.status.name[0].toUpperCase() + task.status.name.substring(1);
    if (task.status == DownloadStatus.completed ||
        task.status == DownloadStatus.canceled)
      return name;

    final isM3U8 = task.url.contains('.m3u8');
    if (isM3U8) {
      final pct = (task.progress * 100).toStringAsFixed(0);
      return task.totalBytes > 0
          ? '$name · $pct% · ${task.downloadedBytes}/${task.totalBytes} segs'
          : '$name · ${task.downloadedBytes} segs';
    }
    if (task.totalBytes > 0) {
      final pct = (task.progress * 100).toStringAsFixed(0);
      return '$name · $pct% · ${_mb(task.downloadedBytes)}/${_mb(task.totalBytes)} MB';
    }
    return '$name · ${_mb(task.downloadedBytes)} MB';
  }

  String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
}

// ─── Offline Files Tab ────────────────────────────────────────────────────────

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
    _filesFuture = _getFiles();
  }

  Future<List<File>> _getFiles() async {
    final prefs = await ref.read(downloadPrefsProvider.future);
    final dir = Directory(prefs.downloadPath);
    if (!await dir.exists()) return [];
    final entities = await dir.list(recursive: true).toList();
    final files =
        entities
            .whereType<File>()
            .where((f) => f.path.endsWith('.mp4'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );
    return files;
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      setState(() => _filesFuture = _getFiles());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _openFile(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  void _confirmDelete(BuildContext context, File file) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete file?'),
        content: const Text(
          'This will permanently remove the downloaded file.',
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
            child: Text(
              'Delete',
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FutureBuilder<List<File>>(
      future: _filesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final files = snapshot.data ?? [];
        if (files.isEmpty) {
          return const _EmptyState(
            icon: Icons.video_library_outlined,
            title: 'No downloaded files',
            subtitle: 'Downloaded episodes will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: files.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 72,
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
          itemBuilder: (context, i) {
            final file = files[i];
            final sizeStr = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(
              1,
            );
            final name = file.path.split('/').last.replaceAll('.mp4', '');

            return InkWell(
              onTap: () => _openFile(file),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.video_file_outlined,
                      size: 24,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$sizeStr MB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _IconBtn(
                      icon: Icons.delete_outline_rounded,
                      color: colors.error,
                      onPressed: () => _confirmDelete(context, file),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

/// Flat icon button — no background, just ripple.
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _IconBtn({required this.icon, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return IconButton(
      icon: Icon(icon, size: 20),
      color: iconColor,
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
