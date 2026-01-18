import 'dart:convert';
import 'package:http/http.dart' as http;

class CacheConfig {
  final Duration? duration;
  final bool forceRefresh;
  final String? customKey;

  const CacheConfig({this.duration, this.forceRefresh = false, this.customKey});

  static const CacheConfig short = CacheConfig(duration: Duration(minutes: 5));

  static const CacheConfig medium = CacheConfig(duration: Duration(hours: 1));

  static const CacheConfig long = CacheConfig(duration: Duration(days: 1));
}

class UniversalHttpClient {
  UniversalHttpClient._();

  static final UniversalHttpClient _instance = UniversalHttpClient._();

  static UniversalHttpClient get instance => _instance;

  final http.Client _client = http.Client();

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    CacheConfig? cacheConfig,
  }) async {
    final response = await _client.get(url, headers: headers);

    return response;
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _client.post(url, headers: headers, body: body, encoding: encoding);
  }

  void close() {
    _client.close();
  }
}
