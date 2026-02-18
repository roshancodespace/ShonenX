// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/universal/universal_news.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';

import 'package:shonenx/main.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/repositories/watch_progress_repository.dart';
import 'package:shonenx/features/home/model/home_section.dart';
import 'package:shonenx/shared/providers/settings/home_layout_notifier.dart';
import 'package:shonenx/features/home/view/widget/continue_section.dart';
import 'package:shonenx/features/home/view_model/homepage_notifier.dart';
import 'package:shonenx/features/home/view/widget/header_section.dart';
import 'package:shonenx/features/home/view/widget/home_section.dart';
import 'package:shonenx/features/home/view/widget/spotlight_section.dart';
import 'package:shonenx/features/news/view_model/news_provider.dart';
import 'package:shonenx/features/watchlist/view_model/watchlist_notifier.dart';
import 'package:shonenx/shared/providers/settings/experimental_notifier.dart';
import 'package:shonenx/features/home/view/widget/search_model.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  late final ProviderSubscription<AsyncValue<List<UniversalNews>>>
  _newsListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupNewsListener();
  }

  void _setupNewsListener() {
    _newsListener = ref.listenManual(newsProvider, (previous, next) {
      if (previous is AsyncData && next is AsyncData) {
        if (!mounted) return;
        final router = GoRouter.of(context);
        final String currentLocation =
            router.routerDelegate.currentConfiguration.last.matchedLocation;
        const mainTabs = {'/', '/browse', '/downloads', '/watchlist'};

        if (!mainTabs.contains(currentLocation)) return;

        final oldList = previous?.value ?? [];
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
                onPressed: () => context.push('/news'),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _newsListener.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // let background tasks know if we're actually looking at the app
  Future<void> _setAppOpenStatus(bool isOpen) async {
    await sharedPrefs.setBool('is_app_open', isOpen);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isOpen = state == AppLifecycleState.resumed;
    _setAppOpenStatus(isOpen);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homepageProvider);
    final layout = ref.watch(homeLayoutProvider);
    final sections = layout.where((s) => s.enabled).toList();

    final useNewUI = ref.watch(experimentalProvider.select((s) => s.newUI));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(homepageProvider.notifier).fetchHomePage(),
        child: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: sections.length + 2,
              itemBuilder: (context, index) {
                if (index == 0)
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: HeaderSection(isDesktop: false),
                  );

                if (state.isLoading)
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                if (state.error != null)
                  return Center(child: Text('Error: ${state.error}'));

                final home = state.homePage;
                if (home == null) return const SizedBox.shrink();

                // bottom spacer so the nav bar doesn't choke the content
                if (index == sections.length + 1)
                  return const SizedBox(height: 80);

                return _HomeSectionRenderer(
                  section: sections[index - 1],
                  home: home,
                );
              },
            ),
            if (useNewUI)
              Positioned(
                bottom: 100,
                right: 30,
                child: FloatingActionButton(
                  heroTag: 'search_fab',
                  onPressed: () => showSearchModal(context, 'search_fab'),
                  child: const Icon(Iconsax.search_normal),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

//  handles the switching logic so the main build isn't a mess
class _HomeSectionRenderer extends StatelessWidget {
  final HomeSection section;
  final HomePage home;

  const _HomeSectionRenderer({required this.section, required this.home});

  @override
  Widget build(BuildContext context) {
    switch (section.type) {
      case HomeSectionType.spotlight:
        if (home.trendingAnime.isEmpty) return const SizedBox.shrink();
        return SpotlightSection(spotlightAnime: home.trendingAnime);

      case HomeSectionType.continueWatching:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
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

  // mapping the dynamic data IDs to the actual home page lists
  List<UniversalMedia> _getStandardMedia(String? id, HomePage home) {
    return switch (id) {
      'trending' => home.trendingAnime,
      'popular' => home.popularAnime,
      'most_favorite' => home.mostFavoriteAnime,
      'most_watched' => home.mostWatchedAnime,
      'top_rated' => home.topRatedAnime,
      'recently_updated' => home.recentlyUpdated,
      'upcoming' => home.upcomingAnime,
      _ => [],
    };
  }
}

class _WatchlistHomeSection extends ConsumerStatefulWidget {
  final String title;
  final String status;

  const _WatchlistHomeSection({required this.title, required this.status});

  @override
  ConsumerState<_WatchlistHomeSection> createState() =>
      _WatchlistHomeSectionState();
}

class _WatchlistHomeSectionState extends ConsumerState<_WatchlistHomeSection> {
  @override
  void initState() {
    super.initState();
    _fetchListIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _WatchlistHomeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _fetchListIfNeeded();
    }
  }

  void _fetchListIfNeeded() {
    final state = ref.read(watchlistProvider);
    final list = state.listFor(widget.status);

    if (list.isEmpty && !state.loadingStatuses.contains(widget.status)) {
      ref.read(watchlistProvider.notifier).fetchListForStatus(widget.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(
      watchlistProvider.select((state) => state.listFor(widget.status)),
    );

    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    return HomeSectionWidget(
      title: widget.title,
      mediaList: list.map((e) => e.media).toList(),
    );
  }
}

final sortedWatchProgressProvider =
    Provider<AsyncValue<List<AnimeWatchProgressEntry>>>((ref) {
      return ref.watch(watchProgressStreamProvider).whenData((list) {
        if (list.isEmpty) return [];
        return list.whereType<AnimeWatchProgressEntry>().toList()..sort(
          (a, b) => (b.lastUpdated ?? DateTime(0)).compareTo(
            a.lastUpdated ?? DateTime(0),
          ),
        );
      });
    });

class _ContinueWatchingSection extends ConsumerWidget {
  const _ContinueWatchingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(sortedWatchProgressProvider)
        .when(
          data: (sorted) {
            if (sorted.isEmpty) return const SizedBox.shrink();
            return ContinueSection(allProgress: sorted.take(15).toList());
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
  }
}
