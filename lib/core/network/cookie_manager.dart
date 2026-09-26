import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;

final cookieManagerProvider = Provider<CookieManager>((ref) => CookieManager());

class CookieManager {
  static final CookieManager _instance = CookieManager._internal();
  factory CookieManager() => _instance;
  CookieManager._internal();

  Map<String, String> _domainCookies = {};
  Map<String, String> _domainUserAgents = {};
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      final cookiesJsonStr =
          prefs.getString('generic_domain_cookies_map') ?? '{}';
      final Map<String, dynamic> decodedCookies = jsonDecode(cookiesJsonStr);
      _domainCookies = decodedCookies.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      final uaJsonStr = prefs.getString('generic_domain_ua_map') ?? '{}';
      final Map<String, dynamic> decodedUas = jsonDecode(uaJsonStr);
      _domainUserAgents = decodedUas.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  /// Store cookies and User-Agent associated with a domain/origin.
  Future<void> setCookies(
    String urlOrDomain,
    String cookieString,
    String userAgent,
  ) async {
    await _init();
    final normalizedDomain = _normalizeDomain(urlOrDomain);

    bool changed = false;
    if (_domainCookies[normalizedDomain] != cookieString) {
      _domainCookies[normalizedDomain] = cookieString;
      changed = true;
    }

    if (_domainUserAgents[normalizedDomain] != userAgent) {
      _domainUserAgents[normalizedDomain] = userAgent;
      changed = true;
    }

    if (changed) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'generic_domain_cookies_map',
          jsonEncode(_domainCookies),
        );
        await prefs.setString(
          'generic_domain_ua_map',
          jsonEncode(_domainUserAgents),
        );
      } catch (_) {}
    }

    // Sync to Extension Runtime if ready
    if (bridge.AnymeXRuntimeBridge.controller.isReady.value) {
      final origin = _getOriginForAnymeX(urlOrDomain);
      if (origin.isNotEmpty) {
        await bridge.AnymeXRuntimeBridge.setCookies(origin, cookieString);
        await bridge.AnymeXRuntimeBridge.setUserAgent(origin, userAgent);
      }
    }
  }

  /// Retrieve User-Agent for a requested domain/origin.
  Future<String> getUserAgent(String urlOrDomain) async {
    await _init();
    final normalizedDomain = _normalizeDomain(urlOrDomain);
    return _domainUserAgents[normalizedDomain] ??
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  }

  /// Retrieve cookies for a requested domain/origin.
  Future<String> getCookies(String urlOrDomain) async {
    await _init();
    final normalizedDomain = _normalizeDomain(urlOrDomain);
    return _domainCookies[normalizedDomain] ?? '';
  }

  String _normalizeDomain(String urlOrDomain) {
    try {
      final uri = Uri.tryParse(urlOrDomain);
      if (uri != null && uri.hasAuthority) {
        return uri.host; // e.g., 'animepahe.pw'
      }
    } catch (_) {}
    return urlOrDomain;
  }

  String _getOriginForAnymeX(String urlOrDomain) {
    try {
      final uri = Uri.tryParse(urlOrDomain);
      if (uri != null && uri.hasScheme && uri.hasAuthority) {
        return '${uri.scheme}://${uri.host}';
      }
    } catch (_) {}
    return urlOrDomain;
  }
}
