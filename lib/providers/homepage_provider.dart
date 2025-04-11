import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/anilist/services/anilist_service.dart';
import 'package:shonenx/api/models/anime/page_model.dart';

// Provider for AnilistService to enable dependency injection
final anilistServiceProvider =
    Provider<AnilistService>((ref) => AnilistService());

// Improved homePageProvider with caching
final homePageProvider = FutureProvider.autoDispose<HomePage>((ref) async {
  // Keep the provider alive for 5 minutes to avoid unnecessary refetches
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), () => link.close());

  // Log the start of data fetching
  dev.log('Fetching home page data...', name: 'homePageProvider');

  // Get the AnilistService instance from the provider
  final anilistService = ref.watch(anilistServiceProvider);

  try {
    // Fetch data concurrently to improve performance
    final fetchFutures = await Future.wait([
      anilistService.getTrendingAnime(),
      anilistService.getPopularAnime(),
      anilistService.getRecentlyUpdatedAnime(),
    ]);

    final trending = fetchFutures[0];
    final popular = fetchFutures[1];
    final recentlyUpdated = fetchFutures[2];

    final homePageData = HomePage(
      trendingAnime: trending,
      popularAnime: popular,
      recentlyUpdated: recentlyUpdated,
      spotlight: [], // You can populate this if needed
      featured: [], // You can populate this if needed
    );

    dev.log('Home page data fetched successfully', name: 'homePageProvider');
    return homePageData;
  } catch (e, stackTrace) {
    dev.log('Failed to fetch home page data: $e',
        name: 'homePageProvider', error: e, stackTrace: stackTrace);
    throw Exception('Failed to load home page data: $e');
  }
});

