import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';

class Featured {
  final String? path;
  final String? title;
  final List<BaseAnimeModel>? animes;

  Featured({this.path, this.title, this.animes});
}

class HomePage {
  final List<UniversalMedia> trendingAnime;
  final List<UniversalMedia> popularAnime;
  final List<UniversalMedia> recentlyUpdated;
  final List<UniversalMedia> topRatedAnime;
  final List<UniversalMedia> mostFavoriteAnime;
  final List<UniversalMedia> mostWatchedAnime;
  final List<UniversalMedia> upcomingAnime;

  HomePage({
    this.trendingAnime = const [],
    this.popularAnime = const [],
    this.recentlyUpdated = const [],
    this.topRatedAnime = const [],
    this.mostFavoriteAnime = const [],
    this.mostWatchedAnime = const [],
    this.upcomingAnime = const [],
  });
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

  SearchPage(
      {this.totalPages = 0,
      this.currentPage = 0,
      this.results = const [],
      this.hasNextPage = false});
}
