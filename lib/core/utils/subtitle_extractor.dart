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
}
