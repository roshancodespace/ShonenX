import 'package:shonenx/core/anilist/services/anilist_service.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/anilist/page_response.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/features/browse/model/search_filter.dart';

class AniListRepository implements AnimeRepository {
  final AnilistService service;

  AniListRepository(this.service);

  @override
  Future<List<Media>> searchAnime(
    String title, {
    int page = 1,
    int perPage = 10,
    SearchFilter? filter,
  }) {
    return service.searchAnime(title,
        page: page, perPage: perPage, filter: filter);
  }

  @override
  Future<List<String>> getGenres() {
    return service.getGenres();
  }

  @override
  Future<List<String>> getTags() {
    return service.getTags();
  }

  @override
  Future<Media?> getAnimeDetails(int animeId) {
    return service.getAnimeDetails(animeId);
  }

  @override
  Future<List<Media>> getFavorites() {
    return service.getFavorites();
  }

  @override
  Future<List<Media>> toggleFavorite(int animeId) {
    return service.toggleFavorite(animeId);
  }

  @override
  Future<List<Media>> getPopularAnime({int page = 1, int perPage = 10}) {
    return service.getPopularAnime(page: page, perPage: perPage);
  }

  @override
  Future<List<Media>> getRecentlyUpdatedAnime(
      {int page = 1, int perPage = 10}) {
    return service.getRecentlyUpdatedAnime(page: page, perPage: perPage);
  }

  @override
  Future<List<Media>> getTopRatedAnime({int page = 1, int perPage = 10}) {
    return service.getTopRatedAnime(page: page, perPage: perPage);
  }

  @override
  Future<List<Media>> getTrendingAnime({int page = 1, int perPage = 10}) {
    return service.getTrendingAnime(page: page, perPage: perPage);
  }

  @override
  Future<List<Media>> getUpcomingAnime({int page = 1, int perPage = 10}) {
    return service.getUpcomingAnime(page: page, perPage: perPage);
  }

  @override
  Future<List<Media>> getMostFavoriteAnime({int page = 1, int perPage = 10}) {
    return service.getMostFavoriteAnime(page: page, perPage: perPage);
  }

  @override
  Future<PageResponse> getUserAnimeList(
      {required String type,
      required String status,
      required int page,
      required int perPage}) {
    return service.getUserAnimeList(
        type: type, status: status, page: page, perPage: perPage);
  }

  @override
  Future<MediaListEntry?> updateUserAnimeList(
      {required int mediaId,
      String? status,
      double? score,
      int? progress,
      FuzzyDateInput? startedAt,
      FuzzyDateInput? completedAt,
      int? repeat,
      String? notes,
      bool? private}) {
    return service.updateUserAnimeList(
      mediaId: mediaId,
      status: status,
      score: score,
      progress: progress,
      startedAt: startedAt,
      completedAt: completedAt,
      repeat: repeat,
      notes: notes,
      private: private,
    );
  }

  @override
  Future<MediaListEntry?> getAnimeEntry(int animeId) {
    return service.getAnimeEntry(animeId);
  }

  @override
  Future<List<String>> getSupportedStatuses() async {
    return [
      "CURRENT",
      "PLANNING",
      "COMPLETED",
      "DROPPED",
      "PAUSED",
      "REPEATING",
    ];
  }

  @override
  String get name => 'anilist';
}
