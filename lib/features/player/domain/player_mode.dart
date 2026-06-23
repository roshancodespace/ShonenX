import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

sealed class PlayerMode {
  const PlayerMode();
}

class PlayerModeOnline extends PlayerMode {
  final UnifiedMedia media;
  final UnifiedEpisode episode;
  final SourceInfo sourceInfo;
  final Duration? startPosition;

  const PlayerModeOnline({
    required this.media,
    required this.episode,
    required this.sourceInfo,
    this.startPosition,
  });
}

class PlayerModeOffline extends PlayerMode {
  final String filePath;
  final String? title;

  const PlayerModeOffline({
    required this.filePath,
    this.title,
  });
}
