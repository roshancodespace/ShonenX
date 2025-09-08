import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/media_list_collection.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';


abstract class AnimeRepository {
  String get name;
  Future<MediaListCollection> getUserAnimeList(
      {required String type, required String status});
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
