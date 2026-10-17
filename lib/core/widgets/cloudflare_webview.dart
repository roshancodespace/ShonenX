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
      await SessionManager().syncFromWebView(_controller, widget.url);
      if (mounted) {
        setState(() => _synced = true);
      }
    } catch (e, st) {
      _log.e('Error syncing Cloudflare session: $e', e, st);
    } finally {
      _isSyncing = false;
    }
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
