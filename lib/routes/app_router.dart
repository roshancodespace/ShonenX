import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

// Import statements consolidated and organized by feature
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
  // Constants moved to class level
  static const _routes = ['/home', '/browse', '/watchlist'];

  // Router configuration
  static final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      _buildOnboardingRoute(),
      _buildMainNavigationRoute(),
      _buildSettingsRoute(),
      _buildSearchRoute(),
      _buildDetailsRoute(),
      _buildSettingsSubRoute(),
      _buildWatchlistCategoryRoute(),
      _buildStreamRoute(),
    ],
  );

  // Route builders
  static GoRoute _buildOnboardingRoute() => GoRoute(
        path: '/',
        builder: (_, __) => const OnboardingScreen(),
      );

  static StatefulShellRoute _buildMainNavigationRoute() =>
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppRouterScreen(
          child: navigationShell,
        ),
        branches: [
          _buildBranch('/home', const HomeScreen()),
          _buildBranch('/browse', const BrowseScreen()),
          _buildBranch('/watchlist', const WatchlistScreen()),
        ],
      );

  static StatefulShellBranch _buildBranch(String path, Widget screen) =>
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: path,
            builder: (_, __) => screen,
          ),
        ],
      );

  static GoRoute _buildSettingsRoute() => GoRoute(
        path: '/settings',
        pageBuilder: (_, __) => const CupertinoPage(child: SettingsScreen()),
      );

  static GoRoute _buildSearchRoute() => GoRoute(
        path: '/search',
        builder: (_, state) {
          final searchType = state.uri.queryParameters['type'];
          final searchModel = state.extra as SearchModel?;

          if (searchType != null && searchModel != null) {
            return SearchResultScreen(
              searchModel: searchModel,
              searchType: searchType,
            );
          }
          return const BrowseScreen();
        },
      );

  static GoRoute _buildDetailsRoute() => GoRoute(
        path: '/details',
        pageBuilder: (_, state) {
          final params = state.uri.queryParameters;
          return CupertinoPage(
            child: DetailsScreen(
              key: ValueKey(params['id']),
              id: params['id']!,
              image: params['image']!,
              name: params['name']!,
              type: params['type'],
              tag: params['tag'],
            ),
          );
        },
      );

  static GoRoute _buildSettingsSubRoute() => GoRoute(
        path: '/settings/:screen',
        pageBuilder: (_, state) {
          final title = state.pathParameters['screen'];
          return CupertinoPage(
            child: switch (title) {
              'About' => AboutScreen(title: title!),
              'Theme' => ThemeScreenV2(title: title!),
              _ => const SettingsScreen(),
            },
          );
        },
      );

  static GoRoute _buildWatchlistCategoryRoute() => GoRoute(
        path: '/watchlist/:category',
        pageBuilder: (_, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return CupertinoPage(
            child: ViewAllScreen(
              title: state.pathParameters['category']!,
              items: extras?['items'] as List<BaseAnimeCard>,
              watchlistBox: extras?['box'] as WatchlistBox,
            ),
          );
        },
      );

  static GoRoute _buildStreamRoute() => GoRoute(
        path: '/stream',
        pageBuilder: (_, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return CupertinoPage(
            child: StreamScreen(
              anime: extras?['anime'] as AnimeItem,
              episodes: extras?['episodes'] as List<Episode>,
              episode: extras?['episode'] as Episode,
            ),
          );
        },
      );
}

class AppRouterScreen extends StatefulWidget {
  final Widget child;

  const AppRouterScreen({super.key, required this.child});

  @override
  State<AppRouterScreen> createState() => _AppRouterScreenState();
}

class _AppRouterScreenState extends State<AppRouterScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeSelectedIndex();
  }

  void _initializeSelectedIndex() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final location = GoRouter.of(context).state!.path!;
      final index =
          AppRouter._routes.indexWhere((route) => location.startsWith(route));

      if (index != -1) {
        setState(() => _selectedIndex = index);
      }
    });
  }

  void _onNavBarTap(int index) {
    if (_selectedIndex != index) {
      context.go(AppRouter._routes[index]);
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: _buildNavigationBar(theme),
    );
  }

  Widget _buildNavigationBar(ThemeData theme) => Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavItem(
                        icon: HugeIcons.strokeRoundedHome02,
                        activeIcon: HugeIcons.strokeRoundedHome01,
                        isSelected: _selectedIndex == 0,
                        onTap: () => _onNavBarTap(0),
                        theme: theme,
                      ),
                      _buildNavItem(
                        icon: HugeIcons.strokeRoundedGlobal,
                        activeIcon: HugeIcons.strokeRoundedGlobalSearch,
                        isSelected: _selectedIndex == 1,
                        onTap: () => _onNavBarTap(1),
                        theme: theme,
                      ),
                      _buildNavItem(
                        icon: HugeIcons.strokeRoundedAllBookmark,
                        activeIcon: HugeIcons.strokeRoundedCollectionsBookmark,
                        isSelected: _selectedIndex == 2,
                        onTap: () => _onNavBarTap(2),
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) =>
      IconButton(
        onPressed: onTap,
        icon: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
}
