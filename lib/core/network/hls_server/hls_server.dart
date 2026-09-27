import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';

import 'hls_stream.dart';
import 'hls_playlist.dart';

class HlsServer {
  final HTTP _httpClient;
  HttpServer? _server;
  final Map<String, HlsStream> _streams = {};
  int _port = 0;

  static final _log = AppLogger.scope(HlsServer);

  Timer? _inactivityTimer;

  HlsServer(this._httpClient);

  int get port => _port;
  bool get isRunning => _server != null;

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      _log.i('HLS Server inactive for 5 minutes, shutting down');
      stop();
    });
  }

  Future<void> start() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      _log.i('HLS Server started on port $_port');
      _server!.listen(_handleRequest);
      _resetInactivityTimer();
    } catch (e) {
      _log.e('Failed to start HLS Server', e);
      rethrow;
    }
  }

  Future<void> stop() async {
    _inactivityTimer?.cancel();
    await _server?.close(force: true);
    _server = null;
    _port = 0;
    _streams.clear();
    _log.i('HLS Server stopped');
  }

  /// Registers a stream and returns the localhost URL to play it.
  Future<String> register({
    required String id,
    required String url,
    Map<String, String>? headers,
  }) async {
    if (!isRunning) {
      await start();
    }

    final stream = HlsStream(id: id, upstreamUrl: url, headers: headers ?? {});
    _streams[id] = stream;

    _resetInactivityTimer();

    return 'http://127.0.0.1:$_port/stream/$id/playlist.m3u8';
  }

  void unregister(String id) {
    _streams.remove(id);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    _resetInactivityTimer();
    try {
      final uri = request.uri;
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 3 || pathSegments[0] != 'stream') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final streamId = pathSegments[1];
      final stream = _streams[streamId];

      if (stream == null) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final action = pathSegments[2];

      if (action == 'playlist.m3u8') {
        await HlsPlaylist.processPlaylist(request, stream, _httpClient, _port);
      } else if (action == 'segment') {
        await stream.processSegment(request, _httpClient);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    } catch (e, st) {
      _log.e('Error handling request', e, st);
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }
}

final hlsServerProvider = Provider<HlsServer>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final server = HlsServer(httpClient);
  ref.onDispose(() {
    server.stop();
  });
  return server;
});
