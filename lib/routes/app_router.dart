import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/boxes/watchlist_box.dart';
import 'package:nekoflow/data/models/episodes_model.dart';
import 'package:nekoflow/data/models/search_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/screens/main/browse/browse_screen.dart';
import 'package:nekoflow/screens/main/browse/search_result_screen.dart';
import 'package:nekoflow/screens/main/details/details_screen.dart';
import 'package:nekoflow/screens/main/home/home_screen.dart';
import 'package:nekoflow/screens/main/settings/about/about_screen.dart';
import 'package:nekoflow/screens/main/settings/settings_screen.dart';
import 'package:nekoflow/screens/main/settings/theme_screen_v2.dart';
import 'package:nekoflow/screens/main/stream/stream_screen.dart';
import 'package:nekoflow/screens/main/watchlist/view_all_screen.dart';
import 'package:nekoflow/screens/main/watchlist/watchlist_screen.dart';
import 'package:nekoflow/screens/onboarding/onboarding_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppRouterScreen(
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/browse',
            builder: (context, state) => const BrowseScreen(),
          ),
          GoRoute(
            path: '/watchlist',
            builder: (context, state) => const WatchlistScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            const CupertinoPage(child: SettingsScreen()),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          String? searchType = state.uri.queryParameters['type'];
          SearchModel? searchModel = state.extra as SearchModel?;
          if (searchType != null || searchModel != null) {
            return SearchResultScreen(
              searchModel: searchModel!,
              searchType: searchType!,
            );
          }
          return const BrowseScreen();
        },
      ),
      GoRoute(
        path: '/details',
        pageBuilder: (context, state) {
          String? animeId = state.uri.queryParameters['id'];
          String? image = state.uri.queryParameters['image'];
          String? name = state.uri.queryParameters['name'];
          String? type = state.uri.queryParameters['type'];
          String? tag = state.uri.queryParameters['tag'];
          return CupertinoPage(
            child: DetailsScreen(
              key: ValueKey(animeId),
              id: animeId!,
              image: image!,
              name: name!,
              type: type,
              tag: tag,
            ),
          );
        },
      ),
      GoRoute(
        path: '/settings/:screen',
        pageBuilder: (context, state) {
          final String? title = state.pathParameters['screen'];
          switch (title) {
            case 'About':
              return CupertinoPage(
                  child: AboutScreen(
                title: title!,
              ));
            case 'Theme':
              return CupertinoPage(
                  child: ThemeScreenV2(
                title: title!,
              ));
            default:
              return CupertinoPage(child: SettingsScreen());
          }
        },
      ),
      GoRoute(
        path: '/watchlist/:category',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extras =
              state.extra as Map<String, dynamic>?;
          final String? category = state.pathParameters['category'];
          final WatchlistBox box = extras?['box'] as WatchlistBox;
          final List<BaseAnimeCard> items =
              extras?['items'] as List<BaseAnimeCard>;
          return CupertinoPage(
            child: ViewAllScreen(
              title: category!,
              items: items,
              watchlistBox: box,
            ),
          );
        },
      ),
      GoRoute(
        path: '/stream',
        pageBuilder: (context, state) {
          final Map<String, dynamic>? extras =
              state.extra as Map<String, dynamic>?;
          final List<Episode> episodes = extras?['episodes'] as List<Episode>;
          final Episode episode = extras?['episode'] as Episode;
          final AnimeItem anime = extras?['anime'] as AnimeItem;
          return CupertinoPage(
            child: StreamScreen(
              anime: anime,
              episodes: episodes,
              episode: episode,
            ),
          );
        },
      ),
    ],
  );
}

class AppRouterScreen extends StatefulWidget {
  final Widget child;
  const AppRouterScreen({super.key, required this.child});

  @override
  State<AppRouterScreen> createState() => _AppRouterScreenState();
}

class _AppRouterScreenState extends State<AppRouterScreen> {
  static const List<String> _routes = ['/home', '/browse', '/watchlist'];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // Listen to GoRouter location changes to update the navigation bar
    GoRouter.of(context).routeInformationProvider.addListener(() {
      final location = GoRouter.of(context).state!.path!;
      setState(() {
        _selectedIndex =
            _routes.indexWhere((route) => location.startsWith(route));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: CrystalNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (_selectedIndex != index) {
            context.go(_routes[index]);
          }
        },
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        enableFloatingNavBar: true,
        marginR: const EdgeInsets.symmetric(horizontal: 120, vertical: 16),
        splashBorderRadius: 24,
        borderRadius: 50,
        enablePaddingAnimation: true,
        items: [
          CrystalNavigationBarItem(
            icon: HugeIcons.strokeRoundedHome01,
            unselectedIcon: HugeIcons.strokeRoundedHome02,
          ),
          CrystalNavigationBarItem(
            icon: HugeIcons.strokeRoundedGlobalSearch,
            unselectedIcon: HugeIcons.strokeRoundedGlobal,
          ),
          CrystalNavigationBarItem(
            icon: HugeIcons.strokeRoundedCollectionsBookmark,
            unselectedIcon: HugeIcons.strokeRoundedAllBookmark,
          ),
        ],
      ),
    );
  }
}
