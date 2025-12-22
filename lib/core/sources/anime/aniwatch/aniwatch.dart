import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/sources/anime/aniwatch/parser.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';
import 'package:html/parser.dart' show parse;

class AniwatchProvider extends AnimeProvider {
  AniwatchProvider({String? customApiUrl})
      : super(
            apiUrl: customApiUrl != null
                ? '$customApiUrl/anime/zoro'
                : "https://shonenx-aniwatch-instance.vercel.app/api/v2/hianime",
            baseUrl: 'https://hianime.in',
            providerName: 'aniwatch');

  Map<String, String> _getHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
    };
  }

  @override
  Future<HomePage> getHome() async {
    debugPrint('Fetching home page from $baseUrl');
    return HomePage();
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
    final response =
        await http.get(Uri.parse("$apiUrl/anime/$animeId/episodes"));
    final data = jsonDecode(response.body)['data'];

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
    final response = await http.get(
      Uri.parse(
          '$apiUrl/episode/sources?animeEpisodeId=$episodeId&server=$serverName&category=${category ?? 'sub'}'),
    );
    final data = jsonDecode(response.body)['data'];

    return BaseSourcesModel(
      sources: (data['sources'] as List<dynamic>)
          .map((source) => Source(
                url: source['url'],
                isM3U8: source['isM3U8'],
                quality: source['quality'],
              ))
          .toList(),
      tracks: (data['tracks'] as List<dynamic>?)
              ?.map((track) => Subtitle(
                    url: track['url'],
                    lang: track['lang'],
                  ))
              .toList() ??
          [],
    );
  }

  @override
  Future<SearchPage> getSearch(String keyword, String? type, int page) async {
    final hianimeType =
        type != null ? _mapTypeToHianimeType(type.toLowerCase()) : null;
    final url = hianimeType != null
        ? '$apiUrl/search?q=$keyword&page=$page'
        : '$apiUrl/search?q=$keyword&page=$page';

    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    final data = jsonDecode(response.body)['data'];

    return SearchPage(
      totalPages: data['totalPages'],
      currentPage: data['currentPage'],
      results: (data['animes'] as List<dynamic>)
          .map((anime) => BaseAnimeModel(
                id: anime['id'],
                name: anime['name'],
                type: anime['type'],
                duration: anime['duration'],
                episodes: EpisodesModel(
                  sub: anime['episodes']['sub'],
                  dub: anime['episodes']['dub'],
                  total: anime['sub'],
                ),
                poster: anime['poster'],
              ))
          .toList(),
    );
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
    return Future(() => ["hd-1", "hd-2"]);
  }

  @override
  bool getDubSubParamSupport() {
    return true;
  }
}
