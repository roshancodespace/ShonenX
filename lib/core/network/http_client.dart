import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/utils/app_logger.dart';
import 'cache_config.dart';
import 'cache_storage.dart';
export 'cache_config.dart';

class UniversalHttpClient {
  UniversalHttpClient._();
  static final UniversalHttpClient instance = UniversalHttpClient._();

  final http.Client _client = http.Client();
  final CacheStorageService _cacheStorage = CacheStorageService.instance;

  Future<void> init() async {
    await _cacheStorage.init();
  }

  String _generateKey(String method, Uri url, {Object? body}) {
    final hash = Object.hash(method, url.toString(), body?.toString());
    return hash.toUnsigned(32).toRadixString(16);
  }

  Future<http.Response> _request({
    required String method,
    required Uri url,
    required Future<http.Response> Function() networkRequest,
    CacheConfig? cacheConfig,
    Object? body,
  }) async {
    final bool useCache = cacheConfig != null && cacheConfig.duration != null;
    final String key = cacheConfig?.customKey ?? _generateKey(method, url, body: body);

    if (useCache && !cacheConfig.forceRefresh) {
      final cachedData = await _cacheStorage.get(key);
      
      if (cachedData != null) {
        final int timestamp = cachedData['ts'];
        final int durationMs = cachedData['duration'];
        final int now = DateTime.now().millisecondsSinceEpoch;

        if ((now - timestamp) < durationMs) {
          AppLogger.w('[CACHE HIT] $method $url');
          return http.Response(
            cachedData['body'],
            cachedData['statusCode'],
            headers: Map<String, String>.from(cachedData['headers']),
            request: http.Request(method, url),
          );
        } else {
          AppLogger.w('[CACHE EXPIRED] $method $url');
          _cacheStorage.delete(key); 
        }
      }
    }

    try {
      final response = await networkRequest();

      if (useCache && response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.w('[CACHE MISS] Saving $method $url');
        _cacheStorage.put(
          key: key, 
          response: response, 
          duration: cacheConfig.duration!,
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // --- Public Methods ---

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    CacheConfig? cacheConfig,
  }) {
    return _request(
      method: 'GET',
      url: url,
      cacheConfig: cacheConfig,
      networkRequest: () => _client.get(url, headers: headers),
    );
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CacheConfig? cacheConfig,
  }) {
    return _request(
      method: 'POST',
      url: url,
      body: body,
      cacheConfig: cacheConfig,
      networkRequest: () => _client.post(
        url, 
        headers: headers, 
        body: body, 
        encoding: encoding
      ),
    );
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CacheConfig? cacheConfig,
  }) {
    return _request(
      method: 'PUT',
      url: url,
      body: body,
      cacheConfig: cacheConfig,
      networkRequest: () => _client.put(
        url, 
        headers: headers, 
        body: body, 
        encoding: encoding
      ),
    );
  }

  Future<http.Response> head(
    Uri url, {
    Map<String, String>? headers,
    CacheConfig? cacheConfig,
  }) {
    return _request(
      method: 'HEAD',
      url: url,
      cacheConfig: cacheConfig,
      networkRequest: () => _client.head(url, headers: headers),
    );
  }

  Future<void> cleanUp() => _cacheStorage.clearExpired();

  Future<void> wipeCache() => _cacheStorage.clearAll();

  void close() {
    _client.close();
    _cacheStorage.close();
  }
}