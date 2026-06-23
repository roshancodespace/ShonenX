import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/providers/media_source.dart';

abstract class AnimeSource extends MediaSource {
  Future<List<UnifiedEpisode>> getEpisodes(String animeId);
  Future<List<VideoServer>> getServers(String episodeId);
  Future<List<VideoStream>> getSources(String episodeId, VideoServer server);
}
