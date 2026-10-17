import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:webview_all/webview_all.dart';
import 'package:shonenx/core/utils/app_logger.dart';

final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(),
);

class BypassSession {
  final String cookie;
  final String userAgent;
  final DateTime updatedAt;

  BypassSession({
    required this.cookie,
    required this.userAgent,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get hasClearance => cookie.contains('cf_clearance');

  factory BypassSession.fromJson(Map<String, dynamic> json) {
    return BypassSession(
      cookie: json['cookie']?.toString() ?? '',
      userAgent: json['userAgent']?.toString() ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cookie': cookie,
      'userAgent': userAgent,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BypassSession copyWith({
    String? cookie,
    String? userAgent,
    DateTime? updatedAt,
  }) {
    return BypassSession(
      cookie: cookie ?? this.cookie,
      userAgent: userAgent ?? this.userAgent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Manages Cloudflare bypass sessions, mapping cookies and user-agents to domains.
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static final _log = AppLogger.scope(SessionManager);

  /// Map of Host/Domain -> BypassSession
  Map<String, BypassSession> _sessions = {};
  bool _initialized = false;
  Completer<void>? _initCompleter;

  /// Explicitly initialize SessionManager and populate bridge maps from disk.
  Future<void> init() => _init();

  Future<void> _init() async {
    if (_initialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    final completer = Completer<void>();
    _initCompleter = completer;

    try {
      _log.d('Loading persisted Cloudflare sessions...');
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

      // Synchronize all restored sessions to AnymeXRuntimeBridge memory maps
      for (final entry in _sessions.entries) {
        _syncToBridgeMemory(
          entry.key,
          entry.value.cookie,
          entry.value.userAgent,
        );
      }

      _initialized = true;
      _log.s(
        'Initialized with ${_sessions.length} session(s) cached: [${_sessions.keys.join(', ')}]',
      );
      completer.complete();
    } catch (e, st) {
      _initialized = true;
      _log.e('Failed to load sessions from SharedPreferences: $e', e, st);
      completer.complete();
    } finally {
      _initCompleter = null;
    }
  }

  /// Extracts the hostname from a URL or raw domain string.
  static String extractHost(String urlOrDomain) {
    final trimmed = urlOrDomain.trim();
    if (trimmed.isEmpty) return '';

    try {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.hasAuthority && uri.host.isNotEmpty) {
        return uri.host.toLowerCase();
      }
    } catch (_) {}

    String host = trimmed;
    if (host.contains('://')) {
      host = host.split('://').last;
    }
    host = host.split('/').first;
    host = host.split('?').first;
    host = host.split('#').first;
    if (host.contains(':')) {
      host = host.split(':').first;
    }
    return host.toLowerCase().trim();
  }

  /// Finds a [BypassSession] for [urlOrDomain] using progressive domain fallback:
  /// 1. Exact host
  /// 2. Host without 'www.'
  /// 3. Host with 'www.'
  /// 4. Root/parent domain (e.g. sub.domain.com -> domain.com)
  /// 5. Suffix/subdomain match against existing session keys
  BypassSession? _lookupSession(String urlOrDomain) {
    final host = extractHost(urlOrDomain);
    if (host.isEmpty) return null;

    // 1. Exact match
    if (_sessions.containsKey(host)) return _sessions[host];

    // 2. Without 'www.'
    final cleanHost = host.startsWith('www.') ? host.substring(4) : host;
    if (_sessions.containsKey(cleanHost)) return _sessions[cleanHost];

    // 3. With 'www.'
    final withWww = 'www.$cleanHost';
    if (_sessions.containsKey(withWww)) return _sessions[withWww];

    // 4. Parent domain
    final parts = host.split('.');
    if (parts.length >= 2) {
      final parentDomain = parts.sublist(parts.length - 2).join('.');
      if (_sessions.containsKey(parentDomain)) return _sessions[parentDomain];
    }

    // 5. Suffix match
    for (final entry in _sessions.entries) {
      final key = entry.key;
      if (host.endsWith('.$key') || key.endsWith('.$host')) {
        return entry.value;
      }
    }

    return null;
  }

  /// Injects cookies and user-agent directly into AnymeXRuntimeBridge in-memory maps
  /// for host, cleanHost, www-host, and parentDomain so extensions find them immediately.
  void _syncToBridgeMemory(String host, String cookie, String userAgent) {
    if (host.isEmpty) return;
    final cleanHost = host.startsWith('www.') ? host.substring(4) : host;
    final withWww = 'www.$cleanHost';
    final parts = cleanHost.split('.');
    final parentDomain = parts.length >= 2
        ? parts.sublist(parts.length - 2).join('.')
        : '';

    final targets = <String>{host, cleanHost, withWww};
    if (parentDomain.isNotEmpty) targets.add(parentDomain);

    for (final target in targets) {
      if (cookie.isNotEmpty) {
        bridge.AnymeXRuntimeBridge.cookiesMap[target] = cookie;
      }
      if (userAgent.isNotEmpty) {
        bridge.AnymeXRuntimeBridge.userAgentMap[target] = userAgent;
      }
    }
  }

  /// Dispatches cookies and user-agent to the native extension engine if active.
  Future<void> _pushToBridgeNative(
    String origin,
    String cookie,
    String userAgent,
  ) async {
    if (!bridge.AnymeXRuntimeBridge.controller.isReady.value ||
        origin.isEmpty) {
      return;
    }
    try {
      if (cookie.isNotEmpty) {
        await bridge.AnymeXRuntimeBridge.setCookies(origin, cookie);
      }
      if (userAgent.isNotEmpty) {
        await bridge.AnymeXRuntimeBridge.setUserAgent(origin, userAgent);
      }
      _log.d('Pushed cookies & UA to native extension runtime for $origin');
    } catch (e, st) {
      _log.w(
        'Failed to push to native extension runtime for $origin: $e',
        e,
        st,
      );
    }
  }

  Future<void> saveSession(
    String urlOrDomain, {
    String? cookie,
    String? userAgent,
  }) async {
    await _saveSession(urlOrDomain, cookie: cookie, userAgent: userAgent);
  }

  Future<void> _saveSession(
    String urlOrDomain, {
    String? cookie,
    String? userAgent,
  }) async {
    await _init();

    final host = extractHost(urlOrDomain);
    if (host.isEmpty) {
      _log.w('Cannot save session: invalid urlOrDomain "$urlOrDomain"');
      return;
    }

    final cleanHost = host.startsWith('www.') ? host.substring(4) : host;
    final origin = _getOrigin(urlOrDomain);

    final currentSession =
        _lookupSession(host) ?? BypassSession(cookie: '', userAgent: '');

    String updatedCookie = currentSession.cookie;
    String updatedUA = currentSession.userAgent;
    bool changed = false;

    if (cookie != null &&
        cookie.isNotEmpty &&
        currentSession.cookie != cookie) {
      updatedCookie = cookie;
      changed = true;
    }

    if (userAgent != null &&
        userAgent.isNotEmpty &&
        currentSession.userAgent != userAgent) {
      updatedUA = userAgent;
      changed = true;
    }

    if (changed || !_sessions.containsKey(cleanHost)) {
      final newSession = currentSession.copyWith(
        cookie: updatedCookie,
        userAgent: updatedUA,
        updatedAt: DateTime.now(),
      );

      _sessions[cleanHost] = newSession;
      _sessions[host] = newSession;

      // Update in-memory bridge maps
      _syncToBridgeMemory(cleanHost, updatedCookie, updatedUA);

      // Persist to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'cloudflare_bypass_sessions',
          jsonEncode(_sessions.map((k, v) => MapEntry(k, v.toJson()))),
        );
        _log.s(
          'Saved session for $cleanHost (cf_clearance: ${newSession.hasClearance}, cookies: ${updatedCookie.isNotEmpty}, UA: ${updatedUA.isNotEmpty})',
        );
      } catch (e, st) {
        _log.e('Failed to persist session to SharedPreferences', e, st);
      }

      // Push to native bridge if runtime is active
      if (origin.isNotEmpty) {
        await _pushToBridgeNative(origin, updatedCookie, updatedUA);
      }
    }
  }

  Future<String> getCookies(String urlOrDomain) async {
    await _init();
    return getCookiesSync(urlOrDomain);
  }

  String getCookiesSync(String urlOrDomain) {
    return _lookupSession(urlOrDomain)?.cookie ?? '';
  }

  Future<String?> getUserAgent(String urlOrDomain) async {
    await _init();
    return getUserAgentSync(urlOrDomain);
  }

  String? getUserAgentSync(String urlOrDomain) {
    final ua = _lookupSession(urlOrDomain)?.userAgent;
    return (ua != null && ua.isNotEmpty) ? ua : null;
  }

  bool hasClearance(String urlOrDomain) {
    return _lookupSession(urlOrDomain)?.hasClearance ?? false;
  }

  BypassSession? getSessionSync(String urlOrDomain) {
    return _lookupSession(urlOrDomain);
  }

  Future<void> clearSession(String urlOrDomain) async {
    await _init();
    final host = extractHost(urlOrDomain);
    if (host.isEmpty) return;

    final cleanHost = host.startsWith('www.') ? host.substring(4) : host;
    final withWww = 'www.$cleanHost';

    _sessions.remove(host);
    _sessions.remove(cleanHost);
    _sessions.remove(withWww);

    bridge.AnymeXRuntimeBridge.cookiesMap.remove(host);
    bridge.AnymeXRuntimeBridge.cookiesMap.remove(cleanHost);
    bridge.AnymeXRuntimeBridge.cookiesMap.remove(withWww);

    bridge.AnymeXRuntimeBridge.userAgentMap.remove(host);
    bridge.AnymeXRuntimeBridge.userAgentMap.remove(cleanHost);
    bridge.AnymeXRuntimeBridge.userAgentMap.remove(withWww);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cloudflare_bypass_sessions',
        jsonEncode(_sessions.map((k, v) => MapEntry(k, v.toJson()))),
      );
      _log.i('Cleared session for $cleanHost');
    } catch (e, st) {
      _log.e('Failed to persist cleared session in SharedPreferences', e, st);
    }
  }

  Future<void> clearAllSessions() async {
    await _init();
    _sessions.clear();
    bridge.AnymeXRuntimeBridge.cookiesMap.clear();
    bridge.AnymeXRuntimeBridge.userAgentMap.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cloudflare_bypass_sessions');
      _log.i('Cleared all Cloudflare sessions');
    } catch (e, st) {
      _log.e('Failed to clear sessions in SharedPreferences', e, st);
    }
  }

  Future<void> syncFromWebView(
    WebViewController controller,
    String fallbackUrl,
  ) async {
    final log = _log.child('syncFromWebView');
    log.i('Extracting session from WebView for: $fallbackUrl');

    String currentUrl = fallbackUrl;
    try {
      final url = await controller.currentUrl();
      if (url != null && url.isNotEmpty) {
        currentUrl = url;
      }
    } catch (e) {
      log.w('Could not read controller.currentUrl(): $e');
    }

    final targetUrl = currentUrl.isNotEmpty ? currentUrl : fallbackUrl;
    final origin = _getOrigin(targetUrl);
    final host = extractHost(targetUrl);

    if (host.isEmpty) {
      log.w('Could not resolve valid host from "$targetUrl"');
      return;
    }

    // 1. Extract cookies from WebViewCookieManager across candidate URIs
    final cookieManager = WebViewCookieManager();
    final Map<String, String> collectedCookies = {};

    final candidateUris = <Uri>[];
    void addCandidate(String u) {
      final uri = Uri.tryParse(u);
      if (uri != null && uri.hasAuthority && !candidateUris.contains(uri)) {
        candidateUris.add(uri);
      }
    }

    if (currentUrl.isNotEmpty) addCandidate(currentUrl);
    if (origin.isNotEmpty) {
      addCandidate(origin.endsWith('/') ? origin : '$origin/');
      addCandidate(
        origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin,
      );
    }
    if (fallbackUrl.isNotEmpty) {
      addCandidate(fallbackUrl);
      if (!fallbackUrl.endsWith('/')) addCandidate('$fallbackUrl/');
    }

    for (final uri in candidateUris) {
      try {
        final cookies = await cookieManager.getCookies(domain: uri);
        for (final c in cookies) {
          if (c.name.isNotEmpty) {
            collectedCookies[c.name] = c.value;
          }
        }
      } catch (e) {
        log.v('WebViewCookieManager.getCookies error for $uri: $e');
      }
    }

    // 2. Extract cookies via JS document.cookie (supplements non-HttpOnly cookies)
    try {
      final jsResult = await controller.runJavaScriptReturningResult(
        'document.cookie',
      );
      final jsCookieStr = _cleanJsResult(jsResult);
      if (jsCookieStr.isNotEmpty && jsCookieStr != 'null') {
        final pairs = jsCookieStr.split(';');
        for (final pair in pairs) {
          final trimmed = pair.trim();
          if (trimmed.isEmpty) continue;
          final eqIdx = trimmed.indexOf('=');
          if (eqIdx > 0) {
            final key = trimmed.substring(0, eqIdx).trim();
            final val = trimmed.substring(eqIdx + 1).trim();
            collectedCookies.putIfAbsent(key, () => val);
          }
        }
      }
    } catch (e) {
      log.v('document.cookie evaluation failed: $e');
    }

    // 3. Extract User Agent
    String userAgent = '';
    try {
      final ua = await controller.getUserAgent();
      if (ua != null && ua.trim().isNotEmpty) {
        userAgent = ua.trim();
      }
    } catch (e) {
      log.v('controller.getUserAgent failed: $e');
    }

    if (userAgent.isEmpty) {
      try {
        final uaResult = await controller.runJavaScriptReturningResult(
          'navigator.userAgent',
        );
        final cleanUA = _cleanJsResult(uaResult);
        if (cleanUA.isNotEmpty && cleanUA != 'null') {
          userAgent = cleanUA;
        }
      } catch (e) {
        log.v('navigator.userAgent evaluation failed: $e');
      }
    }

    final cookieString = collectedCookies.entries
        .map((e) => '${e.key}=${e.value}')
        .join('; ');

    final hasClearance = collectedCookies.containsKey('cf_clearance');

    log.d(
      'Session extraction results for $host:\n'
      '  • Cookies found: ${collectedCookies.length} (${collectedCookies.keys.join(', ')})\n'
      '  • cf_clearance: $hasClearance\n'
      '  • User-Agent: ${userAgent.isNotEmpty ? (userAgent.length > 70 ? "${userAgent.substring(0, 70)}..." : userAgent) : "NOT FOUND"}',
    );

    if (cookieString.isNotEmpty || userAgent.isNotEmpty) {
      await _saveSession(
        origin.isNotEmpty ? origin : host,
        cookie: cookieString.isNotEmpty ? cookieString : null,
        userAgent: userAgent.isNotEmpty ? userAgent : null,
      );

      if (hasClearance) {
        log.s('Verified cf_clearance acquired and session synced for $host');
      } else {
        log.i('Session cookies synced for $host (awaiting cf_clearance)');
      }
    } else {
      log.w('Could not extract any cookies or user-agent for $host');
    }
  }

  String _getOrigin(String urlOrDomain) {
    try {
      final uri = Uri.tryParse(urlOrDomain);
      if (uri != null && uri.hasScheme && uri.hasAuthority) {
        return '${uri.scheme}://${uri.host}';
      }
    } catch (_) {}
    final host = extractHost(urlOrDomain);
    return host.isNotEmpty ? 'https://$host' : '';
  }

  static String _cleanJsResult(Object? result) {
    if (result == null) return '';
    String s = result.toString().trim();
    if (s.startsWith('"') && s.endsWith('"') && s.length >= 2) {
      try {
        s = jsonDecode(s) as String;
      } catch (_) {
        s = s.substring(1, s.length - 1);
      }
    }
    return s.trim();
  }
}
