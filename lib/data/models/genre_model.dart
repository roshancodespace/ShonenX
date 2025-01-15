import 'package:nekoflow/data/models/search_model.dart';

class GenreDetailModel {
  final bool success;
  final GenreDetailData data;

  GenreDetailModel({
    required this.success,
    required this.data,
  });

  factory GenreDetailModel.fromJson(Map<String, dynamic> json) {
    return GenreDetailModel(
      success: json['success'] ?? false,
      data: GenreDetailData.fromJson(json['data']),
    );
  }
}

class GenreDetailData {
  final String genreName;
  final List<AnimeResult> animes;
  final List<String> genres;
  final List<TopAiringAnime> topAiringAnimes;
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;

  GenreDetailData({
    required this.genreName,
    required this.animes,
    required this.genres,
    required this.topAiringAnimes,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory GenreDetailData.fromJson(Map<String, dynamic> json) {
    return GenreDetailData(
      genreName: json['genreName'] ?? '',
      animes: (json['animes'] as List<dynamic>?)
          ?.map((anime) => AnimeResult.fromJson(anime))
          .toList() ?? [],
      genres: List<String>.from(json['genres'] ?? []),
      topAiringAnimes: (json['topAiringAnimes'] as List<dynamic>?)
          ?.map((anime) => TopAiringAnime.fromJson(anime))
          .toList() ?? [],
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      hasNextPage: json['hasNextPage'] ?? false,
    );
  }
}

class TopAiringAnime {
  final String id;
  final String name;
  final String? japaneseTitle;
  final String poster;
  final String type;
  final AnimeEpisodes episodes;

  TopAiringAnime({
    required this.id,
    required this.name,
    this.japaneseTitle,
    required this.poster,
    required this.type,
    required this.episodes,
  });

  factory TopAiringAnime.fromJson(Map<String, dynamic> json) {
    return TopAiringAnime(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      japaneseTitle: json['jname'],
      poster: json['poster'] ?? '',
      type: json['type'] ?? '',
      episodes: AnimeEpisodes.fromJson(json['episodes'] ?? {}),
    );
  }
}

class AnimeEpisodes {
  final int sub;
  final int dub;

  AnimeEpisodes({
    required this.sub,
    required this.dub,
  });

  factory AnimeEpisodes.fromJson(Map<String, dynamic> json) {
    return AnimeEpisodes(
      sub: json['sub'] ?? 0,
      dub: json['dub'] ?? 0,
    );
  }

  // Convenience method to get total episodes
  int get total => sub + dub;
}