import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';

abstract class BaseAnime {
  String get id;
  String get name;
  String get jname;
  String get poster;
  AnimeEpisodes get episodes;
  String get type;
}

class SpotlightAnime extends BaseAnime {
  @override
  final String id;
  @override
  final String name;
  @override
  final String jname;
  @override
  final String poster;
  @override
  final AnimeEpisodes episodes;
  @override
  final String type;
  final int rank;
  final String description;
  final List<String> otherInfo;

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
      jname: json['jname'] ?? '',
      episodes: AnimeEpisodes.fromJson(json['episodes']),
      type: json['type'] ?? '',
      otherInfo: (json['otherInfo'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class TrendingAnime extends BaseAnime {
  @override
  final String id;
  @override
  final String name;
  @override
  final String jname;
  @override
  final String poster;
  @override
  final AnimeEpisodes episodes = AnimeEpisodes(sub: null, dub: null);
  @override
  final String type = '';
  final int rank;

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

class LatestEpisodeAnime extends BaseAnime implements BaseAnimeCard {
  @override
  final String id;
  @override
  final String name;
  @override
  final String jname;
  @override
  final String poster;
  @override
  final AnimeEpisodes episodes;
  @override
  final String type;
  final String duration;
  final dynamic rating;

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

  @override
  double? get score => null;

  @override
  int? get episodeCount => episodes.sub;

  @override
  String? get status => null;
}

class UpcomingAnime extends BaseAnime implements BaseAnimeCard {
  @override
  final String id;
  @override
  final String name;
  @override
  final String jname;
  @override
  final String poster;
  @override
  final AnimeEpisodes episodes;
  @override
  final String type;
  final String duration;
  final dynamic rating;

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

  @override
  double? get score => null;

  @override
  int? get episodeCount => episodes.sub;

  @override
  String? get status => null;
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

class TopAnime extends BaseAnime {
  @override
  final String id;
  @override
  final String name;
  @override
  final String jname;
  @override
  final String poster;
  @override
  final AnimeEpisodes episodes;
  @override
  final String type = '';
  final int rank;

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

class TopAiringAnime extends BaseAnime implements BaseAnimeCard {
  @override
  final String id;
  @override
  final String name;
  @override
  final String jname;
  @override
  final String poster;
  @override
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

  @override
  double? get score => null;

  @override
  int? get episodeCount => episodes.sub;

  @override
  String? get status => null;
}

class MostPopularAnime extends BaseAnime implements BaseAnimeCard {
  @override
  final String id;
  @override
  final String name;
  @override
  final String jname;
  @override
  final String poster;
  @override
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

  @override
  double? get score => null;

  @override
  int? get episodeCount => episodes.sub;

  @override
  String? get status => null;
}

class MostFavoriteAnime extends BaseAnime implements BaseAnimeCard {
  @override
  final String id;
  @override
  final String name;
  @override
  final String jname;
  @override
  final String poster;
  @override
  final AnimeEpisodes episodes;
  @override
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

  @override
  double? get score => null;

  @override
  int? get episodeCount => episodes.sub;

  @override
  String? get status => null;
}

class LatestCompletedAnime extends BaseAnime implements BaseAnimeCard {
  @override
  final String id;
  @override
  final String name;
  @override
  final String jname;
  @override
  final String poster;
  @override
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

  @override
  double? get score => null;

  @override
  int? get episodeCount => episodes.sub;

  @override
  String? get status => null;
}

class AnimeEpisodes {
  final int? sub;
  final int? dub;

  const AnimeEpisodes({required this.sub, required this.dub});

  factory AnimeEpisodes.fromJson(Map<String, dynamic> json) {
    return AnimeEpisodes(sub: json['sub'], dub: json['dub']);
  }
}
