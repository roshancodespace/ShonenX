import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/database/database_provider.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/http_x.dart';
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

  DownloadRepository get repo => ref.read(downloadRepositoryProvider);

  @override
  Future<DownloadManagerNotifier> build() async {
    final resumable = await repo.getPendingOrPausedTasks();
    for (final task in resumable) {
      _launch(task);
    }
    return this;
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

    // Deduplicate by URL
    final existing = await repo.getTaskByUrl(task.url);
    if (existing != null) {
      if (existing.status == DownloadStatus.downloading ||
          existing.status == DownloadStatus.pending) {
        return; // already running
      }
      // Re-queue a paused / failed task
      existing.status = DownloadStatus.pending;
      existing.updatedAt = DateTime.now();
      await repo.putTask(existing);
      _launch(existing);
      return;
    }

    // Brand new task
    task.status = DownloadStatus.pending;
    task.createdAt = DateTime.now();
    task.updatedAt = DateTime.now();
    await repo.putTask(task);
    _launch(task);
  }

  Future<void> pauseDownload(int taskId) async {
    await _activeEngines[taskId]?.pause();
  }

  Future<void> cancelDownload(int taskId) async {
    await _activeEngines[taskId]?.cancel();
    _activeEngines.remove(taskId);
  }

  Future<void> _launch(DownloadTask task) async {
    final engine = await _buildEngine(
      task: task,
      onProgress:
          ({
            required int downloadedBytes,
            required int totalBytes,
            required double progress,
          }) async {
            task.downloadedBytes = downloadedBytes;
            task.totalBytes = totalBytes;
            task.progress = progress;
            task.updatedAt = DateTime.now();
            await repo.putTask(task);
          },
      onStatus: (DownloadStatus status) async {
        task.status = status;
        task.updatedAt = DateTime.now();
        await repo.putTask(task);

        if (status == DownloadStatus.completed ||
            status == DownloadStatus.failed ||
            status == DownloadStatus.canceled) {
          _activeEngines.remove(task.id);
          await repo.deleteTask(task.id);
        }
      },
    );

    _activeEngines[task.id] = engine;
    engine.start();
  }

  Future<DownloadEngine> _buildEngine({
    required DownloadTask task,
    required OnProgressCallback onProgress,
    required OnStatusCallback onStatus,
  }) async {
    final isHLS = await ref
        .read(httpClientProvider)
        .isHLS(task.url, headers: task.headersMap);
    if (isHLS) {
      return M3U8DownloadEngine(
        task: task,
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
