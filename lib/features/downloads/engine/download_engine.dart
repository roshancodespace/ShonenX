import 'package:shonenx/features/downloads/domain/models/download_task.dart';

typedef OnProgressCallback = void Function({
  required int downloadedBytes,
  required int totalBytes,
  required double progress,
});

typedef OnStatusCallback = void Function(DownloadStatus status);

abstract class DownloadEngine {
  Future<void> start();
  Future<void> pause();
  Future<void> cancel();
}
