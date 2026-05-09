import 'package:html/parser.dart' as html;
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/extractors/kwik.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';

class AnimePaheSource implements AnimeSource {
  final HTTP _client;

  AnimePaheSource({required HTTP client}) : _client = client;

  final _log = AppLogger.scope(AnimePaheSource);

  @override
  SourceInfo get sourceInfo =>
      SourceInfo(id: 'animepahe', name: 'AnimePahe', type: SourceType.inbuilt);

  final String baseUrl = "https://animepahe.pw";
  final String apiUrl = "https://animepahe.pw/api";

  Map<String, String> get headers => {
    'Cookie': '__ddg1=;__ddg2_=',
    'Referer': '$baseUrl/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
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
        apiUrl,
        queryParameters: {'m': 'search', 'q': query.replaceAll('-', ' ')},
        headers: headers,
        cacheDuration: const Duration(days: 1),
      );

      final data = res.json['data'] as List?;
      if (data == null || data.isEmpty) return [];

      final results = data.map<UnifiedMedia>((item) {
        final titleStr = item['title']?.toString() ?? '';
        return UnifiedMedia(
          id: item['session']?.toString() ?? '',
          type: MediaType.ANIME,
          sourceId: sourceInfo.id,
          providerId: item['session']?.toString() ?? '',
          title: MediaTitle(english: titleStr, romaji: titleStr),
          cover: item['poster']?.toString() ?? '',
          status: 'Unknown',
        );
      }).toList();

      log.s('results=${results.length}');
      return results;
    } catch (e, st) {
      log.e('search failed', e, st);
      return [];
    }
  }

  @override
  Future<List<UnifiedMedia>> getTrending({int page = 1}) async {
    return [];
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) async {
    return UnifiedMedia(
      id: providerId,
      type: MediaType.ANIME,
      sourceId: sourceInfo.id,
      providerId: providerId,
      title: const MediaTitle(english: 'AnimePahe Media'),
    );
  }

  @override
  Future<List<UnifiedEpisode>> getEpisodes(String animeId) async {
    final log = _log.child('getEpisodes');

    try {
      final List<dynamic> allData = [];
      final baseEpUrl = '$apiUrl?m=release&id=$animeId&sort=episode_asc';

      final firstRes = await _client.get(
        baseEpUrl,
        headers: headers,
        cacheDuration: const Duration(hours: 5),
      );
      final firstJson = firstRes.json;
      if (firstJson['data'] != null) {
        allData.addAll(firstJson['data'] as List);
      }

      final int totalPages = firstJson['last_page'] ?? 1;

      const batchSize = 5;
      const delayBetweenBatches = Duration(milliseconds: 800);

      for (int i = 1; i < totalPages; i += batchSize) {
        final futures = <Future>[];

        for (int j = i; j < i + batchSize && j < totalPages; j++) {
          futures.add(
            _client.get(
              '$baseEpUrl&page=${j + 1}',
              headers: headers,
              cacheDuration: Duration(
                days: j == 1 && j == totalPages - 1 ? 0 : 30,
              ),
            ),
          );
        }

        final responses = await Future.wait(futures);

        for (final res in responses) {
          final nextJson = res.json;
          if (nextJson['data'] != null) {
            allData.addAll(nextJson['data'] as List);
          }
        }

        if (i + batchSize < totalPages) {
          await Future.delayed(delayBetweenBatches);
        }
      }

      allData.sort(
        (a, b) =>
            (a['episode'] as num? ?? 0).compareTo(b['episode'] as num? ?? 0),
      );

      final episodes = <UnifiedEpisode>[];
      for (int i = 0; i < allData.length; i++) {
        final item = allData[i];
        final epSession = item['session']?.toString() ?? '';
        final epNum = (i + 1).toDouble();
        final rawTitle = item['title']?.toString().trim();
        final title = (rawTitle != null && rawTitle.isNotEmpty)
            ? rawTitle
            : 'Episode ${epNum.toString().contains('.0') ? epNum.toInt() : epNum}';

        episodes.add(
          UnifiedEpisode(
            id: '$animeId||$epSession',
            number: epNum,
            title: title,
            thumbnailUrl: item['snapshot']?.toString(),
          ),
        );
      }

      log.s('episodes=${episodes.length}');
      return episodes;
    } catch (e, st) {
      log.e('getEpisodes failed', e, st);
      return [];
    }
  }

  @override
  Future<List<VideoServer>> getServers(String episodeId) async {
    return [
      VideoServer(id: 'animepahe', name: 'AnimePahe', type: ServerType.sub),
      VideoServer(id: 'animepahe', name: 'AnimePahe', type: ServerType.dub),
    ];
  }

  @override
  Future<List<VideoStream>> getSources(
    String episodeId,
    VideoServer server,
  ) async {
    final log = _log.child('getSources');

    try {
      final parts = episodeId.split('||');
      if (parts.length != 2) throw Exception('Invalid episode ID format');

      final animeSession = parts[0];
      final epSession = parts[1];
      final isDub = server.type == ServerType.dub;

      final episodeUrl = '$baseUrl/play/$animeSession/$epSession';
      final res = await _client.get(
        episodeUrl,
        headers: headers,
        cacheDuration: const Duration(days: 3),
      );

      final document = html.parse(res.body);
      final buttons = document.querySelectorAll('div#resolutionMenu > button');

      final streams = <VideoStream>[];
      final extractTasks = <Future<void>>[];

      for (final btn in buttons) {
        final kwikUrl = btn.attributes['data-src'] ?? '';
        if (kwikUrl.isEmpty) continue;

        final audioAttr = btn.attributes['data-audio'] ?? '';
        final bool isStreamDub = audioAttr.toLowerCase() == 'eng';
        if (isStreamDub != isDub) continue;

        final resAttr = btn.attributes['data-resolution'];
        final quality = resAttr != null
            ? '${resAttr}p'
            : '${btn.text.trim().isNotEmpty ? btn.text.trim() : 'Auto'} | ${isStreamDub ? 'DUB' : 'SUB'}';
        extractTasks.add(() async {
          try {
            final directUrl = await _extractKwikStream(kwikUrl);

            if (directUrl != null && directUrl.isNotEmpty) {
              streams.add(
                VideoStream(
                  url: directUrl,
                  quality: quality,
                  headers: {
                    'Referer': 'https://kwik.cx/',
                    'User-Agent': headers['User-Agent']!,
                  },
                  subtitles: [],
                ),
              );
            }
          } catch (e) {
            log.w('Failed to extract Kwik stream for $quality: $e');
          }
        }());
      }

      await Future.wait(extractTasks);
      log.s('streams=${streams.length}');
      return streams;
    } catch (e, st) {
      log.e('getSources failed', e, st);
      return [];
    }
  }

  Future<String?> _extractKwikStream(String url) async {
    final result = await Kwik().extract(url, server: 'Kwik', quality: '');
    return result.isNotEmpty ? result.first.url : null;
  }
}
