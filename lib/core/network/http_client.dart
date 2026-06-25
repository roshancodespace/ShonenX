import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/caching/cache_manager.dart';
import 'package:shonenx/core/caching/domain/cache_entry.dart';

class HttpResponse {
  final int statusCode;
  final Map<String, String>? headers;
  final String body;

  HttpResponse(this.statusCode, this.body, {this.headers});

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
    : _client = HttpClient(),
      _cache = cacheManager;

  static HTTP? _instance;

  factory HTTP({CacheManager? cacheManager}) {
    return _instance ??= HTTP._internal(cacheManager: cacheManager);
  }

  final HttpClient _client;
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

  Future<HttpResponse> _request(
    String method,
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
    Duration? cacheDuration,
  }) async {
    final shouldCache = _shouldCache(cacheDuration);
    final key = _buildKey(url, queryParameters, body);

    if (shouldCache &&
        _cache != null &&
        !_cache.cacheConfig.bypassCache &&
        (method == 'GET' || method == 'POST')) {
      final cached = await _cache.get(key);
      if (cached != null) {
        return HttpResponse(200, utf8.decode(cached.bodyBytes));
      }
    }

    final uri = Uri.parse(url).replace(queryParameters: queryParameters);
    final req = await _client.openUrl(method, uri);

    headers?.forEach(req.headers.set);

    if (body != null) {
      final hasContentType =
          headers?.keys.any((k) => k.toLowerCase() == 'content-type') ?? false;
      if (!hasContentType) {
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      }
      req.write(body is String ? body : jsonEncode(body));
    }

    final res = await req.close().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw HttpException('Request timeout'),
    );

    final resBody = await res.transform(utf8.decoder).join();
    final response = HttpResponse(
      res.statusCode,
      resBody,
      headers: res.headers.contentType == null
          ? {}
          : {'content-type': res.headers.contentType!.mimeType},
    );

    if (shouldCache &&
        _cache != null &&
        (method == 'GET' || method == 'POST') &&
        res.statusCode >= 200 &&
        res.statusCode < 300 &&
        resBody.trim().isNotEmpty) {
      await _cache.put(
        key,
        CacheEntry()
          ..key = key
          ..bodyBytes = utf8.encode(resBody)
          ..etag = res.headers.value(HttpHeaders.etagHeader)
          ..lastModified = res.headers.value(HttpHeaders.lastModifiedHeader),
        cacheDuration!,
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

  bool _shouldCache(Duration? cacheDuration) {
    if (_cache != null && !_cache.cacheConfig.enableCaching) {
      return false;
    }
    return cacheDuration != null && cacheDuration > Duration.zero;
  }
}

final httpClientProvider = Provider<HTTP>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  return HTTP(cacheManager: cacheManager);
});
