import 'dart:developer';
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
