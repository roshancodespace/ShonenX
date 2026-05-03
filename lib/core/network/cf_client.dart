import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CFClient {
  static final CFClient instance = CFClient._internal();
  CFClient._internal();

  static GlobalKey<NavigatorState>? navigatorKey;

  final String _userAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
  String _cookieString = '';
  bool _isSolving = false;

  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async => _request(url, queryParameters, (u, h) => http.get(u, headers: h));

  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? queryParameters,
  }) async => _request(
    url,
    queryParameters,
    (u, h) => http.post(u, headers: h, body: body),
  );

  Future<http.Response> _request(
    String url,
    Map<String, String>? params,
    Future<http.Response> Function(Uri, Map<String, String>) action,
  ) async {
    final uri = Uri.parse(url).replace(queryParameters: params);
    var response = await action(uri, _buildApiHeaders());

    if (response.statusCode >= 400 && _isCfBlock(response)) {
      final baseUrl = '${uri.scheme}://${uri.host}';
      String? jsonString = await _solveAndFetchHeadless(
        baseUrl,
        uri.toString(),
      );

      if (_isValidFetch(jsonString)) {
        return http.Response(
          jsonString!,
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      jsonString = await _solveAndFetchUI(baseUrl, uri.toString());

      if (_isValidFetch(jsonString)) {
        return http.Response(
          jsonString!,
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      throw Exception("Cloudflare bypass failed.");
    }
    return response;
  }

  bool _isCfBlock(http.Response res) {
    final s = res.headers['server']?.toLowerCase() ?? '';
    final b = res.body.toLowerCase();
    return s.contains('cloudflare') ||
        b.contains('cloudflare') ||
        b.contains('just a moment');
  }

  bool _isValidFetch(String? data) {
    if (data == null || data.startsWith('FETCH_ERROR')) return false;
    final lower = data.toLowerCase();
    if (lower.contains('cloudflare') && lower.contains('just a moment')) {
      return false;
    }
    return true;
  }

  Map<String, String> _buildApiHeaders() => {
    'User-Agent': _userAgent,
    if (_cookieString.isNotEmpty) 'Cookie': _cookieString,
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'en-US,en;q=0.9',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
  };

  Future<String?> _solveAndFetchHeadless(
    String baseUrl,
    String targetApiUrl,
  ) async {
    if (_isSolving) {
      await Future.delayed(const Duration(seconds: 3));
      return null;
    }

    _isSolving = true;
    final completer = Completer<String?>();
    HeadlessInAppWebView? webView;

    final timer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) completer.complete(null);
    });

    webView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(baseUrl)),
      initialSettings: _getOptimizedSettings(),
      initialUserScripts: UnmodifiableListView<UserScript>([
        UserScript(
          source: _evasionScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ]),
      onLoadStop: (controller, url) async {
        await controller.evaluateJavascript(source: _interactionScript);
        _pollAndFetch(controller, targetApiUrl, completer);
      },
    );

    try {
      await webView.run();
      return await completer.future;
    } finally {
      timer.cancel();
      await webView.dispose();
      _isSolving = false;
    }
  }

  Future<String?> _solveAndFetchUI(String baseUrl, String targetApiUrl) async {
    final context = navigatorKey?.currentContext;
    if (context == null) return null;

    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => CfSolverScreen(
          baseUrl: baseUrl,
          targetApiUrl: targetApiUrl,
          settings: _getOptimizedSettings(forUI: true),
          evasionScript: _evasionScript,
        ),
      ),
    );
    return result;
  }

  InAppWebViewSettings _getOptimizedSettings({bool forUI = false}) =>
      InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        preferredContentMode: UserPreferredContentMode.DESKTOP,
        userAgent: _userAgent,
        mediaPlaybackRequiresUserGesture: false,
        transparentBackground: forUI,
        useHybridComposition: forUI,
        thirdPartyCookiesEnabled: true,
      );

  void _pollAndFetch(
    InAppWebViewController controller,
    String targetApiUrl,
    Completer<String?> completer,
  ) {
    Timer.periodic(const Duration(milliseconds: 500), (t) async {
      if (completer.isCompleted) {
        t.cancel();
        return;
      }
      try {
        final currentUrl = await controller.getUrl();
        if (currentUrl == null) return;

        final cookies = await CookieManager.instance().getCookies(
          url: currentUrl,
        );
        final cStr = cookies.map((c) => '${c.name}=${c.value}').join('; ');

        if (cStr.contains('cf_clearance')) {
          t.cancel();
          _cookieString = cStr;

          final String jsFetchCode =
              '''
            async function fetchApiData() {
              try {
                const res = await fetch("$targetApiUrl", { 
                  headers: { 'Accept': 'application/json' },
                  credentials: 'include'
                });
                return await res.text();
              } catch(e) { return "FETCH_ERROR:" + e.message; }
            }
            fetchApiData();
          ''';
          final result = await controller.evaluateJavascript(
            source: jsFetchCode,
          );
          completer.complete(result?.toString());
        }
      } catch (_) {}
    });
  }

  void clearCookies() => _cookieString = '';

  final String _evasionScript = '''
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    window.chrome = { runtime: {} };
    Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3] });
    Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
  ''';

  final String _interactionScript = '''
    setInterval(() => {
      document.dispatchEvent(new MouseEvent('mousemove', { bubbles: true, clientX: Math.random()*800, clientY: Math.random()*600 }));
      document.querySelectorAll('input[type="checkbox"]').forEach(c => c.click());
      document.querySelectorAll('iframe').forEach(i => {
        const r = i.getBoundingClientRect();
        i.dispatchEvent(new MouseEvent('click', { bubbles: true, clientX: r.left+r.width/2, clientY: r.top+r.height/2 }));
      });
    }, 500);
  ''';
}

class CfSolverScreen extends StatefulWidget {
  final String baseUrl;
  final String targetApiUrl;
  final InAppWebViewSettings settings;
  final String evasionScript;

  const CfSolverScreen({
    super.key,
    required this.baseUrl,
    required this.targetApiUrl,
    required this.settings,
    required this.evasionScript,
  });

  @override
  State<CfSolverScreen> createState() => _CfSolverScreenState();
}

class _CfSolverScreenState extends State<CfSolverScreen> {
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Security Check', style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
        elevation: 1,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.baseUrl)),
              initialSettings: widget.settings,
              initialUserScripts: UnmodifiableListView<UserScript>([
                UserScript(
                  source: widget.evasionScript,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                ),
              ]),
              onLoadStop: (controller, url) {
                setState(() => _isLoading = false);
                _startAggressivePolling(controller);
              },
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
          ],
        ),
      ),
    );
  }

  void _startAggressivePolling(InAppWebViewController controller) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        final currentUrl = await controller.getUrl();
        if (currentUrl == null) return;

        final cookies = await CookieManager.instance().getCookies(
          url: currentUrl,
        );
        final cStr = cookies.map((c) => '${c.name}=${c.value}').join('; ');

        if (cStr.contains('cf_clearance')) {
          timer.cancel();

          final String jsFetchCode =
              '''
            async function fetchApiData() {
              try {
                const res = await fetch("${widget.targetApiUrl}", { 
                  headers: { 'Accept': 'application/json' },
                  credentials: 'include'
                });
                return await res.text();
              } catch(e) { return "FETCH_ERROR:" + e.message; }
            }
            fetchApiData();
          ''';

          final result = await controller.evaluateJavascript(
            source: jsFetchCode,
          );
          if (mounted) Navigator.pop(context, result?.toString());
        }
      } catch (_) {}
    });
  }
}
