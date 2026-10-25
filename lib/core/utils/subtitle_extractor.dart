import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';

class SubtitleExtractor {
  static String? resolveSubtitleLabel(
    SubtitleTrack sub,
    VideoStream stream,
    VideoServer? server,
  ) {
    final serverName = server?.name.trim();
    final originalLabel = sub.label?.trim();
    final quality = stream.quality.trim();
    final serverLower = serverName?.toLowerCase() ?? '';
    final hasValidServer =
        serverName != null &&
        serverLower.isNotEmpty &&
        serverLower != 'default' &&
        serverLower != 'auto';
    final hasQuality = quality.isNotEmpty && quality.toLowerCase() != 'auto';

    final parts = <String>[];
    if (hasValidServer) parts.add(serverName);
    if (hasQuality) parts.add(quality);

    if (originalLabel != null &&
        originalLabel.isNotEmpty &&
        originalLabel.toLowerCase() != 'auto' &&
        originalLabel.toLowerCase() != 'default' &&
        originalLabel.toLowerCase() != sub.language.toLowerCase() &&
        (!hasValidServer ||
            !originalLabel.toLowerCase().contains(serverLower))) {
      parts.add(originalLabel);
    }

    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  static List<SubtitleTrack> extractFromServers(
    Map<VideoServer, List<VideoStream>> serverStreams, {
    bool includeNone = false,
  }) {
    final result = <SubtitleTrack>[if (includeNone) SubtitleTrack.none];
    final Set<String> seenUrls = {};

    for (final entry in serverStreams.entries) {
      final server = entry.key;
      for (final stream in entry.value) {
        for (final sub in stream.subtitles) {
          if (!seenUrls.contains(sub.url) && sub.url.isNotEmpty) {
            seenUrls.add(sub.url);
            result.add(
              sub.copyWith(label: resolveSubtitleLabel(sub, stream, server)),
            );
          }
        }
      }
    }
    return result;
  }

  static String formatDisplayTitle(SubtitleTrack sub) {
    final label = sub.label?.trim();
    final lang = sub.language.trim();
    if (label == null || label.isEmpty) {
      return lang.isEmpty ? 'Unknown' : lang;
    }
    if (lang.isEmpty || label.toLowerCase().contains(lang.toLowerCase())) {
      return label;
    }
    return '$lang • $label';
  }

  static const Map<String, List<String>> languageAliases = {
    'en': ['en', 'eng', 'english'],
    'ja': ['ja', 'jpn', 'japanese', 'nihongo'],
    'es': ['es', 'spa', 'spanish', 'espanol', 'español', 'castilian', 'latin'],
    'fr': ['fr', 'fre', 'fra', 'french', 'francais', 'français'],
    'de': ['de', 'ger', 'deu', 'german', 'deutsch'],
    'pt': ['pt', 'por', 'portuguese', 'portugues', 'português', 'brazilian'],
    'it': ['it', 'ita', 'italian', 'italiano'],
    'ru': ['ru', 'rus', 'russian', 'russkiy'],
    'ar': ['ar', 'ara', 'arabic'],
    'hi': ['hi', 'hin', 'hindi'],
    'id': ['id', 'ind', 'indonesian', 'bahasa'],
    'tr': ['tr', 'tur', 'turkish', 'turkce', 'türkçe'],
    'vi': ['vi', 'vie', 'vietnamese', 'tieng viet', 'tiếng việt'],
    'th': ['th', 'tha', 'thai'],
    'pl': ['pl', 'pol', 'polish', 'polski'],
    'zh': ['zh', 'chi', 'zho', 'chinese', 'mandarin', 'cantonese'],
    'ko': ['ko', 'kor', 'korean', 'hangul'],
    'nl': ['nl', 'dut', 'nld', 'dutch', 'nederlands'],
    'fil': ['fil', 'tgl', 'tagalog', 'filipino'],
    'ms': ['ms', 'may', 'msa', 'malay'],
    'sv': ['sv', 'swe', 'swedish', 'svenska'],
    'uk': ['uk', 'ukr', 'ukrainian'],
    'ro': ['ro', 'rum', 'ron', 'romanian'],
    'el': ['el', 'gre', 'ell', 'greek'],
    'hu': ['hu', 'hun', 'hungarian'],
    'cs': ['cs', 'cze', 'ces', 'czech'],
    'da': ['da', 'dan', 'danish'],
    'fi': ['fi', 'fin', 'finnish'],
    'no': ['no', 'nor', 'norwegian'],
    'he': ['he', 'heb', 'hebrew'],
  };

  static String? normalizeLanguageCode(String raw) {
    final clean = raw.toLowerCase().trim();
    if (clean.isEmpty) return null;

    final tokens = clean
        .split(RegExp(r'[^a-z0-9áéíóúñçãõâêîôûäëïöü]'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;

    for (final entry in languageAliases.entries) {
      for (final alias in entry.value) {
        if (tokens.contains(alias) || clean == alias) {
          return entry.key;
        }
      }
    }

    return tokens.first;
  }

  static bool matchesLanguage(String lang1, String lang2) {
    final code1 = normalizeLanguageCode(lang1);
    final code2 = normalizeLanguageCode(lang2);
    if (code1 == null || code2 == null) return false;
    return code1 == code2;
  }
}
