import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/core/models/universal/universal_page_response.dart';
import 'package:shonenx/features/browse/model/search_filter.dart';

abstract class AnimeRepository {
  String get name;
  Future<UniversalPageResponse<UniversalMediaListEntry>> getUserAnimeList({
    required String type,
    required String status,
    required int page,
    required int perPage,
  });
  Future<UniversalMediaListEntry?> updateUserAnimeList({
    required int mediaId,
    String? status,
    double? score,
    int? progress,
    FuzzyDateInput? startedAt,
    FuzzyDateInput? completedAt,
    int? repeat,
    String? notes,
    bool? private,
  });
  Future<UniversalMediaListEntry?> getAnimeEntry(int animeId);
  Future<List<UniversalMedia>> toggleFavorite(int ani);
  Future<UniversalPageResponse<UniversalMedia>> getFavorites(
      {int page = 1, int perPage = 10});
  Future<List<UniversalMedia>> searchAnime(
    String title, {
    int page = 1,
    int perPage = 10,
    SearchFilter? filter,
  });
  Future<UniversalMedia?> getAnimeDetails(int animeId);
  Future<List<UniversalMedia>> getTrendingAnime(
      {int page = 1, int perPage = 15});
  Future<List<UniversalMedia>> getPopularAnime(
      {int page = 1, int perPage = 15});
  Future<List<UniversalMedia>> getTopRatedAnime(
      {int page = 1, int perPage = 15});
  Future<List<UniversalMedia>> getRecentlyUpdatedAnime(
      {int page = 1, int perPage = 15});
  Future<List<UniversalMedia>> getUpcomingAnime(
      {int page = 1, int perPage = 15});
  Future<List<UniversalMedia>> getMostFavoriteAnime(
      {int page = 1, int perPage = 15});
  Future<List<String>> getSupportedStatuses();
  Future<List<String>> getGenres();
  Future<List<String>> getTags();
}
