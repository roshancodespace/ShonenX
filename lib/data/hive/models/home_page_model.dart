import 'package:hive_flutter/hive_flutter.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'home_page_model.g.dart';

@HiveType(typeId: HiveTypeIds.homePage)
class HomePageModel {
  @HiveField(0)
  final List<Map<String, dynamic>> trendingAnime;
  @HiveField(1)
  final List<Map<String, dynamic>> popularAnime;
  @HiveField(2)
  final List<Map<String, dynamic>> recentlyUpdated;
  @HiveField(3)
  final List<Map<String, dynamic>> topRatedAnime;
  @HiveField(4)
  final List<Map<String, dynamic>> mostFavoriteAnime;
  @HiveField(5)
  final List<Map<String, dynamic>> mostWatchedAnime;
  @HiveField(6)
  final DateTime lastUpdated;

  HomePageModel({
    this.trendingAnime = const [],
    this.popularAnime = const [],
    this.recentlyUpdated = const [],
    this.topRatedAnime = const [],
    this.mostFavoriteAnime = const [],
    this.mostWatchedAnime = const [],
    required this.lastUpdated,
  });

  HomePage toHomePage() {
    List<Media> safeParse(String label, List list) {
      try {
        Map<String, dynamic> convertToStringKeys(Map<dynamic, dynamic> input) {
          return input.map((key, value) {
            if (value is Map) {
              return MapEntry(key.toString(), convertToStringKeys(value));
            } else if (value is List) {
              return MapEntry(
                  key.toString(),
                  value
                      .map((v) => v is Map ? convertToStringKeys(v) : v)
                      .toList());
            }
            return MapEntry(key.toString(), value);
          });
        }

        return list
            .whereType<Map>()
            .map((item) => Media.fromJson(convertToStringKeys(item)))
            .toList();
      } catch (e, st) {
        print("⚠️ Failed to parse $label: $e");
        print(st);
        return [];
      }
    }

    return HomePage(
      trendingAnime: safeParse("trendingAnime", trendingAnime),
      popularAnime: safeParse("popularAnime", popularAnime),
      recentlyUpdated: safeParse("recentlyUpdated", recentlyUpdated),
      topRatedAnime: safeParse("topRatedAnime", topRatedAnime),
      mostFavoriteAnime: safeParse("mostFavoriteAnime", mostFavoriteAnime),
      mostWatchedAnime: safeParse("mostWatchedAnime", mostWatchedAnime),
    );
  }

  factory HomePageModel.fromHomePage(HomePage homePage) {
    return HomePageModel(
      trendingAnime:
          homePage.trendingAnime.map((item) => item.toJson()).toList(),
      popularAnime: homePage.popularAnime.map((item) => item.toJson()).toList(),
      recentlyUpdated:
          homePage.recentlyUpdated.map((item) => item.toJson()).toList(),
      topRatedAnime:
          homePage.topRatedAnime.map((item) => item.toJson()).toList(),
      mostFavoriteAnime:
          homePage.mostFavoriteAnime.map((item) => item.toJson()).toList(),
      mostWatchedAnime:
          homePage.mostWatchedAnime.map((item) => item.toJson()).toList(),
      lastUpdated: DateTime.now(),
    );
  }
}
