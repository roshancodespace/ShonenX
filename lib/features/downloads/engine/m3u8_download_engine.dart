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
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';

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

  final int concurrentSegments;
  final RemuxerPreference remuxerPreference;

  M3U8DownloadEngine({
    required this.task,
    this.concurrentSegments = 4,
    this.remuxerPreference = RemuxerPreference.auto,
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
        concurrentSegments: concurrentSegments,
        remuxerPreference: remuxerPreference.name,
        sendPort: _receivePort.sendPort,
      );

      _isolate = await Isolate.spawn(_m3u8Worker, config);

      _receivePort.listen((msg) async {
        if (_cancelled || _paused) return;
        if (msg is SendPort) {
          _commandPort = msg;
        } else if (msg is Map<String, dynamic>) {
          final type = msg['type'];
          if (type == 'progress') {
            final downloaded = msg['downloadedBytes'] as int;
            final total = msg['totalBytes'] as int;
            final downloadedSegs = msg['downloadedSegments'] as int? ?? 0;
            final totalSegs = msg['totalSegments'] as int? ?? 0;
            onProgress(
              downloadedBytes: downloaded,
              totalBytes: total,
              downloadedSegments: downloadedSegs,
              totalSegments: totalSegs,
              progress: total > 0
                  ? downloaded / total
                  : (totalSegs > 0 ? downloadedSegs / totalSegs : 0.0),
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
  final int concurrentSegments;
  final String remuxerPreference;
  final SendPort sendPort;

  _M3U8TaskConfig({
    required this.id,
    required this.url,
    required this.savePath,
    required this.headers,
    this.concurrentSegments = 4,
    this.remuxerPreference = 'auto',
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

    final batchSize = task.concurrentSegments > 0 ? task.concurrentSegments : 4;
    int completedSegments = 0;
    int totalSegments = segments.length;
    int totalDownloadedBytes = 0;
    DateTime lastLog = DateTime.now();

    for (var s in segments) {
      final f = File(p.join(tempDir.path, '${s.fileIndex}.ts'));
      if (f.existsSync() && f.lengthSync() > 0) {
        completedSegments++;
        totalDownloadedBytes += f.lengthSync();
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
          final file = File(p.join(tempDir.path, '${seg.fileIndex}.ts'));

          if (file.existsSync() && file.lengthSync() > 0) return;

          final bytes = await _fetch(seg.url, task.headers, client);
          if (bytes == null) {
            throw Exception("Failed to download segment ${seg.fileIndex}");
          }

          final data = seg.key != null
              ? _decrypt(bytes, seg.key!, seg.iv, seg.seq)
              : bytes;
          await file.writeAsBytes(data);
          completedSegments++;
          totalDownloadedBytes += data.length;
        }),
      );

      if (DateTime.now().difference(lastLog).inMilliseconds > 1000) {
        final estTotal = completedSegments > 0
            ? (totalDownloadedBytes ~/ completedSegments) * totalSegments
            : 0;
        task.sendPort.send({
          'type': 'progress',
          'downloadedBytes': totalDownloadedBytes,
          'totalBytes': estTotal,
          'downloadedSegments': completedSegments,
          'totalSegments': totalSegments,
        });
        lastLog = DateTime.now();
      }
    }

    if (isCancelled) throw Exception("Cancelled");

    final tempStitchedPath = p.join(tempDir.path, 'stitched.ts');
    final stitchedFile = File(tempStitchedPath);
    final sink = stitchedFile.openWrite();

    for (var s in segments) {
      final f = File(p.join(tempDir.path, '${s.fileIndex}.ts'));
      if (f.existsSync() && f.lengthSync() > 0) {
        await sink.addStream(f.openRead());
      } else {
        throw Exception(
          "Missing or corrupted segment ${s.fileIndex} during stitching",
        );
      }
    }

    await sink.close();

    bool remuxed = false;
    if (task.remuxerPreference == 'auto' &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      try {
        final check = await Process.run('ffmpeg', ['-version']);
        if (check.exitCode == 0) {
          final res = await Process.run('ffmpeg', [
            '-y',
            '-i',
            tempStitchedPath,
            '-c',
            'copy',
            task.savePath,
          ]);
          if (res.exitCode == 0 && File(task.savePath).existsSync()) {
            remuxed = true;
          }
        }
      } catch (_) {
        remuxed = false;
      }
    }

    if (!remuxed) {
      await stitchedFile.copy(task.savePath);
    }

    await tempDir.delete(recursive: true);

    task.sendPort.send({
      'type': 'progress',
      'downloadedBytes': totalDownloadedBytes,
      'totalBytes': totalDownloadedBytes,
      'downloadedSegments': totalSegments,
      'totalSegments': totalSegments,
    });
    task.sendPort.send({'type': 'status', 'status': 'completed'});
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
            _resolveUrl(baseUri, next),
            headers,
            client,
            port,
          );
        }
      }
    }
  }

  Uint8List? key, iv;
  int mediaSeq = 0;
  int fileIndex = 0;
  int segmentCount = 0;

  for (final line in lines) {
    final trim = line.trim();
    if (trim.isEmpty) continue;

    if (trim.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
      mediaSeq = int.tryParse(trim.split(':').last) ?? 0;
    } else if (trim.startsWith('#EXT-X-MAP')) {
      final mapUri = RegExp(r'URI="([^"]+)"').firstMatch(trim)?.group(1);
      if (mapUri != null) {
        segments.add(_Segment(_resolveUrl(baseUri, mapUri), key, iv, -1, -1));
      }
    } else if (trim.startsWith('#EXT-X-KEY')) {
      final keyUri = RegExp(r'URI="([^"]+)"').firstMatch(trim)?.group(1);
      final ivHex = RegExp(
        r'IV=(?:0x)?([0-9A-Fa-f]+)',
        caseSensitive: false,
      ).firstMatch(trim)?.group(1);

      if (keyUri != null) {
        key = await _fetch(_resolveUrl(baseUri, keyUri), headers, client);
        if (key == null) throw Exception("Failed to fetch decryption key");
      }
      if (ivHex != null) iv = _hexToBytes(ivHex);
    } else if (!trim.startsWith('#')) {
      segments.add(
        _Segment(
          _resolveUrl(baseUri, trim),
          key,
          iv,
          mediaSeq + segmentCount,
          fileIndex,
        ),
      );
      segmentCount++;
      fileIndex++;
    }
  }

  return segments;
}

String _resolveUrl(Uri baseUri, String url) {
  final parsed = Uri.parse(url);
  if (parsed.hasScheme) return url;

  final resolved = baseUri.resolve(url);
  if (baseUri.hasQuery && !parsed.hasQuery) {
    return resolved.replace(query: baseUri.query).toString();
  }
  return resolved.toString();
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
  try {
    final encrypter = Encrypter(
      AES(Key(key), mode: AESMode.cbc, padding: 'PKCS7'),
    );
    return Uint8List.fromList(
      encrypter.decryptBytes(Encrypted(bytes), iv: IV(effectiveIV)),
    );
  } catch (e) {
    final fallbackEncrypter = Encrypter(
      AES(Key(key), mode: AESMode.cbc, padding: null),
    );
    return Uint8List.fromList(
      fallbackEncrypter.decryptBytes(Encrypted(bytes), iv: IV(effectiveIV)),
    );
  }
}

Uint8List _seqToIV(int seq) {
  final iv = Uint8List(16);
  int s = seq < 0 ? 0 : seq;
  for (int i = 15; i >= 0; i--) {
    iv[i] = (s >> (8 * (15 - i))) & 0xFF;
  }
  return iv;
}

Uint8List _hexToBytes(String hex) {
  hex = hex.padLeft(32, '0');
  return Uint8List.fromList(
    List.generate(
      16,
      (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    ),
  );
}

class _Segment {
  final String url;
  final Uint8List? key;
  final Uint8List? iv;
  final int seq;
  final int fileIndex;
  _Segment(this.url, this.key, this.iv, this.seq, this.fileIndex);
}
