// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/features/home/view/widget/continue_section.dart';
import 'package:shonenx/features/home/view_model/homepage_notifier.dart';
import 'package:shonenx/features/home/view/widget/header_section.dart';
import 'package:shonenx/features/home/view/widget/home_section.dart';
import 'package:shonenx/features/home/view/widget/spotlight_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homepageProvider);

    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (state.error != null)
      return Center(child: Text('Error: ${state.error}'));

    final home = state.homePage;
    if (home == null) return const SizedBox.shrink();

    final sections = [
      if (home.trendingAnime.isNotEmpty)
        _buildHomeSection('Trending Anime', home.trendingAnime),
      if (home.popularAnime.isNotEmpty)
        _buildHomeSection('Popular Anime', home.popularAnime),
      if (home.mostFavoriteAnime.isNotEmpty)
        _buildHomeSection('Most Favorite', home.mostFavoriteAnime),
      if (home.mostWatchedAnime.isNotEmpty)
        _buildHomeSection('Most Watched', home.mostWatchedAnime),
      if (home.topRatedAnime.isNotEmpty)
        _buildHomeSection('Top Rated', home.topRatedAnime),
      if (home.recentlyUpdated.isNotEmpty)
        _buildHomeSection('Recently Updated', home.recentlyUpdated),
      if (home.upcomingAnime.isNotEmpty)
        _buildHomeSection('Upcoming', home.upcomingAnime),
    ];

    return RefreshIndicator(
      onRefresh: () => ref.read(homepageProvider.notifier).fetchHomePage(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HeaderSection(isDesktop: false),
          if (home.trendingAnime.isNotEmpty)
            SpotlightSection(spotlightAnime: home.trendingAnime),
          const SizedBox(height: 16),

          // Continue Watching Section
          ref.watch(watchProgressStreamProvider).when(
                data: (allProgress) {
                  if (allProgress.isEmpty) return const SizedBox.shrink();
                  final sorted = allProgress.toList()
                    ..sort((a, b) => (b.lastUpdated ?? DateTime(0))
                        .compareTo(a.lastUpdated ?? DateTime(0)));
                  return ContinueSection(allProgress: sorted.take(15).toList());
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

          // All home sections
          ...sections,
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHomeSection(String title, List<UniversalMedia> mediaList) =>
      HomeSectionWidget(title: title, mediaList: mediaList);
}
