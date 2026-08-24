import 'package:collection/collection.dart';
import 'package:shonenx/core/utils/http_x.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';

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
          preferredTypeStreams.firstWhereOrNull(
            (s) => matchesQuality(s.quality, preferredQuality!),
          ) ??
          streams.firstWhereOrNull(
            (s) => matchesQuality(s.quality, preferredQuality!),
          );
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
    } catch (_) {
      // Non-HLS streams or network errors — fall back to just "Auto"
    }

    // Pick the preferred quality from the parsed list
    VideoStream activeQuality = qualitiesList.first;
    if (preferredQuality != null && preferredQuality != 'Auto') {
      final match = qualitiesList.firstWhereOrNull(
        (s) => matchesQuality(s.quality, preferredQuality!),
      );
      if (match != null) activeQuality = match;
    }

    return (list: qualitiesList, active: activeQuality);
  }

  SubtitleTrack resolveSubtitle(List<SubtitleTrack> subtitles) {
    if (subtitles.isEmpty) return SubtitleTrack.none;

    // User explicitly disabled subtitles
    if (preferredSubtitleLang == 'Off') return SubtitleTrack.none;

    // No preference set — return first (usually "Off")
    if (preferredSubtitleLang == null) return subtitles.first;

    final pref = preferredSubtitleLang!.toLowerCase();
    final match = subtitles.firstWhereOrNull(
      (s) =>
          s.language.toLowerCase().contains(pref) ||
          pref.contains(s.language.toLowerCase()),
    );
    return match ?? subtitles.first;
  }

  AudioTrack? resolveAudioTrack(List<AudioTrack> tracks) {
    if (tracks.isEmpty) return null;

    if (preferredAudioLang == 'Auto') return AudioTrack.auto;
    if (preferredAudioLang == null) return null;

    final pref = preferredAudioLang!.toLowerCase();
    return tracks.firstWhereOrNull(
      (t) =>
          (t.language?.toLowerCase().contains(pref) == true) ||
          t.label.toLowerCase().contains(pref) ||
          pref.contains(t.language?.toLowerCase() ?? '---') ||
          pref.contains(t.label.toLowerCase()),
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
}
