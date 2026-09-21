import 'package:shonenx/features/player/utils/subtitle_parser.dart';

abstract class BaseSubtitleParser {
  const BaseSubtitleParser();

  /// Parses the raw subtitle content string and returns a list of cues.
  List<SubtitleCue> parse(String content);

  /// Helper to cleanly parse time strings like HH:MM:SS.mmm or MM:SS,mmm
  Duration parseDuration(
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
