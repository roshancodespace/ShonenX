import 'package:isar_community/isar.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';

class DownloadRepository {
  final Isar _isar;

  DownloadRepository(this._isar);

  Future<void> putTask(DownloadTask task) async {
    task.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.downloadTasks.put(task);
    });
  }

  Future<void> deleteTask(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.downloadTasks.delete(id);
    });
  }

  Future<DownloadTask?> getTaskByUrl(String url) async {
    return await _isar.downloadTasks.getByUrl(url);
  }

  Future<DownloadTask?> getTaskById(Id id) async {
    return await _isar.downloadTasks.get(id);
  }

  Future<List<DownloadTask>> getPendingOrPausedTasks() async {
    return await _isar.downloadTasks
        .filter()
        .statusBetween(DownloadStatus.pending, DownloadStatus.paused)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<List<DownloadTask>> getUnfinishedTasks() async {
    return await _isar.downloadTasks
        .filter()
        .not()
        .statusEqualTo(DownloadStatus.completed)
        .findAll();
  }

  Stream<List<DownloadTask>> watchAllTasks() {
    return _isar.downloadTasks.where().sortByCreatedAtDesc().watch(
      fireImmediately: true,
    );
  }
}
