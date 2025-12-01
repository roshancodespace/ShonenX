import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/view_model/downloads_notifier.dart';
import 'package:shonenx/storage_provider.dart';
import 'package:shonenx/core/services/m3u8_downloader.dart';

class DownloadService {
  final Ref ref;
  final StorageProvider _storageProvider = StorageProvider();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  final Map<String, CancelToken> _cancelTokens = {};

  DownloadService(this.ref);

  Dio getDio() => _dio;

  Future<void> downloadFile(DownloadItem item) async {
    if (item.downloadUrl.contains('.m3u8')) {
      await _downloadM3u8(item);
    } else {
      await _downloadStandard(item);
    }
  }

  Future<void> _downloadStandard(DownloadItem item) async {
    try {
      final dir = await _storageProvider.getDefaultDirectory();
      final downloadsNotifier = ref.read(downloadsProvider.notifier);
      if (dir == null) {
        downloadsNotifier
            .updateProgress(item.copyWith(state: DownloadStatus.failed));
        return;
      }
      await _storageProvider.requestPermission();

      int receivedBytes = 0;
      final file = File(item.filePath);
      if (await file.exists()) {
        receivedBytes = await file.length();
      }

      final cancelToken = CancelToken();
      _cancelTokens[item.filePath] = cancelToken;

      int lastBytes = 0;
      int lastTime = DateTime.now().millisecondsSinceEpoch;

      await _dio.download(
        item.downloadUrl,
        item.filePath,
        cancelToken: cancelToken,
        options: Options(
          headers:
              receivedBytes > 0 ? {'range': 'bytes=$receivedBytes-'} : null,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final totalSize = receivedBytes + total;
            final currentProgress = receivedBytes + received;
            final currentTime = DateTime.now().millisecondsSinceEpoch;
            final timeDiff = currentTime - lastTime;

            int speed = 0;
            Duration? eta;

            if (timeDiff > 1000) {
              final bytesDiff = currentProgress - lastBytes;
              speed = (bytesDiff / (timeDiff / 1000)).round();

              final remainingBytes = totalSize - currentProgress;
              if (speed > 0) {
                eta = Duration(seconds: remainingBytes ~/ speed);
              }

              lastBytes = currentProgress;
              lastTime = currentTime;
            }

            final progress = currentProgress / totalSize;

            if (timeDiff > 1000 || progress >= 1.0) {
              downloadsNotifier.updateProgress(item.copyWith(
                  progress: currentProgress,
                  size: totalSize,
                  speed: speed,
                  eta: eta,
                  state: progress >= 1.0
                      ? DownloadStatus.downloaded
                      : DownloadStatus.downloading));
            }
          }
        },
        deleteOnError: false,
      );
      _cancelTokens.remove(item.filePath);
    } catch (e) {
      _cancelTokens.remove(item.filePath);
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.w("Download paused");
      } else {
        ref
            .read(downloadsProvider.notifier)
            .updateProgress(item.copyWith(state: DownloadStatus.failed));
        rethrow;
      }
    }
  }

  Future<void> _downloadM3u8(DownloadItem item) async {
    final downloadsNotifier = ref.read(downloadsProvider.notifier);

    // Extract filename without extension for outputName
    final fileName = item.filePath.split('/').last;
    final outputName = fileName.endsWith('.mp4')
        ? fileName.substring(0, fileName.length - 4)
        : fileName;
    final saveDir = item.filePath.substring(0, item.filePath.lastIndexOf('/'));

    final cancelToken = CancelToken();
    _cancelTokens[item.filePath] = cancelToken;

    final downloader = M3u8Downloader(
      m3u8Url: item.downloadUrl,
      savePath: saveDir,
      outputName: outputName,
      headers: item.headers,
      cancelToken: cancelToken,
      onProgress: (received, total, speed, eta) {
        downloadsNotifier.updateProgress(item.copyWith(
          progress: received,
          size: total,
          speed: speed.toInt(),
          eta: eta,
          state: received >= total
              ? DownloadStatus.downloaded
              : DownloadStatus.downloading,
        ));
      },
      onStatusChanged: (msg) {
        AppLogger.i("Download Status [${item.episodeTitle}]: $msg");
      },
    );

    try {
      await downloader.download();

      _cancelTokens.remove(item.filePath);
    } catch (e) {
      _cancelTokens.remove(item.filePath);
      if (e is DioException && e.type == DioExceptionType.cancel) {
        AppLogger.w("Download paused");
      } else {
        ref
            .read(downloadsProvider.notifier)
            .updateProgress(item.copyWith(state: DownloadStatus.failed));
        rethrow;
      }
    }
  }

  void pauseDownload(DownloadItem item) {
    if (_cancelTokens.containsKey(item.filePath)) {
      _cancelTokens[item.filePath]?.cancel();
      _cancelTokens.remove(item.filePath);
    }
  }

  void resumeDownload(DownloadItem item) {
    downloadFile(item);
  }

  Future<void> deleteDownload(DownloadItem item) async {
    // Pause if downloading
    pauseDownload(item);

    final file = File(item.filePath);
    final dir = Directory(item.filePath);

    try {
      // Case 1: Path is a directory (e.g., temp folder or extracted m3u8 folder)
      if (await dir.exists() &&
          await dir
              .stat()
              .then((s) => s.type == FileSystemEntityType.directory)) {
        await dir.delete(recursive: true);
        AppLogger.w("Deleted folder: ${dir.path}");
      }
      // Case 2: Path is a file (single .mp4 or .ts or m3u8)
      else if (await file.exists()) {
        await file.delete();
        AppLogger.w("Deleted file: ${file.path}");
      }
    } catch (e) {
      AppLogger.e("Failed to delete download: $e");
    }

    // Remove from download provider
    ref.read(downloadsProvider.notifier).removeDownload(item);
  }
}
