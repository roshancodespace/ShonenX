class DownloadUrlHelper {
  /// Unwraps the real target URL if [url] is a local bridge URL
  /// (e.g. http://localhost:.../m3u8?url=... or http://127.0.0.1:.../m3u8?url=...).
  /// Returns the extracted upstream URL (including magnets/torrents).
  static String extractUrl(String url) {
    String finalUrl = url;
    if (finalUrl.startsWith('http://127.0.0.1') ||
        finalUrl.startsWith('http://localhost')) {
      final uri = Uri.tryParse(finalUrl);

      if (uri != null &&
          uri.path == '/m3u8' &&
          uri.queryParameters.containsKey('url')) {
        final extractedUrl = uri.queryParameters['url'];
        if (extractedUrl != null && extractedUrl.isNotEmpty) {
          finalUrl = extractedUrl;
        }
      }
    }
    return finalUrl;
  }

  /// Extracts the direct upstream URL for the internal download manager.
  /// Returns `null` if the URL is a torrent/magnet stream, because the internal
  /// download service does not support torrent engines.
  static String? extractDownloadUrl(String url) {
    final extracted = extractUrl(url);
    if (isTorrent(extracted)) return null;
    return extracted;
  }

  /// Extracts any referer / user-agent headers encoded in the local bridge URL
  /// query parameters and merges them with existing [headers].
  static Map<String, String> extractHeadersFromUrl(
    String url,
    Map<String, String>? headers,
  ) {
    final merged = Map<String, String>.from(headers ?? {});
    final uri = Uri.tryParse(url);
    if (uri != null &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1') &&
        uri.path == '/m3u8') {
      final referer = uri.queryParameters['referer'];
      if (referer != null &&
          referer.isNotEmpty &&
          !merged.containsKey('Referer')) {
        merged['Referer'] = referer;
      }
      final userAgent = uri.queryParameters['useragent'];
      if (userAgent != null &&
          userAgent.isNotEmpty &&
          !merged.containsKey('User-Agent')) {
        merged['User-Agent'] = userAgent;
      }
    }
    return merged;
  }

  /// Checks if [url] represents a torrent or magnet link.
  static bool isTorrent(String url) {
    final trimmed = url.trim().toLowerCase();
    if (trimmed.startsWith('magnet:') || trimmed.startsWith('torrent:')) {
      return true;
    }
    final uri = Uri.tryParse(url);
    if (uri != null) {
      if (uri.scheme == 'magnet' || uri.scheme == 'torrent') return true;
      if (uri.path.toLowerCase().endsWith('.torrent')) return true;
    }
    return false;
  }
}
