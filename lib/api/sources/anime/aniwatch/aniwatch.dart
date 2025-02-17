import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/api/models/anime/page_model.dart';
import 'package:shonenx/api/models/anime/server_model.dart';
import 'package:shonenx/api/models/anime/source_model.dart';
import 'package:shonenx/api/sources/anime/aniwatch/parser.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:html/parser.dart' show parse;

class AniwatchProvider extends AnimeProvider {
  AniwatchProvider()
      : super(baseUrl: 'https://aniwatchtv.to', providerName: 'aniwatch');

  Map<String, String> _getHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
    };
  }

  @override
  Future<HomePage> getHome() async {
    debugPrint('Fetching home page from $baseUrl');
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
    final response = await http.get(
        Uri.parse("$baseUrl/ajax/v2/episode/list/${animeId.split('-').last}"),
        headers: _getHeaders());
    final document = parse(json.decode(response.body)['html']);
    return parseEpisodes(document, "$baseUrl/ajax/v2/episode/list/",
        animeId: animeId);
  }

  @override
  Future<BaseServerModel> getServers(String episodeId) async {
    final response = await http.get(
        Uri.parse("$baseUrl/ajax/v2/episode/servers?episodeId=$episodeId"),
        headers: _getHeaders());
    final document = parse(json.decode(response.body)['html']);
    return parseServers(
        document, "$baseUrl/ajax/v2/episode/servers?episodeId=$episodeId");
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
          'https://aniwatch-api-instance.vercel.app/api/v2/hianime/episode/sources?animeEpisodeId=$episodeId&server=${serverName.toLowerCase()}&category=${category.toLowerCase()}'),
      headers: _getHeaders(),
    );
    return BaseSourcesModel.fromJson(json.decode(response.body)['data']);
  }

  @override
  Future<SearchPage> getSearch(String keyword, String? type, int page) async {
    final hianimeType =
        type != null ? _mapToAniwatchType(type.toLowerCase()) : null;
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

  int? _mapToAniwatchType(String type) {
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
