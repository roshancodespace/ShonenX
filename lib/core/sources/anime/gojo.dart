import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/anilist/services/anilist_service.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class GojoProvider implements AnimeProvider {
  @override
  String get apiUrl => "https://backend.animetsu.cc/api/anime";

  @override
  String get baseUrl => "https://animetsu.cc";

  @override
  Map<String, String> get headers => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
        'Origin': 'https://animetsu.cc',
        'Referer': 'https://animetsu.cc/',
      };

  @override
  Future<DetailPage> getDetails(String animeId) {
    throw UnimplementedError();
  }

  @override
  Future<BaseEpisodeModel> getEpisodes(String animeId,
      {String? anilistId, String? malId}) async {
    final url = Uri.parse("$apiUrl/eps/$animeId");
    final res = await http.get(url, headers: headers);

    if (res.statusCode != 200) {
      throw Exception("Failed to load episodes: ${res.statusCode}");
    }

    final List<dynamic> json = jsonDecode(res.body);

    final episodes = json.map<EpisodeDataModel>((item) {
      final int epNum = item['number']?.toInt() ?? 0;
      final bool isFiller = item['isFiller'] ?? false;
      final String? img = item['image'];
      final String? title = item['title'];

      return EpisodeDataModel(
        id: epNum.toString(),
        number: epNum,
        title: title ?? 'Episode $epNum',
        thumbnail: img,
        isFiller: isFiller,
      );
    }).toList();

    // Sort by episode number just in case
    episodes.sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));

    return BaseEpisodeModel(
      episodes: episodes,
      totalEpisodes: episodes.length,
    );
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
    final res = await AnilistService(null).searchAnime(keyword, page: page);
    return SearchPage(results: res.map((a) => a.toBaseAnimeModel(a)).toList());
  }

  @override
  Future<BaseSourcesModel> getSources(String animeId, String episodeId,
      String? serverName, String? category) async {
    final id = animeId;
    final epNum = episodeId;
    if (id.isEmpty || epNum.isEmpty) {
      return BaseSourcesModel();
    }
    final isDub = category?.toLowerCase() == 'dub';
    // 1. Get the list of servers
    final serverUrl = Uri.parse("$apiUrl/servers?id=$id&num=$epNum");
    final serverListRes = await http.get(serverUrl, headers: headers);

    if (serverListRes.statusCode != 200) {
      return BaseSourcesModel();
    }

    final List<dynamic> serversJson = jsonDecode(serverListRes.body);

    List<Source> sources = [];
    List<Subtitle> tracks = [];

    // 2. Prepare futures to fetch streams from all servers in parallel
    final List<Future<http.Response>> futures = [];

    for (var it in serversJson) {
      final url =
          "$apiUrl/tiddies?server=${it['id']}&id=$id&num=$epNum&subType=${isDub ? "dub" : "sub"}";
      futures.add(http.get(Uri.parse(url), headers: headers));
    }

    // 3. Wait for all requests to finish
    final responses = await Future.wait(futures);

    // 4. Parse results
    for (int i = 0; i < responses.length; i++) {
      final response = responses[i];
      if (response.statusCode != 200) continue;

      final json = jsonDecode(response.body);
      final List<dynamic>? sourceList = json['sources'];
      final List<dynamic>? subtitleList = json['subtitles'];

      // Extract Subtitles (Tracks) - usually only need to do this once, but logic checks every response
      if (subtitleList != null && tracks.isEmpty) {
        tracks = subtitleList.map<Subtitle>((sub) {
          return Subtitle(
            url: sub['url'],
            lang: sub['lang'],
            isSub: sub['isSub'] ?? false,
          );
        }).toList();
      }

      // Extract Sources
      if (sourceList != null) {
        final currentServerName = serversJson[i]['id'] ?? 'Gojo';

        for (var item in sourceList) {
          String quality = item['quality'] ?? 'default';
          if (quality.trim() == 'master') quality = 'Auto';

          sources.add(Source(
            url: item['url'],
            quality: "$currentServerName - $quality",
          ));
        }
      }
    }

    return BaseSourcesModel(
      headers: headers,
      sources: sources,
      tracks: tracks,
      intro: Intro(start: 0, end: 0),
      outro: Intro(start: 0, end: 0),
    );
  }

  @override
  Future<BaseServerModel> getSupportedServers({dynamic metadata}) async {
    AppLogger.w(metadata);
    if (metadata != null) {
      final res = (await http.get(
          Uri.parse(
              '$apiUrl/servers?id=${metadata['id']}&num=${metadata['epNumber']}'),
          headers: headers));
      final List<dynamic> data = jsonDecode(res.body);
      final dub = <ServerData>[];
      final sub = <ServerData>[];

      for (final d in data) {
        final server =
            ServerData(name: d['tip'], id: d['id'], isDub: d['hasDub']);

        if (d['hasDub'] == 'true') {
          dub.add(server);
        } else {
          sub.add(server);
        }
      }

      return BaseServerModel(
        dub: dub,
        sub: sub,
      );
    }
    return BaseServerModel();
  }

  @override
  Future<WatchPage> getWatch(String animeId) {
    throw UnimplementedError();
  }

  @override
  String get providerName => 'gojo';
}
