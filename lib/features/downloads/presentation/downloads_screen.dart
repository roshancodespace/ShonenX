import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
import 'package:shonenx/core/services/one_dm_service.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

sealed class OfflineItem {
  final String name;
  const OfflineItem(this.name);
}

class OfflineFile extends OfflineItem {
  final File file;
  final int sizeBytes;
  const OfflineFile(super.name, this.file, this.sizeBytes);
}

class OfflineFolder extends OfflineItem {
  final Directory directory;
  final List<OfflineFile> files;
  final int totalSizeBytes;
  const OfflineFolder(
    super.name,
    this.directory,
    this.files,
    this.totalSizeBytes,
  );
}

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

class _DownloadTile extends ConsumerStatefulWidget {
  final DownloadTask task;
  const _DownloadTile({required this.task});

  @override
  ConsumerState<_DownloadTile> createState() => _DownloadTileState();
}

class _DownloadTileState extends ConsumerState<_DownloadTile> {
  int _lastBytes = 0;
  DateTime _lastTime = DateTime.now();
  double _speedBps = 0.0;

  @override
  void didUpdateWidget(covariant _DownloadTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.status != DownloadStatus.downloading) {
      _speedBps = 0.0;
      return;
    }
    final now = DateTime.now();
    final diff = now.difference(_lastTime);
    if (diff.inSeconds >= 1) {
      final bytesDiff = widget.task.downloadedBytes - _lastBytes;
      if (bytesDiff >= 0) {
        _speedBps = bytesDiff / diff.inSeconds;
      }
      _lastBytes = widget.task.downloadedBytes;
      _lastTime = now;
    } else if (widget.task.downloadedBytes < _lastBytes) {
      // Reset if task restarted
      _lastBytes = widget.task.downloadedBytes;
      _lastTime = now;
    }
  }

  @override
  void initState() {
    super.initState();
    _lastBytes = widget.task.downloadedBytes;
    _lastTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = task.status;
    final isDone = status == DownloadStatus.completed;
    final isCanceled = status == DownloadStatus.canceled;
    final isFailed = status == DownloadStatus.failed;

    return InkWell(
      onTap: isFailed ? () => _showErrorDetailsSheet(context, ref, task) : null,
      borderRadius: BorderRadius.circular(8),
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
                    size: 24,
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
                      color: isFailed ? colors.error : colors.onSurfaceVariant,
                      fontWeight: isFailed ? FontWeight.w500 : null,
                    ),
                  ),
                  if (isFailed &&
                      task.errorReason != null &&
                      task.errorReason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showErrorDetailsSheet(context, ref, task),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.errorContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 13,
                              color: colors.error,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                task.errorReason!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: colors.error,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
            if (isDone)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _IconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: colors.error,
                    onPressed: () => ref
                        .read(downloadManagerProvider.notifier)
                        .cancelDownload(task.id),
                  ),
                ],
              )
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
                  if (status == DownloadStatus.failed)
                    _IconBtn(
                      icon: Icons.refresh_rounded,
                      color: colors.primary,
                      onPressed: () => ref
                          .read(downloadManagerProvider.notifier)
                          .startDownload(task),
                    )
                  else if (status == DownloadStatus.paused ||
                      status == DownloadStatus.canceled)
                    _IconBtn(
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => ref
                          .read(downloadManagerProvider.notifier)
                          .startDownload(task),
                    ),
                  const SizedBox(width: 4),
                  _IconBtn(
                    icon: Icons.close_rounded,
                    color: colors.error,
                    onPressed: () => ref
                        .read(downloadManagerProvider.notifier)
                        .cancelDownload(task.id),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showErrorDetailsSheet(
    BuildContext context,
    WidgetRef ref,
    DownloadTask task,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final error = task.errorReason?.trim() ?? 'Unknown error occurred.';

    final isRateLimit =
        error.toLowerCase().contains('429') ||
        error.toLowerCase().contains('rate limit') ||
        error.toLowerCase().contains('throttl');
    final isForbidden =
        error.toLowerCase().contains('403') ||
        error.toLowerCase().contains('forbidden') ||
        error.toLowerCase().contains('expired');
    final isNetwork =
        error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('connection') ||
        error.toLowerCase().contains('timeout') ||
        error.toLowerCase().contains('socket');

    AppBottomSheet.show(
      context: context,
      title: 'Download Interrupted',
      titleIcon: Icons.warning_amber_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // File Name Header
          Text(
            task.fileName.isNotEmpty
                ? task.fileName
                : 'Episode ${task.episodeNumber}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Preserved Data Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress Preserved (${(task.progress * 100).toStringAsFixed(1)}%)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Downloaded segments (${_mb(task.downloadedBytes)} MB) are kept safely on disk. Resuming will pick up where it stopped without restarting from 0%.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Error Diagnosis Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.errorContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason for Failure',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.error,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        error,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Suggested Resolution
          Text(
            'Recommended Resolution',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (isRateLimit) ...[
            _resolutionBullet(
              context,
              'Server Throttling (HTTP 429)',
              'The video host blocked requests because too many segments downloaded simultaneously. Wait a few seconds, then tap Resume.',
            ),
            _resolutionBullet(
              context,
              'Lower Concurrency',
              'Go to Settings → Downloads and reduce "Concurrent Downloads" or "Concurrent Segments" to prevent triggering CDN rate limits.',
            ),
          ] else if (isForbidden) ...[
            _resolutionBullet(
              context,
              'Expired Stream URL (HTTP 403)',
              'The stream link or access token has expired. Tap Resume to attempt auto-refresh, or re-open the episode player to get fresh links.',
            ),
          ] else if (isNetwork) ...[
            _resolutionBullet(
              context,
              'Connection Interrupted',
              'The connection dropped or timed out. Verify your Wi-Fi or mobile data connection and tap Resume.',
            ),
          ] else ...[
            _resolutionBullet(
              context,
              'Resume Stream',
              'Tap Resume Download below to retry connecting and download remaining segments.',
            ),
          ],
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Resume Download'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref
                        .read(downloadManagerProvider.notifier)
                        .startDownload(task);
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (Platform.isAndroid) ...[
                IconButton.filledTonal(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  tooltip: 'Download via 1DM',
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await OneDMService.instance.download(
                      url: task.url,
                      fileName: task.fileName,
                      headers: task.headersMap,
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              IconButton.outlined(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: colors.error,
                ),
                tooltip: 'Cancel & Delete',
                onPressed: () {
                  Navigator.of(context).pop();
                  ref
                      .read(downloadManagerProvider.notifier)
                      .cancelDownload(task.id);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _resolutionBullet(BuildContext context, String title, String body) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(DownloadStatus s) => switch (s) {
    DownloadStatus.completed => Icons.check_circle_outline_rounded,
    DownloadStatus.failed => Icons.error_outline_rounded,
    DownloadStatus.paused => Icons.play_arrow_outlined,
    DownloadStatus.canceled => Icons.cancel_outlined,
    _ => Icons.pause,
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
    final task = widget.task;
    final name =
        task.status.name[0].toUpperCase() + task.status.name.substring(1);
    if (task.status == DownloadStatus.completed) {
      final segText = task.totalSegments > 0
          ? ' (${task.totalSegments} seg)'
          : '';
      return '$name · ${_mb(task.totalBytes > 0 ? task.totalBytes : task.downloadedBytes)} MB$segText';
    }
    if (task.status == DownloadStatus.failed) {
      final pct = (task.progress * 100).toStringAsFixed(0);
      final mbText = task.totalBytes > 0
          ? '${_mb(task.downloadedBytes)}/${_mb(task.totalBytes)} MB'
          : '${_mb(task.downloadedBytes)} MB';
      return 'Failed ($pct% · $mbText saved) · Tap for details';
    }
    if (task.status == DownloadStatus.canceled) {
      return name;
    }
    final isHls =
        task.isM3u8 || task.url.contains('.m3u8') || task.totalSegments > 0;
    if (isHls && task.totalSegments > 0) {
      final pct = (task.progress * 100).toStringAsFixed(0);
      final totalMb = task.totalBytes > 0 ? '/${_mb(task.totalBytes)}' : '';
      return '$name · $pct% (${task.downloadedSegments}/${task.totalSegments} seg) · ${_mb(task.downloadedBytes)}$totalMb MB $_etaText';
    }
    if (task.totalBytes > 0) {
      final pct = (task.progress * 100).toStringAsFixed(0);
      return '$name · $pct% · ${_mb(task.downloadedBytes)}/${_mb(task.totalBytes)} MB $_etaText';
    }
    return '$name · ${_mb(task.downloadedBytes)} MB $_etaText';
  }

  String get _etaText {
    if (widget.task.status != DownloadStatus.downloading || _speedBps <= 0) {
      return '';
    }
    if (widget.task.totalBytes > 0) {
      final remainingBytes =
          widget.task.totalBytes - widget.task.downloadedBytes;
      if (remainingBytes <= 0) {
        return '· ${_formatSpeed(_speedBps)}';
      }
      final seconds = remainingBytes / _speedBps;
      if (seconds.isInfinite || seconds.isNaN) {
        return '· ${_formatSpeed(_speedBps)}';
      }
      return '· ${_formatSpeed(_speedBps)} · ${_formatDuration(Duration(seconds: seconds.toInt()))}';
    }
    return '· ${_formatSpeed(_speedBps)}';
  }

  String _formatSpeed(double speedBps) {
    if (speedBps >= 1024 * 1024) {
      return '${(speedBps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else if (speedBps >= 1024) {
      return '${(speedBps / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${speedBps.toInt()} B/s';
    }
  }

  String _formatDuration(Duration d) {
    final parts = <String>[];
    if (d.inHours > 0) parts.add('${d.inHours}h');
    if (d.inMinutes.remainder(60) > 0) {
      parts.add('${d.inMinutes.remainder(60)}m');
    }
    parts.add('${d.inSeconds.remainder(60)}s');
    return parts.join(' ');
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
  late Future<List<OfflineItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _getItems();
  }

  Future<List<OfflineItem>> _getItems() async {
    final prefs = await ref.read(downloadPrefsProvider.future);
    final dir = Directory(prefs.downloadPath);
    if (!await dir.exists()) return [];

    final items = <OfflineItem>[];
    final entities = await dir.list().toList();

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.mp4')) {
        final name = entity.path.split('/').last.replaceAll('.mp4', '');
        items.add(OfflineFile(name, entity, await entity.length()));
      } else if (entity is Directory) {
        final subEntities = await entity.list(recursive: true).toList();
        final files = <OfflineFile>[];
        int totalSize = 0;

        for (final sub in subEntities) {
          if (sub is File && sub.path.endsWith('.mp4')) {
            final name = sub.path.split('/').last.replaceAll('.mp4', '');
            final size = await sub.length();
            files.add(OfflineFile(name, sub, size));
            totalSize += size;
          }
        }

        if (files.isNotEmpty) {
          files.sort((a, b) => a.name.compareTo(b.name));
          final name = entity.path.split('/').last;
          items.add(OfflineFolder(name, entity, files, totalSize));
        }
      }
    }

    items.sort((a, b) {
      if (a is OfflineFolder && b is OfflineFile) return -1;
      if (a is OfflineFile && b is OfflineFolder) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return items;
  }

  void _openFile(File file) {
    final name = file.path.split('/').last.replaceAll('.mp4', '');
    context.pushPlayer(PlayerModeOffline(filePath: file.path, title: name));
  }

  Future<void> _openExternal(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  void _showDeleteSheet({
    required BuildContext context,
    required String title,
    required String message,
    required Future<void> Function() onDelete,
  }) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) {
        return AppBottomSheet(
          title: title,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.error,
                        foregroundColor: colors.onError,
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await onDelete();
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteFile(BuildContext context, OfflineFile item) {
    _showDeleteSheet(
      context: context,
      title: 'Delete Episode?',
      message: 'This will permanently remove ${item.name}.',
      onDelete: () async {
        await item.file.delete();
        setState(() {
          _itemsFuture = _getItems();
        });
      },
    );
  }

  void _confirmDeleteFolder(BuildContext context, OfflineFolder item) {
    _showDeleteSheet(
      context: context,
      title: 'Delete Folder?',
      message:
          'This will permanently remove all ${item.files.length} episodes in ${item.name}.',
      onDelete: () async {
        await item.directory.delete(recursive: true);
        setState(() {
          _itemsFuture = _getItems();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FutureBuilder<List<OfflineItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.video_library_outlined,
            title: 'No downloaded files',
            subtitle: 'Downloaded episodes will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80, top: 8),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];

            if (item is OfflineFolder) {
              final sizeStr = (item.totalSizeBytes / (1024 * 1024))
                  .toStringAsFixed(1);
              return Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: Icon(
                    Icons.folder_open_rounded,
                    color: colors.primary,
                    size: 28,
                  ),
                  title: Text(
                    item.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${item.files.length} episodes · $sizeStr MB',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.only(left: 16),
                  children: [
                    for (final fileItem in item.files)
                      _buildFileTile(context, fileItem, theme, colors),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _confirmDeleteFolder(context, item),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete Folder'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            } else if (item is OfflineFile) {
              return _buildFileTile(context, item, theme, colors);
            }
            return const SizedBox();
          },
        );
      },
    );
  }

  Widget _buildFileTile(
    BuildContext context,
    OfflineFile item,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final sizeStr = (item.sizeBytes / (1024 * 1024)).toStringAsFixed(1);

    return InkWell(
      onTap: () => _openFile(item.file),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
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
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$sizeStr MB',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: colors.onSurfaceVariant,
                size: 20,
              ),
              onSelected: (val) {
                if (val == 'play') _openFile(item.file);
                if (val == 'external') _openExternal(item.file);
                if (val == 'delete') _confirmDeleteFile(context, item);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'play',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Play in ShonenX'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'external',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Play Externally'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: colors.error,
                      ),
                      const SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: colors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
