import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

sealed class ReaderMode {
  const ReaderMode();
}

class ReaderModeOnline extends ReaderMode {
  final UnifiedMedia media;
  final UnifiedEpisode episode; // This represents the chapter
  final SourceInfo sourceInfo;
  final int startPosition;

  const ReaderModeOnline({
    required this.media,
    required this.episode,
    required this.sourceInfo,
    this.startPosition = 1,
  });
}

class ReaderModeOffline extends ReaderMode {
  final String filePath; // To be implemented later for downloaded chapters
  final String? title;

  const ReaderModeOffline({required this.filePath, this.title});
}
