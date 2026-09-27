import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as webview;

final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(),
);

/// Manages Cloudflare bypass sessions, mapping cookies to domains,
/// and synchronizing state with the extension runtime bridge.
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

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
      final Map<String, dynamic> decodedUAs = jsonDecode(uaJsonStr);
      _domainUserAgents = decodedUAs.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  /// Store cookies associated with a domain/origin.
  Future<void> setCookies(String urlOrDomain, String cookieString) async {
    await _init();
    final normalizedDomain = _normalizeDomain(urlOrDomain);

    bool changed = false;
    if (_domainCookies[normalizedDomain] != cookieString) {
      _domainCookies[normalizedDomain] = cookieString;
      changed = true;
    }

    if (changed) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'generic_domain_cookies_map',
          jsonEncode(_domainCookies),
        );
      } catch (_) {}
    }

    // Sync to Extension Runtime if ready
    if (bridge.AnymeXRuntimeBridge.controller.isReady.value) {
      final origin = _getOriginForAnymexRuntime(urlOrDomain);
      if (origin.isNotEmpty) {
        await bridge.AnymeXRuntimeBridge.setCookies(origin, cookieString);
      }
    }
  }

  /// Store User-Agent associated with a domain/origin.
  Future<void> setUserAgent(String urlOrDomain, String userAgent) async {
    await _init();
    final normalizedDomain = _normalizeDomain(urlOrDomain);

    bool changed = false;
    if (_domainUserAgents[normalizedDomain] != userAgent) {
      _domainUserAgents[normalizedDomain] = userAgent;
      changed = true;
    }

    if (changed) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'generic_domain_ua_map',
          jsonEncode(_domainUserAgents),
        );
      } catch (_) {}
    }

    // Sync to Extension Runtime if ready
    if (bridge.AnymeXRuntimeBridge.controller.isReady.value) {
      final origin = _getOriginForAnymexRuntime(urlOrDomain);
      if (origin.isNotEmpty) {
        await bridge.AnymeXRuntimeBridge.setUserAgent(origin, userAgent);
      }
    }
  }

  /// Retrieve cookies for a requested domain/origin.
  Future<String> getCookies(String urlOrDomain) async {
    await _init();
    return getCookiesSync(urlOrDomain);
  }

  /// Synchronously retrieve cookies for a requested domain/origin.
  String getCookiesSync(String urlOrDomain) {
    final normalizedDomain = _normalizeDomain(urlOrDomain);
    return _domainCookies[normalizedDomain] ?? '';
  }

  /// Retrieve User-Agent for a requested domain/origin.
  Future<String?> getUserAgent(String urlOrDomain) async {
    await _init();
    return getUserAgentSync(urlOrDomain);
  }

  /// Synchronously retrieve User-Agent for a requested domain/origin.
  String? getUserAgentSync(String urlOrDomain) {
    final normalizedDomain = _normalizeDomain(urlOrDomain);
    return _domainUserAgents[normalizedDomain];
  }

  /// Extracts cookies from the given WebView controller and saves them to the session.
  Future<void> syncFromWebView(
    webview.InAppWebViewController controller,
    String fallbackUrl,
  ) async {
    final currentUrlObj = await controller.getUrl();
    final currentUrl = currentUrlObj?.toString() ?? fallbackUrl;

    final origin = _getOriginForAnymexRuntime(currentUrl);

    final inAppCookieManager = webview.CookieManager.instance();
    final cookies = await inAppCookieManager.getCookies(
      url: webview.WebUri(origin),
    );

    if (cookies.isNotEmpty) {
      final cookieString = cookies
          .map((c) => '${c.name}=${c.value}')
          .join('; ');
      await setCookies(origin, cookieString);
    }

    try {
      final uaResult = await controller.evaluateJavascript(
        source: 'navigator.userAgent',
      );
      if (uaResult != null) {
        final ua = uaResult.toString().replaceAll('"', '');
        if (ua.isNotEmpty) {
          await setUserAgent(origin, ua);
        }
      }
    } catch (_) {}
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

  String _getOriginForAnymexRuntime(String urlOrDomain) {
    try {
      final uri = Uri.tryParse(urlOrDomain);
      if (uri != null && uri.hasScheme && uri.hasAuthority) {
        return '${uri.scheme}://${uri.host}';
      }
    } catch (_) {}
    return urlOrDomain;
  }
}
