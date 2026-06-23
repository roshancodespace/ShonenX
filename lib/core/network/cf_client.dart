import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CFClient {
  static final CFClient instance = CFClient._internal();
  CFClient._internal();

  static GlobalKey<NavigatorState>? navigatorKey;

  String _userAgent = "";
  Map<String, String> _domainCookies = {};
  bool _cookiesLoaded = false;
  bool _isSolving = false;

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
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36';
        }
      }
      _cookiesLoaded = true;
    } catch (_) {
      _cookiesLoaded = true;
    }
  }

  Future<void> _saveCookieForDomain(String domain, String cookieString) async {
    _domainCookies[domain] = cookieString;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cf_domain_cookies_map',
        json.encode(_domainCookies),
      );
    } catch (_) {}
  }

  void updateSystemUserAgent(String ua) async {
    if (ua.isNotEmpty && _userAgent != ua) {
      _userAgent = ua;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cf_synced_user_agent', ua);
      } catch (_) {}
    }
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
    return await Navigator.push<bool?>(
          context,
          MaterialPageRoute(
            builder: (context) => CfSolverScreen(baseUrl: baseUrl),
          ),
        ) ??
        false;
  }
}

class CfSolverScreen extends StatefulWidget {
  final String baseUrl;
  const CfSolverScreen({super.key, required this.baseUrl});
  @override
  State<CfSolverScreen> createState() => _CfSolverScreenState();
}

class _CfSolverScreenState extends State<CfSolverScreen> {
  bool _ready = false;
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
    try {
      await CookieManager.instance().deleteAllCookies();
    } catch (_) {}
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _ready
          ? InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.baseUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                thirdPartyCookiesEnabled: true,
                clearCache: true,
                isTextInteractionEnabled: true,
                sharedCookiesEnabled: true,
                allowContentAccess: true,
                enable2DCanvasAcceleration: true,
                isUserInteractionEnabled: true,
                isFindInteractionEnabled: true,
              ),
              onLoadStop: (controller, url) async {
                final ua = await controller.evaluateJavascript(
                  source: "navigator.userAgent;",
                );
                if (ua != null) {
                  CFClient.instance.updateSystemUserAgent(ua.toString());
                }
                _poll(controller);
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  void _poll(InAppWebViewController controller) async {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri(widget.baseUrl),
      );
      final hasClearance = cookies.any(
        (c) => c.name.toLowerCase().contains('cf_'),
      );
      if (hasClearance) {
        timer.cancel();
        final cookieString = cookies
            .map((c) => '${c.name}=${c.value}')
            .join('; ');
        await CFClient.instance._saveCookieForDomain(
          WebUri(widget.baseUrl).host,
          cookieString,
        );
        if (mounted) Navigator.pop(context, true);
      }
    });
  }
}
