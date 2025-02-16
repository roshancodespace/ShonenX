import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/api/models/anime/anime_model.dep.dart';

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
  final List<BaseAnimeModel> spotlight;
  final List<BaseAnimeModel> trending;
  final List<Featured> featured;

  HomePage({
    this.trendingAnime = const [],
    this.popularAnime = const [],
    this.recentlyUpdated = const [],
    this.spotlight = const [],
    this.trending = const [],
    this.featured = const [],
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
  final List<BaseAnimeModel> results;

  SearchPage({
    this.totalPages = 0,
    this.currentPage = 0,
    this.results = const [],
  });
}
