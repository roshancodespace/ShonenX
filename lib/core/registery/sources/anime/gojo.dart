import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/anilist/services/anilist_service.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';

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
  Future<BaseEpisodeModel> getEpisodes(
    String animeId, {
    String? anilistId,
    String? malId,
  }) async {
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

    return BaseEpisodeModel(episodes: episodes, totalEpisodes: episodes.length);
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
    final res = await AnilistService(
      getAuthContext: () => null,
      getAdultParam: () => false,
    ).searchAnime(keyword, page: page);
    return SearchPage(results: res.map((a) => a.toBaseAnimeModel(a)).toList());
  }

  @override
  Future<BaseSourcesModel> getSources(
    String animeId,
    String episodeId,
    String? serverName,
    String? category,
  ) async {
    if (animeId.isEmpty || episodeId.isEmpty) {
      return BaseSourcesModel();
    }

    final sources = <Source>[];
    List<Subtitle> tracks = [];

    final url =
        "$apiUrl/tiddies?server=$serverName&id=$animeId&num=$episodeId&subType=$category";

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode != 200) {
      return BaseSourcesModel(
        headers: headers,
        sources: sources,
        tracks: tracks,
        intro: Intro(start: 0, end: 0),
        outro: Intro(start: 0, end: 0),
      );
    }

    final json = jsonDecode(response.body);

    // Parse subtitles once
    final subtitleList = json['subtitles'] as List<dynamic>?;
    if (subtitleList != null) {
      tracks = subtitleList
          .map(
            (sub) => Subtitle(
              url: sub['url'] as String,
              lang: sub['lang'] as String,
              isSub: sub['isSub'] as bool? ?? false,
            ),
          )
          .toList();
    }

    // Parse sources
    final sourceList = json['sources'] as List<dynamic>?;
    if (sourceList != null) {
      final currentServer = serverName ?? 'Gojo';

      sources.addAll(
        sourceList.map((item) {
          var quality = (item['quality'] as String?)?.trim() ?? 'default';
          if (quality == 'master') quality = 'Auto';

          return Source(
            url: item['url'] as String,
            quality: "$currentServer - $quality",
          );
        }),
      );
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
    if (metadata == null) return BaseServerModel();

    final res = await http.get(
      Uri.parse(
        '$apiUrl/servers?id=${metadata['id']}&num=${metadata['epNumber']}',
      ),
      headers: headers,
    );

    final List<dynamic> data = jsonDecode(res.body);

    final sub = <ServerData>[];
    final dub = <ServerData>[];

    for (final d in data) {
      final bool hasDub = d['hasDub'] == true || d['hasDub'] == 'true';

      final base = ServerData(name: d['tip'], id: d['id'], isDub: false);

      sub.add(base);
      if (hasDub) {
        dub.add(base.copyWith(isDub: true));
      }
    }

    return BaseServerModel(sub: sub, dub: dub);
  }

  @override
  Future<WatchPage> getWatch(String animeId) {
    throw UnimplementedError();
  }

  @override
  String get providerName => 'gojo';
}
