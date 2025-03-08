import 'dart:convert';
import 'dart:developer';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/api/models/anime/page_model.dart';
import 'package:shonenx/api/models/anime/server_model.dart';
import 'package:shonenx/api/models/anime/source_model.dart';
import 'package:shonenx/api/sources/anime/aniwatch/parser.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:html/parser.dart' show parse;

class KaidoProvider extends AnimeProvider {
  KaidoProvider() : super(baseUrl: 'https://kaido.to', providerName: 'kaido');

  Map<String, String> _getHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 8.0.0; SM-G955U Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Mobile Safari/537.36',
    };
  }

  @override
  Future<HomePage> getHome() async {
    log('Fetching home page from $baseUrl');
    final response =
        await http.get(Uri.parse('$baseUrl/home'), headers: _getHeaders());
    final document = parse(response.body);
    return HomePage(
      spotlight: parseSpotlight(document, baseUrl),
      trending: parseTrending(document, baseUrl),
      featured: parseFeatured(document, baseUrl),
    );
  }

  @override
  Future<DetailPage> getDetails(String animeId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/$animeId'), headers: _getHeaders());
    final document = parse(response.body);
    return parseDetail(document, baseUrl, animeId: animeId);
  }

  @override
  Future<WatchPage> getWatch(String animeId) async {
    final response = await http.get(Uri.parse('$baseUrl/watch/$animeId'),
        headers: _getHeaders());
    final document = parse(response.body);
    return parseWatch(document, baseUrl, animeId: animeId);
  }

  @override
  Future<BaseEpisodeModel> getEpisodes(String animeId) async {
    log("Fetching : $baseUrl/ajax/episode/list/${animeId.split('-').last}");
    final response = await http.get(
        Uri.parse("$baseUrl/ajax/episode/list/${animeId.split('-').last}"),
        headers: _getHeaders());
    final document = parse(json.decode(response.body)['html']);
    return parseEpisodes(document, "$baseUrl/ajax/episode/list/",
        animeId: animeId);
  }

  @override
  Future<BaseServerModel> getServers(String episodeId) async {
    log("Fetching : $baseUrl/ajax/episode/servers?episodeId=$episodeId");
    final response = await http.get(
        Uri.parse("$baseUrl/ajax/episode/servers?episodeId=$episodeId"),
        headers: _getHeaders());
    final document = parse(json.decode(response.body)['html']);
    return parseServers(
        document, "$baseUrl/ajax/episode/servers?episodeId=$episodeId");
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
      String serverName, String category) async {
    final response = await http.get(
      Uri.parse(
          'https://animaze-swart.vercel.app/anime/zoro/watch/$animeId\$episode\$$episodeId\$$category'),
    );
    final responseBody = json.decode(response.body);
    log('Sources: ${responseBody['sources']}', name: "Sources");
    log('Subtitles: ${responseBody['subtitles']}', name: "Subtitles");
    log("Response status code: ${response.statusCode}");
    return BaseSourcesModel.fromJson(responseBody);
  }

  @override
  Future<SearchPage> getSearch(String keyword, String? type, int page) async {
    final hianimeType =
        type != null ? _mapTypeToHianimeType(type.toLowerCase()) : null;
    final url = hianimeType != null
        ? '$baseUrl/search?keyword=$keyword&type=$hianimeType&page=$page'
        : '$baseUrl/search?keyword=$keyword&page=$page';
    log(url);
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    final document = parse(response.body);
    return parseSearch(document, baseUrl, keyword: keyword, page: page);
  }

  @override
  Future<SearchPage> getPage(String route, int page) async {
    final response = await http.get(Uri.parse('$baseUrl/$route?page=$page'),
        headers: _getHeaders());
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
}
