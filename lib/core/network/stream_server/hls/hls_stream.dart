import 'dart:convert';
import 'dart:io';

import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';

import '../proxy_stream.dart';
import 'hls_crypto.dart';
import 'hls_playlist.dart';

class HlsStream extends ProxyStream {
  final Map<String, List<int>> _keyCache = {};

  static final _log = AppLogger.scope(HlsStream);

  HlsStream({
    required super.id,
    required super.upstreamUrl,
    required super.headers,
  });

  @override
  String getLocalUrl(int port) {
    return 'http://127.0.0.1:$port/stream/$id/playlist.m3u8';
  }

  @override
  Future<void> handleRequest(
    HttpRequest request,
    HTTP httpClient,
    int port,
  ) async {
    final action = request.uri.pathSegments[2];
    if (action == 'playlist.m3u8') {
      await HlsPlaylist.processPlaylist(request, this, httpClient, port);
    } else if (action == 'segment') {
      await _processSegment(request, httpClient);
    } else {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }
  }

  Future<List<int>> _getKey(String keyUrl, HTTP httpClient) async {
    if (_keyCache.containsKey(keyUrl)) {
      return _keyCache[keyUrl]!;
    }
    final res = await httpClient.get(
      keyUrl,
      headers: headers,
      suppressLogs: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to fetch key: ${res.statusCode}');
    }
    final keyBytes = res.bodyBytes;
    _keyCache[keyUrl] = keyBytes;
    return keyBytes;
  }

  Future<void> _processSegment(HttpRequest request, HTTP httpClient) async {
    final response = request.response;
    try {
      final urlStr = request.uri.queryParameters['url'];
      if (urlStr == null) {
        response.statusCode = HttpStatus.badRequest;
        await response.close();
        return;
      }

      final segmentUrl = utf8.decode(base64Url.decode(urlStr));

      final keyUrlStr = request.uri.queryParameters['key'];
      final ivStr = request.uri.queryParameters['iv'];

      final res = await httpClient.get(
        segmentUrl,
        headers: headers,
        suppressLogs: true,
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        response.statusCode = res.statusCode;
        await response.close();
        return;
      }

      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType.parse('video/MP2T');

      if (keyUrlStr != null && ivStr != null) {
        // Needs decryption
        final keyUrl = utf8.decode(base64Url.decode(keyUrlStr));
        final key = await _getKey(keyUrl, httpClient);
        final iv = HlsCrypto.parseIv(ivStr);

        final decrypted = HlsCrypto.decrypt(res.bodyBytes, key, iv);
        response.add(decrypted);
      } else {
        // Pass through
        response.add(res.bodyBytes);
      }

      await response.close();
    } catch (e) {
      _log.e('Failed to process segment', e);
      try {
        response.statusCode = HttpStatus.internalServerError;
        await response.close();
      } catch (_) {}
    }
  }
}
