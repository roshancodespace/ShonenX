import 'package:shonenx/core/anilist/services/anilist_service.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';

class Gojo implements AnimeProvider {
  @override
  // TODO: implement apiUrl
  String get apiUrl => "https://backend.animetsu.cc/api/anime";

  @override
  String get baseUrl => "https://animetsu.cc";

  @override
  Future<DetailPage> getDetails(String animeId) {
    // TODO: implement getDetails
    throw UnimplementedError();
  }

  @override
  bool getDubSubParamSupport() {
    // TODO: implement getDubSubParamSupport
    throw UnimplementedError();
  }

  @override
  Future<BaseEpisodeModel> getEpisodes(String animeId) {
    // TODO: implement getEpisodes
    throw UnimplementedError();
  }

  @override
  Future<HomePage> getHome() {
    // TODO: implement getHome
    throw UnimplementedError();
  }

  @override
  Future<SearchPage> getPage(String route, int page) {
    // TODO: implement getPage
    throw UnimplementedError();
  }

  @override
  Future<SearchPage> getSearch(String keyword, String? type, int page) async {
    final res = await AnilistService(null).searchAnime(keyword, page: page);
    return SearchPage(
        results: res
            .map((a) => BaseAnimeModel(
                  id: a.id.toString(),
                  anilistId: a.id,
                  name: a.title?.english ?? a.title?.romaji ?? a.title?.native,
                  jname: a.title?.native,
                  type: a.format,
                  description: a.description,
                  poster: a.coverImage?.medium ?? a.coverImage?.large,
                  banner: a.bannerImage,
                  genres: a.genres,
                  releaseDate: a.startDate?.toDateTime?.toIso8601String(),
                  number: a.episodes,
                ))
            .toList());
  }

  @override
  Future<BaseSourcesModel> getSources(
      String animeId, String episodeId, String? serverName, String? category) {
    // TODO: implement getSources
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getSupportedServers() {
    // TODO: implement getSupportedServers
    throw UnimplementedError();
  }

  @override
  Future<WatchPage> getWatch(String animeId) {
    // TODO: implement getWatch
    throw UnimplementedError();
  }

  @override
  // TODO: implement providerName
  String get providerName => throw UnimplementedError();
}
