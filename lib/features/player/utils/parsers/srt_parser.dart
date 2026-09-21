import 'package:shonenx/features/player/utils/subtitle_parser.dart';
import 'package:shonenx/features/player/utils/parsers/subtitle_parser_base.dart';

class SrtParser extends BaseSubtitleParser {
  const SrtParser();

  @override
  List<SubtitleCue> parse(String content) {
    final List<SubtitleCue> cues = [];
    final text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Matches: 00:00:00.000 --> 00:00:00.000 or 00:00:00,000 --> 00:00:00,000
    final RegExp timePattern = RegExp(
      r'(?:(?:(\d+):)?(\d{1,2}):(\d{1,2})[.,](\d{1,3}))\s*-->\s*(?:(?:(\d+):)?(\d{1,2}):(\d{1,2})[.,](\d{1,3}))',
    );

    final List<String> blocks = text.split(RegExp(r'\n\n+'));

    for (final block in blocks) {
      final match = timePattern.firstMatch(block);
      if (match != null) {
        final start = parseDuration(
          match.group(1),
          match.group(2),
          match.group(3),
          match.group(4),
        );
        final end = parseDuration(
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
          final cleanText = SubtitleParser.cleanSubtitleText(
            textLines.join('\n'),
          );

          if (cleanText.isNotEmpty) {
            cues.add(SubtitleCue(start: start, end: end, text: cleanText));
          }
        }
      }
    }

    return cues;
  }
}
