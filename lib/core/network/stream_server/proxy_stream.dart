import 'dart:io';

import 'package:shonenx/core/network/http_client.dart';

/// Represents a generic stream that can be served via the [StreamServer].
abstract class ProxyStream {
  final String id;
  final String upstreamUrl;
  final Map<String, String> headers;

  ProxyStream({
    required this.id,
    required this.upstreamUrl,
    required this.headers,
  });

  /// The entrypoint URL for this stream on the local server.
  String getLocalUrl(int port);

  /// Handle an incoming request for this stream.
  Future<void> handleRequest(HttpRequest request, HTTP httpClient, int port);
}
