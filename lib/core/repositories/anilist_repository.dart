import 'package:shonenx/core/anilist/services/anilist_service.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/anilist/page_response.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';

class AniListRepository implements AnimeRepository {
  final AnilistService service;

  AniListRepository(this.service);

  @override
  Future<List<Media>> searchAnime(String title,
      {int page = 1, int perPage = 10}) {
    return service.searchAnime(title, page: page, perPage: perPage);
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
  Future<List<Media>> getPopularAnime() {
    return service.getPopularAnime();
  }

  @override
  Future<List<Media>> getRecentlyUpdatedAnime() {
    return service.getRecentlyUpdatedAnime();
  }

  @override
  Future<List<Media>> getTopRatedAnime() {
    return service.getTopRatedAnime();
  }

  @override
  Future<List<Media>> getTrendingAnime() {
    return service.getTrendingAnime();
  }

  @override
  Future<List<Media>> getUpcomingAnime() {
    return service.getUpcomingAnime();
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
  String get name => 'anilist';
}
