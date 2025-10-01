import 'dart:developer';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> extractQualities(
    String m3u8Url, Map<String, String>? headers) async {
  try {
    final response = await http.get(Uri.parse(m3u8Url), headers: headers);
    if (response.statusCode != 200) {
      log('Failed to fetch m3u8: HTTP ${response.statusCode}');
      return [];
    }

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
            final fullUrl = Uri.parse(m3u8Url).resolve(videoUrl).toString();

            // Fetch media playlist to calculate size
            double sizeMb = await _calculatePlaylistSize(fullUrl, headers);

            extractedQualities.add({
              'quality': resolution,
              'url': fullUrl,
              'size_mb': sizeMb,
            });
          }
        }
      }
    }

    // Fallback if no variants found
    if (extractedQualities.isEmpty) {
      double sizeMb = await _calculatePlaylistSize(m3u8Url, headers);
      extractedQualities.add({'quality': 'Default', 'url': m3u8Url, 'size_mb': sizeMb});
    }

    return extractedQualities;
  } catch (e) {
    log('Error extracting qualities: $e');
    return [];
  }
}

Future<double> _calculatePlaylistSize(String playlistUrl, Map<String, String>? headers) async {
  try {
    final response = await http.get(Uri.parse(playlistUrl), headers: headers);
    if (response.statusCode != 200) return 0;

    final lines = response.body.split('\n');
    int totalBytes = 0;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final tsUrl = Uri.parse(playlistUrl).resolve(line).toString();
      try {
        final head = await http.head(Uri.parse(tsUrl), headers: headers);
        final contentLength = head.headers['content-length'];
        if (contentLength != null) {
          totalBytes += int.tryParse(contentLength) ?? 0;
        }
      } catch (_) {
        continue; // Skip failed HEAD requests
      }
    }

    return totalBytes / (1024 * 1024); // Convert bytes to MB
  } catch (_) {
    return 0;
  }
}
