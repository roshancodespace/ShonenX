import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/database/database_provider.dart';
import 'package:shonenx/features/downloads/domain/download_repository.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/engine/direct_download_engine.dart';
import 'package:shonenx/features/downloads/engine/download_engine.dart';

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

  void _launch(DownloadTask task) {
    final engine = _buildEngine(
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

  DownloadEngine _buildEngine({
    required DownloadTask task,
    required OnProgressCallback onProgress,
    required OnStatusCallback onStatus,
  }) {
    if (task.url.contains('.m3u8')) {
      throw UnimplementedError('HLS downloads are not yet supported');
    }
    return DirectDownloadEngine(
      task: task,
      onProgress: onProgress,
      onStatus: onStatus,
    );
  }
}
