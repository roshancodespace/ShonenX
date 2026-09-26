import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart' as bridge;
import 'package:shonenx/source_engine/models/source_info.dart';

class CFClient {
  static final CFClient instance = CFClient._internal();
  CFClient._internal();

  static GlobalKey<NavigatorState>? navigatorKey;

  String _userAgent = "";
  Map<String, String> _domainCookies = {};
  bool _cookiesLoaded = false;
  bool _isSolving = false;

  String get currentUserAgent => _userAgent;
  Map<String, String> get domainCookies => Map.unmodifiable(_domainCookies);

  Future<void> init() async {
    await _ensureCookiesLoaded();
  }

  Future<void> _ensureCookiesLoaded() async {
    if (_cookiesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cf_domain_cookies_map') ?? '{}';
      final Map<String, dynamic> decoded = json.decode(jsonStr);
      _domainCookies = decoded.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      final storedUa = prefs.getString('cf_synced_user_agent');
      if (storedUa != null && storedUa.isNotEmpty) {
        _userAgent = storedUa;
      } else {
        try {
          _userAgent = await InAppWebViewController.getDefaultUserAgent();
        } catch (_) {
          _userAgent =
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';
        }
      }
      _cookiesLoaded = true;

      // Sync all loaded cookies and UA to AnymeXRuntimeBridge so plugins have clearance on launch
      for (final entry in _domainCookies.entries) {
        final domain = entry.key;
        final cookieStr = entry.value;
        if (domain.isNotEmpty && cookieStr.isNotEmpty) {
          final url = domain.startsWith('http') ? domain : 'https://$domain';
          unawaited(bridge.AnymeXRuntimeBridge.setCookies(url, cookieStr));
          if (_userAgent.isNotEmpty) {
            unawaited(bridge.AnymeXRuntimeBridge.setUserAgent(url, _userAgent));
          }
        }
      }
      if (_userAgent.isNotEmpty) {
        unawaited(bridge.AnymeXRuntimeBridge.setUserAgent('https://anymex.default', _userAgent));
      }
    } catch (_) {
      _cookiesLoaded = true;
    }
  }

  Future<void> _saveCookieForDomain(String domain, String cookieString, {String? url}) async {
    final cleanHost = domain.replaceAll(RegExp(r'^https?://'), '').split('/').first;
    _domainCookies[cleanHost] = cookieString;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cf_domain_cookies_map',
        json.encode(_domainCookies),
      );
    } catch (_) {}

    // Synchronize directly with AnymeXRuntimeBridge so all plugins receive clearance
    try {
      final targetUrl = url ?? (cleanHost.startsWith('http') ? cleanHost : 'https://$cleanHost');
      await bridge.AnymeXRuntimeBridge.setCookies(targetUrl, cookieString);
    } catch (_) {}
  }

  void updateSystemUserAgent(String ua, {String? domain}) async {
    if (ua.isNotEmpty) {
      _userAgent = ua;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cf_synced_user_agent', ua);
      } catch (_) {}

      try {
        if (domain != null && domain.isNotEmpty) {
          final cleanHost = domain.replaceAll(RegExp(r'^https?://'), '').split('/').first;
          await bridge.AnymeXRuntimeBridge.setUserAgent('https://$cleanHost', ua);
        }
        await bridge.AnymeXRuntimeBridge.setUserAgent('https://anymex.default', ua);
      } catch (_) {}
    }
  }

  bool hasClearanceForHost(String host) {
    if (host.isEmpty) return false;
    final cleanHost = host.replaceAll(RegExp(r'^https?://'), '').split('/').first;
    final cookie = _domainCookies[cleanHost];
    if (cookie == null || cookie.isEmpty) return false;
    return cookie.contains('cf_clearance') || cookie.contains('cf_') || cookie.contains('__cf');
  }

  String? getCookiesForHost(String host) {
    if (host.isEmpty) return null;
    final cleanHost = host.replaceAll(RegExp(r'^https?://'), '').split('/').first;
    return _domainCookies[cleanHost];
  }

  Future<void> clearCookiesForHost(String host) async {
    if (host.isEmpty) return;
    final cleanHost = host.replaceAll(RegExp(r'^https?://'), '').split('/').first;
    _domainCookies.remove(cleanHost);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cf_domain_cookies_map',
        json.encode(_domainCookies),
      );
      await bridge.AnymeXRuntimeBridge.setCookies('https://$cleanHost', '');
      await CookieManager.instance().deleteCookies(url: WebUri('https://$cleanHost'));
    } catch (_) {}
  }

  static Future<bool> solveForUrl(
    BuildContext context,
    String url, {
    String? title,
  }) async {
    final effectiveUrl = url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';

    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (context) => CfSolverScreen(
          baseUrl: effectiveUrl,
          title: title,
        ),
      ),
    );
    return result ?? false;
  }

  static Future<bool> solveForSource(
    BuildContext context,
    SourceInfo source,
  ) async {
    final url = source.baseUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No base URL found for source "${source.name}".'),
        ),
      );
      return false;
    }
    return solveForUrl(context, url, title: '${source.name} Verification');
  }

  Map<String, String> _buildHeaders(Uri uri, Map<String, String>? userHeaders) {
    final domain = uri.host;
    Map<String, String> finalHeaders = {
      if (_userAgent.isNotEmpty) 'User-Agent': _userAgent,
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language': 'en-US,en;q=0.9',
      'X-Requested-With': 'XMLHttpRequest',
    };
    if (userHeaders != null) finalHeaders.addAll(userHeaders);
    String cfCookie = _domainCookies[domain] ?? '';
    final existingCookieKey = finalHeaders.keys.cast<String?>().firstWhere(
      (k) => k?.toLowerCase() == 'cookie',
      orElse: () => null,
    );
    if (existingCookieKey != null) {
      final userCookie = finalHeaders[existingCookieKey]!;
      finalHeaders['Cookie'] = cfCookie.isNotEmpty
          ? '$userCookie; $cfCookie'
          : userCookie;
      finalHeaders.remove(existingCookieKey);
    } else if (cfCookie.isNotEmpty) {
      finalHeaders['Cookie'] = cfCookie;
    }
    return finalHeaders;
  }

  bool _isCfBlock(http.Response res) {
    final server = res.headers['server']?.toLowerCase() ?? '';
    return server.contains('cloudflare') ||
        res.headers.containsKey('cf-ray') ||
        res.statusCode == 403 ||
        res.statusCode == 503;
  }

  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) => _request(
    url,
    queryParameters,
    headers,
    (u, h) => http.get(u, headers: h),
  );

  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? queryParameters,
  }) => _request(
    url,
    queryParameters,
    headers,
    (u, h) => http.post(u, headers: h, body: body),
  );

  Future<http.Response> _request(
    String url,
    Map<String, String>? params,
    Map<String, String>? headers,
    Future<http.Response> Function(Uri, Map<String, String>) action,
  ) async {
    await _ensureCookiesLoaded();
    final uri = Uri.parse(url).replace(queryParameters: params);
    var response = await action(uri, _buildHeaders(uri, headers));
    if (_isCfBlock(response)) {
      if (_isSolving) throw Exception("Verification in progress.");
      _isSolving = true;
      try {
        final bool solved = await _solveWithUI('${uri.scheme}://${uri.host}');
        _isSolving = false;
        if (solved) {
          _cookiesLoaded = false;
          await _ensureCookiesLoaded();
          return await action(uri, _buildHeaders(uri, headers));
        }
        throw Exception("Failed to solve challenge.");
      } catch (e) {
        _isSolving = false;
        rethrow;
      }
    }
    return response;
  }

  Future<bool> _solveWithUI(String baseUrl) async {
    final context = navigatorKey?.currentContext;
    if (context == null) return false;
    return await solveForUrl(context, baseUrl);
  }
}

class CfSolverScreen extends StatefulWidget {
  final String baseUrl;
  final String? title;

  const CfSolverScreen({
    super.key,
    required this.baseUrl,
    this.title,
  });

  @override
  State<CfSolverScreen> createState() => _CfSolverScreenState();
}

class _CfSolverScreenState extends State<CfSolverScreen> {
  InAppWebViewController? _controller;
  double _progress = 0.0;
  String _pageTitle = '';
  bool _ready = false;
  bool _isSolved = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final host = Uri.tryParse(widget.baseUrl)?.host ?? widget.baseUrl;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title ?? 'Cloudflare Solver',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              host,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload',
            onPressed: () => _controller?.reload(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.tonalIcon(
              onPressed: () {
                if (_controller != null) {
                  _checkVerification(_controller!, manualTrigger: true);
                }
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Done'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              minHeight: 2.5,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Complete the Cloudflare verification challenge if prompted. The window will close automatically once clearance is detected.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _ready
                ? InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.baseUrl)),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      domStorageEnabled: true,
                      databaseEnabled: true,
                      thirdPartyCookiesEnabled: true,
                      sharedCookiesEnabled: true,
                      allowContentAccess: true,
                      enable2DCanvasAcceleration: true,
                      isUserInteractionEnabled: true,
                      isFindInteractionEnabled: true,
                      useWideViewPort: true,
                      loadWithOverviewMode: true,
                      supportZoom: true,
                      builtInZoomControls: true,
                      displayZoomControls: false,
                      cacheEnabled: true,
                      clearCache: false,
                    ),
                    onWebViewCreated: (controller) {
                      _controller = controller;
                    },
                    onProgressChanged: (controller, progress) {
                      if (mounted) {
                        setState(() => _progress = progress / 100.0);
                      }
                    },
                    onTitleChanged: (controller, title) {
                      if (mounted && title != null) {
                        setState(() => _pageTitle = title);
                      }
                    },
                    onLoadStop: (controller, url) async {
                      final ua = await controller.evaluateJavascript(
                        source: "navigator.userAgent;",
                      );
                      if (ua != null && ua.toString().isNotEmpty) {
                        CFClient.instance.updateSystemUserAgent(
                          ua.toString(),
                          domain: url?.host,
                        );
                      }
                      _startPolling(controller);
                      _checkVerification(controller);
                    },
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  void _startPolling(InAppWebViewController controller) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: 1000),
      (timer) async {
        if (!mounted || _isSolved) {
          timer.cancel();
          return;
        }
        await _checkVerification(controller);
      },
    );
  }

  Future<void> _checkVerification(
    InAppWebViewController controller, {
    bool manualTrigger = false,
  }) async {
    if (_isSolved) return;

    try {
      final currentUrl = await controller.getUrl();
      final targetUri = currentUrl ?? WebUri(widget.baseUrl);
      final cookies = await CookieManager.instance().getCookies(url: targetUri);

      final hasClearance = cookies.any(
        (c) => c.name.toLowerCase() == 'cf_clearance',
      );
      final hasCfCookie = cookies.any(
        (c) =>
            c.name.toLowerCase().startsWith('cf_') ||
            c.name.toLowerCase().startsWith('__cf'),
      );

      final title = (await controller.getTitle()) ?? _pageTitle;
      final isChallengeTitle =
          title.toLowerCase().contains('just a moment') ||
          title.toLowerCase().contains('attention required') ||
          title.toLowerCase().contains('cloudflare');

      final isSolved = hasClearance ||
          (manualTrigger && cookies.isNotEmpty) ||
          (hasCfCookie && !isChallengeTitle && _progress >= 0.85);

      if (isSolved) {
        _isSolved = true;
        _pollingTimer?.cancel();

        final cookieString =
            cookies.map((c) => '${c.name}=${c.value}').join('; ');

        String userAgent = '';
        try {
          final ua = await controller.evaluateJavascript(
            source: 'navigator.userAgent;',
          );
          if (ua != null && ua.toString().isNotEmpty) {
            userAgent = ua.toString();
          }
        } catch (_) {}

        final domain = targetUri.host.isNotEmpty
            ? targetUri.host
            : WebUri(widget.baseUrl).host;

        await CFClient.instance._saveCookieForDomain(
          domain,
          cookieString,
          url: widget.baseUrl,
        );

        if (userAgent.isNotEmpty) {
          CFClient.instance.updateSystemUserAgent(userAgent, domain: domain);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Cloudflare verified for $domain! Clearance active.'),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (_) {}
  }
}
