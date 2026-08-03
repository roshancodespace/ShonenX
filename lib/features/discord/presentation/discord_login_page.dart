import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class DiscordLoginPage extends StatefulWidget {
  final Function(String) onTokenExtracted;

  const DiscordLoginPage({super.key, required this.onTokenExtracted});

  @override
  State<DiscordLoginPage> createState() => _DiscordLoginPageState();
}

class _DiscordLoginPageState extends State<DiscordLoginPage> {
  late InAppWebViewController _controller;
  bool _ready = false;
  bool _tokenExtracted = false;
  bool _isLoading = true;
  double _progress = 0.0;
  bool _isResetting = false;

  static const String _interceptScript = '''
    (function() {
      if (window.__tokenListenerInstalled) return;
      window.__tokenListenerInstalled = true;

      function sendToken(token) {
        if (!token || token === 'null') return;
        var clean = token.replace(/"/g, '').trim();
        if (clean.length < 30) return;
        try {
          window.flutter_inappwebview.callHandler('onTokenFound', clean);
        } catch(e) {
          window.__discordToken = clean;
        }
      }

      function checkStorage() {
        try {
          var t = localStorage.getItem('token') || sessionStorage.getItem('token');
          if (t && t !== 'null') {
            sendToken(t);
            return true;
          }
        } catch(e) {}
        try {
          var keys = Object.keys(localStorage);
          for (var i = 0; i < keys.length; i++) {
            var val = localStorage.getItem(keys[i]);
            if (val && /^[\\w-]{50,100}\$/.test(val.replace(/"/g, ''))) {
              sendToken(val);
              return true;
            }
          }
        } catch(e) {}
        return false;
      }

      (function patchNetwork() {
        var _fetch = window.fetch;
        window.fetch = function() {
          var args = arguments;
          if (args && args[1] && args[1].headers) {
            var h = args[1].headers;
            var auth = h.Authorization || h.authorization;
            if (auth) sendToken(auth);
          }
          return _fetch.apply(this, arguments).then(function(res) {
            if (res && res.url && res.url.indexOf('/api/') !== -1) {
              try {
                res.clone().json().then(function(json) {
                  if (json && json.token) sendToken(json.token);
                }).catch(function(){});
              } catch(e) {}
            }
            return res;
          });
        };

        var _open = XMLHttpRequest.prototype.open;
        var _setRequestHeader = XMLHttpRequest.prototype.setRequestHeader;

        XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
          if (header && header.toLowerCase() === 'authorization') {
            sendToken(value);
          }
          return _setRequestHeader.apply(this, arguments);
        };

        XMLHttpRequest.prototype.open = function() {
          this.addEventListener('load', function() {
            try {
              if (this.responseText) {
                var json = JSON.parse(this.responseText);
                if (json && json.token) sendToken(json.token);
              }
            } catch(e) {}
          });
          return _open.apply(this, arguments);
        };
      })();

      var attempts = 0;
      var timer = setInterval(function() {
        attempts++;
        if (window.__discordToken) { sendToken(window.__discordToken); }
        if (checkStorage() || attempts > 40) {
          clearInterval(timer);
        }
      }, 1000);
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _initPlatform();
  }

  Future<void> _initPlatform() async {
    try {
      await CookieManager.instance().deleteAllCookies();
    } catch (_) {}
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  void _handleToken(String raw) {
    if (_tokenExtracted) return;
    final token = raw.trim().replaceAll('"', '');
    if (token.isEmpty || token == 'null') return;
    _tokenExtracted = true;
    widget.onTokenExtracted(token);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _resetSession() async {
    setState(() => _isResetting = true);

    try {
      await _controller.evaluateJavascript(
        source: '''
        try { localStorage.clear(); } catch(e) {}
        try { sessionStorage.clear(); } catch(e) {}
        try { window.__tokenListenerInstalled = false; } catch(e) {}
        try { window.__discordToken = null; } catch(e) {}
      ''',
      );

      await InAppWebViewController.clearAllCache();

      final cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies();

      _tokenExtracted = false;

      await _controller.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://discord.com/login')),
      );
    } catch (e) {
      debugPrint('Reset error: $e');
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Discord Login',
      leadingWidget: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF5865F2).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.discord, color: Color(0xFF5865F2), size: 18),
      ),
      showBackButton: true,
      actions: [
        if (_isLoading || _isResetting || !_ready)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _resetSession,
            tooltip: 'Reset session',
          ),
        const SizedBox(width: 10),
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
      body: _ready
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  color: theme.colorScheme.tertiaryContainer.withValues(
                    alpha: 0.7,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.onTertiaryContainer,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Self-bot token login is against Discord Terms of Service. Use with caution.',
                          style: TextStyle(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InAppWebView(
                    webViewEnvironment: webViewEnvironment,
                    initialUrlRequest: URLRequest(
                      url: WebUri('https://discord.com/login'),
                    ),
                    initialUserScripts: UnmodifiableListView([
                      UserScript(
                        source: _interceptScript,
                        injectionTime:
                            UserScriptInjectionTime.AT_DOCUMENT_START,
                      ),
                    ]),
                    initialSettings: InAppWebViewSettings(
                      useHybridComposition: false,
                      javaScriptEnabled: true,
                      domStorageEnabled: true,
                      databaseEnabled: true,
                      supportZoom: false,
                      useWideViewPort: true,
                      loadWithOverviewMode: true,
                      allowUniversalAccessFromFileURLs: true,
                      allowFileAccessFromFileURLs: true,
                      limitsNavigationsToAppBoundDomains: false,
                    ),
                    onWebViewCreated: (controller) {
                      _controller = controller;
                      _controller.addJavaScriptHandler(
                        handlerName: 'onTokenFound',
                        callback: (args) {
                          if (args.isNotEmpty) {
                            _handleToken(args[0].toString());
                          }
                        },
                      );
                    },
                    onLoadStart: (controller, url) {
                      if (mounted) setState(() => _isLoading = true);
                    },
                    onLoadStop: (controller, url) async {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                          _progress = 1.0;
                        });
                      }
                      await controller.evaluateJavascript(
                        source: _interceptScript,
                      );
                    },
                    onProgressChanged: (controller, progress) {
                      if (mounted) {
                        setState(() => _progress = progress / 100);
                      }
                    },
                    onUpdateVisitedHistory: (controller, url, isReload) async {
                      await controller.evaluateJavascript(
                        source: _interceptScript,
                      );
                    },
                    shouldOverrideUrlLoading:
                        (controller, navigationAction) async =>
                            NavigationActionPolicy.ALLOW,
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

extension DiscordLoginNavigation on BuildContext {
  Future<void> showDiscordLogin(Function(String) onTokenExtracted) async {
    await Navigator.of(this).push(
      MaterialPageRoute(
        builder: (context) =>
            DiscordLoginPage(onTokenExtracted: onTokenExtracted),
      ),
    );
  }
}
