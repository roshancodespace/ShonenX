import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/sources/anime/aniwatch/parser.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';
import 'package:html/parser.dart' show parse;
import 'package:shonenx/core/utils/app_logger.dart';

class HiAnimeProvider extends AnimeProvider {
  HiAnimeProvider({String? customApiUrl})
      : super(
            apiUrl: customApiUrl != null
                ? '$customApiUrl/anime/zoro'
                : "${dotenv.env['API_URL']}/anime/zoro",
            baseUrl: 'https://hianime.in',
            providerName: 'hianime');

  Map<String, String> _getHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
    };
  }

  @override
  Future<HomePage> getHome() async {
    AppLogger.d('Fetching home page from $baseUrl');
    return HomePage();
    // final response =
    //     await http.get(Uri.parse('$baseUrl/home'), headers: _getHeaders());
    // AppLogger.d('Received home page response');
    // final document = parse(response.body);
    // return HomePage(
    //   spotlight: parseSpotlight(document, baseUrl),
    //   trending: parseTrending(document, baseUrl),
    //   featured: parseFeatured(document, baseUrl),
    // );
  }

  @override
  Future<DetailPage> getDetails(String animeId) async {
    AppLogger.d('Fetching details for animeId: $animeId');
    final response =
        await http.get(Uri.parse('$baseUrl/$animeId'), headers: _getHeaders());
    AppLogger.d('Received details response for animeId: $animeId');
    final document = parse(response.body);
    return parseDetail(document, baseUrl, animeId: animeId);
  }

  @override
  Future<WatchPage> getWatch(String animeId) async {
    AppLogger.d('Fetching watch page for animeId: $animeId');
    final response = await http.get(Uri.parse('$baseUrl/watch/$animeId'),
        headers: _getHeaders());
    AppLogger.d('Received watch page response for animeId: $animeId');
    final document = parse(response.body);
    return parseWatch(document, baseUrl, animeId: animeId);
  }

  // @override
  // Future<BaseEpisodeModel> getEpisodes(String animeId) async {
  //   AppLogger.d('Fetching episodes for animeId: $animeId');
  //   final response = await http.get(
  //       Uri.parse("$baseUrl/ajax/v2/episode/list/${animeId.split('-').last}"),
  //       headers: _getHeaders());
  //   AppLogger.d('Received episodes response for animeId: $animeId');
  //   final document = parse(json.decode(response.body)['html']);
  //   return parseEpisodes(document, "$baseUrl/ajax/v2/episode/list/",
  //       animeId: animeId);
  // }
  @override
  Future<BaseEpisodeModel> getEpisodes(String animeId) async {
    AppLogger.w('Fetching episodes for animeId: $animeId');
    final response = await http.get(Uri.parse(
        "https://shonenx-aniwatch-instance.vercel.app/api/v2/hianime/anime/$animeId/episodes"));
    final data = jsonDecode(response.body)['data'];
    AppLogger.w(data.toString());
    return BaseEpisodeModel(
      episodes: (data['episodes'] as List<dynamic>)
          .map((episode) => EpisodeDataModel(
              id: episode['episodeId'],
              number: episode['number'],
              title: episode['title'],
              isFiller: episode['isFiller']))
          .toList(),
      totalEpisodes: data['totalEpisodes'],
    );
  }


  String? retrieveServerId(Document document, int index, String category) {
    final serverItems = document.querySelectorAll(
        '.ps_-block.ps_-block-sub.servers-$category > .ps__-list .server-item');
    return serverItems
        .firstWhere((el) => el.attributes['data-server-id'] == index.toString())
        .attributes['data-id'];
  }

  @override
  Future<BaseSourcesModel> getSources(String animeId, String episodeId,
      String? serverName, String? category) async {
    final actualAnimeId = episodeId.split('?').first;
    final actualEpisodeId = episodeId.split('?').last.split('=').last;
    AppLogger.d(
        'Fetching sources for animeId: $actualAnimeId, episodeId: $actualEpisodeId, server: $serverName, category: $category');
    final response = await http.get(
      Uri.parse(
          'https://yumaapi.vercel.app/watch?episodeId=$actualAnimeId\$episode\$$actualEpisodeId&type=dub&server=$serverName'),
    );
    final data = jsonDecode(response.body);
    AppLogger.w(data.toString());

    return BaseSourcesModel(
      sources: (data['sources'] as List<dynamic>)
          .map((source) => Source(
                url: source['url'],
                isM3U8: source['isM3U8'],
                quality: source[
                    'quality'], // this might be null — handle it if needed
              ))
          .toList(),
      tracks: (data['subtitles']
                  as List<dynamic>?) // ✅ was 'subtitles', now 'tracks'
              ?.map((track) => Subtitle(
                    url: track['url'],
                    lang: track['lang'],
                  ))
              .toList() ??
          [],
    );
  }
  // @override
  // Future<BaseSourcesModel> getSources(String animeId, String episodeId,
  //     String? serverName, String? category) async {
  //   AppLogger.d(
  //       'Fetching sources for animeId: $animeId, episodeId: $episodeId, server: $serverName, category: $category');
  //   final response = await http.get(
  //     Uri.parse(
  //         'https://shonenx-aniwatch-instance.vercel.app/api/v2/hianime/episode/sources?animeEpisodeId=$episodeId&server=$serverName&category=${category ?? 'sub'}'),
  //   );
  //   final data = jsonDecode(response.body)['data'];
  //   AppLogger.w(data.toString());

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
    final hianimeType =
        type != null ? _mapTypeToHianimeType(type.toLowerCase()) : null;
    final url = hianimeType != null
        ? '$baseUrl/search?keyword=$keyword&type=$hianimeType&page=$page'
        : '$baseUrl/search?keyword=$keyword&page=$page';
    AppLogger.d('Searching with URL: $url');
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    AppLogger.d('Received search response for keyword: $keyword');
    final document = parse(response.body);
    return parseSearch(document, baseUrl, keyword: keyword, page: page);
  }

  @override
  Future<SearchPage> getPage(String route, int page) async {
    AppLogger.d('Fetching page for route: $route, page: $page');
    final response = await http.get(Uri.parse('$baseUrl/$route?page=$page'),
        headers: _getHeaders());
    AppLogger.d('Received page response for route: $route');
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
      _ => null
    };
  }

  @override
  Future<List<String>> getSupportedServers() {
    return Future(() => ["vidcloud", "megacloud"]);
  }

  @override
  bool getDubSubParamSupport() {
    return true;
  }
}
