import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';

import 'package:http/http.dart' as http;

class AnimePaheProvider extends AnimeProvider {
  AnimePaheProvider({String? customApiUrl})
      : super(
            apiUrl: customApiUrl != null
                ? '$customApiUrl/anime/animepahe'
                : "${dotenv.env['API_URL']}/anime/animepahe",
            baseUrl: 'https://animepahe.ru/',
            providerName: 'animepahe');

  @override
  Future<HomePage> getHome() {
    throw UnimplementedError();
  }

  @override
  Future<DetailPage> getDetails(String animeId) {
    throw UnimplementedError();
  }

  @override
  Future<BaseEpisodeModel> getEpisodes(String animeId) async {
    final response = await http.get(Uri.parse('$apiUrl/info/$animeId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch episodes: HTTP ${response.statusCode}');
    }
    final data = jsonDecode(response.body);

    return BaseEpisodeModel(
        totalEpisodes: data['totalEpisodes'],
        episodes: (data['episodes'] as List<dynamic>)
            .map(
              (episode) => EpisodeDataModel(
                id: episode['id'],
                number: episode['number'] as int,
                title: episode['title'],
                thumbnail: episode['image'],
                url: episode['url'],
              ),
            )
            .toList());
  }

  @override
  Future<WatchPage> getWatch(String animeId) {
    throw UnimplementedError();
  }

  @override
  Future<SearchPage> getPage(String route, int page) {
    throw UnimplementedError();
  }

  @override
  Future<SearchPage> getSearch(String keyword, String? type, int page) async {
    final response = await http.get(Uri.parse('$apiUrl/$keyword'));
    final data = jsonDecode(response.body);

    return SearchPage(
      totalPages: data['totalPages'],
      currentPage: data['cucurrentPage'],
      results: (data['results'] as List<dynamic>)
          .map(
            (anime) => BaseAnimeModel(
              id: anime['id'],
              name: anime['title'],
              url: anime['url'],
              jname: anime['japaneseTitle'],
              type: anime['type'],
              episodes: EpisodesModel(
                sub: anime['sub'],
                dub: anime['dub'],
                total: anime['sub'],
              ),
              poster: anime['image'],
            ),
          )
          .toList(),
    );
  }

  @override
  Future<BaseSourcesModel> getSources(
    String animeId,
    String episodeId,
    String? serverName,
    String? category,
  ) async {
    try {
      final response =
          await http.get(Uri.parse('$apiUrl/watch?episodeId=$episodeId'));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch sources: HTTP ${response.statusCode}');
      }
      final jsonString = response.body;
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      if (!data.containsKey('sources')) {
        throw Exception('API response missing "sources" key');
      }

      return BaseSourcesModel(
        sources: (data['sources'] as List<dynamic>)
            .map((source) => Source.fromJson(source))
            .toList(),
        tracks: (data['tracks'] as List<dynamic>?)
                ?.map((track) => Subtitle.fromJson(track))
                .toList() ??
            [],
      );
    } catch (e) {
      rethrow; // Propagate the error to the caller (e.g., WatchScreen)
    }
  }

  @override
  Future<List<String>> getSupportedServers() {
    return Future(() => []);
  }

  @override
  bool getDubSubParamSupport() {
    return false;
  }
}
