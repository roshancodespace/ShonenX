import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/universal/universal_page_response.dart';
import 'package:shonenx/core/utils/app_utils.dart';

class HomePageModel {
  final Map<String, Map<String, dynamic>> sections;
  final DateTime lastUpdated;

  const HomePageModel({required this.sections, required this.lastUpdated});

  HomePage toHomePage() => HomePage(
    trendingAnime: _parseMediaPage('trendingAnime'),
    popularAnime: _parseMediaPage('popularAnime'),
    recentlyUpdated: _parseMediaPage('recentlyUpdated'),
    topRatedAnime: _parseMediaPage('topRatedAnime'),
    mostFavoriteAnime: _parseMediaPage('mostFavoriteAnime'),
    mostWatchedAnime: _parseMediaPage('mostWatchedAnime'),
    upcomingAnime: _parseMediaPage('upcomingAnime'),
  );

  UniversalPageResponse<UniversalMedia> _parseMediaPage(String key) {
    if (!sections.containsKey(key)) return UniversalPageResponse.empty();

    final sectionData = sections[key]!;
    final pageInfo = sectionData['pageInfo'];
    final data = sectionData['data'] as List<dynamic>? ?? [];

    return UniversalPageResponse<UniversalMedia>(
      pageInfo: UniversalPageInfo(
        total: pageInfo?['total'] ?? 0,
        currentPage: pageInfo?['currentPage'] ?? 1,
        lastPage: pageInfo?['lastPage'] ?? 1,
        hasNextPage: pageInfo?['hasNextPage'] ?? false,
        perPage: pageInfo?['perPage'] ?? 25,
      ),
      data: safeParse(key, data),
    );
  }

  factory HomePageModel.fromHomePage(HomePage page) => HomePageModel(
    sections: {
      'trendingAnime': _serializePage(page.trendingAnime),
      'popularAnime': _serializePage(page.popularAnime),
      'recentlyUpdated': _serializePage(page.recentlyUpdated),
      'topRatedAnime': _serializePage(page.topRatedAnime),
      'mostFavoriteAnime': _serializePage(page.mostFavoriteAnime),
      'mostWatchedAnime': _serializePage(page.mostWatchedAnime),
      'upcomingAnime': _serializePage(page.upcomingAnime),
    },
    lastUpdated: DateTime.now(),
  );

  static Map<String, dynamic> _serializePage(
    UniversalPageResponse<UniversalMedia> page,
  ) {
    return {
      'pageInfo': {
        'total': page.pageInfo.total,
        'currentPage': page.pageInfo.currentPage,
        'lastPage': page.pageInfo.lastPage,
        'hasNextPage': page.pageInfo.hasNextPage,
        'perPage': page.pageInfo.perPage,
      },
      'data': page.data.map((e) => e.toJson()).toList(),
    };
  }
}
