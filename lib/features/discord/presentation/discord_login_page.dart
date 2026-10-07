import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:webview_all/webview_all.dart';

class DiscordLoginPage extends StatefulWidget {
  final Function(String) onTokenExtracted;

  const DiscordLoginPage({super.key, required this.onTokenExtracted});

  @override
  State<DiscordLoginPage> createState() => _DiscordLoginPageState();
}

class _DiscordLoginPageState extends State<DiscordLoginPage> {
  late final WebViewController _controller;
  Timer? _pollTimer;
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
        window.__discordToken = clean;
        try {
          if (typeof onTokenFound !== 'undefined' && onTokenFound.postMessage) {
            onTokenFound.postMessage(clean);
          } else if (window.onTokenFound && window.onTokenFound.postMessage) {
            window.onTokenFound.postMessage(clean);
          }
        } catch(e) {}
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
        if (_fetch) {
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
        }

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
        if (checkStorage() || attempts > 60) {
          clearInterval(timer);
        }
      }, 1000);
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
      )
      ..addJavaScriptChannel(
        'onTokenFound',
        onMessageReceived: (JavaScriptMessage message) {
          _handleToken(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
            _injectScript();
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _progress = 1.0;
              });
            }
            _injectScript();
            _pollToken();
          },
          onProgress: (int progress) {
            if (mounted) {
              setState(() => _progress = progress / 100.0);
            }
          },
          onUrlChange: (UrlChange change) {
            _injectScript();
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Discord WebView error: ${error.description}');
          },
        ),
      );

    _initPlatform();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPlatform() async {
    try {
      await WebViewCookieManager().clearCookies();
    } catch (_) {}
    if (mounted) {
      setState(() => _ready = true);
    }
    await _controller.loadRequest(Uri.parse('https://discord.com/login'));
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_tokenExtracted) {
        _pollTimer?.cancel();
        return;
      }
      _pollToken();
    });
  }

  Future<void> _injectScript() async {
    try {
      await _controller.runJavaScript(_interceptScript);
    } catch (_) {}
  }

  Future<void> _pollToken() async {
    if (_tokenExtracted) return;
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          if (window.__discordToken) return window.__discordToken;
          try {
            var t = localStorage.getItem('token') || sessionStorage.getItem('token');
            if (t && t !== 'null') return t;
          } catch(e) {}
          return '';
        })()
      ''');
      final str = result.toString().trim().replaceAll('"', '');
      if (str.isNotEmpty && str != 'null' && str.length >= 30) {
        _handleToken(str);
      }
    } catch (_) {}
  }

  void _handleToken(String raw) {
    if (_tokenExtracted) return;
    final token = raw.trim().replaceAll('"', '');
    if (token.isEmpty || token == 'null') return;
    _tokenExtracted = true;
    _pollTimer?.cancel();
    widget.onTokenExtracted(token);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _resetSession() async {
    setState(() => _isResetting = true);

    try {
      await _controller.runJavaScript('''
        try { localStorage.clear(); } catch(e) {}
        try { sessionStorage.clear(); } catch(e) {}
        try { window.__tokenListenerInstalled = false; } catch(e) {}
        try { window.__discordToken = null; } catch(e) {}
      ''');

      await _controller.clearCache();
      await WebViewCookieManager().clearCookies();

      _tokenExtracted = false;
      await _controller.loadRequest(Uri.parse('https://discord.com/login'));
      _startPolling();
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
                Expanded(child: WebViewWidget(controller: _controller)),
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
