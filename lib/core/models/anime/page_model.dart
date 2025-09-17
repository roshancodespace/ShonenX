import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anime/anime_model.dep.dart';

class Featured {
  final String? path;
  final String? title;
  final List<BaseAnimeModel>? animes;

  Featured({this.path, this.title, this.animes});
}

class HomePage {
  final List<Media> trendingAnime;
  final List<Media> popularAnime;
  final List<Media> recentlyUpdated;
  final List<Media> topRatedAnime;
  final List<Media> mostFavoriteAnime;
  final List<Media> mostWatchedAnime;

  HomePage({
    this.trendingAnime = const [],
    this.popularAnime = const [],
    this.recentlyUpdated = const [],
    this.topRatedAnime = const [],
    this.mostFavoriteAnime = const [],
    this.mostWatchedAnime = const [],
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

  SearchPage({
    this.totalPages = 0,
    this.currentPage = 0,
    this.results = const [],
    this.hasNextPage = false
  });
}
