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

  static int parseSizeToBytes(String? sizeStr) {
    if (sizeStr == null || sizeStr.isEmpty) return 0;

    final upperStr = sizeStr.toUpperCase().trim();
    final RegExp regex = RegExp(r'([\d.]+)\s*([KMGT]?B)');
    final match = regex.firstMatch(upperStr);

    if (match == null) return 0;

    final double? value = double.tryParse(match.group(1)!);
    if (value == null) return 0;

    final unit = match.group(2);

    switch (unit) {
      case 'KB':
        return (value * 1024).round();
      case 'MB':
        return (value * 1024 * 1024).round();
      case 'GB':
        return (value * 1024 * 1024 * 1024).round();
      case 'TB':
        return (value * 1024 * 1024 * 1024 * 1024).round();
      case 'B':
        return value.round();
      default:
        return 0;
    }
  }

  /// Extracts the file extension for a subtitle URL (e.g. 'vtt', 'srt', 'ass').
  static String getSubtitleExtension(String url) {
    try {
      final uri = Uri.tryParse(url);
      final path = uri?.path ?? url;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1) {
        final ext = path.substring(lastDot + 1).toLowerCase();
        if (['srt', 'vtt', 'ass', 'ssa', 'sub', 'txt'].contains(ext)) {
          return ext;
        }
      }
    } catch (_) {}
    final lower = url.toLowerCase();
    if (lower.contains('.vtt')) return 'vtt';
    if (lower.contains('.ass')) return 'ass';
    if (lower.contains('.ssa')) return 'ssa';
    return 'srt';
  }

  /// Builds an optimal subtitle filename following standard media player conventions:
  /// `<video_basename>.<language>.<extension>`
  ///
  /// Examples:
  /// - `One Piece - Episode 1.English.vtt`
  /// - `Naruto - Episode 5.ja.srt`
  static String formatSubtitleFileName({
    required String videoFileName,
    required String language,
    String? label,
    required String subtitleUrl,
  }) {
    final videoBaseName = videoFileName.contains('.')
        ? videoFileName.substring(0, videoFileName.lastIndexOf('.'))
        : videoFileName;

    var cleanLang = '';
    if (language.isNotEmpty && language.toLowerCase() != 'off') {
      cleanLang = language;
    } else if (label != null && label.isNotEmpty) {
      final parts = label.split(' - ');
      cleanLang = parts.last.trim();
    }

    if (cleanLang.isEmpty) {
      cleanLang = 'sub';
    }

    // Clean any invalid filename characters
    cleanLang = cleanLang.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (cleanLang.isEmpty) cleanLang = 'sub';

    final ext = getSubtitleExtension(subtitleUrl);
    return '$videoBaseName.$cleanLang.$ext';
  }
}
