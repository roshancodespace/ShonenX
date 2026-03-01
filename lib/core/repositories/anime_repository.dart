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
    FuzzyDate? startedAt,
    FuzzyDate? completedAt,
    int? repeat,
    String? notes,
    bool? private,
  });
  Future<UniversalMediaListEntry?> getAnimeEntry(int animeId);
  Future<List<UniversalMedia>> toggleFavorite(int ani);
  Future<UniversalPageResponse<UniversalMedia>> getFavorites({
    int page = 1,
    int perPage = 25,
  });
  Future<List<UniversalMedia>> searchAnime(
    String title, {
    int page = 1,
    int perPage = 25,
    SearchFilter? filter,
  });
  Future<UniversalMedia?> getAnimeDetails(int animeId);
  Future<UniversalPageResponse<UniversalMedia>> getTrendingAnime({
    int page = 1,
    int perPage = 25,
  });
  Future<UniversalPageResponse<UniversalMedia>> getPopularAnime({
    int page = 1,
    int perPage = 25,
  });
  Future<UniversalPageResponse<UniversalMedia>> getTopRatedAnime({
    int page = 1,
    int perPage = 25,
  });
  Future<UniversalPageResponse<UniversalMedia>> getRecentlyUpdatedAnime({
    int page = 1,
    int perPage = 25,
  });
  Future<UniversalPageResponse<UniversalMedia>> getUpcomingAnime({
    int page = 1,
    int perPage = 25,
  });
  Future<UniversalPageResponse<UniversalMedia>> getMostFavoriteAnime({
    int page = 1,
    int perPage = 25,
  });
  Future<List<String>> getSupportedStatuses();
  Future<List<String>> getGenres();
  Future<List<String>> getTags();
}
