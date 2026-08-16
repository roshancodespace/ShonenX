import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhttp/rhttp.dart' as rhttp;
import 'package:shonenx/core/caching/cache_manager.dart';
import 'package:shonenx/core/caching/domain/cache_entry.dart';

class HttpResponse {
  final int statusCode;
  final Map<String, String>? headers;
  final Uint8List bodyBytes;

  HttpResponse(this.statusCode, this.bodyBytes, {this.headers});

  String get body {
    try {
      return utf8.decode(bodyBytes);
    } catch (_) {
      return String.fromCharCodes(bodyBytes);
    }
  }

  dynamic get json {
    if (statusCode < 200 || statusCode >= 300) {
      throw HttpException('HTTP $statusCode: $body');
    }
    if (body.trimLeft().startsWith('<')) {
      throw Exception(
        'Expected JSON but received HTML (status $statusCode). '
        'The server may be behind a Cloudflare challenge.',
      );
    }
    return jsonDecode(body);
  }
}

class HTTP {
  HTTP._internal({CacheManager? cacheManager})
    : _client = rhttp.RhttpClient.createSync(
        settings: const rhttp.ClientSettings(
          throwOnStatusCode: false,
          userAgent:
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          timeoutSettings: rhttp.TimeoutSettings(
            timeout: Duration(seconds: 30),
            connectTimeout: Duration(seconds: 30),
          ),
        ),
      ),
      _cache = cacheManager;

  static HTTP? _instance;

  factory HTTP({CacheManager? cacheManager}) {
    return _instance ??= HTTP._internal(cacheManager: cacheManager);
  }

  final rhttp.RhttpClient _client;
  final CacheManager? _cache;

  String _normalizeBody(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _buildKey(String url, Map<String, String>? query, Object? body) {
    final buffer = StringBuffer(url);

    if (query != null && query.isNotEmpty) {
      buffer.write('?');

      final keys = query.keys.toList()..sort();
      for (var i = 0; i < keys.length; i++) {
        if (i > 0) buffer.write('&');
        final key = keys[i];
        buffer
          ..write(key)
          ..write('=')
          ..write(query[key]);
      }
    }

    if (body != null) {
      buffer.write(query == null || query.isEmpty ? '?' : '&');
      buffer.write('body=');

      if (body is String) {
        buffer.write(_normalizeBody(body));
      } else {
        buffer.write(_normalizeBody(jsonEncode(body)));
      }
    }

    return buffer.toString();
  }

  Duration _getEffectiveCacheDuration(
    Map<String, String> lowerHeaders,
    Duration? cacheDuration,
  ) {
    if (cacheDuration != null && cacheDuration > Duration.zero) {
      return cacheDuration;
    }

    final cacheControl = lowerHeaders[HttpHeaders.cacheControlHeader];
    if (cacheControl != null) {
      final match = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
      if (match != null) {
        final seconds = int.tryParse(match.group(1) ?? '');
        if (seconds != null && seconds > 0) {
          return Duration(seconds: seconds);
        }
      }
    }

    return Duration.zero;
  }

  Future<HttpResponse> _request(
    String method,
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
    Duration? cacheDuration,
  }) async {
    final key = _buildKey(url, queryParameters, body);

    final bool isCacheable =
        method == 'GET' ||
        (method == 'POST' &&
            cacheDuration != null &&
            cacheDuration > Duration.zero);

    if (_cache != null &&
        _cache.cacheConfig.enableCaching &&
        !_cache.cacheConfig.bypassCache &&
        isCacheable) {
      final cached = await _cache.get(key);
      if (cached != null) {
        return HttpResponse(200, Uint8List.fromList(cached.bodyBytes));
      }
    }

    final requestHeaders = Map<String, String>.from(headers ?? {});
    rhttp.HttpBody? rBody;

    if (body != null) {
      final hasContentType = requestHeaders.keys.any(
        (k) => k.toLowerCase() == 'content-type',
      );
      if (!hasContentType) {
        requestHeaders['content-type'] = 'application/json';
      }
      rBody = rhttp.HttpBody.text(body is String ? body : jsonEncode(body));
    }

    rhttp.HttpMethod rMethod;
    switch (method.toUpperCase()) {
      case 'GET':
        rMethod = rhttp.HttpMethod.get;
        break;
      case 'POST':
        rMethod = rhttp.HttpMethod.post;
        break;
      case 'PUT':
        rMethod = rhttp.HttpMethod.put;
        break;
      case 'PATCH':
        rMethod = rhttp.HttpMethod.patch;
        break;
      case 'DELETE':
        rMethod = rhttp.HttpMethod.delete;
        break;
      case 'HEAD':
        rMethod = rhttp.HttpMethod.head;
        break;
      default:
        rMethod = rhttp.HttpMethod.get;
    }

    rhttp.HttpBytesResponse res;
    try {
      res = await _client.requestBytes(
        method: rMethod,
        url: url,
        headers: requestHeaders.isNotEmpty
            ? rhttp.HttpHeaders.rawMap(requestHeaders)
            : null,
        query: queryParameters,
        body: rBody,
      );
    } catch (e) {
      if (e is rhttp.RhttpTimeoutException) {
        throw HttpException('Request timeout');
      }
      rethrow;
    }

    final bodyBytes = res.body;
    final lowerHeaders = res.headerMap.map(
      (k, v) => MapEntry(k.toLowerCase(), v),
    );

    final contentType = lowerHeaders['content-type'];
    final responseHeaders = contentType == null
        ? <String, String>{}
        : {'content-type': contentType};

    final response = HttpResponse(
      res.statusCode,
      bodyBytes,
      headers: responseHeaders,
    );

    final effectiveTtl = _getEffectiveCacheDuration(
      lowerHeaders,
      cacheDuration,
    );

    if (effectiveTtl > Duration.zero &&
        _cache != null &&
        _cache.cacheConfig.enableCaching &&
        isCacheable &&
        res.statusCode >= 200 &&
        res.statusCode < 300 &&
        bodyBytes.isNotEmpty) {
      await _cache.put(
        key,
        CacheEntry()
          ..key = key
          ..bodyBytes = bodyBytes
          ..etag = lowerHeaders[HttpHeaders.etagHeader]
          ..lastModified = lowerHeaders[HttpHeaders.lastModifiedHeader],
        effectiveTtl,
      );
    }
    return response;
  }

  Future<HttpResponse> get(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Duration? cacheDuration = Duration.zero,
  }) {
    return _request(
      'GET',
      url,
      headers: headers,
      queryParameters: queryParameters,
      cacheDuration: cacheDuration,
    );
  }

  Future<HttpResponse> post(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
    Duration? cacheDuration,
  }) {
    return _request(
      'POST',
      url,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      cacheDuration: cacheDuration,
    );
  }

  Future<HttpResponse> put(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
  }) {
    return _request(
      'PUT',
      url,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<HttpResponse> patch(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
  }) {
    return _request(
      'PATCH',
      url,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<HttpResponse> delete(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      'DELETE',
      url,
      headers: headers,
      queryParameters: queryParameters,
    );
  }

  Future<HttpResponse> head(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      'HEAD',
      url,
      headers: headers,
      queryParameters: queryParameters,
    );
  }
}

final httpClientProvider = Provider<HTTP>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  return HTTP(cacheManager: cacheManager);
});
