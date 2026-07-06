import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
  });
}

class SubtitleParser {
  static Future<List<SubtitleCue>> parseFromUrl(
    String url, {
    Map<String, String>? headers,
  }) async {
    print(url);
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes, allowMalformed: true);
        return parseString(content);
      }
    } catch (_) {}
    return [];
  }

  static List<SubtitleCue> parseString(String content) {
    final List<SubtitleCue> cues = [];
    // Normalize newlines
    final text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Matches: 00:00:00.000 --> 00:00:00.000 or 00:00:00,000 --> 00:00:00,000
    final RegExp timePattern = RegExp(
      r'(?:(?:(\d+):)?(\d{1,2}):(\d{1,2})[.,](\d{1,3}))\s*-->\s*(?:(?:(\d+):)?(\d{1,2}):(\d{1,2})[.,](\d{1,3}))',
    );

    final List<String> blocks = text.split(RegExp(r'\n\n+'));

    for (final block in blocks) {
      final match = timePattern.firstMatch(block);
      if (match != null) {
        final start = _parseDuration(
          match.group(1),
          match.group(2),
          match.group(3),
          match.group(4),
        );
        final end = _parseDuration(
          match.group(5),
          match.group(6),
          match.group(7),
          match.group(8),
        );

        // Extract text after the timestamp line
        final lines = block.split('\n');
        final timeLineIndex = lines.indexWhere((l) => timePattern.hasMatch(l));

        if (timeLineIndex != -1 && timeLineIndex < lines.length - 1) {
          final textLines = lines.sublist(timeLineIndex + 1);
          final cleanText = cleanSubtitleText(textLines.join('\n'));

          if (cleanText.isNotEmpty) {
            cues.add(SubtitleCue(start: start, end: end, text: cleanText));
          }
        }
      }
    }

    return cues;
  }

  static String cleanSubtitleText(String text) {
    var cleaned = text;
    // Remove HTML tags
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    // Remove ASS style/override tags e.g. {\an8}, {\pos(400,500)}
    cleaned = cleaned.replaceAll(RegExp(r'\{[^}]*\}'), '');
    // Replace ASS newline \N with actual newline
    cleaned = cleaned.replaceAll(RegExp(r'\\N', caseSensitive: false), '\n');

    // Fix UTF-8 decoded as Latin-1 Mojibake & common ellipsis symbols
    cleaned = cleaned
        .replaceAll('â€¦', '...')
        .replaceAll('…', '...')
        .replaceAll('â€™', "'")
        .replaceAll('â‘', "'")
        .replaceAll('â€²', "'")
        .replaceAll('â€œ', '"')
        .replaceAll('â€', '"')
        .replaceAll('â€"', '-')
        .replaceAll('â€”', '-');

    // Decode common HTML entities
    cleaned = cleaned
        .replaceAll('&hellip;', '...')
        .replaceAll('&#8230;', '...')
        .replaceAll('&#x2026;', '...')
        .replaceAll('&amp;', '&')
        .replaceAll('&#38;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#34;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&#60;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#62;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#160;', ' ');

    return cleaned.trim();
  }

  static Duration _parseDuration(
    String? hoursStr,
    String? minsStr,
    String? secsStr,
    String? msStr,
  ) {
    final hours = int.tryParse(hoursStr ?? '0') ?? 0;
    final mins = int.tryParse(minsStr ?? '0') ?? 0;
    final secs = int.tryParse(secsStr ?? '0') ?? 0;
    // Pad milliseconds to 3 digits (e.g. .1 -> .100)
    int ms = 0;
    if (msStr != null) {
      if (msStr.length == 1) {
        msStr += '00';
      } else if (msStr.length == 2) {
        msStr += '0';
      }
      ms = int.tryParse(msStr) ?? 0;
    }
    return Duration(
      hours: hours,
      minutes: mins,
      seconds: secs,
      milliseconds: ms,
    );
  }
}
