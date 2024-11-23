import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';

class SpotlightAnime {
  final int rank;
  final String id;
  final String name;
  final String description;
  final String poster;
  final String? jname;
  final AnimeEpisodes? episodes;
  final String? type;
  final List<String>? otherInfo;

  SpotlightAnime({
    required this.rank,
    required this.id,
    required this.name,
    required this.description,
    required this.poster,
    required this.jname,
    required this.episodes,
    required this.type,
    required this.otherInfo,
  });

  factory SpotlightAnime.fromJson(Map<String, dynamic> json) {
    return SpotlightAnime(
      rank: json['rank'],
      id: json['id'],
      name: json['name'],
      description: json['description'],
      poster: json['poster'],
      jname: json['jname'],
      episodes: AnimeEpisodes.fromJson(json['episodes']),
      type: json['type'],
      otherInfo:
          (json['otherInfo'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}

class TrendingAnime {
  final int rank;
  final String id;
  final String name;
  final String jname;
  final String poster;

  TrendingAnime({
    required this.rank,
    required this.id,
    required this.name,
    required this.jname,
    required this.poster,
  });

  factory TrendingAnime.fromJson(Map<String, dynamic> json) {
    return TrendingAnime(
      rank: json['rank'],
      id: json['id'],
      name: json['name'],
      jname: json['jname'],
      poster: json['poster'],
    );
  }
}

class LatestEpisodeAnime implements BaseAnimeCard{
  @override
  final String id;
  @override
  final String name;
  final String jname;
  @override
  final String poster;
  final String duration;
  @override
  final String type;
  final dynamic rating;
  final AnimeEpisodes episodes;

  LatestEpisodeAnime({
    required this.id,
    required this.name,
    required this.jname,
    required this.poster,
    required this.duration,
    required this.type,
    required this.rating,
    required this.episodes,
  });

  factory LatestEpisodeAnime.fromJson(Map<String, dynamic> json) {
    return LatestEpisodeAnime(
      id: json['id'],
      name: json['name'],
      jname: json['jname'],
      poster: json['poster'],
      duration: json['duration'],
      type: json['type'],
      rating: json['rating'],
      episodes: AnimeEpisodes.fromJson(json['episodes']),
    );
  }
}

class UpcomingAnime {
  final String id;
  final String name;
  final String jname;
  final String poster;
  final String duration;
  final String type;
  final dynamic rating;
  final AnimeEpisodes episodes;

  UpcomingAnime({
    required this.id,
    required this.name,
    required this.jname,
    required this.poster,
    required this.duration,
    required this.type,
    required this.rating,
    required this.episodes,
  });

  factory UpcomingAnime.fromJson(Map<String, dynamic> json) {
    return UpcomingAnime(
      id: json['id'],
      name: json['name'],
      jname: json['jname'],
      poster: json['poster'],
      duration: json['duration'],
      type: json['type'],
      rating: json['rating'],
      episodes: AnimeEpisodes.fromJson(json['episodes']),
    );
  }
}

class TopAnimeList {
  final List<TopAnime> today;
  final List<TopAnime> week;
  final List<TopAnime> month;

  TopAnimeList({
    required this.today,
    required this.week,
    required this.month,
  });

  factory TopAnimeList.fromJson(Map<String, dynamic> json) {
    return TopAnimeList(
      today: (json['today'] as List<dynamic>)
          .map((e) => TopAnime.fromJson(e))
          .toList(),
      week: (json['week'] as List<dynamic>)
          .map((e) => TopAnime.fromJson(e))
          .toList(),
      month: (json['month'] as List<dynamic>)
          .map((e) => TopAnime.fromJson(e))
          .toList(),
    );
  }
}

class TopAnime {
  final String id;
  final int rank;
  final String name;
  final String jname;
  final String poster;
  final AnimeEpisodes episodes;

  TopAnime({
    required this.id,
    required this.rank,
    required this.name,
    required this.jname,
    required this.poster,
    required this.episodes,
  });

  factory TopAnime.fromJson(Map<String, dynamic> json) {
    return TopAnime(
      id: json['id'],
      rank: json['rank'],
      name: json['name'],
      jname: json['jname'],
      poster: json['poster'],
      episodes: AnimeEpisodes.fromJson(json['episodes']),
    );
  }
}

class TopAiringAnime implements BaseAnimeCard {
  @override
  final String id;
  @override
  final String name;
  final String jname;
  @override
  final String poster;
  final AnimeEpisodes episodes;
  @override
  final String type;

  TopAiringAnime({
    required this.id,
    required this.name,
    required this.jname,
    required this.poster,
    required this.episodes,
    required this.type,
  });

  factory TopAiringAnime.fromJson(Map<String, dynamic> json) {
    return TopAiringAnime(
      id: json['id'],
      name: json['name'],
      jname: json['jname'],
      poster: json['poster'],
      episodes: AnimeEpisodes.fromJson(json['episodes']),
      type: json['type'],
    );
  }
}

class MostPopularAnime implements BaseAnimeCard {
  @override
  final String id;
  @override
  final String name;
  final String jname;
  @override
  final String poster;
  final AnimeEpisodes episodes;
  @override
  final String type;

  MostPopularAnime({
    required this.id,
    required this.name,
    required this.jname,
    required this.poster,
    required this.episodes,
    required this.type,
  });

  factory MostPopularAnime.fromJson(Map<String, dynamic> json) {
    return MostPopularAnime(
      id: json['id'],
      name: json['name'],
      jname: json['jname'],
      poster: json['poster'],
      episodes: AnimeEpisodes.fromJson(json['episodes']),
      type: json['type'],
    );
  }
}

class MostFavoriteAnime {
  final String id;
  final String name;
  final String jname;
  final String poster;
  final AnimeEpisodes episodes;
  final String type;

  MostFavoriteAnime({
    required this.id,
    required this.name,
    required this.jname,
    required this.poster,
    required this.episodes,
    required this.type,
  });

  factory MostFavoriteAnime.fromJson(Map<String, dynamic> json) {
    return MostFavoriteAnime(
      id: json['id'],
      name: json['name'],
      jname: json['jname'],
      poster: json['poster'],
      episodes: AnimeEpisodes.fromJson(json['episodes']),
      type: json['type'],
    );
  }
}

class LatestCompletedAnime implements BaseAnimeCard {
  @override
  final String id;
  @override
  final String name;
  final String jname;
  @override
  final String poster;
  final AnimeEpisodes episodes;
  @override
  final String type;

  LatestCompletedAnime({
    required this.id,
    required this.name,
    required this.jname,
    required this.poster,
    required this.episodes,
    required this.type,
  });

  factory LatestCompletedAnime.fromJson(Map<String, dynamic> json) {
    return LatestCompletedAnime(
      id: json['id'],
      name: json['name'],
      jname: json['jname'],
      poster: json['poster'],
      episodes: AnimeEpisodes.fromJson(json['episodes']),
      type: json['type'],
    );
  }
}

class AnimeEpisodes {
  final int? sub;
  final int? dub;

  AnimeEpisodes({required this.sub, required this.dub});

  factory AnimeEpisodes.fromJson(Map<String, dynamic> json) {
    return AnimeEpisodes(sub: json['sub'], dub: json['dub']);
  }
}
