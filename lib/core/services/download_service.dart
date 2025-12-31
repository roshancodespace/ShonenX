// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/downloads/view_model/downloads_notifier.dart';
import 'package:shonenx/features/settings/model/download_settings_model.dart';
import 'package:shonenx/features/settings/view_model/download_settings_notifier.dart';
import 'package:shonenx/storage_provider.dart';

class DownloadService {
  final Ref ref;
  final Map<String, SimpleCancelToken> _cancelTokens = {};

  DownloadService(this.ref);

  DownloadSettingsModel get _settings => ref.read(downloadSettingsProvider);

  DownloadNotifier get _notifier => ref.read(downloadsProvider.notifier);

  Future<void> startDownload(DownloadItem item) async {
    // Ensure storage permissions
    if (!_settings.useCustomPath || _settings.customDownloadPath == null) {
      if (!await StorageProvider().requestPermission()) {
        return _fail(item, 'Storage permission denied');
      }
    }

    // Resolve content type if missing
    if (item.contentType == null) {
      item = await _resolveType(item);
    }

    final token = SimpleCancelToken();
    _cancelTokens[item.filePath] = token;

    try {
      if (item.isM3U8) {
        AppLogger.i('Downloading M3U8: ${item.downloadUrl}');
        await _downloadM3U8(item, token);
      } else {
        AppLogger.i('Downloading File: ${item.downloadUrl}');
        await _downloadFile(item, token);
      }
      _cancelTokens.remove(item.filePath);
    } catch (e) {
      if (token.isCancelled) {
        _notifier
            .updateDownloadState(item.copyWith(state: DownloadStatus.paused));
      } else {
        _fail(item, e.toString());
      }
    }
  }

  Future<DownloadItem> _resolveType(DownloadItem item) async {
    try {
      final res = await http.head(Uri.parse(item.downloadUrl),
          headers: item.headers.cast<String, String>());

      var contentType = res.headers['content-type'];

      // If generic stream or null, try to guess from extension
      if (contentType == null || contentType == 'application/octet-stream') {
        final uri = Uri.parse(item.downloadUrl);
        final path = uri.path.toLowerCase();
        if (path.endsWith('.mp4')) {
          contentType = 'video/mp4';
        } else if (path.endsWith('.mkv')) {
          contentType = 'video/x-matroska';
        } else if (path.endsWith('.m3u8')) {
          contentType = 'application/vnd.apple.mpegurl'; // Usual m3u8 mime
        }
      }

      if (contentType != null) {
        return item.copyWith(contentType: contentType);
      }
    } catch (_) {}
    return item;
  }

  Future<void> _downloadFile(DownloadItem item, SimpleCancelToken token) async {
    final file = File(item.filePath);
    await file.parent.create(recursive: true);

    final req = http.Request('GET', Uri.parse(item.downloadUrl));
    req.headers.addAll(item.headers.cast<String, String>());

    final existingSize = await file.exists() ? await file.length() : 0;
    if (existingSize > 0) req.headers['Range'] = 'bytes=$existingSize-';

    final client = http.Client();
    token.addListener(() => client.close());

    try {
      final res = await client.send(req);
      // Accept 200 and 206
      if (res.statusCode >= 400) throw Exception('HTTP ${res.statusCode}');

      int total = existingSize;

      bool isResume = false;
      if (res.statusCode == 206) {
        isResume = true;
        final contentRange = res.headers['content-range'];
        if (contentRange != null) {
          final totalStr = contentRange.split('/').last;
          if (totalStr != '*') {
            total = int.tryParse(totalStr) ?? 0;
          }
        }
      }

      if (res.statusCode == 200) {
        isResume = false;
        total = int.tryParse(res.headers['content-length'] ?? '') ?? 0;
      } else if (total == 0) {
        total = (int.tryParse(res.headers['content-length'] ?? '') ?? 0) +
            existingSize;
      }

      var current = isResume ? existingSize : 0;
      final sink =
          file.openWrite(mode: isResume ? FileMode.append : FileMode.write);

      var downloadingItem = item.copyWith(
          state: DownloadStatus.downloading,
          size: total > 0 ? total : null,
          totalSegments: null);

      _notifier.updateDownloadState(downloadingItem);

      try {
        await for (final chunk in res.stream) {
          if (token.isCancelled) {
            throw Exception('Cancelled');
          }
          sink.add(chunk);
          current += chunk.length;
          if (!token.isCancelled) {
            downloadingItem = downloadingItem.copyWith(progress: current);
            _notifier.updateDownloadState(downloadingItem);
          }
        }
      } finally {
        await sink.close();
      }

      // Integrity Check
      if (total > 0 && current < total) {
        if (!token.isCancelled)
          throw Exception('Download incomplete: $current / $total');
      }

      if (!token.isCancelled)
        _notifier.updateDownloadState(
            downloadingItem.copyWith(state: DownloadStatus.downloaded));
    } catch (e) {
      // If cancelled, likely ClientException or explicit Cancelled.
      if (!token.isCancelled) rethrow;
      throw Exception('Cancelled');
    } finally {
      client.close();
    }
  }

  Future<http.Response> _getWithRetry(Uri uri, Map<String, String> headers,
      {http.Client? client}) async {
    int retries = 0;
    while (retries < 5) {
      try {
        final res = await (client?.get(uri, headers: headers) ??
            http.get(uri, headers: headers));
        if (res.statusCode == 200 || res.statusCode == 206) return res;
        throw HttpException('HTTP ${res.statusCode}');
      } catch (e) {
        retries++;
        if (retries >= 5) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('Unreachable');
  }

  Future<void> _downloadM3U8(DownloadItem item, SimpleCancelToken token) async {
    final tempDir = Directory(p.join(p.dirname(item.filePath),
        '.temp_${p.basename(item.filePath).hashCode}'));
    await tempDir.create(recursive: true);

    // 1. Fetch & Parse Playlist (Recursive)
    AppLogger.i('Fetching M3U8: ${item.downloadUrl}');
    List<_Segment> segments;
    try {
      segments = await _parsePlaylist(
          item.downloadUrl, item.headers.cast<String, String>());
    } catch (e) {
      return _fail(item, 'Playlist processing failed: $e');
    }

    if (segments.isEmpty) return _fail(item, 'No segments found');

    if (segments.length > 5000) {
      AppLogger.w(
          'Unusually high segment count: ${segments.length} for ${item.episodeTitle}');
    }

    AppLogger.infoPair('Segments', segments.length);
    // Use a local variable to track state updates to avoid capturing stale 'item'
    var downloadingItem = item.copyWith(
        state: DownloadStatus.downloading,
        totalSegments: segments.length,
        size: null,
        progress: 0);
    _notifier.updateDownloadState(downloadingItem);

    // 3. Download Segments
    final batchSize = _settings.parallelDownloads;
    int completed = 0;

    // Skip existing
    for (var i = 0; i < segments.length; i++) {
      if (await File(p.join(tempDir.path, '$i.ts')).exists()) completed++;
    }
    downloadingItem = downloadingItem.copyWith(progress: completed);
    _notifier.updateDownloadState(downloadingItem);

    // Create a client for this download session
    final client = http.Client();
    token.addListener(() => client.close());

    try {
      for (var i = 0; i < segments.length; i += batchSize) {
        if (token.isCancelled) return;

        final end =
            (i + batchSize < segments.length) ? i + batchSize : segments.length;
        final batch = segments.sublist(i, end);

        try {
          await Future.wait(batch.map((seg) async {
            if (token.isCancelled) return;
            final file = File(p.join(tempDir.path, '${seg.index}.ts'));
            if (await file.exists()) return;

            try {
              final res = await _getWithRetry(
                  Uri.parse(seg.url), item.headers.cast<String, String>(),
                  client: client); // Use the cancellable client

              var bytes = res.bodyBytes;
              if (bytes.isEmpty) {
                AppLogger.w('Segment ${seg.index} returned 0 bytes');
              } else if (seg.index < 5 || seg.index % 100 == 0) {
                // Sample log for size
                AppLogger.d('Segment ${seg.index} size: ${bytes.length} bytes');
              }

              if (seg.key != null) {
                bytes = _decrypt(bytes, seg.key!, seg.iv, seg.index);
              }
              await file.writeAsBytes(bytes);

              if (token.isCancelled) return;

              completed++;
              if (completed % 10 == 0) {
                downloadingItem = downloadingItem.copyWith(progress: completed);
                _notifier.updateDownloadState(downloadingItem);
              }
            } catch (e) {
              if (token.isCancelled) {
                // Cancellation can cause client closed exception, which is expected
                return;
              }
              if (!token.isCancelled) {
                _fail(downloadingItem, 'Segment ${seg.index} failed: $e');
                pauseDownload(downloadingItem);
              }
            }
          }));
        } catch (e) {
          // Futures might throw if client closed
          if (token.isCancelled) return;
          rethrow;
        }

        if (_settings.speedLimitKBps > 0)
          await Future.delayed(
              Duration(milliseconds: 1000 ~/ _settings.speedLimitKBps));
      }
    } finally {
      client.close();
    }

    // 4. Stitch
    AppLogger.i('Stitching...');
    final output = File(item.filePath);
    await output.parent.create(recursive: true);
    final sink = output.openWrite();

    int totalSize = 0;
    for (var i = 0; i < segments.length; i++) {
      final segFile = File(p.join(tempDir.path, '$i.ts'));
      if (await segFile.exists()) {
        final len = await segFile.length();
        totalSize += len;
        await sink.addStream(segFile.openRead());
      }
    }
    await sink.close();
    await tempDir.delete(recursive: true);

    AppLogger.success(
        'Download Complete: ${item.episodeTitle} (Size: $totalSize)');
    _notifier.updateDownloadState(downloadingItem.copyWith(
        state: DownloadStatus.downloaded,
        progress: totalSize,
        size: totalSize,
        totalSegments: null));
  }

  Uint8List _decrypt(Uint8List bytes, Uint8List key, Uint8List? iv, int seq) {
    // IV handling: Use provided IV or derive from sequence number
    final effectiveIV = iv ?? _seqToIV(seq);
    final encrypter = Encrypter(AES(Key(key), mode: AESMode.cbc));
    return Uint8List.fromList(
        encrypter.decryptBytes(Encrypted(bytes), iv: IV(effectiveIV)));
  }

  Uint8List _seqToIV(int seq) {
    final iv = Uint8List(16);
    for (int i = 15; i >= 0; i--) {
      iv[i] = (seq >> (8 * (15 - i))) & 0xFF;
    }
    return iv;
  }

  Uint8List _hexToBytes(String hex) {
    hex = hex.replaceAll('0x', '');
    if (hex.length % 2 != 0) hex = '0$hex';
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  void _fail(DownloadItem item, String reason) {
    AppLogger.fail(reason);
    ref
        .read(downloadsProvider.notifier)
        .updateDownloadState(item.copyWith(state: DownloadStatus.failed));
  }

  void pauseDownload(DownloadItem item) {
    _cancelTokens[item.filePath]?.cancel();
    _notifier.updateDownloadState(item.copyWith(state: DownloadStatus.paused));
  }

  void resumeDownload(DownloadItem item) => startDownload(item);

  Future<void> deleteDownload(DownloadItem item) async {
    pauseDownload(item);

    try {
      final basePath = _settings.useCustomPath
          ? _settings.customDownloadPath
          : (await StorageProvider().getDefaultDirectory())?.path;

      if (basePath == null) return;

      final file = File(p.join(basePath, item.filePath));
      if (!await file.exists()) {
        ref.read(downloadsProvider.notifier).removeDownload(item);
        return;
      }

      final episodeDir = file.parent;
      final animeDir = episodeDir.parent;

      await file.delete();

      final episodeRemaining = episodeDir.listSync(followLinks: false);

      if (episodeRemaining.isEmpty) {
        await episodeDir.delete();
      }

      final animeRemaining = animeDir.listSync(followLinks: false);

      if (animeRemaining.isEmpty) {
        await animeDir.delete(recursive: true);
      }

      ref.read(downloadsProvider.notifier).removeDownload(item);
    } catch (e) {
      AppLogger.e('Failed to delete download: $e');
    }
  }

  Future<List<_Segment>> _parsePlaylist(
      String url, Map<String, String> headers) async {
    final res = await _getWithRetry(Uri.parse(url), headers);
    final lines = LineSplitter.split(res.body).toList();
    final segments = <_Segment>[];
    final baseUri = Uri.parse(url);

    // CHECK FOR MASTER PLAYLIST
    bool isMaster = lines.any((l) => l.contains('#EXT-X-STREAM-INF'));

    if (isMaster) {
      AppLogger.i('Master Playlist detected: $url');
      String? bestVariantUrl;
      int maxBandwidth = 0;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.startsWith('#EXT-X-STREAM-INF')) {
          // Parse Bandwidth
          final bandwidthMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);
          final bandwidth =
              bandwidthMatch != null ? int.parse(bandwidthMatch.group(1)!) : 0;

          // Resolution check if needed, but bandwidth is usually good proxy

          // URL is next line
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1].trim();
            if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
              if (bandwidth > maxBandwidth) {
                maxBandwidth = bandwidth;
                bestVariantUrl = baseUri.resolve(nextLine).toString();
              }
            }
          }
        }
      }

      if (bestVariantUrl != null) {
        AppLogger.i(
            'Selected Best Variant: $bestVariantUrl (Bandwidth: $maxBandwidth)');
        return _parsePlaylist(bestVariantUrl, headers);
      }

      // If failed to parse variants, fall through or throw
      throw Exception('Failed to find valid variant in Master Playlist');
    }

    // MEDIA PLAYLIST PARSING
    String? currentKeyUrl;
    Uint8List? currentKey;
    Uint8List? currentIV;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('#')) {
        if (trimmed.startsWith('#EXT-X-KEY')) {
          final keyUri = RegExp(r'URI="([^"]+)"').firstMatch(trimmed)?.group(1);
          final ivHex =
              RegExp(r'IV=0x([0-9A-Fa-f]+)').firstMatch(trimmed)?.group(1);

          if (keyUri != null) {
            final absKeyUrl = baseUri.resolve(keyUri).toString();
            if (currentKeyUrl != absKeyUrl) {
              currentKeyUrl = absKeyUrl;
              AppLogger.d('Fetching Key: $absKeyUrl');
              try {
                final keyRes =
                    await _getWithRetry(Uri.parse(absKeyUrl), headers);
                currentKey = keyRes.bodyBytes;
              } catch (e) {
                AppLogger.d("Failed to fetch key $absKeyUrl: $e");
              }
            }
          }
          if (ivHex != null) {
            currentIV = _hexToBytes(ivHex);
          }
        }
      } else {
        final absoluteUrl = baseUri.resolve(trimmed).toString();
        if (trimmed.toLowerCase().contains('.m3u8')) {
          AppLogger.d(
              "Found nested playlist in Media Playlist context? $absoluteUrl");
          segments.add(
              _Segment(absoluteUrl, currentKey, currentIV, segments.length));
        } else {
          segments.add(
              _Segment(absoluteUrl, currentKey, currentIV, segments.length));
        }
      }
    }
    return segments;
  }
}

class SimpleCancelToken {
  bool isCancelled = false;
  final List<void Function()> _listeners = [];

  void addListener(void Function() listener) => _listeners.add(listener);

  void cancel() {
    isCancelled = true;
    for (final listener in _listeners) {
      try {
        listener();
      } catch (_) {}
    }
  }
}

class _Segment {
  final String url;
  final Uint8List? key;
  final Uint8List? iv;
  final int index;
  _Segment(this.url, this.key, this.iv, this.index);
}
