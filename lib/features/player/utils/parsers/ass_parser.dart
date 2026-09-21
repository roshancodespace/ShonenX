import 'package:flutter/rendering.dart';
import 'package:shonenx/features/player/utils/subtitle_parser.dart';
import 'package:shonenx/features/player/utils/parsers/subtitle_parser_base.dart';

class AssParser extends BaseSubtitleParser {
  const AssParser();

  @override
  List<SubtitleCue> parse(String content) {
    final List<SubtitleCue> cues = [];
    final text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final lines = text.split('\n');
    bool inEventsBlock = false;

    // Typically Dialogue: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
    // Start/End are in H:MM:SS.cs format (e.g., 0:00:00.00)
    for (final line in lines) {
      if (line.trim().startsWith('[Events]')) {
        inEventsBlock = true;
        continue;
      }
      if (line.trim().startsWith('[') && inEventsBlock) {
        // Entered a new block, stop parsing events if we only support one Events block
        break;
      }

      if (inEventsBlock && line.startsWith('Dialogue:')) {
        final contentStr = line.substring('Dialogue:'.length).trim();
        final parts = contentStr.split(',');

        // ASS dialogue lines have 9 commas before the text begins (10 fields total typically)
        // Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
        if (parts.length >= 10) {
          final startStr = parts[1].trim(); // H:MM:SS.cs
          final endStr = parts[2].trim(); // H:MM:SS.cs
          final rawText = parts
              .sublist(9)
              .join(','); // Join back any commas in the text

          final start = _parseAssTime(startStr);
          final end = _parseAssTime(endStr);

          if (start != null && end != null) {
            Alignment cueAlignment = Alignment.bottomCenter;
            final alignmentMatch = RegExp(r'\{\\an(\d)\}').firstMatch(rawText);
            if (alignmentMatch != null) {
              final an = int.tryParse(alignmentMatch.group(1) ?? '') ?? 2;
              switch (an) {
                case 1:
                  cueAlignment = Alignment.bottomLeft;
                  break;
                case 2:
                  cueAlignment = Alignment.bottomCenter;
                  break;
                case 3:
                  cueAlignment = Alignment.bottomRight;
                  break;
                case 4:
                  cueAlignment = Alignment.centerLeft;
                  break;
                case 5:
                  cueAlignment = Alignment.center;
                  break;
                case 6:
                  cueAlignment = Alignment.centerRight;
                  break;
                case 7:
                  cueAlignment = Alignment.topLeft;
                  break;
                case 8:
                  cueAlignment = Alignment.topCenter;
                  break;
                case 9:
                  cueAlignment = Alignment.topRight;
                  break;
              }
            }

            final cleanText = SubtitleParser.cleanSubtitleText(rawText);
            if (cleanText.isNotEmpty) {
              cues.add(
                SubtitleCue(
                  start: start,
                  end: end,
                  text: cleanText,
                  alignment: cueAlignment,
                ),
              );
            }
          }
        }
      }
    }

    // Sort by start time, since ASS doesn't strictly guarantee chronological order
    cues.sort((a, b) => a.start.compareTo(b.start));
    return cues;
  }

  Duration? _parseAssTime(String time) {
    // Format is H:MM:SS.cs
    final RegExp r = RegExp(r'^(\d+):(\d{2}):(\d{2})\.(\d{2})$');
    final match = r.firstMatch(time);
    if (match != null) {
      return parseDuration(
        match.group(1),
        match.group(2),
        match.group(3),
        match.group(4)! +
            '0', // convert centiseconds to milliseconds (e.g. 99 -> 990)
      );
    }
    return null;
  }
}
