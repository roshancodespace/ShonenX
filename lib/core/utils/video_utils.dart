import 'package:path/path.dart' as p;
import 'package:shonenx/core/network/http_client.dart';

class VideoUtils {
  static const List<String> _commonVideoExtensions = [
    '.mp4',
    '.mkv',
    '.webm',
    '.avi',
    '.mov',
    '.flv',
    '.wmv',
  ];

  static const List<String> _m3u8ContentTypes = [
    'application/vnd.apple.mpegurl',
    'application/x-mpegurl',
    'video/mp2t',
  ];

  static Future<bool> isM3U8(String url, {Map<String, String>? headers}) async {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      final extension = p.extension(uri.path).toLowerCase();

      if (extension == '.m3u8') return true;
      if (_commonVideoExtensions.contains(extension)) return false;
    } catch (_) {}

    try {
      final response = await UniversalHttpClient.instance
          .head(
            Uri.parse(url),
            headers: headers,
            cacheConfig: CacheConfig.short,
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final contentType =
            response.headers['content-type']?.toLowerCase() ?? '';
        return _m3u8ContentTypes.any((type) => contentType.contains(type));
      }
    } catch (_) {}

    return false;
  }
}
