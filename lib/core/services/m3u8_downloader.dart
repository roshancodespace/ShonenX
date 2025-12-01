import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/utils/extractors.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class M3u8Downloader {
  final String m3u8Url;
  final String savePath;
  final String outputName;
  final Map<dynamic, dynamic>? headers;
  final int maxConcurrentSegments;
  final int retryAttempts;
  final Duration timeout;
  final Function(int received, int total, double speed, Duration eta)?
      onProgress;
  final Function(String message)? onStatusChanged;
  final CancelToken? cancelToken;

  M3u8Downloader({
    required this.m3u8Url,
    required this.savePath,
    required this.outputName,
    this.headers,
    this.maxConcurrentSegments = 3,
    this.retryAttempts = 3,
    this.timeout = const Duration(seconds: 10),
    this.onProgress,
    this.onStatusChanged,
    this.cancelToken,
  });

  final Dio _dio = Dio();
  late final CancelToken _cancelToken = cancelToken ?? CancelToken();
  bool _isCancelled = false;

  Future<void> download() async {
    try {
      _onStatus("Parsing M3U8 playlist...");
      final segments = await parseSegments(m3u8Url, headers: headers);

      if (segments.isEmpty) {
        throw Exception("No segments found in M3U8 playlist");
      }

      _onStatus("Found ${segments.length} segments. Preparing download...");

      final tempDir = Directory("$savePath/temp");
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      int totalSegments = segments.length;
      int downloadedSegments = 0;
      int totalBytes = 0; // Estimated
      int receivedBytes = 0;

      // Check for existing segments to resume
      for (var segment in segments) {
        final fileName = _getSegmentFileName(segment);
        final file = File("${tempDir.path}/$fileName");
        if (await file.exists()) {
          downloadedSegments++;
          receivedBytes += await file.length();
        }
      }

      // Estimate total size
      if (downloadedSegments < totalSegments) {
        try {
          // Try to get size of first segment for estimation
          final firstSegUrl = segments.first;
          final resp = await _dio.head(firstSegUrl,
              options: Options(headers: headers?.cast<String, dynamic>()));
          final segSize =
              int.tryParse(resp.headers.value('content-length') ?? '0') ?? 0;
          if (segSize > 0) {
            totalBytes = segSize * totalSegments;
          } else {
            totalBytes = totalSegments * 1024 * 1024; // 1MB fallback
          }
        } catch (_) {
          totalBytes = totalSegments * 1024 * 1024;
        }
      } else {
        totalBytes = receivedBytes;
      }

      if (totalBytes < receivedBytes) totalBytes = receivedBytes;

      _onProgress(receivedBytes, totalBytes, 0, Duration.zero);

      // Download Queue
      final queue = List<String>.from(segments);
      final activeDownloads = <Future>[];

      int lastTime = DateTime.now().millisecondsSinceEpoch;
      int lastBytes = receivedBytes;

      // Concurrency Loop
      while (queue.isNotEmpty || activeDownloads.isNotEmpty) {
        if (_isCancelled) {
          throw DioException(
              requestOptions: RequestOptions(), type: DioExceptionType.cancel);
        }

        // Fill queue up to maxConcurrentSegments
        while (queue.isNotEmpty &&
            activeDownloads.length < maxConcurrentSegments) {
          final segmentUrl = queue.removeAt(0);
          final future =
              _downloadSegmentWithRetry(segmentUrl, tempDir.path).then((bytes) {
            receivedBytes += bytes;
          });
          activeDownloads.add(future);

          // Remove from active list when done
          future.whenComplete(() {
            activeDownloads.remove(future);
          });
        }

        if (activeDownloads.isEmpty && queue.isEmpty) break;

        // Wait for at least one to finish or small delay
        await Future.any([
          ...activeDownloads,
          Future.delayed(const Duration(milliseconds: 200))
        ]);

        // Update Progress
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final timeDiff = currentTime - lastTime;

        if (timeDiff > 1000) {
          final bytesDiff = receivedBytes - lastBytes;
          final speed = (bytesDiff / (timeDiff / 1000)); // bytes per second

          final remainingBytes = totalBytes - receivedBytes;
          Duration eta = Duration.zero;
          if (speed > 0) {
            eta = Duration(seconds: (remainingBytes / speed).ceil());
          }

          _onProgress(receivedBytes, totalBytes, speed, eta);

          lastBytes = receivedBytes;
          lastTime = currentTime;
        }
      }

      // Final check
      if (_isCancelled) {
        throw DioException(
            requestOptions: RequestOptions(), type: DioExceptionType.cancel);
      }

      _onStatus("Merging segments...");
      await _mergeSegments(tempDir.path, savePath, outputName);

      _onStatus("Download complete");
      _onProgress(totalBytes, totalBytes, 0, Duration.zero);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        _onStatus("Download paused");
      } else {
        _onStatus("Download failed: $e");
        rethrow;
      }
    }
  }

  Future<int> _downloadSegmentWithRetry(String url, String tempDirPath) async {
    int attempts = 0;
    while (attempts < retryAttempts) {
      if (_isCancelled) return 0;
      try {
        return await _downloadSegment(url, tempDirPath);
      } catch (e) {
        attempts++;
        if (attempts >= retryAttempts) {
          AppLogger.e(
              "Failed to download segment $url after $attempts attempts: $e");
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    return 0;
  }

  Future<int> _downloadSegment(String url, String tempDirPath) async {
    final fileName = _getSegmentFileName(url);
    final savePath = "$tempDirPath/$fileName";
    final file = File(savePath);

    if (await file.exists()) {
      return await file.length();
    }

    await _dio.download(
      url,
      savePath,
      cancelToken: _cancelToken,
      options: Options(
        headers: {
          ...(headers ?? {}),
          'Connection': 'keep-alive',
        },
        receiveTimeout: timeout,
        sendTimeout: timeout,
      ),
    );

    return await file.length();
  }

  Future<void> _mergeSegments(
      String tempDirPath, String outputDir, String outputName) async {
    // Reuse logic from DownloadService or move it to a utility
    // For now, implementing it here to be self-contained or we can make it static in a Utils class

    final tempDir = Directory(tempDirPath);
    final tsFiles = tempDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(".ts"))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (tsFiles.isEmpty) return;

    final fileListPath = "$tempDirPath/segments.txt";
    final fileList = File(fileListPath);
    final sink = fileList.openWrite();
    for (var file in tsFiles) {
      sink.writeln("file '${file.path}'");
    }
    await sink.close();

    // Ensure output name has .mp4 extension if not present
    var finalName = outputName;
    if (!finalName.endsWith('.mp4')) {
      finalName += '.mp4';
    }

    final output = path.join(outputDir, finalName);

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final cmd = "-f concat -safe 0 -i '$fileListPath' -c copy '$output'";
      final session = await FFmpegKit.execute(cmd);
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        throw Exception("FFmpeg merge failed");
      }
    } else if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      final result = await Process.run('ffmpeg', [
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        fileListPath,
        '-c',
        'copy',
        output,
      ]);
      if (result.exitCode != 0) {
        throw Exception("FFmpeg merge failed: ${result.stderr}");
      }
    }

    await tempDir.delete(recursive: true);
  }

  String _getSegmentFileName(String url) {
    final parts = url.split('/').where((p) => p.isNotEmpty).toList();
    final file = parts.last;
    if (parts.length >= 2 && parts[parts.length - 2].contains("url_")) {
      final folder = parts[parts.length - 2];
      return "${folder}_$file";
    }
    return file;
  }

  void cancel() {
    _isCancelled = true;
    _cancelToken.cancel();
  }

  void _onStatus(String msg) {
    if (onStatusChanged != null) onStatusChanged!(msg);
  }

  void _onProgress(int received, int total, double speed, Duration eta) {
    if (onProgress != null) onProgress!(received, total, speed, eta);
  }
}
