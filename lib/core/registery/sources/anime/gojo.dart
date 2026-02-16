import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class GojoProvider implements AnimeProvider {
  @override
  String get apiUrl => "https://b.animetsu.live";

  String get proxyUrl => "https://ani.metsu.site";

  @override
  String get baseUrl => "https://animetsu.live";

  @override
  Map<String, String> get headers => {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
    'Referer': baseUrl,
    'Origin': baseUrl,
  };

  @override
  Future<DetailPage> getDetails(String animeId) {
    throw UnimplementedError();
  }

  @override
  Future<BaseEpisodeModel> getEpisodes(
    String animeId, {
    String? anilistId,
    String? malId,
  }) async {
    try {
      final url = Uri.parse("$apiUrl/api/anime/eps/$animeId");
      final res = await UniversalHttpClient.instance.get(url, headers: headers);

      if (res.statusCode != 200) {
        return BaseEpisodeModel(episodes: [], totalEpisodes: 0);
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! List) {
        return BaseEpisodeModel(episodes: [], totalEpisodes: 0);
      }

      final episodes = decoded.map<EpisodeDataModel>((item) {
        try {
          final epNum = (item['ep_num'] as num?)?.toInt() ?? 0;

          String? formattedDate;
          final airedAt = item['aired_at'];
          if (airedAt is String && airedAt.isNotEmpty) {
            formattedDate = DateFormat(
              "d MMM y",
            ).format(DateTime.parse(airedAt).toLocal());
          }
          return EpisodeDataModel(
            id: "$animeId/$epNum",
            number: epNum,
            title: item['name'] ?? 'Episode $epNum',
            thumbnail: "$proxyUrl/proxy${item['img'] ?? ''}",
            isFiller: item['isFiller'] ?? false,
            description: item['description'],
            date: formattedDate,
          );
        } catch (_) {
          return EpisodeDataModel(
            id: 'invalid',
            number: 0,
            title: 'Episode',
            thumbnail: '',
          );
        }
      }).toList();

      episodes.sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

      return BaseEpisodeModel(
        episodes: episodes,
        totalEpisodes: episodes.length,
      );
    } catch (e, s) {
      AppLogger.e("[Gojo] getEpisodes", [e, s]);
      return BaseEpisodeModel(episodes: [], totalEpisodes: 0);
    }
  }

  @override
  Future<HomePage> getHome() {
    throw UnimplementedError();
  }

  @override
  Future<SearchPage> getPage(String route, int page) {
    throw UnimplementedError();
  }

  @override
  Future<SearchPage> getSearch(String keyword, String? type, int page) async {
    try {
      final res = await UniversalHttpClient.instance.get(
        Uri.parse("$apiUrl/api/anime/search?query=$keyword&page=$page"),
        headers: headers,
        cacheConfig: CacheConfig.long,
      );

      if (res.statusCode != 200) {
        return SearchPage(results: []);
      }

      final json = jsonDecode(res.body);
      final results = json['results'];

      if (results is! List) {
        return SearchPage(results: []);
      }

      return SearchPage(
        results: results.map<BaseAnimeModel>((a) {
          return BaseAnimeModel(
            id: a['id'],
            name:
                a['title']?['english'] ??
                a['title']?['romaji'] ??
                a['title']?['native'] ??
                'Unknown',
            poster: a['cover_image']?['medium'],
            description: a['description'],
            genres: (a['genres'] as List?)?.cast<String>() ?? [],
          );
        }).toList(),
      );
    } catch (e, s) {
      AppLogger.e("[Gojo] getSearch", [e, s]);
      return SearchPage(results: []);
    }
  }

  @override
  Future<BaseSourcesModel> getSources(
    String animeId,
    String episodeId,
    String? serverName,
    String? category,
  ) async {
    try {
      if (animeId.isEmpty || episodeId.isEmpty) {
        return BaseSourcesModel();
      }

      final uri = Uri.parse("$apiUrl/api/anime/oppai/$episodeId").replace(
        queryParameters: {'server': serverName, 'source_type': category},
      );

      final response = await UniversalHttpClient.instance.get(
        uri,
        headers: headers,
        cacheConfig: CacheConfig.long,
      );

      if (response.statusCode != 200) {
        return BaseSourcesModel(headers: headers);
      }

      final json = jsonDecode(response.body);

      final tracks =
          (json['subs'] as List?)
              ?.map(
                (sub) =>
                    Subtitle(url: sub['url'], lang: sub['lang'], isSub: true),
              )
              .toList() ??
          [];

      final currentServer = serverName ?? 'Gojo';
      print(json);

      final sources =
          (json['sources'] as List?)?.map((item) {
            var quality = item['quality']?.trim() ?? 'default';
            final type = item['type']?.trim() ?? 'm3u8';
            final needProxy = item['need_proxy'] == true;
            final sourceUrl = needProxy
                ? "$apiUrl/proxy${item['url']}"
                : item['url'];

            if (quality == 'master') quality = 'Auto';

            return Source(
              url: sourceUrl,
              quality: "$currentServer - $quality",
              headers: headers,
              isM3U8:
                  type == "m3u8" || type == "hls" || type == "video/mpegurl",
              type: type,
            );
          }).toList() ??
          [];

      final skips = json['skips'] as Map<String, dynamic>?;

      final introData = skips?['intro'];
      final intro = Intro(
        start: (introData?['start'] as num?)?.toInt(),
        end: (introData?['end'] as num?)?.toInt(),
      );

      final endingData = skips?['ending'];
      final ending = Intro(
        start: (endingData?['start'] as num?)?.toInt(),
        end: (endingData?['end'] as num?)?.toInt(),
      );

      return BaseSourcesModel(
        headers: headers,
        sources: sources,
        tracks: tracks,
        intro: intro,
        outro: ending,
      );
    } catch (e, s) {
      AppLogger.e("[Gojo] getSources", [e, s]);
      return BaseSourcesModel(headers: headers);
    }
  }

  @override
  Future<BaseServerModel> getSupportedServers({dynamic metadata}) async {
    try {
      if (metadata == null ||
          metadata['epId'] == null ||
          metadata['epNumber'] == null) {
        return BaseServerModel();
      }

      final uri = Uri.parse(
        '$apiUrl/api/anime/servers/${metadata['id']}/${metadata['epNumber']}',
      );

      final res = await UniversalHttpClient.instance.get(uri, headers: headers);

      if (res.statusCode != 200) {
        return BaseServerModel();
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! List) {
        return BaseServerModel();
      }

      final servers = decoded
          .map<ServerData?>((item) {
            try {
              final name = item['tip']?.toString();
              final id = item['id']?.toString();

              if (name == null || id == null) return null;

              return ServerData(name: name, id: id);
            } catch (_) {
              return null;
            }
          })
          .whereType<ServerData>()
          .toList();

      if (servers.isEmpty) {
        return BaseServerModel();
      }

      return BaseServerModel(
        sub: servers,
        dub: servers.map((e) => e.copyWith(isDub: true)).toList(),
      );
    } catch (e, s) {
      AppLogger.e("[Gojo] getSupportedServers", [e, s]);
      return BaseServerModel();
    }
  }

  @override
  Future<WatchPage> getWatch(String animeId) {
    throw UnimplementedError();
  }

  @override
  String get providerName => 'gojo';
}
