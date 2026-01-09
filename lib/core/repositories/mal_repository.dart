import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/anilist/page_response.dart';
import 'package:shonenx/core/myanimelist/services/mal_service.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/features/browse/model/search_filter.dart';

class MalRepository implements AnimeRepository {
  final MyAnimeListService service;

  MalRepository(this.service);

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
    // TODO: implement getFavorites
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> getPopularAnime({int page = 1, int perPage = 10}) {
    // TODO: implement getPopularAnime
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> getRecentlyUpdatedAnime(
      {int page = 1, int perPage = 10}) {
    // TODO: implement getRecentlyUpdatedAnime
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> getTopRatedAnime({int page = 1, int perPage = 10}) {
    // TODO: implement getTopRatedAnime
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> getTrendingAnime({int page = 1, int perPage = 10}) {
    // TODO: implement getTrendingAnime
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> getUpcomingAnime({int page = 1, int perPage = 10}) {
    // TODO: implement getUpcomingAnime
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> getMostFavoriteAnime({int page = 1, int perPage = 10}) {
    // TODO: implement getMostFavoriteAnime
    throw UnimplementedError();
  }

  @override
  String get name => 'myanimelist';

  @override
  Future<MediaListEntry?> updateUserAnimeList({
    required int mediaId,
    String? status,
    double? score, // GraphQL expects Float
    int? progress,
    FuzzyDateInput? startedAt,
    FuzzyDateInput? completedAt,
    int? repeat,
    String? notes,
    bool? private,
  }) {
    // TODO: implement updateUserAnimeListEntry
    throw UnimplementedError();
  }

  @override
  Future<PageResponse> getUserAnimeList(
      {required String type,
      required String status,
      required int page,
      required int perPage}) async {
    return await service.getUserAnimeList(
        type: type, status: status, page: page, perPage: perPage);
  }

  @override
  Future<MediaListEntry?> getAnimeEntry(int animeId) {
    // TODO: implement getAnimeEntry
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> toggleFavorite(int animeId) {
    // TODO: implement toggleFavorite
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getSupportedStatuses() async {
    return [
      "watching",
      "completed",
      "on_hold",
      "dropped",
      "plan_to_watch",
    ];
  }
}
