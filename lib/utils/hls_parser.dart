import 'package:http/http.dart' as http;

Future<List<Map<String, String>>> extractQualities(String m3u8Url) async {
  try {
    final response = await http.get(Uri.parse(m3u8Url));
    if (response.statusCode != 200) throw Exception('Failed to fetch M3U8');

    final lines = response.body.split('\n');
    List<Map<String, String>> qualities = [];

    for (int i = 0; i < lines.length - 1; i++) {
      if (lines[i].contains('EXT-X-STREAM-INF')) {
        final quality = RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(lines[i]);
        if (quality != null) {
          qualities.add({
            'resolution': quality.group(1)!,
            'url': lines[i + 1], // Next line contains the URL
          });
        }
      }
    }
    return qualities;
  } catch (e) {
    // handleError('Quality extraction failed: ${e.toString()}');
    return [];
  }
}
