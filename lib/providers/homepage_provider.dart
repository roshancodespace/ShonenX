import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/anilist/services/anilist_service.dart';
import 'package:shonenx/api/models/anime/page_model.dart';

final homePageProvider = FutureProvider<HomePage>((ref) async {
  log('Fetching home page data...');
  final anilistService = AnilistService();
  final trending = await anilistService.getTrendingAnime();
  final popular = await anilistService.getPopularAnime();
  final recentlyUpdated = await anilistService.getRecentlyUpdatedAnime();
  final homePageData = HomePage(
      trendingAnime: trending,
      popularAnime: popular,
      recentlyUpdated: recentlyUpdated,
      spotlight: [],
      featured: []);
  return homePageData;
});
