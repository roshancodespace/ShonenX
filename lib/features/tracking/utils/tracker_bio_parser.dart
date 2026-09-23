class TrackerBioParser {
  static String parse(String bio) {
    if (bio.isEmpty) return bio;

    var parsed = bio;

    parsed = parsed.replaceAllMapped(RegExp(r'\*\*\s*(.*?)\s*\*\*'), (match) {
      final text = match.group(1) ?? '';
      return '**$text**';
    });

    parsed = parsed.replaceAllMapped(RegExp(r'img\d*\((.*?)\)'), (match) {
      final url = match.group(1)?.trim() ?? '';
      return '![img]($url)';
    });

    parsed = parsed.replaceAllMapped(RegExp(r'webm\((.*?)\)'), (match) {
      final url = match.group(1)?.trim() ?? '';
      return '[WebM Video]($url)';
    });

    parsed = parsed.replaceAllMapped(RegExp(r'youtube\((.*?)\)'), (match) {
      final url = match.group(1)?.trim() ?? '';
      if (!url.startsWith('http')) {
        return '[YouTube Video](https://youtube.com/watch?v=$url)';
      }
      return '[YouTube Video]($url)';
    });

    parsed = parsed.replaceAllMapped(RegExp(r'~!(.*?)!~', dotAll: true), (
      match,
    ) {
      final text = match.group(1)?.trim() ?? '';
      return '> $text';
    });

    parsed = parsed.replaceAllMapped(RegExp(r'~~~(.*?)~~~', dotAll: true), (
      match,
    ) {
      final text = match.group(1)?.trim() ?? '';
      return '\n$text\n';
    });

    parsed = parsed.replaceAllMapped(
      RegExp(r'\[b\](.*?)\[\/b\]', caseSensitive: false, dotAll: true),
      (match) {
        return '**${match.group(1)}**';
      },
    );

    parsed = parsed.replaceAllMapped(
      RegExp(r'\[i\](.*?)\[\/i\]', caseSensitive: false, dotAll: true),
      (match) {
        return '*${match.group(1)}*';
      },
    );

    parsed = parsed.replaceAllMapped(
      RegExp(r'\[u\](.*?)\[\/u\]', caseSensitive: false, dotAll: true),
      (match) {
        return '__${match.group(1)}__';
      },
    );

    parsed = parsed.replaceAllMapped(
      RegExp(r'\[s\](.*?)\[\/s\]', caseSensitive: false, dotAll: true),
      (match) {
        return '~~${match.group(1)}~~';
      },
    );

    parsed = parsed.replaceAllMapped(
      RegExp(
        r'\[center\](.*?)\[\/center\]',
        caseSensitive: false,
        dotAll: true,
      ),
      (match) {
        return '\n${match.group(1)}\n';
      },
    );

    parsed = parsed.replaceAllMapped(
      RegExp(r'\[img.*?\](.*?)\[\/img\]', caseSensitive: false, dotAll: true),
      (match) {
        return '![img](${match.group(1)})';
      },
    );

    parsed = parsed.replaceAllMapped(
      RegExp(
        r'\[url=(.*?)\](.*?)\[\/url\]',
        caseSensitive: false,
        dotAll: true,
      ),
      (match) {
        return '[${match.group(2)}](${match.group(1)})';
      },
    );

    parsed = parsed.replaceAllMapped(
      RegExp(r'\[url\](.*?)\[\/url\]', caseSensitive: false, dotAll: true),
      (match) {
        return '[${match.group(1)}](${match.group(1)})';
      },
    );

    parsed = parsed.replaceAllMapped(
      RegExp(
        r'\[spoiler.*?\](.*?)\[\/spoiler\]',
        caseSensitive: false,
        dotAll: true,
      ),
      (match) {
        return '> ${match.group(1)}';
      },
    );

    parsed = parsed.replaceAllMapped(
      RegExp(r'<u>(.*?)<\/u>', caseSensitive: false, dotAll: true),
      (match) {
        final text = match.group(1) ?? '';
        return '__${text}__';
      },
    );

    parsed = parsed.replaceAllMapped(
      RegExp(r'<b>(.*?)<\/b>', caseSensitive: false, dotAll: true),
      (match) {
        final text = match.group(1) ?? '';
        return '**$text**';
      },
    );

    parsed = parsed.replaceAllMapped(
      RegExp(r'<i>(.*?)<\/i>', caseSensitive: false, dotAll: true),
      (match) {
        final text = match.group(1) ?? '';
        return '*$text*';
      },
    );

    parsed = parsed.replaceAllMapped(
      RegExp(r'<strike>(.*?)<\/strike>', caseSensitive: false, dotAll: true),
      (match) {
        final text = match.group(1) ?? '';
        return '~~$text~~';
      },
    );

    parsed = parsed.replaceAll(RegExp(r'\n+'), '\n\n');

    return parsed;
  }
}
