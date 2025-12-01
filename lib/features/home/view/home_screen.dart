// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/features/home/view/widget/continue_section.dart';
import 'package:shonenx/features/home/view_model/homepage_notifier.dart';
import 'package:shonenx/features/home/view/widget/header_section.dart';
import 'package:shonenx/features/home/view/widget/home_section.dart';
import 'package:shonenx/features/home/view/widget/spotlight_section.dart';
import 'package:shonenx/shared/providers/update_provider.dart';
import 'package:shonenx/utils/updater.dart';

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
    if (home == null) return const SizedBox();

    if (!kDebugMode && ref.read(automaticUpdatesProvider)) {
      checkForUpdates(context);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(homepageProvider.notifier).fetchHomePage(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HeaderSection(isDesktop: false),
          SpotlightSection(homePage: home),
          const SizedBox(height: 16),
          Consumer(builder: (context, ref, child) {
            final allProgress =
                ref.watch(watchProgressRepositoryProvider).getAllProgress();
            return ContinueSection(allProgress: allProgress);
          }),
          if (home.trendingAnime.isNotEmpty)
            HomeSectionWidget(
                title: 'Trending Anime', mediaList: home.trendingAnime),
          if (home.popularAnime.isNotEmpty)
            HomeSectionWidget(
                title: 'Popular Anime', mediaList: home.popularAnime),
          if (home.mostFavoriteAnime.isNotEmpty)
            HomeSectionWidget(
                title: 'Most Favorite', mediaList: home.mostFavoriteAnime),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
