import 'package:shonenx/core/services/anilist/anilist_service.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/core/models/universal/universal_page_response.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/features/browse/model/search_filter.dart';

class AniListRepository implements AnimeRepository {
  final AnilistService service;

  AniListRepository(this.service);

  @override
  Future<List<UniversalMedia>> searchAnime(
    String title, {
    int page = 1,
    int perPage = 10,
    SearchFilter? filter,
  }) async {
    final media = await service.searchAnime(
      title,
      page: page,
      perPage: perPage,
      filter: filter,
    );
    return media.map((e) => UniversalMedia.fromAnilist(e)).toList();
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
  Future<UniversalMedia?> getAnimeDetails(int animeId) async {
    final media = await service.getAnimeDetails(animeId);
    return media != null ? UniversalMedia.fromAnilist(media) : null;
  }

  @override
  Future<UniversalPageResponse<UniversalMedia>> getFavorites({
    int page = 1,
    int perPage = 25,
  }) async {
    final data = await service.getFavorites(page: page, perPage: perPage);
    final flattenMedias = data.mediaList.map((e) => e.media).toList();
    return UniversalPageResponse(
      data: flattenMedias.map((e) => UniversalMedia.fromAnilist(e)).toList(),
      pageInfo: UniversalPageInfo(
        currentPage: data.pageInfo.currentPage,
        hasNextPage: data.pageInfo.hasNextPage,
        lastPage: data.pageInfo.lastPage,
        perPage: data.pageInfo.perPage,
        total: data.pageInfo.total,
      ),
    );
  }

  @override
  Future<List<UniversalMedia>> toggleFavorite(int animeId) async {
    final media = await service.toggleFavorite(animeId);
    return media.map((e) => UniversalMedia.fromAnilist(e)).toList();
  }

  @override
  Future<List<UniversalMedia>> getPopularAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    final media = await service.getPopularAnime(page: page, perPage: perPage);
    return media.map((e) => UniversalMedia.fromAnilist(e)).toList();
  }

  @override
  Future<List<UniversalMedia>> getRecentlyUpdatedAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    final media = await service.getRecentlyUpdatedAnime(
      page: page,
      perPage: perPage,
    );
    return media.map((e) => UniversalMedia.fromAnilist(e)).toList();
  }

  @override
  Future<List<UniversalMedia>> getTopRatedAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    final media = await service.getTopRatedAnime(page: page, perPage: perPage);
    return media.map((e) => UniversalMedia.fromAnilist(e)).toList();
  }

  @override
  Future<List<UniversalMedia>> getTrendingAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    final media = await service.getTrendingAnime(page: page, perPage: perPage);
    return media.map((e) => UniversalMedia.fromAnilist(e)).toList();
  }

  @override
  Future<List<UniversalMedia>> getUpcomingAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    final media = await service.getUpcomingAnime(page: page, perPage: perPage);
    return media.map((e) => UniversalMedia.fromAnilist(e)).toList();
  }

  @override
  Future<List<UniversalMedia>> getMostFavoriteAnime({
    int page = 1,
    int perPage = 25,
  }) async {
    final media = await service.getMostFavoriteAnime(
      page: page,
      perPage: perPage,
    );
    return media.map((e) => UniversalMedia.fromAnilist(e)).toList();
  }

  @override
  Future<UniversalPageResponse<UniversalMediaListEntry>> getUserAnimeList({
    required String type,
    required String status,
    required int page,
    required int perPage,
  }) async {
    final data = await service.getUserAnimeList(
      type: type,
      status: status,
      page: page,
      perPage: perPage,
    );
    return UniversalPageResponse(
      data: data.mediaList
          .map((e) => UniversalMediaListEntry.fromAnilist(e))
          .toList(),
      pageInfo: UniversalPageInfo(
        currentPage: data.pageInfo.currentPage,
        hasNextPage: data.pageInfo.hasNextPage,
        lastPage: data.pageInfo.lastPage,
        perPage: data.pageInfo.perPage,
        total: data.pageInfo.total,
      ),
    );
  }

  @override
  Future<UniversalMediaListEntry?> updateUserAnimeList({
    required int mediaId,
    String? status,
    double? score,
    int? progress,
    FuzzyDate? startedAt,
    FuzzyDate? completedAt,
    int? repeat,
    String? notes,
    bool? private,
  }) async {
    final entry = await service.updateUserAnimeList(
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
    return entry != null ? UniversalMediaListEntry.fromAnilist(entry) : null;
  }

  @override
  Future<UniversalMediaListEntry?> getAnimeEntry(int animeId) async {
    final entry = await service.getAnimeEntry(animeId);
    return entry != null ? UniversalMediaListEntry.fromAnilist(entry) : null;
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
