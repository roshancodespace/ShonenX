import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/repositories/anime_repository.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/home/model/home_page.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

class HomepageState {
  final HomePage? homePage;
  final DateTime lastUpdated;
  final bool isLoading;
  final String? error;

  const HomepageState({
    this.homePage,
    required this.lastUpdated,
    this.isLoading = true,
    this.error,
  });

  HomepageState copyWith({
    HomePage? homePage,
    DateTime? lastUpdated,
    bool? isLoading,
    String? error,
  }) {
    return HomepageState(
      homePage: homePage ?? this.homePage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomepageNotifier extends Notifier<HomepageState> {
  AnimeRepository get _repo => ref.read(animeRepositoryProvider);
  Box<HomePageModel> get _box => Hive.box<HomePageModel>(_boxName);
  static const _boxName = 'home_page';

  @override
  HomepageState build() {
    final cachedModel = _box.get(0);

    return HomepageState(
      homePage: cachedModel?.toHomePage(),
      lastUpdated: cachedModel?.lastUpdated ?? DateTime.now(),
      isLoading: false,
    );
  }

  Future<HomepageState> initialize({bool forceRefresh = false}) async {
    final shouldRefresh = forceRefresh ||
        state.homePage == null ||
        state.homePage!.trendingAnime.isEmpty ||
        state.homePage!.popularAnime.isEmpty ||
        state.homePage!.mostFavoriteAnime.isEmpty ||
        state.lastUpdated
            .isBefore(DateTime.now().subtract(const Duration(hours: 6)));

    return shouldRefresh ? await fetchHomePage() : state;
  }

  void clearCache() {
    Hive.box<HomePageModel>(_boxName).clear();
    state = HomepageState(
      lastUpdated: DateTime.now(),
      isLoading: false,
    );
  }

  Future<HomepageState> fetchHomePage() async {
    try {
      final trending = await _repo.getTrendingAnime();
      final popular = await _repo.getPopularAnime();
      final mostFavorite = await _repo.getTopRatedAnime();

      final homePage = HomePage(
        trendingAnime: trending,
        popularAnime: popular,
        recentlyUpdated: [],
        topRatedAnime: [],
        mostFavoriteAnime: mostFavorite,
        mostWatchedAnime: [],
      );

      AppLogger.d('✅ Successfully fetched homepage data');
      _saveToHive(homePage);
      return state.copyWith(homePage: homePage, isLoading: false);
    } catch (err, stackTrace) {
      AppLogger.e('❌ Error fetching homepage data', err, stackTrace);
      return state.copyWith(error: err.toString(), isLoading: false);
    }
  }

  void _saveToHive(HomePage page) {
    final box = Hive.box<HomePageModel>(_boxName);
    final model = HomePageModel.fromHomePage(page);
    box.put(0, model);
    state = state.copyWith(
      homePage: page,
      lastUpdated: model.lastUpdated,
      isLoading: false,
    );
  }
}

final homepageProvider = NotifierProvider<HomepageNotifier, HomepageState>(
  HomepageNotifier.new,
);
