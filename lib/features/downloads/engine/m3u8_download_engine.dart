import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/engine/download_engine.dart';

class M3U8DownloadEngine implements DownloadEngine {
  final DownloadTask task;
  final OnProgressCallback onProgress;
  final OnStatusCallback onStatus;

  Isolate? _isolate;
  SendPort? _commandPort;
  final ReceivePort _receivePort = ReceivePort();

  bool _cancelled = false;
  bool _paused = false;
  bool _isRunning = false;

  M3U8DownloadEngine({
    required this.task,
    required this.onProgress,
    required this.onStatus,
  });

  @override
  Future<void> start() async {
    _isRunning = true;
    _paused = false;
    _cancelled = false;

    onStatus(DownloadStatus.downloading);

    try {
      final config = _M3U8TaskConfig(
        id: task.id,
        url: task.url,
        savePath: task.savePath,
        headers: task.headersMap,
        sendPort: _receivePort.sendPort,
      );

      _isolate = await Isolate.spawn(_m3u8Worker, config);

      _receivePort.listen((msg) async {
        if (msg is SendPort) {
          _commandPort = msg;
        } else if (msg is Map<String, dynamic>) {
          final type = msg['type'];
          if (type == 'progress') {
            final downloaded = msg['downloadedBytes'] as int;
            final total = msg['totalBytes'] as int;
            onProgress(
              downloadedBytes: downloaded,
              totalBytes: total,
              progress: total > 0 ? downloaded / total : 0.0,
            );
          } else if (type == 'status') {
            final statusStr = msg['status'] as String;
            if (statusStr == 'completed') {
              onStatus(DownloadStatus.completed);
              _cleanup();
            } else if (statusStr == 'failed') {
              onStatus(DownloadStatus.failed);
              _cleanup();
            }
          }
        } else if (msg is String) {
          if (msg.startsWith('err:')) {
            if (!_cancelled && !_paused) {
              onStatus(DownloadStatus.failed);
            }
            _cleanup();
          }
        }
      });
    } catch (e) {
      if (!_cancelled && !_paused) {
        onStatus(DownloadStatus.failed);
      }
      _cleanup();
    }
  }

  @override
  Future<void> pause() async {
    _paused = true;
    _commandPort?.send('cancel');
    _cleanup();
    onStatus(DownloadStatus.paused);
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
    _commandPort?.send('cancel');
    _cleanup();

    if (!_isRunning) {
      final file = File(task.savePath);
      if (await file.exists()) {
        await file.delete();
      }
      onStatus(DownloadStatus.canceled);
    }
  }

  void _cleanup() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _commandPort = null;
    _isRunning = false;
  }
}

class _M3U8TaskConfig {
  final int id;
  final String url;
  final String savePath;
  final Map<String, String> headers;
  final SendPort sendPort;

  _M3U8TaskConfig({
    required this.id,
    required this.url,
    required this.savePath,
    required this.headers,
    required this.sendPort,
  });
}

Future<void> _m3u8Worker(_M3U8TaskConfig task) async {
  final cmdPort = ReceivePort();
  task.sendPort.send(cmdPort.sendPort);

  bool isCancelled = false;
  cmdPort.listen((msg) {
    if (msg == 'cancel') isCancelled = true;
  });

  final client = http.Client();

  try {
    final tempDir = Directory('${p.dirname(task.savePath)}/.temp_${task.id}');
    await tempDir.create(recursive: true);

    final segments = await _parsePlaylist(
      task.url,
      task.headers,
      client,
      task.sendPort,
    );
    if (segments.isEmpty) throw Exception("Empty playlist");

    final batchSize = 3;
    int completedSegments = 0;
    int totalSegments = segments.length;
    DateTime lastLog = DateTime.now();

    for (var s in segments) {
      if (File(p.join(tempDir.path, '${s.index}.ts')).existsSync()) {
        completedSegments++;
      }
    }

    for (var i = 0; i < segments.length; i += batchSize) {
      if (isCancelled) break;

      final end = (i + batchSize < segments.length)
          ? i + batchSize
          : segments.length;
      final batch = segments.sublist(i, end);

      await Future.wait(
        batch.map((seg) async {
          if (isCancelled) return;
          final file = File(p.join(tempDir.path, '${seg.index}.ts'));
          if (await file.exists()) return;

          final bytes = await _fetch(seg.url, task.headers, client);
          if (bytes != null) {
            final data = seg.key != null
                ? _decrypt(bytes, seg.key!, seg.iv, seg.index)
                : bytes;
            await file.writeAsBytes(data);
            completedSegments++;
          }
        }),
      );

      if (DateTime.now().difference(lastLog).inMilliseconds > 1000) {
        task.sendPort.send({
          'type': 'progress',
          'downloadedBytes': completedSegments,
          'totalBytes': totalSegments,
        });
        lastLog = DateTime.now();
      }
    }

    if (isCancelled) throw Exception("Cancelled");

    final output = File(task.savePath);
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

    if (!isCancelled) {
      task.sendPort.send({
        'type': 'progress',
        'downloadedBytes': totalSegments,
        'totalBytes': totalSegments,
      });
      task.sendPort.send({'type': 'status', 'status': 'completed'});
    }
  } catch (e) {
    if (!isCancelled) task.sendPort.send('err:$e');
  } finally {
    client.close();
    Isolate.exit();
  }
}

Future<List<_Segment>> _parsePlaylist(
  String url,
  Map<String, String> headers,
  http.Client client,
  SendPort port,
) async {
  final bytes = await _fetch(url, headers, client);
  if (bytes == null) throw Exception("Failed to load m3u8");

  final lines = LineSplitter.split(utf8.decode(bytes)).toList();
  final baseUri = Uri.parse(url);
  final segments = <_Segment>[];

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

  return segments;
}

Future<Uint8List?> _fetch(
  String url,
  Map<String, String> headers,
  http.Client client,
) async {
  for (int i = 0; i < 3; i++) {
    try {
      final res = await client.get(Uri.parse(url), headers: headers);
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
