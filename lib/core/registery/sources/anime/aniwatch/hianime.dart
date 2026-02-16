import 'dart:convert';
import 'package:html/dom.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/sources/anime/aniwatch/parser.dart';
import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/env_loader.dart';
import 'package:html/parser.dart' show parse;

class HiAnimeProvider extends AnimeProvider {
  HiAnimeProvider({String? customApiUrl})
    : super(
        apiUrl: customApiUrl ?? API_URL,
        baseUrl: 'https://hianimez.to',
        providerName: 'hianime',
      );

  @override
  Map<String, String> get headers => {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
  };

  @override
  Future<HomePage> getHome() async {
    return HomePage();
    // final response =
    //     await UniversalHttpClient.instance.get(Uri.parse('$baseUrl/home'), headers: headers);

    // final document = parse(response.body);
    // return HomePage(
    //   spotlight: parseSpotlight(document, baseUrl),
    //   trending: parseTrending(document, baseUrl),
    //   featured: parseFeatured(document, baseUrl),
    // );
  }

  @override
  Future<DetailPage> getDetails(String animeId) async {
    final response = await UniversalHttpClient.instance.get(
      Uri.parse('$baseUrl/$animeId'),
      headers: headers,
    );
    final document = parse(response.body);
    return parseDetail(document, baseUrl, animeId: animeId);
  }

  @override
  Future<WatchPage> getWatch(String animeId) async {
    final response = await UniversalHttpClient.instance.get(
      Uri.parse('$baseUrl/watch/$animeId'),
      headers: headers,
    );
    final document = parse(response.body);
    return parseWatch(document, baseUrl, animeId: animeId);
  }

  // @override
  // Future<BaseEpisodeModel> getEpisodes(String animeId) async {

  //   final response = await UniversalHttpClient.instance.get(
  //       Uri.parse("$baseUrl/ajax/v2/episode/list/${animeId.split('-').last}"),
  //       headers: headers);

  //   final document = parse(json.decode(response.body)['html']);
  //   return parseEpisodes(document, "$baseUrl/ajax/v2/episode/list/",
  //       animeId: animeId);
  // }
  @override
  Future<BaseEpisodeModel> getEpisodes(
    String animeId, {
    String? anilistId,
    String? malId,
  }) async {
    final response = await UniversalHttpClient.instance.get(
      Uri.parse(
        "https://shonenx-aniwatch-instance-mu.vercel.app/api/v2/hianime/anime/$animeId/episodes",
      ),
    );
    final data = jsonDecode(response.body)['data'];
    return BaseEpisodeModel(
      episodes: (data['episodes'] as List<dynamic>)
          .map(
            (episode) => EpisodeDataModel(
              id: episode['episodeId'],
              number: episode['number'],
              title: episode['title'],
              isFiller: episode['isFiller'],
            ),
          )
          .toList(),
      totalEpisodes: data['totalEpisodes'],
    );
  }

  String? retrieveServerId(Document document, int index, String category) {
    final serverItems = document.querySelectorAll(
      '.ps_-block.ps_-block-sub.servers-$category > .ps__-list .server-item',
    );
    return serverItems
        .firstWhere((el) => el.attributes['data-server-id'] == index.toString())
        .attributes['data-id'];
  }

  @override
  Future<BaseSourcesModel> getSources(
    String animeId,
    String episodeId,
    String? serverName,
    String? category,
  ) async {
    final actualEpisodeId = "$animeId?$episodeId";
    final response = await UniversalHttpClient.instance.get(
      Uri.parse(
        '$apiUrl/episode/sources?animeEpisodeId=$actualEpisodeId&server=$serverName&category=$category',
      ),
      cacheConfig: CacheConfig.veryLong,
    );
    final data = jsonDecode(response.body)['data'];
    final tracks = (data['tracks'] as List?)
        ?.map(
          (t) => Subtitle(
            url: t['url'],
            lang: t['lang'],
            isSub: t['lang'] != 'thumbnails',
          ),
        )
        .toList();
    return BaseSourcesModel(
      headers: data['headers'],
      preview: tracks?.where((t) => t.isSub == null || t.isSub == false).first,
      intro: Intro(
        start: data['intro']['start'] as int,
        end: data['intro']['end'] as int,
      ),
      outro: Intro(
        start: data['outro']['start'] as int,
        end: data['outro']['end'] as int,
      ),
      sources: (data['sources'] as List<dynamic>)
          .map(
            (source) => Source(
              url: source['url'],
              isM3U8: source['isM3U8'],
              quality: source['quality'],
              type: source['type'],
            ),
          )
          .toList(),
      anilistID: data['anilistID'],
      malID: data['malID'],
      tracks:
          (data['subtitles'] as List<dynamic>?)
              ?.map((track) => Subtitle(url: track['url'], lang: track['lang']))
              .toList() ??
          [],
    );
  }
  // @override
  // Future<BaseSourcesModel> getSources(String animeId, String episodeId,
  //     String? serverName, String? category) async {
  //   final response = await UniversalHttpClient.instance.get(
  //     Uri.parse(
  //         'https://shonenx-aniwatch-instance-mu..vercel.app/api/v2/hianime/episode/sources?animeEpisodeId=$episodeId&server=$serverName&category=${category ?? 'sub'}'),
  //   );
  //   final data = jsonDecode(response.body)['data'];

  //   return BaseSourcesModel(
  //     sources: (data['sources'] as List<dynamic>)
  //         .map((source) => Source(
  //               url: source['url'],
  //               isM3U8: source['isM3U8'],
  //               quality: source[
  //                   'quality'], // this might be null — handle it if needed
  //             ))
  //         .toList(),
  //     tracks:
  //         (data['tracks'] as List<dynamic>?) // ✅ was 'subtitles', now 'tracks'
  //                 ?.map((track) => Subtitle(
  //                       url: track['url'],
  //                       lang: track['lang'],
  //                     ))
  //                 .toList() ??
  //             [],
  //   );
  // }

  @override
  Future<SearchPage> getSearch(String keyword, String? type, int page) async {
    final hianimeType = type != null
        ? _mapTypeToHianimeType(type.toLowerCase())
        : null;
    final url = hianimeType != null
        ? '$baseUrl/search?keyword=$keyword&type=$hianimeType&page=$page'
        : '$baseUrl/search?keyword=$keyword&page=$page';
    final response = await UniversalHttpClient.instance.get(
      Uri.parse(url),
      headers: headers,
    );
    final document = parse(response.body);
    return parseSearch(document, baseUrl, keyword: keyword, page: page);
  }

  @override
  Future<SearchPage> getPage(String route, int page) async {
    final response = await UniversalHttpClient.instance.get(
      Uri.parse('$baseUrl/$route?page=$page'),
      headers: headers,
    );
    final document = parse(response.body);
    return parsePage(document, baseUrl, route: route, page: page);
  }

  int? _mapTypeToHianimeType(String type) {
    return switch (type) {
      'movie' => 1,
      'tv' => 2,
      'ova' => 3,
      'ona' => 4,
      'special' => 5,
      'music' => 6,
      _ => null,
    };
  }

  @override
  Future<BaseServerModel> getSupportedServers({dynamic metadata}) async {
    final animeId = metadata['id'];
    final episodeId = metadata['epId'];
    final res = await UniversalHttpClient.instance.get(
      Uri.parse('$apiUrl/episode/servers?animeEpisodeId=$animeId?$episodeId'),
      cacheConfig: CacheConfig.veryLong,
    );
    final data = jsonDecode(res.body);
    final sub = data['data']['sub'] as List?;
    final dub = data['data']['dub'] as List?;
    return Future(
      () => BaseServerModel(
        sub:
            sub
                ?.map(
                  (server) => ServerData(
                    id: server['serverName'],
                    name: server['serverId'].toString(),
                    isDub: false,
                  ),
                )
                .toList() ??
            [],
        dub:
            dub
                ?.map(
                  (server) => ServerData(
                    id: server['serverName'],
                    name: server['serverId'].toString(),
                    isDub: true,
                  ),
                )
                .toList() ??
            [],
      ),
    );
  }
}
