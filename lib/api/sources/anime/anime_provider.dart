import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/api/models/anime/page_model.dart';
import 'package:shonenx/api/models/anime/server_model.dart';
import 'package:shonenx/api/models/anime/source_model.dart';

abstract class AnimeProvider {
  final String providerName;
  final String baseUrl;

  AnimeProvider({required this.baseUrl, required this.providerName});

  Future<HomePage> getHome();
  Future<DetailPage> getDetails(String animeId);
  Future<BaseEpisodeModel> getEpisodes(String animeId);
  Future<BaseServerModel> getServers(String episodeId);
  Future<BaseSourcesModel> getSources(
      String animeId, String episodeId, String serverName, String category);
  Future<SearchPage> getSearch(String keyword, String? type, int page);
  Future<SearchPage> getPage(String route, int page);
  Future<WatchPage> getWatch(String animeId);
}
