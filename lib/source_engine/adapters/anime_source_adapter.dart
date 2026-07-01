import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';
import 'base_source_adapter.dart';

class AnimeSourceAdapter extends BaseSourceAdapter implements AnimeSource {
  AnimeSourceAdapter({
    required super.sourceInfo,
    required super.source,
  });

  @override
  final log = AppLogger.scope(AnimeSourceAdapter);

  @override
  Future<List<UnifiedEpisode>> getEpisodes(String animeId) async {
    final methodLog = log.child('getEpisodes');
    try {
      final parts = animeId.split('|');
      methodLog.i('url=${parts[0]} title=${parts.length > 1 ? parts[1] : ''}');

      final detail = await source.methods.getDetail(
        bridge.DMedia(url: parts[0], title: parts[1]),
      );

      methodLog.d('episodes=${detail.episodes?.length ?? 0}');

      return (detail.episodes ?? [])
          .map(
            (e) => UnifiedEpisode(
              id: '${e.url!}|${e.episodeNumber}',
              title: e.name,
              number: double.parse(e.episodeNumber),
              scanlator: e.scanlator,
            ),
          )
          .toList();
    } catch (e, st) {
      methodLog.e('getEpisodes failed', e, st);
      return [];
    }
  }

  @override
  Future<List<VideoServer>> getServers(String episodeId) async {
    final methodLog = log.child('getServers');
    methodLog.i('episodeId=$episodeId');
    return [VideoServer(id: '1', name: 'Default')];
  }

  @override
  Future<List<VideoStream>> getSources(
    String episodeId,
    VideoServer server,
  ) async {
    final methodLog = log.child('getSources');
    try {
      methodLog.i('episodeId=$episodeId server=${server.name}');
      final parts = episodeId.split('|');

      final videos = await source.methods.getVideoList(
        bridge.DEpisode(url: parts[0], episodeNumber: parts[1]),
      );

      methodLog.d('streams=${videos.length}');

      return videos
          .map(
            (e) => VideoStream(
              url: e.url,
              quality: e.title ?? e.quality,
              headers: e.headers,
              subtitles: (e.subtitles ?? [])
                  .map((s) => SubtitleTrack(url: s.file!, language: s.label!))
                  .toList(),
            ),
          )
          .toList();
    } catch (e, st) {
      methodLog.e('getSources failed', e, st);
      return [];
    }
  }

  @override
  Future<List<String>> getFilterGenres() async {
    return [];
  }

  @override
  Future<List<String>> getFilterTags() async {
    return [];
  }
}
