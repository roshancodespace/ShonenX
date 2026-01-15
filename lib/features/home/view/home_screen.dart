// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
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

    return RefreshIndicator(
      onRefresh: () => ref.read(homepageProvider.notifier).fetchHomePage(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 10),
        cacheExtent: 600,
        itemCount: _itemCount(home),

        itemBuilder: (context, index) {
          return _buildItemByIndex(context, ref, home, index);
        },
      ),
    );
  }

  int _itemCount(HomePage home) {
    int count = 0;

    count++; // Header
    if (home.trendingAnime.isNotEmpty) count++; // Spotlight
    count++; // Continue Watching

    if (home.trendingAnime.isNotEmpty) count++;
    if (home.popularAnime.isNotEmpty) count++;
    if (home.mostFavoriteAnime.isNotEmpty) count++;
    if (home.mostWatchedAnime.isNotEmpty) count++;
    if (home.topRatedAnime.isNotEmpty) count++;
    if (home.recentlyUpdated.isNotEmpty) count++;
    if (home.upcomingAnime.isNotEmpty) count++;

    count++; // Bottom spacing

    return count;
  }

  Widget _buildItemByIndex(
    BuildContext context,
    WidgetRef ref,
    HomePage home,
    int index,
  ) {
    int currentIndex = 0;

    /// HEADER
    if (index == currentIndex) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: const HeaderSection(isDesktop: false),
      );
    }
    currentIndex++;

    /// SPOTLIGHT
    if (home.trendingAnime.isNotEmpty) {
      if (index == currentIndex) {
        return SpotlightSection(spotlightAnime: home.trendingAnime);
      }
      currentIndex++;
    }

    /// CONTINUE WATCHING
    if (index == currentIndex) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: _ContinueWatchingSection(),
      );
    }
    currentIndex++;

    /// HOME SECTIONS
    final sections = <_HomeSectionData>[
      if (home.trendingAnime.isNotEmpty)
        _HomeSectionData('Trending Anime', home.trendingAnime),
      if (home.popularAnime.isNotEmpty)
        _HomeSectionData('Popular Anime', home.popularAnime),
      if (home.mostFavoriteAnime.isNotEmpty)
        _HomeSectionData('Most Favorite', home.mostFavoriteAnime),
      if (home.mostWatchedAnime.isNotEmpty)
        _HomeSectionData('Most Watched', home.mostWatchedAnime),
      if (home.topRatedAnime.isNotEmpty)
        _HomeSectionData('Top Rated', home.topRatedAnime),
      if (home.recentlyUpdated.isNotEmpty)
        _HomeSectionData('Recently Updated', home.recentlyUpdated),
      if (home.upcomingAnime.isNotEmpty)
        _HomeSectionData('Upcoming', home.upcomingAnime),
    ];

    final sectionIndex = index - currentIndex;

    if (sectionIndex >= 0 && sectionIndex < sections.length) {
      final section = sections[sectionIndex];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: HomeSectionWidget(
          title: section.title,
          mediaList: section.media,
        ),
      );
    }

    /// BOTTOM SPACING
    return const SizedBox(height: 80);
  }
}

class _ContinueWatchingSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(watchProgressStreamProvider)
        .when(
          data: (allProgress) {
            if (allProgress.isEmpty) return const SizedBox.shrink();

            final sorted = [...allProgress]
              ..sort(
                (a, b) => (b.lastUpdated ?? DateTime(0)).compareTo(
                  a.lastUpdated ?? DateTime(0),
                ),
              );

            return ContinueSection(allProgress: sorted.take(15).toList());
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
  }
}

class _HomeSectionData {
  final String title;
  final List<UniversalMedia> media;

  _HomeSectionData(this.title, this.media);
}
