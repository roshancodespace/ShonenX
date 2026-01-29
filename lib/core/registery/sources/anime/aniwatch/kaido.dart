import 'dart:convert';
import 'dart:developer';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/registery/sources/anime/aniwatch/parser.dart';
import 'package:shonenx/core/registery/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/env_loader.dart';
import 'package:html/parser.dart' show parse;

class KaidoProvider extends AnimeProvider {
  KaidoProvider({String? customApiUrl})
      : super(
            apiUrl: customApiUrl != null
                ? '$customApiUrl/anime/zoro'
                : "$API_URL/anime/zoro",
            baseUrl: 'https://kaido.to',
            providerName: 'kaido');

  Map<String, String> _getHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 8.0.0; SM-G955U Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Mobile Safari/537.36',
    };
  }

  Future<Document?> _fetchDocument(String url) async {
    try {
      log("Fetching: $url", name: providerName);
      final response = await http.get(Uri.parse(url), headers: _getHeaders());

      if (response.statusCode == 200) {
        return parse(response.body);
      } else {
        log("Error ${response.statusCode}: Failed to fetch $url",
            name: providerName, level: 900);
      }
    } catch (e) {
      log("Exception: $e", name: providerName, level: 1000);
    }
    return null;
  }

  @override
  Future<HomePage> getHome() async {
    // final document = await _fetchDocument('$baseUrl/home');
    return HomePage();
    // if (document == null) {
    //   throw Exception("Failed to fetch HomePage from $baseUrl");
    // }
    // return HomePage(
    //   spotlight: parseSpotlight(document, baseUrl),
    //   trending: parseTrending(document, baseUrl),
    //   featured: parseFeatured(document, baseUrl),
    // );
  }

  @override
  Future<DetailPage> getDetails(String animeId) async {
    final document = await _fetchDocument('$baseUrl/$animeId');
    if (document == null) {
      throw Exception("Failed to fetch DetailPage for $animeId");
    }
    return parseDetail(document, baseUrl, animeId: animeId);
  }

  @override
  Future<WatchPage> getWatch(String animeId) async {
    final document = await _fetchDocument('$baseUrl/watch/$animeId');
    if (document == null) {
      throw Exception("Failed to fetch WatchPage for $animeId");
    }
    return parseWatch(document, baseUrl, animeId: animeId);
  }

  @override
  Future<BaseEpisodeModel> getEpisodes(String animeId,
      {String? anilistId, String? malId}) async {
    final episodeUrl = "$baseUrl/ajax/episode/list/${animeId.split('-').last}";
    final response =
        await http.get(Uri.parse(episodeUrl), headers: _getHeaders());

    if (response.statusCode == 200) {
      final document = parse(json.decode(response.body)['html']);
      return parseEpisodes(document, episodeUrl, animeId: animeId);
    } else {
      throw Exception("Failed to fetch episodes for $animeId");
    }
  }

  String? retrieveServerId(Document document, int index, String category) {
    try {
      final serverItems = document.querySelectorAll(
          '.ps_-block.ps_-block-sub.servers-$category > .ps__-list .server-item');
      return serverItems
          .firstWhere(
              (el) => el.attributes['data-server-id'] == index.toString())
          .attributes['data-id'];
    } catch (e) {
      log("Error retrieving server ID: $e", name: providerName, level: 900);
      return null;
    }
  }

  @override
  Future<BaseSourcesModel> getSources(String animeId, String episodeId,
      String? serverName, String? category) async {
    final apiUrl =
        '${this.apiUrl}/watch/$animeId\$episode\$$episodeId\$$category?server=${serverName ?? (await getSupportedServers()).sub.first}';

    try {
      log("Fetching sources from: $apiUrl", name: providerName);
      final response =
          await http.get(Uri.parse(apiUrl), headers: _getHeaders());

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        log("Sources found: ${responseBody['sources'].length}",
            name: providerName);
        return BaseSourcesModel.fromJson(responseBody);
      } else {
        log("Error ${response.statusCode}: Failed to fetch sources",
            name: providerName);
        throw Exception("Failed to fetch sources for episode $episodeId");
      }
    } catch (e) {
      log("Exception fetching sources: $e", name: providerName, level: 1000);
      throw Exception("Error fetching sources for $animeId - $episodeId");
    }
  }

  @override
  Future<SearchPage> getSearch(String keyword, String? type, int page) async {
    final hianimeType =
        type != null ? _mapTypeToHianimeType(type.toLowerCase()) : null;
    final searchUrl = hianimeType != null
        ? '$baseUrl/search?keyword=$keyword&type=$hianimeType&page=$page'
        : '$baseUrl/search?keyword=$keyword&page=$page';

    final document = await _fetchDocument(searchUrl);
    if (document == null) {
      throw Exception("Failed to fetch search results for $keyword");
    }
    return parseSearch(document, baseUrl, keyword: keyword, page: page);
  }

  @override
  Future<SearchPage> getPage(String route, int page) async {
    final pageUrl = '$baseUrl/$route?page=$page';
    final document = await _fetchDocument(pageUrl);
    if (document == null) {
      throw Exception("Failed to fetch page $page for route $route");
    }
    return parsePage(document, baseUrl, route: route, page: page);
  }

  @override
  Future<BaseServerModel> getSupportedServers({dynamic metadata}) {
    // return Future(() => ["vidcloud", "streamsb", "vidstreaming", "streamtape"]);
    return Future(() => BaseServerModel());
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
