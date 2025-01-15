import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadService {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> downloadFile(String url, String filename, Function(int, int) onProgress) async {
    try {
      _cancelToken = CancelToken();

      final hasPermission = await _requestPermission();
      if (!hasPermission) {
        throw Exception("Storage permission denied");
      }

      final dir = Directory('/storage/emulated/0/Download/ShonenX');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final savePath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}_$filename";

      await _dio.download(
        url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received, total);
          }
        },
      );

      debugPrint('Download complete: $savePath');
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('Download cancelled');
      } else {
        debugPrint('Download failed: $e');
        rethrow;
      }
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel('Download cancelled by user');
    _cancelToken = null;
  }
}
