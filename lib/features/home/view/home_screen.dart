import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/features/home/model/home_section.dart';
import 'package:shonenx/features/settings/view_model/home_layout_notifier.dart';
import 'package:shonenx/features/home/view/widget/continue_section.dart';
import 'package:shonenx/features/home/view_model/homepage_notifier.dart';
import 'package:shonenx/features/home/view/widget/header_section.dart';
import 'package:shonenx/features/home/view/widget/home_section.dart';
import 'package:shonenx/features/home/view/widget/spotlight_section.dart';
import 'package:shonenx/features/news/view_model/news_provider.dart';
import 'package:shonenx/features/watchlist/view_model/watchlist_notifier.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _setAppOpenStatus(bool isOpen) async {
    final box = Hive.box('settings');
    await box.put('is_app_open', isOpen);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isOpen = state == AppLifecycleState.resumed;
    _setAppOpenStatus(isOpen);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(newsProvider, (previous, next) {
      if (previous is AsyncData && next is AsyncData) {
        final router = GoRouter.of(context);
        final String currentLocation =
            router.routerDelegate.currentConfiguration.last.matchedLocation;
        const mainTabs = {'/', '/browse', '/downloads', '/watchlist'};
        if (!mainTabs.contains(currentLocation)) return;
        final oldList = previous!.value ?? [];
        final newList = next.value ?? [];

        final oldUrls = oldList.map((e) => e.url).toSet();
        final newItems = newList
            .where((e) => !oldUrls.contains(e.url))
            .toList();

        if (newItems.isNotEmpty) {
          final count = newItems.length;
          final message = count == 1
              ? 'New Article: ${newItems.first.title ?? "Check it out!"}'
              : '$count New Articles Available!';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              action: SnackBarAction(
                label: 'VIEW',
                onPressed: () {
                  context.push('/news');
                },
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });

    final state = ref.watch(homepageProvider);
    final layout = ref.watch(homeLayoutProvider);

    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());

    if (state.error != null)
      return Center(child: Text('Error: ${state.error}'));

    final home = state.homePage;

    if (home == null) return const SizedBox.shrink();

    // Filter enabled sections
    final sections = layout.where((s) => s.enabled).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(homepageProvider.notifier).fetchHomePage(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 10),
        cacheExtent: 600,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        itemCount: sections.length + 2, // + Header + Bottom Padding
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: HeaderSection(isDesktop: false),
            );
          }

          if (index == sections.length + 1) {
            return const SizedBox(height: 80);
          }

          final section = sections[index - 1]; // Offset header
          return _buildSection(context, ref, section, home);
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    WidgetRef ref,
    HomeSection section,
    HomePage home,
  ) {
    switch (section.type) {
      case HomeSectionType.spotlight:
        if (home.trendingAnime.isEmpty) return const SizedBox.shrink();
        return SpotlightSection(spotlightAnime: home.trendingAnime);

      case HomeSectionType.continueWatching:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _ContinueWatchingSection(),
        );

      case HomeSectionType.standard:
        final media = _getStandardMedia(section.dataId, home);
        if (media.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: HomeSectionWidget(title: section.title, mediaList: media),
        );

      case HomeSectionType.watchlist:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _WatchlistHomeSection(
            title: section.title,
            status: section.dataId!,
          ),
        );
    }
  }

  List<UniversalMedia> _getStandardMedia(String? id, HomePage home) {
    switch (id) {
      case 'trending':
        return home.trendingAnime;
      case 'popular':
        return home.popularAnime;
      case 'most_favorite':
        return home.mostFavoriteAnime;
      case 'most_watched':
        return home.mostWatchedAnime;
      case 'top_rated':
        return home.topRatedAnime;
      case 'recently_updated':
        return home.recentlyUpdated;
      case 'upcoming':
        return home.upcomingAnime;
      default:
        return [];
    }
  }
}

class _WatchlistHomeSection extends ConsumerWidget {
  final String title;
  final String status;

  const _WatchlistHomeSection({required this.title, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(watchlistProvider);
    final list = state.listFor(status);

    if (list.isEmpty) {
      if (!state.loadingStatuses.contains(status)) {
        Future.microtask(() {
          ref.read(watchlistProvider.notifier).fetchListForStatus(status);
        });
      }
      return const SizedBox.shrink(); // Hide if empty
    }

    return HomeSectionWidget(
      title: title,
      mediaList: list.map((e) => e.media).toList(),
    );
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
