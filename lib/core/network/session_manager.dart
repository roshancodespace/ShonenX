import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/core/utils/app_logger.dart';

final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(),
);

class BypassSession {
  final String cookie;
  final String userAgent;
  final DateTime updatedAt;

  BypassSession({
    required String cookie,
    required String userAgent,
    DateTime? updatedAt,
  }) : cookie = _sanitize(cookie),
       userAgent = _sanitize(userAgent),
       updatedAt = updatedAt ?? DateTime.now();

  bool get hasClearance => cookie.contains('cf_clearance');

  static String _sanitize(String val) {
    return val.replaceAll('\r', '').replaceAll('\n', '').trim();
  }

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

/// Manager for Cloudflare cookies and User-Agent bypass sessions.
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static final _log = AppLogger.scope(SessionManager);

  final Map<String, BypassSession> _sessions = {};
  bool _initialized = false;
  Future<void>? _initFuture;

  /// Synchronously initialize with an existing SharedPreferences instance.
  void initWithPrefs(SharedPreferences prefs) {
    if (_initialized) return;
    _loadFromPrefs(prefs);
    _initialized = true;
  }

  /// Initialize SessionManager and restore persisted sessions.
  Future<void> _init([SharedPreferences? prefs]) async {
    if (_initialized) return;
    if (_initFuture != null) return _initFuture;

    final completer = Completer<void>();
    _initFuture = completer.future;

    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      _loadFromPrefs(p);
      _initialized = true;
      completer.complete();
    } catch (e, st) {
      _initialized = true;
      _log.e('Failed to load sessions from SharedPreferences: $e', e, st);
      completer.complete();
    } finally {
      _initFuture = null;
    }
  }

  void _loadFromPrefs(SharedPreferences prefs) {
    try {
      final raw = prefs.getString('cloudflare_bypass_sessions');
      if (raw == null || raw.isEmpty) return;

      final Map<String, dynamic> decoded = jsonDecode(raw);
      final Map<String, BypassSession> loaded = {};

      decoded.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final host = extractHost(key);
          if (host.isNotEmpty) {
            loaded[host] = BypassSession.fromJson(value);
          }
        }
      });

      _sessions.addAll(loaded);

      // Sync restored sessions into AnymeXRuntimeBridge memory maps
      _syncAllToBridge();

      _log.s(
        'Restored ${_sessions.length} session(s) cached: [${_sessions.keys.join(', ')}]',
      );
    } catch (e, st) {
      _log.e('Failed to parse persisted sessions: $e', e, st);
    }
  }

  /// Extracts the normalized lowercase hostname from a URL or raw domain.
  static String extractHost(String urlOrDomain) {
    var raw = urlOrDomain.trim();
    if (raw.isEmpty) return '';

    if (raw.contains('://')) {
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.host.isNotEmpty) {
        return _cleanHost(uri.host);
      }
      raw = raw.split('://').last;
    }

    final slashIdx = raw.indexOf('/');
    if (slashIdx != -1) raw = raw.substring(0, slashIdx);

    final qIdx = raw.indexOf('?');
    if (qIdx != -1) raw = raw.substring(0, qIdx);

    final hIdx = raw.indexOf('#');
    if (hIdx != -1) raw = raw.substring(0, hIdx);

    final colonIdx = raw.indexOf(':');
    if (colonIdx != -1 && !raw.contains('::')) {
      raw = raw.substring(0, colonIdx);
    }

    return _cleanHost(raw);
  }

  static String _cleanHost(String host) {
    var h = host.trim().toLowerCase();
    if (h.endsWith('.')) {
      h = h.substring(0, h.length - 1);
    }
    return h;
  }

  /// Fast, deterministic O(1) domain lookup with safe hierarchy fallbacks.
  BypassSession? _lookupSession(String urlOrDomain) {
    final host = extractHost(urlOrDomain);
    if (host.isEmpty || _sessions.isEmpty) return null;

    // 1. Exact match
    final exact = _sessions[host];
    if (exact != null) return exact;

    // 2. www-stripped or www-prepended match
    if (host.startsWith('www.')) {
      final clean = host.substring(4);
      final match = _sessions[clean];
      if (match != null) return match;
    } else {
      final withWww = 'www.$host';
      final match = _sessions[withWww];
      if (match != null) return match;
    }

    // 3. Parent domain lookups (e.g. sub.domain.com -> domain.com)
    final parts = host.split('.');
    if (parts.length > 2) {
      for (int i = 1; i < parts.length - 1; i++) {
        final parent = parts.sublist(i).join('.');
        final match = _sessions[parent];
        if (match != null) return match;
      }
    }

    return null;
  }

  /// Injects cookies and user-agent into AnymeXRuntimeBridge memory maps.
  void _syncHostToBridge(String host, String cookie, String userAgent) {
    if (host.isEmpty) return;
    final cleanHost = host.startsWith('www.') ? host.substring(4) : host;
    final withWww = 'www.$cleanHost';

    final targets = <String>{host, cleanHost, withWww};
    for (final target in targets) {
      if (cookie.isNotEmpty) {
        bridge.AnymeXRuntimeBridge.cookiesMap[target] = cookie;
      }
      if (userAgent.isNotEmpty) {
        bridge.AnymeXRuntimeBridge.userAgentMap[target] = userAgent;
      }
    }
  }

  void _syncAllToBridge() {
    for (final entry in _sessions.entries) {
      _syncHostToBridge(entry.key, entry.value.cookie, entry.value.userAgent);
    }
  }

  /// Dispatches cookies and user-agent to the native extension engine safely.
  Future<void> _pushToBridgeNative(
    String host,
    String cookie,
    String userAgent,
  ) async {
    if (!bridge.AnymeXRuntimeBridge.controller.isReady.value || host.isEmpty) {
      return;
    }
    final origin = 'https://$host';
    try {
      if (cookie.isNotEmpty) {
        await bridge.AnymeXRuntimeBridge.setCookies(origin, cookie);
      }
      if (userAgent.isNotEmpty) {
        await bridge.AnymeXRuntimeBridge.setUserAgent(origin, userAgent);
      }
      _log.d('Pushed cookies & UA to native extension runtime for $origin');
    } catch (e) {
      _log.w('Failed to push to native extension runtime for $origin: $e');
    }
  }

  /// Saves session data for [urlOrDomain].
  Future<void> saveSession(
    String urlOrDomain, {
    String? cookie,
    String? userAgent,
  }) async {
    final host = extractHost(urlOrDomain);
    if (host.isEmpty) return;

    final cleanHost = host.startsWith('www.') ? host.substring(4) : host;
    final current =
        _lookupSession(cleanHost) ?? BypassSession(cookie: '', userAgent: '');

    final newCookie = cookie != null && cookie.isNotEmpty
        ? cookie
        : current.cookie;
    final newUA = userAgent != null && userAgent.isNotEmpty
        ? userAgent
        : current.userAgent;

    if (newCookie == current.cookie &&
        newUA == current.userAgent &&
        _sessions.containsKey(cleanHost)) {
      return;
    }

    final updated = current.copyWith(
      cookie: newCookie,
      userAgent: newUA,
      updatedAt: DateTime.now(),
    );

    _sessions[cleanHost] = updated;
    if (host != cleanHost) {
      _sessions[host] = updated;
    }

    // Sync bridge memory maps immediately
    _syncHostToBridge(cleanHost, newCookie, newUA);
    if (host != cleanHost) {
      _syncHostToBridge(host, newCookie, newUA);
    }

    // Persist to disk asynchronously
    unawaited(_persistSessions());

    // Push to native bridge if runtime is active
    unawaited(_pushToBridgeNative(cleanHost, newCookie, newUA));
  }

  Future<void> _persistSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final copy = Map<String, BypassSession>.from(_sessions);
      final encoded = jsonEncode(copy.map((k, v) => MapEntry(k, v.toJson())));
      await prefs.setString('cloudflare_bypass_sessions', encoded);
    } catch (e, st) {
      _log.e('Failed to persist session to SharedPreferences: $e', e, st);
    }
  }

  String getCookiesSync(String urlOrDomain) {
    return _lookupSession(urlOrDomain)?.cookie ?? '';
  }

  Future<String> getCookies(String urlOrDomain) async {
    if (!_initialized) await _init();
    return getCookiesSync(urlOrDomain);
  }

  String? getUserAgentSync(String urlOrDomain) {
    final ua = _lookupSession(urlOrDomain)?.userAgent;
    return (ua != null && ua.isNotEmpty) ? ua : null;
  }

  Future<String?> getUserAgent(String urlOrDomain) async {
    if (!_initialized) await _init();
    return getUserAgentSync(urlOrDomain);
  }

  bool hasClearance(String urlOrDomain) {
    return _lookupSession(urlOrDomain)?.hasClearance ?? false;
  }

  BypassSession? getSessionSync(String urlOrDomain) {
    return _lookupSession(urlOrDomain);
  }

  Future<void> clearSession(String urlOrDomain) async {
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

    unawaited(_persistSessions());
    _log.i('Cleared session for $cleanHost');
  }

  Future<void> clearAllSessions() async {
    _sessions.clear();
    bridge.AnymeXRuntimeBridge.cookiesMap.clear();
    bridge.AnymeXRuntimeBridge.userAgentMap.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cloudflare_bypass_sessions');
      _log.i('Cleared all Cloudflare sessions');
    } catch (e, st) {
      _log.e('Failed to clear sessions from SharedPreferences: $e', e, st);
    }
  }
}
