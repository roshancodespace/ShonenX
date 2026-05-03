import 'package:shonenx/core/network/http_client.dart';

extension HttpX on HTTP {
  Future<bool> isHLS(String url, {Map<String, String>? headers}) async {
    final cleanPath = url.split('?').first.split('#').first.toLowerCase();
    if (cleanPath.endsWith('.m3u8') || cleanPath.endsWith('.m3u')) {
      return true;
    }

    try {
      final response = await head(url, headers: headers);
      final contentType = response.headers?['content-type']?.toLowerCase();
      if (contentType != null && contentType.contains('mpegurl')) {
        return true;
      }
    } catch (_) {}

    return false;
  }
}
