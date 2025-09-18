import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/anilist/page_response.dart';

abstract class AnimeRepository {
  String get name;
  Future<PageResponse> getUserAnimeList({
    required String type,
    required String status,
    required int page,
    required int perPage,
  });
  Future<MediaListEntry?> updateUserAnimeList({
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
  Future<MediaListEntry?> getAnimeEntry(int animeId);
  Future<List<Media>> toggleFavorite(int ani);
  Future<List<Media>> getFavorites();
  Future<List<Media>> searchAnime(String title,
      {int page = 1, int perPage = 10});
  Future<Media?> getAnimeDetails(int animeId);
  Future<List<Media>> getTrendingAnime();
  Future<List<Media>> getPopularAnime();
  Future<List<Media>> getTopRatedAnime();
  Future<List<Media>> getRecentlyUpdatedAnime();
  Future<List<Media>> getUpcomingAnime();
}
