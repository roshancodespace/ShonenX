import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/http_x.dart';
import 'package:shonenx/core/services/notification_service.dart';
import 'package:shonenx/core/services/one_dm_service.dart';
import 'package:shonenx/features/downloads/domain/download_repository.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/engine/direct_download_engine.dart';
import 'package:shonenx/features/downloads/engine/download_engine.dart';
import 'package:shonenx/features/downloads/engine/m3u8_download_engine.dart';
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepository(ref.watch(databaseProvider));
});

final downloadTasksProvider = StreamProvider<List<DownloadTask>>((ref) {
  return ref.watch(downloadRepositoryProvider).watchAllTasks();
});

final downloadManagerProvider =
    AsyncNotifierProvider<DownloadManagerNotifier, DownloadManagerNotifier>(
      DownloadManagerNotifier.new,
    );

class DownloadManagerNotifier extends AsyncNotifier<DownloadManagerNotifier> {
  final Map<int, DownloadEngine> _activeEngines = {};
  final Set<int> _launchingIds = {};
  final Set<int> _cancelledTaskIds = {};
  bool _isProcessingQueue = false;

  DownloadRepository get repo => ref.read(downloadRepositoryProvider);

  @override
  Future<DownloadManagerNotifier> build() async {
    final unfinished = await repo.getUnfinishedTasks();
    for (final t in unfinished) {
      if (t.status == DownloadStatus.downloading) {
        t.status = DownloadStatus.pending;
        await repo.putTask(t);
      }
    }
    _processQueue();
    return this;
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    try {
      final prefs = await ref.read(downloadPrefsProvider.future);

      while (_activeEngines.length + _launchingIds.length <
          prefs.concurrentDownloads) {
        final allTasks = await repo.getPendingOrPausedTasks();
        final pending = allTasks
            .where((t) => t.status == DownloadStatus.pending)
            .toList();

        DownloadTask? nextTask;
        for (final task in pending) {
          if (!_activeEngines.containsKey(task.id) &&
              !_launchingIds.contains(task.id) &&
              !_cancelledTaskIds.contains(task.id)) {
            nextTask = task;
            break;
          }
        }

        if (nextTask == null) break;

        _launchingIds.add(nextTask.id);
        _launch(nextTask).whenComplete(() {
          _launchingIds.remove(nextTask?.id);
        });
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> startDownload(DownloadTask task) async {
    final prefs = await ref.read(downloadPrefsProvider.future);

    if (prefs.useOneDM) {
      final success = await OneDMService.instance.download(
        url: task.url,
        fileName: task.fileName,
        headers: Map.fromEntries(
          task.headers.map((header) => header.toMapEntry()),
        ),
      );
      if (success) return;
    }

    _cancelledTaskIds.remove(task.id);

    // Check if file already exists at the target path
    final file = File(task.savePath);
    if (await file.exists()) {
      if (prefs.duplicateAction == DuplicateAction.skip) {
        return; // Skip adding the task
      } else if (prefs.duplicateAction == DuplicateAction.overwrite) {
        await file.delete();
      }
    }

    // Deduplicate by URL
    final existing = await repo.getTaskByUrl(task.url);
    if (existing != null) {
      _cancelledTaskIds.remove(existing.id);
      if ((existing.status == DownloadStatus.downloading ||
              existing.status == DownloadStatus.pending) &&
          (_activeEngines.containsKey(existing.id) ||
              _launchingIds.contains(existing.id))) {
        return; // already running or queueing
      }

      // Re-queue a paused / failed task
      existing.status = DownloadStatus.pending;
      existing.updatedAt = DateTime.now();
      await repo.putTask(existing);
      _processQueue();
      return;
    }

    // Brand new task
    task.status = DownloadStatus.pending;
    task.createdAt = DateTime.now();
    task.updatedAt = DateTime.now();
    await repo.putTask(task);
    _processQueue();
  }

  Future<void> pauseDownload(int taskId) async {
    final engine = _activeEngines[taskId];
    _activeEngines.remove(taskId);
    _launchingIds.remove(taskId);

    if (engine != null) {
      await engine.pause();
    } else {
      final task = await repo.getTaskById(taskId);
      if (task != null &&
          (task.status == DownloadStatus.pending ||
              task.status == DownloadStatus.downloading)) {
        task.status = DownloadStatus.paused;
        await repo.putTask(task);
      }
    }
    await NotificationService.instance.cancelDownloadNotification(taskId);
    _processQueue(); // Start next in queue if available
  }

  Future<void> cancelDownload(int taskId) async {
    _cancelledTaskIds.add(taskId);
    final engine = _activeEngines[taskId];
    _activeEngines.remove(taskId);
    _launchingIds.remove(taskId);

    if (engine != null) {
      try {
        await engine.cancel();
      } catch (_) {}
    }
    await NotificationService.instance.cancelDownloadNotification(taskId);

    final task = await repo.getTaskById(taskId);
    if (task != null) {
      try {
        final f = File(task.savePath);
        if (await f.exists()) await f.delete();
        final temp = File('${task.savePath}.part');
        if (await temp.exists()) await temp.delete();
        final tempDir = Directory(
          '${p.dirname(task.savePath)}/.temp_${task.id}',
        );
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      } catch (_) {}
      await repo.deleteTask(taskId);
    } else {
      await repo.deleteTask(taskId);
    }
    _processQueue(); // Start next in queue if available
  }

  Future<void> _launch(DownloadTask task) async {
    if (_cancelledTaskIds.contains(task.id) ||
        _activeEngines.containsKey(task.id)) {
      return;
    }

    final notif = NotificationService.instance;
    final notifTitle = task.fileName.isNotEmpty
        ? task.fileName
        : 'Episode ${task.episodeNumber}';

    // Show an indeterminate bar immediately so the user gets feedback
    await notif.showDownloadProgress(
      id: task.id,
      title: notifTitle,
      progress: -1,
    );

    if (_cancelledTaskIds.contains(task.id)) {
      await notif.cancelDownloadNotification(task.id);
      return;
    }

    final engine = await _buildEngine(
      task: task,
      onProgress:
          ({
            required int downloadedBytes,
            required int totalBytes,
            int? downloadedSegments,
            int? totalSegments,
            required double progress,
          }) async {
            if (_cancelledTaskIds.contains(task.id) ||
                !_activeEngines.containsKey(task.id)) {
              return;
            }
            task.downloadedBytes = downloadedBytes;
            task.totalBytes = totalBytes;
            if (downloadedSegments != null) {
              task.downloadedSegments = downloadedSegments;
            }
            if (totalSegments != null) {
              task.totalSegments = totalSegments;
            }
            task.progress = progress;
            task.updatedAt = DateTime.now();
            if (!_cancelledTaskIds.contains(task.id) &&
                _activeEngines.containsKey(task.id)) {
              await repo.putTask(task);
            }

            // only update notification every 2 %
            final pct = (progress * 100).toInt();
            if (pct % 2 == 0 && !_cancelledTaskIds.contains(task.id)) {
              await notif.showDownloadProgress(
                id: task.id,
                title: notifTitle,
                progress: progress,
              );
            }
          },
      onStatus: (DownloadStatus status) async {
        if (_cancelledTaskIds.contains(task.id)) {
          _activeEngines.remove(task.id);
          _launchingIds.remove(task.id);
          await notif.cancelDownloadNotification(task.id);
          await repo.deleteTask(task.id);
          return;
        }

        switch (status) {
          case DownloadStatus.completed:
            await notif.showDownloadComplete(id: task.id, title: notifTitle);
            _activeEngines.remove(task.id);
            _launchingIds.remove(task.id);
            await repo.deleteTask(task.id);
            _processQueue();
            break;
          case DownloadStatus.failed:
            task.status = DownloadStatus.failed;
            task.updatedAt = DateTime.now();
            await repo.putTask(task);
            await notif.showDownloadFailed(id: task.id, title: notifTitle);
            _activeEngines.remove(task.id);
            _launchingIds.remove(task.id);
            _processQueue();
            break;
          case DownloadStatus.canceled:
            await notif.cancelDownloadNotification(task.id);
            _activeEngines.remove(task.id);
            _launchingIds.remove(task.id);
            await repo.deleteTask(task.id);
            _processQueue();
            break;
          case DownloadStatus.paused:
            task.status = DownloadStatus.paused;
            task.updatedAt = DateTime.now();
            await repo.putTask(task);
            await notif.cancelDownloadNotification(task.id);
            _activeEngines.remove(task.id);
            _launchingIds.remove(task.id);
            _processQueue();
            break;
          default:
            break;
        }
      },
    );

    if (_cancelledTaskIds.contains(task.id)) {
      await engine.cancel();
      return;
    }

    _activeEngines[task.id] = engine;
    engine.start();
  }

  Future<DownloadEngine> _buildEngine({
    required DownloadTask task,
    required OnProgressCallback onProgress,
    required OnStatusCallback onStatus,
  }) async {
    final isHLS =
        task.isM3u8 ||
        await ref
            .read(httpClientProvider)
            .isHLS(task.url, headers: task.headersMap);

    if (isHLS && !task.isM3u8) {
      task.isM3u8 = true;
      await repo.putTask(task);
    }

    if (isHLS) {
      final prefs = await ref.read(downloadPrefsProvider.future);
      return M3U8DownloadEngine(
        task: task,
        concurrentSegments: prefs.concurrentSegments,
        remuxerPreference: prefs.remuxerPreference,
        onProgress: onProgress,
        onStatus: onStatus,
      );
    }
    return DirectDownloadEngine(
      task: task,
      onProgress: onProgress,
      onStatus: onStatus,
    );
  }
}
