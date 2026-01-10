import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/utils/app_utils.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'home_page.g.dart';

@HiveType(typeId: HiveTypeIds.homePage)
class HomePageModel {
  @HiveField(0)
  final Map<String, List<Map<String, dynamic>>> sections;

  @HiveField(1)
  final DateTime lastUpdated;

  const HomePageModel({
    required this.sections,
    required this.lastUpdated,
  });

  HomePage toHomePage() => HomePage(
        trendingAnime: _parseMediaList('trendingAnime'),
        popularAnime: _parseMediaList('popularAnime'),
        recentlyUpdated: _parseMediaList('recentlyUpdated'),
        topRatedAnime: _parseMediaList('topRatedAnime'),
        mostFavoriteAnime: _parseMediaList('mostFavoriteAnime'),
        mostWatchedAnime: _parseMediaList('mostWatchedAnime'),
        upcomingAnime: _parseMediaList('upcomingAnime'),
      );

  List<UniversalMedia> _parseMediaList(String key) =>
      safeParse(key, sections[key] ?? []);

  factory HomePageModel.fromHomePage(HomePage page) => HomePageModel(
        sections: {
          'trendingAnime': page.trendingAnime.map((e) => e.toJson()).toList(),
          'popularAnime': page.popularAnime.map((e) => e.toJson()).toList(),
          'recentlyUpdated':
              page.recentlyUpdated.map((e) => e.toJson()).toList(),
          'topRatedAnime': page.topRatedAnime.map((e) => e.toJson()).toList(),
          'mostFavoriteAnime':
              page.mostFavoriteAnime.map((e) => e.toJson()).toList(),
          'mostWatchedAnime':
              page.mostWatchedAnime.map((e) => e.toJson()).toList(),
          'upcomingAnime': page.upcomingAnime.map((e) => e.toJson()).toList(),
        },
        lastUpdated: DateTime.now(),
      );
}
