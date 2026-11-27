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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderModeOnline &&
          runtimeType == other.runtimeType &&
          media.id == other.media.id &&
          episode.id == other.episode.id &&
          sourceInfo.id == other.sourceInfo.id &&
          startPosition == other.startPosition;

  @override
  int get hashCode =>
      media.id.hashCode ^
      episode.id.hashCode ^
      sourceInfo.id.hashCode ^
      startPosition.hashCode;
}

class ReaderModeOffline extends ReaderMode {
  final String filePath;
  final String? title;
  final String? chapterTitle;

  const ReaderModeOffline({
    required this.filePath,
    this.title,
    this.chapterTitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderModeOffline &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          title == other.title &&
          chapterTitle == other.chapterTitle;

  @override
  int get hashCode =>
      filePath.hashCode ^ title.hashCode ^ chapterTitle.hashCode;
}
