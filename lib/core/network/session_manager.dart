import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as webview;

final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(),
);

class BypassSession {
  final String cookie;
  final String userAgent;

  BypassSession({required this.cookie, required this.userAgent});

  factory BypassSession.fromJson(Map<String, dynamic> json) {
    return BypassSession(
      cookie: json['cookie']?.toString() ?? '',
      userAgent: json['userAgent']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'cookie': cookie, 'userAgent': userAgent};
  }

  BypassSession copyWith({String? cookie, String? userAgent}) {
    return BypassSession(
      cookie: cookie ?? this.cookie,
      userAgent: userAgent ?? this.userAgent,
    );
  }
}

/// Manages Cloudflare bypass sessions, mapping cookies to domains,
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  /// Map of Domain -> BypassSession
  Map<String, BypassSession> _sessions = {};
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJsonStr =
          prefs.getString('cloudflare_bypass_sessions') ?? '{}';
      final Map<String, dynamic> decoded = jsonDecode(sessionsJsonStr);

      _sessions = decoded.map((key, value) {
        return MapEntry(
          key,
          BypassSession.fromJson(value as Map<String, dynamic>),
        );
      });
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  Future<void> _saveSession(
    String urlOrDomain, {
    String? cookie,
    String? userAgent,
  }) async {
    await _init();
    final normalizedDomain = _normalizeDomain(urlOrDomain);
    final origin = _getOriginForAnymexRuntime(urlOrDomain);

    final currentSession =
        _sessions[normalizedDomain] ?? BypassSession(cookie: '', userAgent: '');
    bool changed = false;

    String updatedCookie = currentSession.cookie;
    String updatedUA = currentSession.userAgent;

    if (cookie != null && currentSession.cookie != cookie) {
      updatedCookie = cookie;
      changed = true;
      if (bridge.AnymeXRuntimeBridge.controller.isReady.value &&
          origin.isNotEmpty) {
        await bridge.AnymeXRuntimeBridge.setCookies(origin, cookie);
      }
    }

    if (userAgent != null && currentSession.userAgent != userAgent) {
      updatedUA = userAgent;
      changed = true;
      if (bridge.AnymeXRuntimeBridge.controller.isReady.value &&
          origin.isNotEmpty) {
        await bridge.AnymeXRuntimeBridge.setUserAgent(origin, userAgent);
      }
    }

    if (changed) {
      _sessions[normalizedDomain] = currentSession.copyWith(
        cookie: updatedCookie,
        userAgent: updatedUA,
      );
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'cloudflare_bypass_sessions',
          jsonEncode(_sessions.map((k, v) => MapEntry(k, v.toJson()))),
        );
      } catch (_) {}
    }
  }

  Future<String> getCookies(String urlOrDomain) async {
    await _init();
    return getCookiesSync(urlOrDomain);
  }

  String getCookiesSync(String urlOrDomain) {
    return _sessions[_normalizeDomain(urlOrDomain)]?.cookie ?? '';
  }

  Future<String?> getUserAgent(String urlOrDomain) async {
    await _init();
    return getUserAgentSync(urlOrDomain);
  }

  String? getUserAgentSync(String urlOrDomain) {
    final ua = _sessions[_normalizeDomain(urlOrDomain)]?.userAgent;
    return (ua != null && ua.isNotEmpty) ? ua : null;
  }

  Future<void> syncFromWebView(
    webview.InAppWebViewController controller,
    String fallbackUrl,
  ) async {
    final currentUrlObj = await controller.getUrl();
    final currentUrl = currentUrlObj?.toString() ?? fallbackUrl;
    final origin = _getOriginForAnymexRuntime(currentUrl);

    // 1. Extract Cookies
    String cookieString = '';
    final cookies = await webview.CookieManager.instance().getCookies(
      url: webview.WebUri(origin),
    );
    if (cookies.isNotEmpty) {
      cookieString = cookies.map((c) => '${c.name}=${c.value}').join('; ');
    }

    // 2. Extract User Agent
    String userAgent = '';
    try {
      final uaResult = await controller.evaluateJavascript(
        source: 'navigator.userAgent',
      );
      if (uaResult != null) {
        userAgent = uaResult.toString().replaceAll('"', '');
      }
    } catch (_) {}

    // 3. Save Both
    if (cookieString.isNotEmpty || userAgent.isNotEmpty) {
      await _saveSession(origin, cookie: cookieString, userAgent: userAgent);
    }
  }

  String _normalizeDomain(String urlOrDomain) {
    try {
      final uri = Uri.tryParse(urlOrDomain);
      if (uri != null && uri.hasAuthority) {
        return uri.host;
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
