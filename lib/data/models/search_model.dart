import 'package:nekoflow/data/models/anime_model.dart';

class SearchModel {
  final int currentPage;
  final bool hasNextPage;
  final int totalPages;
  final String searchQuery;
  final Map<String, List<String>> searchFilters;
  final List<AnimeResult> animes;
  final List<AnimeResult> mostPopularAnimes;

  SearchModel({
    required this.currentPage,
    required this.hasNextPage,
    required this.totalPages,
    required this.searchQuery,
    required this.searchFilters,
    required this.animes,
    required this.mostPopularAnimes,
  });

  factory SearchModel.fromJson(Map<String, dynamic> json) {
    return SearchModel(
      currentPage: json['currentPage'] ?? 1,
      hasNextPage: json['hasNextPage'] as bool,
      totalPages: json['totalPages'] ?? 1,
      searchQuery: json['searchQuery'] ?? '',
      searchFilters: (json['searchFilters'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ) ??
          {},
      animes: (json['animes'] as List<dynamic>)
          .map((animeResult) => AnimeResult.fromJson(animeResult))
          .toList(),
      mostPopularAnimes: (json['mostPopularAnimes'] as List<dynamic>)
          .map((animeResult) => AnimeResult.fromJson(animeResult))
          .toList(),
    );
  }
}


class AnimeResult {
  final String id;
  final String name;
  final String? japaneseTitle;
  final String poster;
  final String? duration;
  final String type;
  final String? rating;
  final bool? nsfw;
  final AnimeEpisodes episodes;

  AnimeResult({
    required this.id,
    required this.name,
    this.japaneseTitle,
    required this.poster,
    this.duration,
    required this.type,
    this.rating,
    this.nsfw,
    required this.episodes,
  });

  factory AnimeResult.fromJson(Map<String, dynamic> json) {
    return AnimeResult(
      id: json['id'] as String,
      name: json['name'] ?? json['title'] as String,
      japaneseTitle: json['jname'] as String?,
      poster: json['poster'] ?? json['image'] as String,
      duration: json['duration'] as String?,
      type: json['type'] as String,
      rating: json['rating'] as String?,
      nsfw: json['nsfw'] ?? false,
      episodes: AnimeEpisodes.fromJson(json['episodes']),
    );
  }
}
