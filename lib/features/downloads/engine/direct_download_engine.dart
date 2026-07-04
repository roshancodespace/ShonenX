import 'dart:io';

import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/engine/download_engine.dart';

class DirectDownloadEngine implements DownloadEngine {
  final DownloadTask task;
  final OnProgressCallback onProgress;
  final OnStatusCallback onStatus;

  final HttpClient _client = HttpClient();
  bool _cancelled = false;
  bool _paused = false;
  bool _isRunning = false;

  DirectDownloadEngine({
    required this.task,
    required this.onProgress,
    required this.onStatus,
  });

  @override
  Future<void> start() async {
    _isRunning = true;
    _paused = false;

    onStatus(DownloadStatus.downloading);

    RandomAccessFile? fileHandle;
    bool hasError = false;
    bool isCompleted = false;

    try {
      final file = File(task.savePath);
      int downloaded = await file.exists() ? await file.length() : 0;

      final request = await _client.getUrl(Uri.parse(task.url));
      if (task.headersMap.isNotEmpty) {
        task.headersMap.forEach((key, value) {
          request.headers.set(key, value);
        });
      }
      if (downloaded > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$downloaded-');
      }

      final response = await request.close();

      // 416 = Range Not Satisfiable → file already fully downloaded
      if (response.statusCode == 416) {
        isCompleted = true;
        return;
      }

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw HttpException('Unexpected status: ${response.statusCode}');
      }

      final contentLength = response.contentLength;
      final total = contentLength == -1 ? -1 : downloaded + contentLength;

      fileHandle = await file.open(mode: FileMode.append);
      int lastDbWrite = 0;

      await for (final chunk in response) {
        if (_cancelled || _paused) break;

        await fileHandle.writeFrom(chunk);
        downloaded += chunk.length;

        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastDbWrite > 500) {
          lastDbWrite = now;
          onProgress(
            downloadedBytes: downloaded,
            totalBytes: total,
            downloadedSegments: 0,
            totalSegments: 0,
            progress: total > 0 ? downloaded / total : -1.0,
          );
        }
      }

      if (!_cancelled && !_paused) {
        isCompleted = true;
        onProgress(
          downloadedBytes: downloaded,
          totalBytes: total > 0 ? total : downloaded,
          downloadedSegments: 0,
          totalSegments: 0,
          progress: 1.0,
        );
      }
    } catch (e) {
      if (!_cancelled && !_paused) {
        hasError = true;
      }
    } finally {
      await fileHandle?.close();
      _client.close(force: true);

      if (_cancelled) {
        final file = File(task.savePath);
        if (await file.exists()) await file.delete();
        onStatus(DownloadStatus.canceled);
      } else if (_paused) {
        onStatus(DownloadStatus.paused);
      } else if (hasError) {
        onStatus(DownloadStatus.failed);
      } else if (isCompleted) {
        onStatus(DownloadStatus.completed);
      }

      _isRunning = false;
    }
  }

  @override
  Future<void> pause() async {
    _paused = true;
    _client.close(force: true);
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
    _client.close(force: true);

    if (!_isRunning) {
      final file = File(task.savePath);
      if (await file.exists()) {
        await file.delete();
      }
      onStatus(DownloadStatus.canceled);
    }
  }
}
