import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/network/doh/doh_cache.dart';
import 'package:shonenx/core/network/doh/doh_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class DohTestResult {
  final bool success;
  final DohProvider provider;
  final int latencyMs;
  final List<String> addresses;
  final String? errorMessage;

  const DohTestResult({
    required this.success,
    required this.provider,
    required this.latencyMs,
    required this.addresses,
    this.errorMessage,
  });
}

class DohResolver {
  DohResolver._internal({HttpClient? httpClient, DohCache? cache})
    : _httpClient =
          httpClient ??
          (HttpClient()
            ..connectionTimeout = const Duration(seconds: 4)
            ..idleTimeout = const Duration(seconds: 20)),
      _cache = cache ?? DohCache();

  static final DohResolver instance = DohResolver._internal();
  static final _log = AppLogger.scope('DoH');

  factory DohResolver({HttpClient? httpClient, DohCache? cache}) {
    return DohResolver._internal(httpClient: httpClient, cache: cache);
  }

  static const String prefsKey = 'doh_provider';

  final HttpClient _httpClient;
  final DohCache _cache;
  final Map<String, Future<List<String>>> _inFlightLookups = {};

  DohProvider _currentProvider = DohProvider.cloudflare;
  DohProvider get currentProvider => _currentProvider;

  static const Map<String, List<String>> _bootstrapHosts = {
    'cloudflare-dns.com': ['1.1.1.1', '1.0.0.1'],
    'dns.google': ['8.8.8.8', '8.8.4.4'],
    '1.1.1.1': ['1.1.1.1'],
    '1.0.0.1': ['1.0.0.1'],
    '8.8.8.8': ['8.8.8.8'],
    '8.8.4.4': ['8.8.4.4'],
    'localhost': ['127.0.0.1'],
  };

  void init(SharedPreferences prefs) {
    final saved = prefs.getString(prefsKey);
    if (saved != null) {
      final match = DohProvider.values.where((p) => p.name == saved);
      if (match.isNotEmpty) {
        _currentProvider = match.first;
        _log.i('DoH initialized with provider: ${_currentProvider.title}');
        return;
      }
    }
    _currentProvider = DohProvider.cloudflare;
    _log.i('DoH initialized with default: ${_currentProvider.title}');
  }

  void setProvider(DohProvider provider) {
    if (_currentProvider != provider) {
      _currentProvider = provider;
      _cache.clear();
      _log.i('DoH provider switched to: ${provider.title}');
    }
  }

  String _sanitizeHost(String rawHost) {
    var host = rawHost.trim().toLowerCase();
    if (host.endsWith('.')) {
      host = host.substring(0, host.length - 1);
    }
    if (host.startsWith('[') && host.contains(']')) {
      final end = host.indexOf(']');
      return host.substring(1, end);
    }
    if (!host.contains('::') && host.contains(':')) {
      host = host.split(':').first;
    }
    return host;
  }

  Future<List<String>> resolve(String host) async {
    final sanitized = _sanitizeHost(host);
    if (sanitized.isEmpty) return const [];

    if (InternetAddress.tryParse(sanitized) != null) {
      return [sanitized];
    }

    if (sanitized == 'localhost' ||
        sanitized.endsWith('.localhost') ||
        sanitized.endsWith('.local') ||
        sanitized.endsWith('.internal')) {
      return const ['127.0.0.1'];
    }

    final bootstrap = _bootstrapHosts[sanitized];
    if (bootstrap != null) {
      return bootstrap;
    }

    final cached = _cache.get(sanitized);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    if (_inFlightLookups.containsKey(sanitized)) {
      return await _inFlightLookups[sanitized]!;
    }

    final completer = Completer<List<String>>();
    _inFlightLookups[sanitized] = completer.future;

    try {
      final result = await _executeResolve(sanitized);
      completer.complete(result);
      return result;
    } catch (e, st) {
      _log.w('Resolve failed for $sanitized: $e', e, st);
      final fallback = await _systemLookup(sanitized);
      completer.complete(fallback);
      return fallback;
    } finally {
      _inFlightLookups.remove(sanitized);
    }
  }

  Future<List<String>> _executeResolve(String host) async {
    if (!_currentProvider.isDoh) {
      return await _systemLookup(host);
    }

    try {
      final dohResult = await _queryDohWithFailover(host, _currentProvider);
      if (dohResult.isNotEmpty) {
        return dohResult;
      }
    } catch (e) {
      _log.w('DoH resolution error for $host: $e. Falling back to system DNS.');
    }

    return await _systemLookup(host);
  }

  Future<List<String>> _queryDohWithFailover(
    String host,
    DohProvider provider,
  ) async {
    try {
      final res = await _queryDohEndpoint(
        host: host,
        endpoint: provider.primaryUrl,
        hostHeader: provider.hostHeader,
        acceptHeader: provider.acceptHeader,
      ).timeout(const Duration(milliseconds: 3500));

      if (res.isNotEmpty) return res;
    } catch (e) {
      _log.w('Primary DoH endpoint failed for $host: $e. Trying secondary...');
    }

    if (provider.secondaryUrl.isNotEmpty) {
      try {
        final res = await _queryDohEndpoint(
          host: host,
          endpoint: provider.secondaryUrl,
          hostHeader: provider.hostHeader,
          acceptHeader: provider.acceptHeader,
        ).timeout(const Duration(milliseconds: 3500));

        if (res.isNotEmpty) return res;
      } catch (e) {
        _log.w('Secondary DoH endpoint failed for $host: $e');
      }
    }

    return const [];
  }

  Future<List<String>> _queryDohEndpoint({
    required String host,
    required String endpoint,
    required String hostHeader,
    required String acceptHeader,
  }) async {
    final uri = Uri.parse(
      endpoint,
    ).replace(queryParameters: {'name': host, 'type': 'A'});

    final req = await _httpClient.getUrl(uri);
    req.headers.set(HttpHeaders.acceptHeader, acceptHeader);
    if (hostHeader.isNotEmpty) {
      req.headers.set(HttpHeaders.hostHeader, hostHeader);
    }

    final resp = await req.close();
    if (resp.statusCode != HttpStatus.ok) {
      _log.w('DoH query returned HTTP ${resp.statusCode}');
      return const [];
    }

    final body = await resp.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;

    final status = json['Status'] as int? ?? -1;
    if (status != 0) {
      return const [];
    }

    final answers = json['Answer'] as List<dynamic>?;
    if (answers == null || answers.isEmpty) {
      return const [];
    }

    final ips = <String>[];
    int minTtl = DohCache.defaultTtlSeconds;

    for (final item in answers) {
      if (item is Map<String, dynamic>) {
        final type = item['type'] as int?;
        final data = item['data'] as String?;
        final ttl = item['TTL'] as int?;

        if (ttl != null && ttl < minTtl && ttl > 0) {
          minTtl = ttl;
        }

        if ((type == 1 || type == 28) && data != null && data.isNotEmpty) {
          ips.add(data.trim());
        }
      }
    }

    if (ips.isNotEmpty) {
      _cache.put(host, ips, ttlSeconds: minTtl);
    }

    return ips;
  }

  Future<List<String>> _systemLookup(String host) async {
    try {
      final lookups = await InternetAddress.lookup(host);
      final addresses = lookups.map((e) => e.address).toList();
      if (addresses.isNotEmpty) {
        _cache.put(host, addresses, ttlSeconds: DohCache.defaultTtlSeconds);
      }
      return addresses;
    } catch (e) {
      _log.w('System DNS lookup failed for $host: $e');
      return const [];
    }
  }

  Future<DohTestResult> testLookup({
    String domain = 'google.com',
    DohProvider? provider,
  }) async {
    final effectiveProvider = provider ?? _currentProvider;
    final stopwatch = Stopwatch()..start();

    try {
      List<String> ips;
      if (!effectiveProvider.isDoh) {
        ips = await _systemLookup(domain);
      } else {
        ips = await _queryDohWithFailover(domain, effectiveProvider);
      }
      stopwatch.stop();

      if (ips.isNotEmpty) {
        return DohTestResult(
          success: true,
          provider: effectiveProvider,
          latencyMs: stopwatch.elapsedMilliseconds,
          addresses: ips,
        );
      } else {
        return DohTestResult(
          success: false,
          provider: effectiveProvider,
          latencyMs: stopwatch.elapsedMilliseconds,
          addresses: const [],
          errorMessage: 'No DNS records found for $domain',
        );
      }
    } catch (e) {
      stopwatch.stop();
      return DohTestResult(
        success: false,
        provider: effectiveProvider,
        latencyMs: stopwatch.elapsedMilliseconds,
        addresses: const [],
        errorMessage: e.toString(),
      );
    }
  }

  void clearCache() {
    _cache.clear();
  }

  void dispose() {
    _cache.clear();
    _httpClient.close(force: true);
  }
}
