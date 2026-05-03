import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';

class GojoSource implements AnimeSource {
  final HTTP _client;

  GojoSource({required HTTP client}) : _client = client;

  final _log = AppLogger.scope(GojoSource);

  @override
  SourceInfo get sourceInfo =>
      SourceInfo(id: 'gojo', name: 'Gojo', type: SourceType.inbuilt);

  final String apiUrl = "https://animetsu.net/v2";
  final String proxyUrl = "https://swiftstream.top/proxy";
  final String baseUrl = "https://animetsu.live";

  Map<String, String> get headers => {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
    'Referer': "$baseUrl/",
    'Origin': baseUrl,
  };

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

      final res = await _client.get(
        "$apiUrl/api/anime/search",
        queryParameters: {'query': query, 'page': "1"},
        headers: headers,
        cacheDuration: const Duration(days: 1),
      );

      final results = res.json['results'];

      final data = results.map<UnifiedMedia>((a) {
        final title = MediaTitle(
          english: a['title']?['english'],
          romaji: a['title']?['romaji'],
          native: a['title']?['native'],
        );

        return UnifiedMedia(
          id: a['id'].toString(),
          sourceId: sourceInfo.id,
          type: MediaType.ANIME,
          providerId: a['id'].toString(),
          title: title,
          cover: a['cover_image']?['medium'] ?? '',
          status: 'Unknown',
        );
      }).toList();

      log.s('results=${data.length}');

      return data;
    } catch (e, st) {
      log.e('search failed', e, st);
      return [];
    }
  }

  @override
  Future<List<UnifiedEpisode>> getEpisodes(String animeId) async {
    final log = _log.child('getEpisodes');

    try {
      final res = await _client.get(
        "$apiUrl/api/anime/eps/$animeId",
        headers: headers,
        cacheDuration: const Duration(hours: 5),
      );

      if (res.json is! List) return [];

      final episodes = (res.json as List).map<UnifiedEpisode>((item) {
        final epNum = (item['ep_num'] as num?)?.toDouble() ?? 0;
        final thumbnailUrl = item['img'] != null
            ? proxyUrl + item['img'] + '#${headers['Referer']}'
            : null;
        return UnifiedEpisode(
          id: "$animeId||$epNum",
          number: epNum,
          title: item['name'] ?? 'Episode $epNum',
          thumbnailUrl: thumbnailUrl,
        );
      }).toList();

      episodes.sort((a, b) => a.number.compareTo(b.number));

      log.s('episodes=${episodes.length}');

      return episodes;
    } catch (e, st) {
      log.e('getEpisodes failed', e, st);
      return [];
    }
  }

  @override
  Future<List<VideoServer>> getServers(String episodeId) async {
    final log = _log.child('getServers');

    try {
      final parts = episodeId.split('||');
      if (parts.length != 2) throw Exception('Invalid episode ID');

      final animeId = parts[0];
      final epNum = parts[1];

      final serverRes = await _client.get(
        '$apiUrl/api/anime/servers/$animeId/$epNum',
        headers: headers,
        cacheDuration: const Duration(days: 3),
      );

      final data = serverRes.json;
      if (data is! List || data.isEmpty) {
        log.w('no servers found');
        return [];
      }

      final servers = data
          .map(
            (server) => VideoServer(
              id: server['id']?.toString() ?? '',
              name: server['tip']?.toString() ?? 'Unknown Server',
            ),
          )
          .where((s) => s.id.isNotEmpty)
          .toList();

      final extended = [
        ...servers,
        ...servers.map(
          (s) => VideoServer(id: s.id, name: s.name, type: ServerType.dub),
        ),
      ];

      log.s('servers=${extended.length}');

      return extended;
    } catch (e, st) {
      log.e('getServers failed', e, st);
      return [];
    }
  }

  @override
  Future<List<VideoStream>> getSources(
    String episodeId,
    VideoServer server,
  ) async {
    final log = _log.child('getSources');

    try {
      final parts = episodeId.split('||');
      if (parts.length != 2) throw Exception('Invalid episode ID');

      final animeId = parts[0];
      final epNum = parts[1];

      final sourceRes = await _client.get(
        "$apiUrl/api/anime/oppai/$animeId/$epNum",
        queryParameters: {
          'server': server.id,
          'source_type': server.type == ServerType.dub ? 'dub' : 'sub',
        },
        headers: headers,
        cacheDuration: const Duration(days: 3),
      );

      if (sourceRes.json is! Map) {
        throw Exception('Invalid source response');
      }

      final sources = sourceRes.json['sources'] as List?;
      final subs = sourceRes.json['subs'] as List?;

      if (sources == null || sources.isEmpty) {
        log.w('no streams found');
        return [];
      }

      final result = sources.map((item) {
        final subtitles =
            subs
                ?.map((e) => SubtitleTrack(url: e['url'], language: e['lang']))
                .toList() ??
            [];

        var quality = item['quality']?.toString().trim() ?? 'default';

        String sourceUrl = item['url']?.toString() ?? '';

        final needProxy =
            item['need_proxy'] == true || sourceUrl.startsWith('/');

        if (needProxy && sourceUrl.startsWith('/')) {
          sourceUrl = "$proxyUrl$sourceUrl";
        }

        if (quality.toLowerCase() == 'master') {
          quality = 'Auto';
        }

        return VideoStream(
          url: sourceUrl,
          quality: quality,
          headers: headers,
          subtitles: subtitles,
        );
      }).toList();

      log.s('streams=${result.length}');

      return result;
    } catch (e, st) {
      log.e('getSources failed', e, st);
      return [];
    }
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) async {
    return UnifiedMedia(
      id: providerId,
      type: MediaType.ANIME,
      sourceId: sourceInfo.id,
      providerId: providerId,
      title: const MediaTitle(english: 'Gojo Media'),
    );
  }

  @override
  Future<List<UnifiedMedia>> getTrending({int page = 1}) async {
    return [];
  }
}

// I/flutter ( 8924): https://swiftstream.top/proxy/oppai/pahe/Fw8cARFZQkNuChkMER0eWl4OHkYeEQYWFC1KX1VdSEBbHAQMDA8HEEoWdFRWVENISEIbVg1QDwdAQxBzBAwCE0sWFRIFWAxYU0IQTXdTCwFLTxFNGQJWUFlTTUtAdwBaBl0MBwEEDF0cVQ
// I/flutter ( 8924): {User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36, Referer: https://animetsu.live/, Origin: https://animetsu.live}
