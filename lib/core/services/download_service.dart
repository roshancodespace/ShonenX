import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/permissions.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/downloads/view_model/downloads_notifier.dart';
import 'package:shonenx/features/settings/model/download_settings_model.dart';
import 'package:shonenx/features/settings/view_model/download_settings_notifier.dart';
import 'package:shonenx/storage_provider.dart';

class DownloadService {
  final Ref ref;
  final DownloadsNotifier _notifier;
  static const int _maxConcurrent = 2;

  final List<DownloadItem> _queue = [];
  final Map<String, Isolate> _isolates = {};
  final Map<String, SendPort> _ports = {};

  DownloadService(this.ref, this._notifier);

  DownloadSettingsModel get _settings => ref.read(downloadSettingsProvider);

  Future<void> startDownload(DownloadItem item) async {
    // Check Permissions & Path
    if (!_settings.useCustomPath || _settings.customDownloadPath == null) {
      if (!await Permissions.requestStoragePermission()) {
        return _fail(item, 'Permission denied');
      }
    }

    final basePath = _settings.useCustomPath
        ? _settings.customDownloadPath!
        : (await StorageProvider.getDefaultDirectory())!.path;

    final itemPath = item.filePath;
    final finalPath = p.isAbsolute(itemPath)
        ? itemPath
        : p.join(basePath, itemPath);

    final queuedItem = item.copyWith(
      state: DownloadStatus.queued,
      filePath: finalPath,
    );

    _notifier.updateDownloadState(queuedItem);
    _queue.add(queuedItem);
    _processQueue();
  }

  void pauseDownload(DownloadItem item) {
    if (_isolates.containsKey(item.id)) {
      _ports[item.id]?.send('cancel');
      _isolates[item.id]?.kill(priority: Isolate.immediate);
      _cleanup(item.id);
    } else {
      _queue.removeWhere((i) => i.id == item.id);
    }
    _notifier.updateDownloadState(item.copyWith(state: DownloadStatus.paused));
  }

  void resumeDownload(DownloadItem item) => startDownload(item);

  Future<void> deleteDownload(DownloadItem item) async {
    pauseDownload(item);
    try {
      final file = File(item.filePath);
      if (await file.exists()) await file.delete();

      // Cleanup parent folder if empty
      if (await file.parent.exists() && file.parent.listSync().isEmpty) {
        await file.parent.delete();
      }
      _notifier.removeDownload(item);
    } catch (e) {
      AppLogger.e('Delete failed: $e');
    }
  }

  void _processQueue() {
    if (_isolates.length >= _maxConcurrent || _queue.isEmpty) return;
    _spawnIsolate(_queue.removeAt(0));
  }

  Future<void> _spawnIsolate(DownloadItem item) async {
    final receivePort = ReceivePort();
    _notifier.updateDownloadState(
      item.copyWith(state: DownloadStatus.downloading),
    );

    try {
      final isolate = await Isolate.spawn(
        _downloadWorker,
        _TaskConfig(item, _settings, receivePort.sendPort),
      );

      _isolates[item.id] = isolate;

      receivePort.listen((msg) {
        if (msg is SendPort) {
          _ports[item.id] = msg;
        } else if (msg is DownloadItem) {
          _notifier.updateDownloadState(msg);
          if (msg.state == DownloadStatus.downloaded) _cleanup(item.id);
        } else if (msg is String) {
          if (msg.startsWith('err:')) _fail(item, msg.substring(4));
          if (msg.startsWith('log:')) {
            AppLogger.d('[Isolate] ${msg.substring(4)}');
          }
        }
      });
    } catch (e) {
      _fail(item, 'Isolate Spawn Error: $e');
    }
  }

  void _cleanup(String id) {
    _isolates.remove(id);
    _ports.remove(id);
    _processQueue();
  }

  void _fail(DownloadItem item, String reason) {
    AppLogger.e(reason);
    _notifier.updateDownloadState(item.copyWith(state: DownloadStatus.failed));
    _cleanup(item.id);
  }
}

class _TaskConfig {
  final DownloadItem item;
  final DownloadSettingsModel settings;
  final SendPort port;
  _TaskConfig(this.item, this.settings, this.port);
}

Future<void> _downloadWorker(_TaskConfig task) async {
  final cmdPort = ReceivePort();
  task.port.send(cmdPort.sendPort);

  bool isCancelled = false;
  cmdPort.listen((msg) {
    if (msg == 'cancel') isCancelled = true;
  });

  final client = http.Client();
  final item = task.item;
  final isM3U8 = item.isM3U8;

  task.port.send('log: Processing as ${isM3U8 ? "M3U8" : "File"}');

  try {
    DownloadItem result;
    if (isM3U8) {
      result = await _processM3U8(task, client, () => isCancelled);
    } else {
      result = await _processFile(task, client, () => isCancelled);
    }

    if (!isCancelled) task.port.send(result);
  } catch (e) {
    if (!isCancelled) task.port.send('err:$e');
  } finally {
    client.close();
    Isolate.exit();
  }
}

Future<DownloadItem> _processFile(
  _TaskConfig task,
  http.Client client,
  bool Function() isCancelled,
) async {
  final file = File(task.item.filePath);
  await file.parent.create(recursive: true);

  // Resume Logic
  final existing = await file.exists() ? await file.length() : 0;
  final req = http.Request('GET', Uri.parse(task.item.downloadUrl));
  req.headers.addAll(task.item.headers.cast());
  if (existing > 0) req.headers['Range'] = 'bytes=$existing-';

  final res = await client.send(req);
  if (res.statusCode >= 400) throw Exception('HTTP ${res.statusCode}');

  // Calc Total Size
  int total = existing;
  if (res.statusCode == 200) {
    total = int.tryParse(res.headers['content-length'] ?? '0') ?? 0;
  } else if (res.statusCode == 206) {
    final range = res.headers['content-range']?.split('/').last;
    if (range != null && range != '*') total = int.parse(range);
  }

  final sink = file.openWrite(mode: FileMode.append);
  int current = existing;
  DateTime lastLog = DateTime.now();

  final throttler = _Throttler(task.settings.speedLimitKBps);

  await for (final chunk in res.stream) {
    if (isCancelled()) throw Exception("Cancelled");
    sink.add(chunk);
    current += chunk.length;
    await throttler.throttle(chunk.length);

    // Update UI every 500ms
    if (DateTime.now().difference(lastLog).inMilliseconds > 500) {
      task.port.send(
        task.item.copyWith(
          state: DownloadStatus.downloading,
          size: total,
          progress: current,
        ),
      );
      lastLog = DateTime.now();
    }
  }
  await sink.close();

  return task.item.copyWith(
    state: DownloadStatus.downloaded,
    size: current,
    progress: current,
  );
}

Future<DownloadItem> _processM3U8(
  _TaskConfig task,
  http.Client client,
  bool Function() isCancelled,
) async {
  final tempDir = Directory(
    '${p.dirname(task.item.filePath)}/.temp_${task.item.id.hashCode}',
  );
  await tempDir.create(recursive: true);

  // Parse Playlist
  final segments = await _parsePlaylist(
    task.item.downloadUrl,
    task.item.headers,
    client,
    task.port,
  );
  if (segments.isEmpty) throw Exception("Empty playlist");

  var currentItem = task.item.copyWith(
    state: DownloadStatus.downloading,
    totalSegments: segments.length,
    progress: 0,
  );
  task.port.send(currentItem);

  // Download Segments (Batched)
  final batchSize = task.settings.parallelDownloads > 0
      ? task.settings.parallelDownloads
      : 3;
  int completed = 0;
  DateTime lastLog = DateTime.now();

  // Count already downloaded
  for (var s in segments) {
    if (File(p.join(tempDir.path, '${s.index}.ts')).existsSync()) completed++;
  }

  final throttler = _Throttler(task.settings.speedLimitKBps);

  for (var i = 0; i < segments.length; i += batchSize) {
    if (isCancelled()) break;

    final end = (i + batchSize < segments.length)
        ? i + batchSize
        : segments.length;
    final batch = segments.sublist(i, end);

    await Future.wait(
      batch.map((seg) async {
        if (isCancelled()) return;
        final file = File(p.join(tempDir.path, '${seg.index}.ts'));
        if (await file.exists()) return;

        final bytes = await _fetch(seg.url, task.item.headers, client);
        if (bytes != null) {
          final data = seg.key != null
              ? _decrypt(bytes, seg.key!, seg.iv, seg.index)
              : bytes;
          await file.writeAsBytes(data);
          completed++;
          await throttler.throttle(data.length);
        }
      }),
    );

    if (DateTime.now().difference(lastLog).inMilliseconds > 1000) {
      task.port.send(currentItem.copyWith(progress: completed));
      lastLog = DateTime.now();
    }
  }

  if (isCancelled()) throw Exception("Cancelled");

  // Stitch Files
  final output = File(task.item.filePath);
  final sink = output.openWrite();
  int totalSize = 0;

  for (var s in segments) {
    final f = File(p.join(tempDir.path, '${s.index}.ts'));
    if (await f.exists()) {
      totalSize += await f.length();
      await sink.addStream(f.openRead());
    }
  }
  await sink.close();
  await tempDir.delete(recursive: true);

  return currentItem.copyWith(
    state: DownloadStatus.downloaded,
    size: totalSize,
    progress: totalSize,
  );
}

Future<List<_Segment>> _parsePlaylist(
  String url,
  Map headers,
  http.Client client,
  SendPort port,
) async {
  final bytes = await _fetch(url, headers, client);
  if (bytes == null) throw Exception("Failed to load m3u8");

  final lines = LineSplitter.split(utf8.decode(bytes)).toList();
  final baseUri = Uri.parse(url);
  final segments = <_Segment>[];

  // Recursively handle Master Playlist
  if (lines.any((l) => l.contains('#EXT-X-STREAM-INF'))) {
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('#EXT-X-STREAM-INF') && i + 1 < lines.length) {
        final next = lines[i + 1].trim();
        if (next.isNotEmpty && !next.startsWith('#')) {
          return _parsePlaylist(
            baseUri.resolve(next).toString(),
            headers,
            client,
            port,
          );
        }
      }
    }
  }

  Uint8List? key, iv;
  for (final line in lines) {
    final trim = line.trim();
    if (trim.isEmpty) continue;

    if (trim.startsWith('#EXT-X-KEY')) {
      final keyUri = RegExp(r'URI="([^"]+)"').firstMatch(trim)?.group(1);
      final ivHex = RegExp(r'IV=0x([0-9A-Fa-f]+)').firstMatch(trim)?.group(1);

      if (keyUri != null) {
        key = await _fetch(baseUri.resolve(keyUri).toString(), headers, client);
      }
      if (ivHex != null) iv = _hexToBytes(ivHex);
    } else if (!trim.startsWith('#')) {
      segments.add(
        _Segment(baseUri.resolve(trim).toString(), key, iv, segments.length),
      );
    }
  }

  port.send('log:Parsed ${segments.length} segments');
  return segments;
}

Future<Uint8List?> _fetch(String url, Map headers, http.Client client) async {
  for (int i = 0; i < 3; i++) {
    try {
      final res = await client.get(Uri.parse(url), headers: headers.cast());
      if (res.statusCode == 200) return res.bodyBytes;
    } catch (_) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }
  return null;
}

Uint8List _decrypt(Uint8List bytes, Uint8List key, Uint8List? iv, int seq) {
  final effectiveIV = iv ?? _seqToIV(seq);
  final encrypter = Encrypter(AES(Key(key), mode: AESMode.cbc));
  return Uint8List.fromList(
    encrypter.decryptBytes(Encrypted(bytes), iv: IV(effectiveIV)),
  );
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
  return Uint8List.fromList(
    List.generate(
      hex.length ~/ 2,
      (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    ),
  );
}

class _Segment {
  final String url;
  final Uint8List? key;
  final Uint8List? iv;
  final int index;
  _Segment(this.url, this.key, this.iv, this.index);
}

class _Throttler {
  final int limitKBps;
  int _bytesTransferred = 0;
  final DateTime _startTime = DateTime.now();

  _Throttler(this.limitKBps);

  Future<void> throttle(int newBytes) async {
    if (limitKBps <= 0) return;

    _bytesTransferred += newBytes;
    final elapsedMs = DateTime.now().difference(_startTime).inMilliseconds;
    if (elapsedMs == 0) return;

    // Expected milliseconds to transfer these bytes at the limit speed
    // limitKBps is KB/s. 1 KB = 1024 bytes.
    // Bytes / (KB/s * 1024) = seconds. * 1000 = ms.
    final expectedMs = (_bytesTransferred / (limitKBps * 1024)) * 1000;

    if (expectedMs > elapsedMs) {
      final waitMs = (expectedMs - elapsedMs).toInt();
      // Don't sleep for too tiny intervals, but ensure aggregated sleep.
      if (waitMs > 10) {
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }
  }
}
