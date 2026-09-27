class NetworkConfig {
  /// User-Agent string for the entire application.
  static const String globalUserAgent =
      'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.193 Mobile Safari/537.36';

  /// Standard sec-ch-ua headers to bypass Cloudflare fingerprinting.
  static const Map<String, String> globalHeaders = {};
}
