import 'dart:developer';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> extractQualities(
    String m3u8Url, Map<String, String>? headers) async {
  try {
    final response = await http.get(Uri.parse(m3u8Url), headers: headers);
    if (response.statusCode == 200) {
      final lines = response.body.split('\n');
      final List<Map<String, dynamic>> extractedQualities = [];

      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('#EXT-X-STREAM-INF')) {
          final resolution =
              RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(lines[i])?.group(1) ??
                  'Unknown';
          if (i + 1 < lines.length) {
            final videoUrl = lines[i + 1].trim();
            if (videoUrl.isNotEmpty && !videoUrl.startsWith('#')) {
              extractedQualities.add({
                'quality': resolution,
                'url': Uri.parse(m3u8Url).resolve(videoUrl).toString(),
              });
            }
          }
        }
      }

      return extractedQualities.isNotEmpty
          ? extractedQualities
          : [
              {'quality': 'Default', 'url': m3u8Url}
            ];
    } else {
      log('Failed to fetch m3u8: HTTP ${response.statusCode}');
      return [];
    }
  } catch (e) {
    log('Error extracting qualities: $e');
    return [];
  }
}
