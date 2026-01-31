import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/network/universal_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';

Future<List<Map<String, dynamic>>> extractQualities(
  String url,
  Map<String, String>? headers,
) async {
  try {
    try {
      final headResponse = await UniversalHttpClient.instance
          .head(Uri.parse(url), headers: headers, cacheConfig: CacheConfig.long)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => http.Response('', 405),
          );

      if (headResponse.statusCode == 200) {
        final contentType = headResponse.headers['content-type'] ?? '';
        final contentLength =
            int.tryParse(headResponse.headers['content-length'] ?? '0') ?? 0;

        if (contentType.startsWith('video/') ||
            contentType == 'application/octet-stream' ||
            contentLength > 10 * 1024 * 1024) {
          // > 10MB
          return [
            {'quality': 'Default', 'url': url},
          ];
        }
      }
    } catch (_) {}

    final rangeHeaders = Map<String, String>.from(headers ?? {});
    rangeHeaders['Range'] = 'bytes=0-4095';

    final response = await UniversalHttpClient.instance.get(
      Uri.parse(url),
      headers: rangeHeaders,
      cacheConfig: CacheConfig.long,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body;

      if (body.contains('#EXTM3U')) {
        if (body.contains('#EXT-X-STREAM-INF') &&
            !body.trim().endsWith('#EXT-X-ENDLIST')) {
          final fullResponse = await UniversalHttpClient.instance.get(
            Uri.parse(url),
            headers: headers,
            cacheConfig: CacheConfig.long,
          );
          return _parseM3U8(fullResponse.body, url);
        }
        return _parseM3U8(body, url);
      } else if (body.contains('<MPD') || url.endsWith('.mpd')) {
        return [
          {'quality': 'Auto', 'url': url},
        ];
      } else {
        return [
          {'quality': 'Default', 'url': url},
        ];
      }
    }

    final fullResponse = await UniversalHttpClient.instance.get(
      Uri.parse(url),
      headers: headers,
      cacheConfig: CacheConfig.long,
    );
    if (fullResponse.statusCode == 200) {
      if (fullResponse.body.contains('#EXTM3U')) {
        return _parseM3U8(fullResponse.body, url);
      }
    }

    return [
      {'quality': 'Default', 'url': url},
    ];
  } catch (e) {
    log('Error extracting qualities: $e');
    return [
      {'quality': 'Default', 'url': url},
    ];
  }
}

List<Map<String, dynamic>> _parseM3U8(String body, String url) {
  final lines = body.split('\n');
  final extractedQualities = <Map<String, dynamic>>[];

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('#EXT-X-STREAM-INF')) {
      final resolutionMatch = RegExp(
        r'RESOLUTION=(\d+x\d+)',
      ).firstMatch(lines[i]);
      final nameMatch = RegExp(r'NAME="([^"]+)"').firstMatch(lines[i]);
      final quality =
          resolutionMatch?.group(1) ?? nameMatch?.group(1) ?? 'Unknown';

      if (i + 1 < lines.length) {
        final videoUrl = lines[i + 1].trim();
        if (videoUrl.isNotEmpty && !videoUrl.startsWith('#')) {
          final fullUrl = Uri.parse(url).resolve(videoUrl).toString();
          extractedQualities.add({'quality': quality, 'url': fullUrl});
        }
      }
    }
  }

  if (extractedQualities.isEmpty) {
    extractedQualities.add({'quality': 'Default', 'url': url});
  }

  AppLogger.d('Extracted qualities: $extractedQualities');
  return extractedQualities;
}
