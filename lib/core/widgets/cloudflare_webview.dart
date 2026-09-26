import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as webview;
import 'package:shonenx/core/network/cookie_manager.dart';

class CloudflareWebView extends StatefulWidget {
  final String url;

  const CloudflareWebView({super.key, required this.url});

  /// Helper to push this route and await resolution.
  static Future<bool> open(BuildContext context, String url) {
    return Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(
            builder: (_) => CloudflareWebView(url: url),
            fullscreenDialog: true,
          ),
        )
        .then((result) => result ?? false);
  }

  @override
  State<CloudflareWebView> createState() => _CloudflareWebViewState();
}

class _CloudflareWebViewState extends State<CloudflareWebView> {
  webview.InAppWebViewController? _controller;
  bool _isLoading = true;
  double _progress = 0.0;
  bool _synced = false;
  bool _cookiesCleared = false;

  @override
  void initState() {
    super.initState();
    _clearOldCookies();
  }

  Future<void> _clearOldCookies() async {
    final inAppCookieManager = webview.CookieManager.instance();
    final url = webview.WebUri(widget.url);
    final cookies = await inAppCookieManager.getCookies(url: url);

    for (var cookie in cookies) {
      if (cookie.name.toLowerCase() == 'cf_clearance') {
        try {
          await inAppCookieManager.deleteCookie(
            url: url,
            name: cookie.name,
            domain: cookie.domain ?? '',
            path: cookie.path ?? '/',
          );
        } catch (e) {
          // Ignore delete errors
        }
      }
    }

    if (mounted) {
      setState(() {
        _cookiesCleared = true;
      });
    }
  }

  Uri get _parsedUri => Uri.parse(widget.url);

  Future<void> _extractAndSyncCookies() async {
    if (_controller == null) return;
    final currentUrlObj = await _controller!.getUrl();
    final currentUrl = currentUrlObj?.toString() ?? widget.url;

    final inAppCookieManager = webview.CookieManager.instance();
    final cookies = await inAppCookieManager.getCookies(
      url: webview.WebUri(currentUrl),
    );

    if (cookies.isNotEmpty) {
      final cookieString = cookies
          .map((c) => '${c.name}=${c.value}')
          .join('; ');

      final nativeUserAgent =
          await _controller!.evaluateJavascript(source: "navigator.userAgent")
              as String? ??
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

      final genericCookieManager = CookieManager();
      await genericCookieManager.setCookies(
        currentUrl,
        cookieString,
        nativeUserAgent,
      );
    }
  }

  Future<void> _checkIfChallengePassed() async {
    if (_controller == null) return;

    final title = await _controller!.getTitle() ?? '';
    final lowerTitle = title.toLowerCase();

    // If the title indicates a Cloudflare challenge, wait.
    if (lowerTitle.contains('just a moment') ||
        lowerTitle.contains('cloudflare') ||
        lowerTitle.contains('attention required')) {
      return;
    }

    final inAppCookieManager = webview.CookieManager.instance();
    final currentUrlObj = await _controller!.getUrl();
    final currentUrl = currentUrlObj?.toString() ?? widget.url;

    final cookies = await inAppCookieManager.getCookies(
      url: webview.WebUri(currentUrl),
    );

    // If we receive the cf_clearance cookie, Cloudflare verification is complete.
    final hasCfClearance = cookies.any(
      (c) => c.name.toLowerCase() == 'cf_clearance',
    );

    if (hasCfClearance) {
      // One more check to ensure we aren't popping on a blank page
      final isChallengePresent =
          await _controller!.evaluateJavascript(
                source:
                    "document.getElementById('challenge-running') != null || document.querySelector('.cf-browser-verification') != null;",
              )
              as bool? ??
          false;

      if (isChallengePresent) return;

      await _extractAndSyncCookies();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _onSyncPressed() async {
    await _extractAndSyncCookies();
    if (mounted) {
      setState(() => _synced = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cookies synced! You can now close this view.'),
        ),
      );
    }
  }

  void _onResetPressed() async {
    setState(() {
      _isLoading = true;
    });

    final inAppCookieManager = webview.CookieManager.instance();
    await inAppCookieManager.deleteAllCookies();

    final genericCookieManager = CookieManager();
    await genericCookieManager.setCookies(
      widget.url,
      '',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    );

    try {
      final webStorageManager = webview.WebStorageManager.instance();
      await webStorageManager.deleteAllData();
    } catch (_) {
      if (_controller != null) {
        try {
          await _controller!.evaluateJavascript(
            source:
                'window.localStorage.clear(); window.sessionStorage.clear();',
          );
        } catch (_) {}
      }
    }

    if (_controller != null) {
      await _controller!.loadUrl(
        urlRequest: webview.URLRequest(url: webview.WebUri(widget.url)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _parsedUri.host.isNotEmpty ? _parsedUri.host : 'Cloudflare Bypass',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset & Clear Data',
            onPressed: _onResetPressed,
          ),
          IconButton(
            icon: Icon(_synced ? Icons.check_circle : Icons.sync),
            tooltip: 'Sync Cookies Manually',
            onPressed: _onSyncPressed,
          ),
        ],
      ),
      body: SafeArea(
        child: !_cookiesCleared
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_isLoading)
                    LinearProgressIndicator(value: _progress, minHeight: 3),
                  Expanded(
                    child: webview.InAppWebView(
                      initialUrlRequest: webview.URLRequest(
                        url: webview.WebUri(widget.url),
                      ),
                      onWebViewCreated: (controller) {
                        _controller = controller;
                      },
                      onLoadStart: (controller, url) {
                        setState(() {
                          _isLoading = true;
                          _progress = 0.0;
                          _synced = false;
                        });
                      },
                      onProgressChanged: (controller, progress) {
                        setState(() {
                          _progress = progress / 100;
                        });
                      },
                      onLoadStop: (controller, url) async {
                        setState(() {
                          _isLoading = false;
                        });
                        await _checkIfChallengePassed();
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
