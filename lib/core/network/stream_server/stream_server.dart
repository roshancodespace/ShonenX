import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';

import 'proxy_stream.dart';

class StreamServer {
  final HTTP _httpClient;
  HttpServer? _server;
  final Map<String, ProxyStream> _streams = {};
  int _port = 0;

  static final _log = AppLogger.scope(StreamServer);

  Timer? _inactivityTimer;

  StreamServer(this._httpClient);

  int get port => _port;
  bool get isRunning => _server != null;

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      _log.i('Stream Server inactive for 5 minutes, shutting down');
      stop();
    });
  }

  Future<void> start() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      _log.i('Stream Server started on port $_port');
      _server!.listen(_handleRequest);
      _resetInactivityTimer();
    } catch (e) {
      _log.e('Failed to start Stream Server', e);
      rethrow;
    }
  }

  Future<void> stop() async {
    _inactivityTimer?.cancel();
    await _server?.close(force: true);
    _server = null;
    _port = 0;
    _streams.clear();
    _log.i('Stream Server stopped');
  }

  /// Registers a stream and returns the localhost URL to play it.
  Future<String> register(ProxyStream stream) async {
    if (!isRunning) {
      await start();
    }

    _streams[stream.id] = stream;

    _resetInactivityTimer();

    return stream.getLocalUrl(_port);
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

      await stream.handleRequest(request, _httpClient, _port);
    } catch (e, st) {
      _log.e('Error handling request', e, st);
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }
}

final streamServerProvider = Provider<StreamServer>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final server = StreamServer(httpClient);
  ref.onDispose(() {
    server.stop();
  });
  return server;
});
