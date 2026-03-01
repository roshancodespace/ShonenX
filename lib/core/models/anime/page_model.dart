import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';
import 'package:shonenx/core/models/universal/universal_page_response.dart';

class Featured {
  final String? path;
  final String? title;
  final List<BaseAnimeModel>? animes;

  Featured({this.path, this.title, this.animes});
}

class HomePage {
  final UniversalPageResponse<UniversalMedia> trendingAnime;
  final UniversalPageResponse<UniversalMedia> popularAnime;
  final UniversalPageResponse<UniversalMedia> recentlyUpdated;
  final UniversalPageResponse<UniversalMedia> topRatedAnime;
  final UniversalPageResponse<UniversalMedia> mostFavoriteAnime;
  final UniversalPageResponse<UniversalMedia> mostWatchedAnime;
  final UniversalPageResponse<UniversalMedia> upcomingAnime;

  HomePage({
    UniversalPageResponse<UniversalMedia>? trendingAnime,
    UniversalPageResponse<UniversalMedia>? popularAnime,
    UniversalPageResponse<UniversalMedia>? recentlyUpdated,
    UniversalPageResponse<UniversalMedia>? topRatedAnime,
    UniversalPageResponse<UniversalMedia>? mostFavoriteAnime,
    UniversalPageResponse<UniversalMedia>? mostWatchedAnime,
    UniversalPageResponse<UniversalMedia>? upcomingAnime,
  }) : trendingAnime = trendingAnime ?? UniversalPageResponse.empty(),
       popularAnime = popularAnime ?? UniversalPageResponse.empty(),
       recentlyUpdated = recentlyUpdated ?? UniversalPageResponse.empty(),
       topRatedAnime = topRatedAnime ?? UniversalPageResponse.empty(),
       mostFavoriteAnime = mostFavoriteAnime ?? UniversalPageResponse.empty(),
       mostWatchedAnime = mostWatchedAnime ?? UniversalPageResponse.empty(),
       upcomingAnime = upcomingAnime ?? UniversalPageResponse.empty();
}

class DetailPage {
  final BaseAnimeModel? anime;

  DetailPage({this.anime});
}

class WatchPage {
  final int? totalEpisodes;
  final BaseAnimeModel? anime;

  WatchPage({this.totalEpisodes, this.anime});
}

class SearchPage {
  final int? totalPages;
  final int? currentPage;
  final bool? hasNextPage;
  final List<BaseAnimeModel> results;

  SearchPage({
    this.totalPages = 0,
    this.currentPage = 0,
    this.results = const [],
    this.hasNextPage = false,
  });
}
