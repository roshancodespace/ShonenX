import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/anilist/page_response.dart';
import 'package:shonenx/core/myanimelist/services/mal_service.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';

class MalRepository implements AnimeRepository {
  final MyAnimeListService service;

  MalRepository(this.service);

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
    // TODO: implement getFavorites
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> getPopularAnime() {
    // TODO: implement getPopularAnime
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> getRecentlyUpdatedAnime() {
    // TODO: implement getRecentlyUpdatedAnime
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> getTopRatedAnime() {
    // TODO: implement getTopRatedAnime
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> getTrendingAnime() {
    // TODO: implement getTrendingAnime
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> getUpcomingAnime() {
    // TODO: implement getUpcomingAnime
    throw UnimplementedError();
  }

  @override
  // TODO: implement name
  String get name => throw UnimplementedError();

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
