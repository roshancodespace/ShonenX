enum TrackerAuthMode {
  auto,
  browser,
  webview;

  String get displayName {
    switch (this) {
      case TrackerAuthMode.auto:
        return 'Auto';
      case TrackerAuthMode.browser:
        return 'Browser';
      case TrackerAuthMode.webview:
        return 'WebView';
    }
  }

  String get description {
    switch (this) {
      case TrackerAuthMode.auto:
        return 'Auto: Browser on desktop (with in-app WebView fallback), in-app WebView on mobile';
      case TrackerAuthMode.browser:
        return 'Browser: Forces external browser with desktop client credentials (localhost redirect)';
      case TrackerAuthMode.webview:
        return 'WebView: Forces in-app WebView with mobile client credentials (app callback)';
    }
  }
}
