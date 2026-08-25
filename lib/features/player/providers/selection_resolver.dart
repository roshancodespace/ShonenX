import 'package:collection/collection.dart';
import 'package:shonenx/core/utils/http_x.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';

const Map<String, List<String>> _languageAliases = {
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

class SelectionResolver {
  String? preferredServerId;
  ServerType? preferredServerType;
  String? preferredQuality;
  String? preferredSubtitleLang;
  String? preferredAudioLang;

  SelectionResolver({
    this.preferredServerId,
    this.preferredServerType,
    this.preferredQuality,
    this.preferredSubtitleLang = 'eng',
    this.preferredAudioLang,
  });

  VideoServer resolveServer(
    List<VideoServer> servers, {
    VideoServer? explicit,
  }) {
    if (explicit != null) return explicit;
    if (servers.isEmpty) return servers.first;

    // Priority 1: exact id + type match
    final exactMatch = servers.firstWhereOrNull(
      (s) => s.id == preferredServerId && s.type == preferredServerType,
    );
    if (exactMatch != null) return exactMatch;

    // Priority 2: type match only
    final typeMatch = servers.firstWhereOrNull(
      (s) => s.type == preferredServerType,
    );
    if (typeMatch != null) return typeMatch;

    // Fallback: first server
    return servers.first;
  }

  VideoStream resolveStream(List<VideoStream> streams) {
    if (streams.isEmpty) return streams.first;

    VideoStream activeStream = streams.first;
    List<VideoStream> preferredTypeStreams = streams;

    // Step 1: filter by sub/dub preference
    if (preferredServerType != null) {
      final matching = _filterByServerType(streams, preferredServerType!);
      if (matching.isNotEmpty) {
        preferredTypeStreams = matching;
        activeStream = matching.first;
      }
    }

    // Step 2: match quality within the preferred type, then fall back to all
    if (preferredQuality != null && preferredQuality != 'Auto') {
      final match =
          resolveBestQuality(preferredTypeStreams, preferredQuality!) ??
          resolveBestQuality(streams, preferredQuality!);
      if (match != null) activeStream = match;
    }

    return activeStream;
  }

  /// Filters streams by sub/dub keywords in their quality label.
  List<VideoStream> _filterByServerType(
    List<VideoStream> streams,
    ServerType type,
  ) {
    final isDub = type == ServerType.dub;
    return streams.where((s) {
      final q = s.quality.toLowerCase();
      final streamIsDub = q.contains('dub') || q.contains('english');
      return isDub ? streamIsDub : !streamIsDub;
    }).toList();
  }

  Future<({List<VideoStream> list, VideoStream active})> resolveQualities(
    VideoStream source,
    HTTP httpClient,
  ) async {
    final qualitiesList = <VideoStream>[source.copyWith(quality: 'Auto')];

    // Try to parse individual qualities from the HLS manifest
    try {
      final parsed = await httpClient.splitM3U8(
        source.url,
        headers: source.headers,
      );
      for (final q in parsed) {
        qualitiesList.add(
          VideoStream(
            url: q.url,
            headers: source.headers,
            quality: q.quality,
            subtitles: source.subtitles,
          ),
        );
      }
    } catch (_) {}

    // Pick the preferred quality from the parsed list
    VideoStream activeQuality = qualitiesList.first;
    if (preferredQuality != null && preferredQuality != 'Auto') {
      final match = resolveBestQuality(qualitiesList, preferredQuality!);
      if (match != null) activeQuality = match;
    }

    return (list: qualitiesList, active: activeQuality);
  }

  VideoStream? resolveBestQuality(List<VideoStream> streams, String target) {
    if (streams.isEmpty) return null;
    if (target.toLowerCase() == 'auto') {
      return streams.firstWhereOrNull(
            (s) => s.quality.toLowerCase() == 'auto',
          ) ??
          streams.first;
    }

    // 1. Exact or direct string match
    final exactMatch = streams.firstWhereOrNull(
      (s) => matchesQuality(s.quality, target),
    );
    if (exactMatch != null) return exactMatch;

    // 2. Numeric resolution proximity match
    final targetRes = parseResolution(target);
    if (targetRes == null) return null;

    final candidates = <VideoStream, int>{};
    for (final s in streams) {
      if (s.quality.toLowerCase() == 'auto') continue;
      final res = parseResolution(s.quality);
      if (res != null) {
        candidates[s] = res;
      }
    }

    if (candidates.isEmpty) return null;

    // Prefer closest available quality at or below the target resolution
    final atOrBelow = candidates.entries
        .where((e) => e.value <= targetRes)
        .toList();
    if (atOrBelow.isNotEmpty) {
      atOrBelow.sort((a, b) => b.value.compareTo(a.value));
      return atOrBelow.first.key;
    }

    // If all available qualities are higher, pick the closest higher resolution
    final sortedByDistance = candidates.entries.toList()
      ..sort(
        (a, b) =>
            (a.value - targetRes).abs().compareTo((b.value - targetRes).abs()),
      );
    return sortedByDistance.first.key;
  }

  int? parseResolution(String q) {
    final clean = q.toLowerCase().replaceAll(' ', '');
    if (clean.contains('4k') ||
        clean.contains('2160') ||
        clean.contains('uhd')) {
      return 2160;
    }
    if (clean.contains('2k') ||
        clean.contains('1440') ||
        clean.contains('qhd')) {
      return 1440;
    }
    if (clean.contains('1080') || clean.contains('fhd')) return 1080;
    if (clean.contains('720') || clean.contains('hd')) return 720;
    if (clean.contains('480') || clean.contains('sd')) return 480;
    if (clean.contains('360')) return 360;
    if (clean.contains('240')) return 240;

    final digits = RegExp(r'(\d{3,4})').firstMatch(clean);
    if (digits != null) return int.tryParse(digits.group(1)!);
    return null;
  }

  SubtitleTrack resolveSubtitle(List<SubtitleTrack> subtitles) {
    if (subtitles.isEmpty) return SubtitleTrack.none;

    if (preferredSubtitleLang == 'Off' ||
        preferredSubtitleLang?.toLowerCase() == 'none') {
      return SubtitleTrack.none;
    }

    if (preferredSubtitleLang == null) return subtitles.first;

    final match = subtitles.firstWhereOrNull(
      (s) => matchesLanguage(s.language, preferredSubtitleLang!),
    );
    return match ?? subtitles.first;
  }

  AudioTrack? resolveAudioTrack(List<AudioTrack> tracks) {
    if (tracks.isEmpty) return null;

    if (preferredAudioLang == 'Auto') return AudioTrack.auto;
    if (preferredAudioLang == null) return null;

    return tracks.firstWhereOrNull(
      (t) =>
          matchesLanguage(t.language ?? '', preferredAudioLang!) ||
          matchesLanguage(t.label, preferredAudioLang!),
    );
  }

  bool matchesQuality(String candidate, String target) {
    final c = candidate.toLowerCase();
    final t = target.toLowerCase();

    // Exact match
    if (c == t) return true;

    // "auto" only matches "auto" — never partial-match against it
    if (t == 'auto') return c == 'auto';
    if (c == 'auto') return false;

    // Strip "p" suffix for numeric comparison (e.g. "1080p" → "1080")
    final cleanTarget = t.replaceAll('p', '').trim();
    if (cleanTarget.isNotEmpty && c.contains(cleanTarget)) return true;

    // Bidirectional substring match as final fallback
    return c.contains(t) || t.contains(c);
  }

  bool matchesLanguage(String candidate, String target) {
    final c = candidate.toLowerCase().trim();
    final t = target.toLowerCase().trim();

    if (c.isEmpty || t.isEmpty) return false;
    if (c == t) return true;
    if (c.contains(t) || t.contains(c)) return true;

    for (final group in _languageAliases.values) {
      final matchesC = group.any((alias) => c == alias || c.contains(alias));
      final matchesT = group.any((alias) => t == alias || t.contains(alias));
      if (matchesC && matchesT) return true;
    }

    return false;
  }
}
