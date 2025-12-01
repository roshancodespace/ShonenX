import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> extractQualities(
    String m3u8Url, Map<String, String>? headers) async {
  try {
    // 1. Fetch the master playlist
    final response = await http.get(Uri.parse(m3u8Url), headers: headers);
    if (response.statusCode != 200) {
      log('Failed to fetch master M3U8: HTTP ${response.statusCode}');
      return [];
    }

    final lines = response.body.split('\n');
    final List<Map<String, dynamic>> extractedQualities = [];

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('#EXT-X-STREAM-INF')) {
        // Look for quality (RESOLUTION or NAME)
        final resolutionMatch =
            RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(lines[i]);
        final nameMatch = RegExp(r'NAME="([^"]+)"').firstMatch(lines[i]);

        // Use resolution, fallback to NAME, then 'Unknown'
        final quality =
            resolutionMatch?.group(1) ?? nameMatch?.group(1) ?? 'Unknown';

        if (i + 1 < lines.length) {
          final videoUrl = lines[i + 1].trim();
          if (videoUrl.isNotEmpty && !videoUrl.startsWith('#')) {
            // 2. Resolve the URL relative to the master playlist URL
            final fullUrl = Uri.parse(m3u8Url).resolve(videoUrl).toString();

            extractedQualities.add({
              'quality': quality,
              'url': fullUrl,
              // 'size_mb' is now omitted for speed
            });
          }
        }
      }
    }

    // Fallback if no variants found (original URL is the stream)
    if (extractedQualities.isEmpty) {
      extractedQualities.add({'quality': 'Default', 'url': m3u8Url});
    }

    return extractedQualities;
  } catch (e) {
    log('Error extracting qualities: $e');
    return [];
  }
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
