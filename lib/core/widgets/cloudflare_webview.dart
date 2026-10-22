import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shonenx/shared/widgets/app_icon_button.dart';
import 'package:webview_all/webview_all.dart';
import 'package:shonenx/core/network/session_manager.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/core/utils/app_logger.dart';

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
  static final _log = AppLogger.scope(CloudflareWebView);
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;
  bool _synced = false;
  bool _canPop = false;
  bool _isSyncing = false;

  Uri get _parsedUri => Uri.parse(widget.url);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _initController();
  }

  Future<void> _initController() async {
    final host = _parsedUri.host;
    final cleanHost = host.replaceFirst('www.', '');

    final bridgeUA =
        bridge.AnymeXRuntimeBridge.userAgentMap[host] ??
        bridge.AnymeXRuntimeBridge.userAgentMap[cleanHost];
    final savedUA = SessionManager().getUserAgentSync(widget.url);
    final uaToUse = (bridgeUA != null && bridgeUA.isNotEmpty)
        ? bridgeUA
        : (savedUA != null && savedUA.isNotEmpty)
        ? savedUA
        : null;

    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    if (uaToUse != null && uaToUse.isNotEmpty) {
      await _controller.setUserAgent(uaToUse);
    }

    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          return NavigationDecision.navigate;
        },
        onPageStarted: (String url) {
          if (mounted) {
            setState(() {
              _isLoading = true;
              _progress = 0.0;
            });
          }
        },
        onProgress: (int progress) {
          if (mounted) {
            setState(() {
              _progress = progress / 100.0;
            });
          }
        },
        onPageFinished: (String url) async {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _progress = 1.0;
            });
          }

          await _syncSession();
        },
      ),
    );

    await _controller.loadRequest(Uri.parse(widget.url));
  }

  Future<void> _syncSession() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _extractAndSaveSession();
      if (mounted) {
        setState(() => _synced = true);
      }
    } catch (e, st) {
      _log.e('Error syncing Cloudflare session: $e', e, st);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _extractAndSaveSession() async {
    final log = _log.child('extractSession');
    String currentUrl = widget.url;
    try {
      final url = await _controller.currentUrl();
      if (url != null && url.isNotEmpty) {
        currentUrl = url;
      }
    } catch (e) {
      log.w('Could not read controller.currentUrl(): $e');
    }

    final targetUrl = currentUrl.isNotEmpty ? currentUrl : widget.url;
    final host = SessionManager.extractHost(targetUrl);
    if (host.isEmpty) return;

    final cookieManager = WebViewCookieManager();
    final Map<String, String> collectedCookies = {};

    final candidateUris = <Uri>[];
    void addCandidate(String u) {
      final uri = Uri.tryParse(u);
      if (uri != null && uri.hasAuthority && !candidateUris.contains(uri)) {
        candidateUris.add(uri);
      }
    }

    addCandidate(targetUrl);
    addCandidate('https://$host/');

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

    try {
      final jsResult = await _controller.runJavaScriptReturningResult(
        'document.cookie',
      );
      final jsCookieStr = _cleanJsResult(jsResult);
      if (jsCookieStr.isNotEmpty && jsCookieStr != 'null') {
        for (final pair in jsCookieStr.split(';')) {
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
    } catch (_) {}

    String userAgent = '';
    try {
      final ua = await _controller.getUserAgent();
      if (ua != null && ua.trim().isNotEmpty) {
        userAgent = ua.trim();
      }
    } catch (_) {}

    if (userAgent.isEmpty) {
      try {
        final uaResult = await _controller.runJavaScriptReturningResult(
          'navigator.userAgent',
        );
        final cleanUA = _cleanJsResult(uaResult);
        if (cleanUA.isNotEmpty && cleanUA != 'null') {
          userAgent = cleanUA;
        }
      } catch (_) {}
    }

    final cookieString = collectedCookies.entries
        .map((e) => '${e.key}=${e.value}')
        .join('; ');

    if (cookieString.isNotEmpty || userAgent.isNotEmpty) {
      await SessionManager().saveSession(
        targetUrl,
        cookie: cookieString.isNotEmpty ? cookieString : null,
        userAgent: userAgent.isNotEmpty ? userAgent : null,
      );
      log.s(
        'Session synced for $host (cookies: ${collectedCookies.length}, clearance: ${collectedCookies.containsKey('cf_clearance')})',
      );
    }
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

  void _onSyncAndClose() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await _syncSession();

    if (!mounted) return;
    final cookies = SessionManager().getCookiesSync(widget.url);
    final hasClearance = cookies.contains('cf_clearance');

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          hasClearance
              ? 'Session synced! cf_clearance verified.'
              : 'Session synced! (${cookies.isNotEmpty ? "Cookies captured" : "No cookies found"})',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() => _canPop = true);
    navigator.pop(true);
  }

  void _reload() {
    _controller.reload();
  }

  Future<void> _resetSession() async {
    try {
      await WebViewCookieManager().clearCookies();
    } catch (_) {}

    try {
      await WebViewDataManager().clearAllWebsiteData();
    } catch (_) {}

    try {
      await _controller.clearCache();
      await _controller.clearLocalStorage();
    } catch (_) {}

    try {
      await _controller.runJavaScript(
        'try { localStorage.clear(); } catch(e) {} try { sessionStorage.clear(); } catch(e) {}',
      );
    } catch (_) {}

    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        await _syncSession();
        if (!mounted) return;
        setState(() => _canPop = true);
        navigator.pop(true);
      },
      child: AppScaffold(
        title: _parsedUri.host.isNotEmpty
            ? _parsedUri.host
            : 'Cloudflare Bypass',
        showBackButton: true,
        actions: [
          AppIconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: 'Reset session',
            onPressed: _resetSession,
          ),
          const SizedBox(width: 8),
          AppIconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload',
            onPressed: _reload,
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton.tonalIcon(
              onPressed: _onSyncAndClose,
              icon: Icon(
                _synced ? Icons.check_circle_rounded : Icons.sync_rounded,
                size: 18,
              ),
              label: Text(_synced ? 'Synced' : 'Sync & Close'),
            ),
          ),
          const SizedBox(width: 8),
        ],
        barBottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _isLoading && _progress > 0 && _progress < 1
              ? LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                  minHeight: 2,
                )
              : const SizedBox(height: 2),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.7,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.onSecondaryContainer,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete any Cloudflare challenge if presented. Cookies and session will sync automatically when done or on close.',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}
