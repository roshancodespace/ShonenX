import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

abstract class AnimeSource {
  SourceInfo get sourceInfo;
  Future<List<UnifiedMedia>> search(
    String query,
    MediaType type, {
    int page = 1,
    bool isAdult = false,
    List<String> sort = const ['SEARCH_MATCH'],
  });

  Future<List<UnifiedMedia>> getTrending({int page = 1});

  Future<UnifiedMedia> getDetails(String providerId, MediaType type);
  Future<List<UnifiedEpisode>> getEpisodes(String animeId);
  Future<List<VideoServer>> getServers(String episodeId);
  Future<List<VideoStream>> getSources(String episodeId, VideoServer server);

  @override
  int get hashCode => sourceInfo.id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimeSource &&
        other.sourceInfo.id == sourceInfo.id &&
        other.sourceInfo.name == sourceInfo.name &&
        other.sourceInfo.type == sourceInfo.type;
  }
}
