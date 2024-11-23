import 'package:nekoflow/data/models/anime_model.dart';

class HomeModel {
  final bool success;
  final HomeData data;

  HomeModel({
    required this.success,
    required this.data,
  });

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    return HomeModel(
      success: json['success'],
      data: HomeData.fromJson(json['data']),
    );
  }
}

class HomeData {
  final List<SpotlightAnime> spotlightAnimes;
  // final List<TrendingAnime> trendingAnimes;
  // final List<LatestEpisodeAnime> latestEpisodeAnimes;
  // final List<UpcomingAnime> topUpcomingAnimes;
  // final TopAnimeList top10Animes;
  final List<TopAiringAnime> topAiringAnimes;
  final List<MostPopularAnime> mostPopularAnimes;
  // final List<MostFavoriteAnime> mostFavoriteAnimes;
  final List<LatestCompletedAnime> latestCompletedAnimes;
  // final List<String> genres;

  HomeData({
    required this.spotlightAnimes,
    // required this.trendingAnimes,
    // required this.latestEpisodeAnimes,
    // required this.topUpcomingAnimes,
    // required this.top10Animes,
    required this.topAiringAnimes,
    required this.mostPopularAnimes,
    // required this.mostFavoriteAnimes,
    required this.latestCompletedAnimes,
    // required this.genres,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      spotlightAnimes: (json['spotlightAnimes'] as List<dynamic>)
          .map((e) => SpotlightAnime.fromJson(e))
          .toList(),
      // trendingAnimes: (json['trendingAnimes'] as List<dynamic>)
      //     .map((e) => TrendingAnime.fromJson(e))
      //     .toList(),
      // latestEpisodeAnimes: (json['latestEpisodeAnimes'] as List<dynamic>)
      //     .map((e) => LatestEpisodeAnime.fromJson(e))
      //     .toList(),
      // topUpcomingAnimes: (json['topUpcomingAnimes'] as List<dynamic>)
      //     .map((e) => UpcomingAnime.fromJson(e))
      //     .toList(),
      // top10Animes: TopAnimeList.fromJson(json['top10Animes']),
      topAiringAnimes: (json['topAiringAnimes'] as List<dynamic>)
          .map((e) => TopAiringAnime.fromJson(e))
          .toList(),
      mostPopularAnimes: (json['mostPopularAnimes'] as List<dynamic>)
          .map((e) => MostPopularAnime.fromJson(e))
          .toList(),
      // mostFavoriteAnimes: (json['mostFavoriteAnimes'] as List<dynamic>)
      //     .map((e) => MostFavoriteAnime.fromJson(e))
      //     .toList(),
      latestCompletedAnimes: (json['latestCompletedAnimes'] as List<dynamic>)
          .map((e) => LatestCompletedAnime.fromJson(e))
          .toList(),
      // genres: (json['genres'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}
