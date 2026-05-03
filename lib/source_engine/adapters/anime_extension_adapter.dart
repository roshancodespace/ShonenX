import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart'
    as bridge;

class AnimeBridgeMethods {
  final Future<bridge.Pages> Function(
    String query,
    int page,
    List<dynamic> filters,
  )
  search;

  final Future<bridge.DMedia> Function(bridge.DMedia media) getDetail;

  final Future<List<bridge.Video>> Function(bridge.DEpisode episode)
  getVideoList;

  final Future<bridge.Pages> Function(int page) getPopular;

  AnimeBridgeMethods({
    required this.search,
    required this.getDetail,
    required this.getVideoList,
    required this.getPopular,
  });
}

class AnimeExtensionAdapter implements AnimeSource {
  @override
  final SourceInfo sourceInfo;

  final AnimeBridgeMethods methods;

  AnimeExtensionAdapter({required this.sourceInfo, required this.methods});

  final _log = AppLogger.scope(AnimeExtensionAdapter);

  @override
  Future<List<UnifiedMedia>> search(
    String query,
    MediaType type, {
    int page = 1,
    bool isAdult = false,
    List<String> sort = const ['SEARCH_MATCH'],
  }) async {
    final log = _log.child('search');

    try {
      log.i('query=$query page=$page');

      final results = await methods.search(query, page, []);

      log.d('results=${results.list.length}');

      return results.list
          .map(
            (e) => UnifiedMedia(
              id: '${e.url!}|${e.title!}',
              type: MediaType.ANIME,
              sourceId: sourceInfo.id,
              providerId: e.url!,
              title: MediaTitle(english: e.title),
              cover: e.cover,
              description: e.description,
            ),
          )
          .toList();
    } catch (e, st) {
      log.e('search failed', e, st);
      return [];
    }
  }

  @override
  Future<List<UnifiedMedia>> getTrending({int page = 1}) async {
    final log = _log.child('getTrending');

    try {
      log.i('page=$page');

      final results = await methods.getPopular(page);

      log.d('results=${results.list.length}');

      return results.list
          .map(
            (e) => UnifiedMedia(
              id: '${e.url!}|${e.title!}',
              type: MediaType.ANIME,
              sourceId: sourceInfo.id,
              providerId: e.url!,
              title: MediaTitle(english: e.title),
              cover: e.cover,
              description: e.description,
            ),
          )
          .toList();
    } catch (e, st) {
      log.e('getTrending failed', e, st);
      return [];
    }
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) async {
    final log = _log.child('getDetails');

    try {
      final parts = providerId.split('|');

      log.i('url=${parts[0]} title=${parts.length > 1 ? parts[1] : ''}');

      final detail = await methods.getDetail(
        bridge.DMedia(url: parts[0], title: parts.length > 1 ? parts[1] : ''),
      );

      return UnifiedMedia(
        id: providerId,
        type: MediaType.ANIME,
        sourceId: sourceInfo.id,
        providerId: parts[0],
        title: MediaTitle(english: detail.title),
        cover: detail.cover,
        description: detail.description,
        genres: detail.genre,
      );
    } catch (e, st) {
      log.e('getDetails failed', e, st);
      throw Exception('Failed to get details');
    }
  }

  @override
  Future<List<UnifiedEpisode>> getEpisodes(String animeId) async {
    final log = _log.child('getEpisodes');

    try {
      final parts = animeId.split('|');

      log.i('url=${parts[0]} title=${parts.length > 1 ? parts[1] : ''}');

      final detail = await methods.getDetail(
        bridge.DMedia(url: parts[0], title: parts[1]),
      );

      log.d('episodes=${detail.episodes?.length ?? 0}');

      return (detail.episodes ?? [])
          .map(
            (e) => UnifiedEpisode(
              id: '${e.url!}|${e.episodeNumber}',
              title: e.name,
              number: double.parse(e.episodeNumber),
            ),
          )
          .toList();
    } catch (e, st) {
      log.e('getEpisodes failed', e, st);
      return [];
    }
  }

  @override
  Future<List<VideoServer>> getServers(String episodeId) async {
    final log = _log.child('getServers');

    log.i('episodeId=$episodeId');

    return [VideoServer(id: '1', name: 'Default')];
  }

  @override
  Future<List<VideoStream>> getSources(
    String episodeId,
    VideoServer server,
  ) async {
    final log = _log.child('getSources');

    try {
      log.i('episodeId=$episodeId server=${server.name}');

      final parts = episodeId.split('|');

      final videos = await methods.getVideoList(
        bridge.DEpisode(url: parts[0], episodeNumber: parts[1]),
      );

      log.d('streams=${videos.length}');

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
      log.e('getSources failed', e, st);
      return [];
    }
  }
}
