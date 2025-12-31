import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/utils/app_logger.dart';

Future<List<Map<String, dynamic>>> extractQualities(
    String url, Map<String, String>? headers) async {
  try {
    // 1. Try HEAD request first to check Content-Type
    try {
      final headResponse =
          await http.head(Uri.parse(url), headers: headers).timeout(
                const Duration(seconds: 5),
                onTimeout: () =>
                    http.Response('', 405), // Fallback if HEAD times out
              );

      if (headResponse.statusCode == 200) {
        final contentType = headResponse.headers['content-type'] ?? '';
        final contentLength =
            int.tryParse(headResponse.headers['content-length'] ?? '0') ?? 0;

        // If it's definitely a video file or very large, return directly
        if (contentType.startsWith('video/') ||
            contentType == 'application/octet-stream' ||
            contentLength > 10 * 1024 * 1024) {
          // > 10MB
          return [
            {'quality': 'Default', 'url': url}
          ];
        }
      }
    } catch (e) {
      // Ignore HEAD errors, fall through to GET
    }

    // 2. Perform a Range GET request (first 4KB)
    final rangeHeaders = Map<String, String>.from(headers ?? {});
    rangeHeaders['Range'] = 'bytes=0-4095'; // First 4KB

    final response = await http.get(Uri.parse(url), headers: rangeHeaders);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body;

      // Check specific signatures
      if (body.contains('#EXTM3U')) {
        if (body.contains('#EXT-X-STREAM-INF') &&
            !body.trim().endsWith('#EXT-X-ENDLIST')) {
          // Fetch full if it looks like a master playlist
          final fullResponse = await http.get(Uri.parse(url), headers: headers);
          return _parseM3U8(fullResponse.body, url);
        }
        return _parseM3U8(body, url);
      } else if (body.contains('<MPD') || url.endsWith('.mpd')) {
        return [
          {'quality': 'Auto', 'url': url}
        ];
      } else {
        // Likely a direct file that we peeked at
        return [
          {'quality': 'Default', 'url': url}
        ];
      }
    }

    // Fallback: If Range failed (server doesn't support it), try full GET
    // ONLY if we haven't already determined it's likely a big file from HEAD (if HEAD worked)
    // But be careful about size.
    final fullResponse = await http.get(Uri.parse(url), headers: headers);
    if (fullResponse.statusCode == 200) {
      if (fullResponse.body.contains('#EXTM3U')) {
        return _parseM3U8(fullResponse.body, url);
      }
    }

    return [
      {'quality': 'Default', 'url': url}
    ];
  } catch (e) {
    log('Error extracting qualities: $e');
    // Return the original url as a fallback instead of empty,
    // so the player at least tries to play it.
    return [
      {'quality': 'Default', 'url': url}
    ];
  }
}

List<Map<String, dynamic>> _parseM3U8(String body, String url) {
  final lines = body.split('\n');
  final extractedQualities = <Map<String, dynamic>>[];

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('#EXT-X-STREAM-INF')) {
      final resolutionMatch =
          RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(lines[i]);
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

Future<List<String>> parseSegments(String m3u8Url,
    {Map<dynamic, dynamic>? headers}) async {
  try {
    final dio = Dio(BaseOptions(headers: {
      ...(headers ?? {}),
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
    }));
    final response = await dio.get(m3u8Url);
    final lines = response.data.toString().split('\n');

    // Calculate Base URL to resolve relative paths
    final uri = Uri.parse(m3u8Url);

    // Include port if present
    final portPart = (uri.hasPort && uri.port != 80 && uri.port != 443)
        ? ':${uri.port}'
        : '';

    final baseUrl =
        "${uri.scheme}://${uri.host}$portPart${uri.path.substring(0, uri.path.lastIndexOf('/') + 1)}";

    List<String> segmentUrls = [];

    for (var line in lines) {
      final trimmed = line.trim();

      // Skip empty lines and tags (lines starting with #)
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      // Check if URL is absolute or relative
      if (trimmed.startsWith('http')) {
        segmentUrls.add(trimmed);
      } else {
        segmentUrls.add('$baseUrl$trimmed');
      }
    }

    return segmentUrls;
  } catch (e) {
    // Return empty list or rethrow based on preference
    throw Exception('Failed to parse M3U8 segments: $e');
  }
}
