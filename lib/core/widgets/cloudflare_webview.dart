import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as webview;
import 'package:shonenx/core/network/session_manager.dart';
import 'package:shonenx/core/network/network_config.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/shared/widgets/app_scaffold.dart';

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

  Uri get _parsedUri => Uri.parse(widget.url);

  void _onSyncAndClose() async {
    if (_controller != null) {
      await SessionManager().syncFromWebView(_controller!, widget.url);
    }

    if (mounted) {
      setState(() => _synced = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session synced! You can now close this view.'),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  void _reload() {
    _controller?.reload();
  }

  Future<void> _resetSession() async {
    final cookieManager = webview.CookieManager.instance();
    await cookieManager.deleteAllCookies();

    try {
      await _controller?.evaluateJavascript(
        source: 'localStorage.clear(); sessionStorage.clear();',
      );
    } catch (_) {}

    try {
      await webview.InAppWebViewController.clearAllCache();
    } catch (_) {}

    _reload();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: _parsedUri.host.isNotEmpty ? _parsedUri.host : 'Cloudflare Bypass',
      showBackButton: true,
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
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
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
                    'Complete any Cloudflare challenge if presented, then tap "Sync & Close" to pass the session to the app.',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                webview.InAppWebView(
                  initialUrlRequest: webview.URLRequest(
                    url: webview.WebUri(widget.url),
                  ),
                  initialUserScripts: null,
                  initialSettings: webview.InAppWebViewSettings(
                    userAgent:
                        bridge.AnymeXRuntimeBridge.userAgentMap[_parsedUri
                            .host] ??
                        bridge.AnymeXRuntimeBridge.userAgentMap[_parsedUri.host
                            .replaceFirst('www.', '')] ??
                        NetworkConfig.globalUserAgent,
                    useHybridComposition: false,
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    useWideViewPort: true,
                    loadWithOverviewMode: true,
                    thirdPartyCookiesEnabled: true,
                    limitsNavigationsToAppBoundDomains: false,
                  ),
                  shouldOverrideUrlLoading: (_, _) async =>
                      webview.NavigationActionPolicy.ALLOW,
                  onWebViewCreated: (controller) {
                    _controller = controller;
                  },
                  onLoadStart: (controller, url) {
                    if (mounted) {
                      setState(() {
                        _isLoading = true;
                        _progress = 0.0;
                      });
                    }
                  },
                  onLoadStop: (controller, url) async {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                        _progress = 1.0;
                      });
                    }

                    if (_controller != null) {
                      await SessionManager().syncFromWebView(
                        _controller!,
                        widget.url,
                      );
                    }
                  },
                  onProgressChanged: (controller, progress) {
                    if (mounted) {
                      setState(() {
                        _progress = progress / 100;
                      });
                    }
                  },
                ),

                Positioned(
                  bottom: 24,
                  right: 24,
                  child: Wrap(
                    spacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'reset_fab',
                        onPressed: _resetSession,
                        icon: const Icon(Icons.cleaning_services_rounded),
                        label: const Text('Reset'),
                        backgroundColor: theme.colorScheme.errorContainer,
                        foregroundColor: theme.colorScheme.onErrorContainer,
                      ),
                      FloatingActionButton.extended(
                        heroTag: 'sync_fab',
                        onPressed: _onSyncAndClose,
                        icon: Icon(
                          _synced ? Icons.check_circle_rounded : Icons.sync,
                        ),
                        label: Text(_synced ? 'Synced!' : 'Sync & Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
