import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/rendering.dart';
import 'package:shonenx/features/player/utils/parsers/subtitle_parser_base.dart';
import 'package:shonenx/features/player/utils/parsers/srt_parser.dart';
import 'package:shonenx/features/player/utils/parsers/ass_parser.dart';

class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;
  final Alignment alignment;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
    this.alignment = Alignment.bottomCenter,
  });
}

class SubtitleParser {
  static Future<List<SubtitleCue>> parseFromUrl(
    String url, {
    Map<String, String>? headers,
  }) async {
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
    if (content.trim().isEmpty) return [];

    BaseSubtitleParser parser;

    // Detect format
    if (content.contains('[Script Info]') || content.contains('[V4+ Styles]')) {
      parser = const AssParser();
    } else {
      // Fallback to SRT/VTT parser for standard block formats
      parser = const SrtParser();
    }

    return parser.parse(content);
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
}
