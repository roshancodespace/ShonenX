import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/utils/app_logger.dart';

class CacheConfig {
  final Duration? duration;
  final bool forceRefresh;
  final String? customKey;

  const CacheConfig({this.duration, this.forceRefresh = false, this.customKey});

  static const CacheConfig short = CacheConfig(duration: Duration(minutes: 5));
  static const CacheConfig medium = CacheConfig(duration: Duration(hours: 1));
  static const CacheConfig long = CacheConfig(duration: Duration(days: 1));
  static const CacheConfig infinite =
      CacheConfig(duration: Duration(days: 365 * 10));
}

class UniversalHttpClient {
  UniversalHttpClient._();

  static final UniversalHttpClient _instance = UniversalHttpClient._();

  static UniversalHttpClient get instance => _instance;

  final http.Client _client = http.Client();

  Box get _box => Hive.box('http_cache_v1');

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    CacheConfig? cacheConfig,
  }) async {
    final String key = cacheConfig?.customKey ?? url.toString();

    if (cacheConfig != null && !cacheConfig.forceRefresh) {
      final cachedData = _box.get(key);
      if (cachedData != null) {
        final int timestamp = cachedData['ts'];
        final DateTime savedTime =
            DateTime.fromMillisecondsSinceEpoch(timestamp);
        final Duration difference = DateTime.now().difference(savedTime);

        // If cache is still valid
        if (cacheConfig.duration != null &&
            difference < cacheConfig.duration!) {
          AppLogger.w('[CACHE HIT] $url');
          return http.Response(
            cachedData['body'],
            cachedData['statusCode'],
            headers: Map<String, String>.from(cachedData['headers']),
            request: http.Request('GET', url),
          );
        } else {
          // Cache expired
          _box.delete(key);
          AppLogger.w('[CACHE EXPIRED] $url');
        }
      }
    }
    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200 &&
          cacheConfig != null &&
          cacheConfig.duration != null) {
        await _box.put(key, {
          'body': response.body,
          'statusCode': response.statusCode,
          'headers': response.headers,
          'ts': DateTime.now().millisecondsSinceEpoch,
        });
        AppLogger.w('[CACHE MISS] $url');
        return response;
      }
    } catch (e) {
      rethrow;
    }
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

  Future<void> clearCache() async {
    await _box.clear();
  }

  void close() {
    _client.close();
    _box.close();
  }
}
