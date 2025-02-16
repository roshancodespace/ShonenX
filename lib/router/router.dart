import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/screens/browse_screen.dart';
import 'package:shonenx/screens/details_screen.dart';
import 'package:shonenx/screens/error_screen.dart';
import 'package:shonenx/screens/home_screen.dart';
import 'package:shonenx/screens/see_all_screen.dart';
import 'package:shonenx/screens/settings/about/privacy_policy_screen.dart';
import 'package:shonenx/screens/settings/about/terms_screen.dart';
import 'package:shonenx/screens/settings/settings_screen.dart';
import 'package:shonenx/screens/settings/about/about_screen.dart';
import 'package:shonenx/screens/settings/appearance/appearance_screen.dart';
import 'package:shonenx/screens/settings/about/help_support_screen.dart';
import 'package:shonenx/screens/settings/profile/profile_screen.dart';
import 'package:shonenx/screens/settings/source/provider_screen.dart';
import 'package:shonenx/screens/settings/profile/sync_screen.dart';
import 'package:shonenx/screens/settings/player/player_screen.dart';
import 'package:shonenx/screens/watch_screen.dart';
import 'package:shonenx/screens/watchlist_screen.dart';

final GoRouter router = GoRouter(
  errorBuilder: (context, state) => ErrorScreen(error: state.error),
  initialLocation: '/',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppRouterScreen(navigationShell: navigationShell),
      branches: [
        _buildHomeBranch(),
        _buildBrowseBranch(),
        _buildWatchlistBranch(),
      ],
    ),
    _buildSettingsRoute(),
    _buildSeeAllRoute(),
    _buildDetailsRoute(),
    _buildWatchRoute(),
    _buildCatchAllRoute(),
  ],
);

StatefulShellBranch _buildHomeBranch() {
  return StatefulShellBranch(routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => const MaterialPage(child: HomeScreen()),
    ),
  ]);
}

StatefulShellBranch _buildBrowseBranch() {
  return StatefulShellBranch(routes: [
    GoRoute(
      path: '/browse',
      pageBuilder: (context, state) => MaterialPage(
        child: BrowseScreen(
          key: ValueKey(state.uri.toString()),
          keyword: state.uri.queryParameters['keyword'],
        ),
      ),
    ),
  ]);
}

StatefulShellBranch _buildWatchlistBranch() {
  return StatefulShellBranch(routes: [
    GoRoute(
      path: '/watchlist',
      pageBuilder: (context, state) =>
          const MaterialPage(child: WatchlistScreen()),
    ),
  ]);
}

GoRoute _buildSettingsRoute() {
  return GoRoute(
    path: '/settings',
    pageBuilder: (context, state) =>
        const MaterialPage(child: SettingsScreen()),
    routes: [
      _buildProfileSettingsRoute(),
      _buildProviderSettingsRoute(),
      _buildAppearanceSettingsRoute(),
      _buildAboutSettingsRoute(),
      _buildPlayerSettingsRoute(),
      _buildSupportSettingsRoute(),
    ],
  );
}

GoRoute _buildProfileSettingsRoute() {
  return GoRoute(
    path: 'profile',
    pageBuilder: (context, state) =>
        const MaterialPage(child: ProfileSettingsScreen()),
    routes: [
      GoRoute(
        path: 'sync',
        pageBuilder: (context, state) =>
            const MaterialPage(child: SyncSettingsScreen()),
      ),
    ],
  );
}

GoRoute _buildProviderSettingsRoute() {
  return GoRoute(
    path: 'providers',
    pageBuilder: (context, state) =>
        const MaterialPage(child: ProviderSettingsScreen()),
  );
}

GoRoute _buildAppearanceSettingsRoute() {
  return GoRoute(
    path: 'appearance',
    pageBuilder: (context, state) =>
        const MaterialPage(child: AppearanceSettingsScreen()),
  );
}

GoRoute _buildAboutSettingsRoute() {
  return GoRoute(
    path: 'about',
    pageBuilder: (context, state) => const MaterialPage(child: AboutScreen()),
    routes: [
      GoRoute(
        path: 'terms',
        pageBuilder: (context, state) =>
            const MaterialPage(child: TermsOfServiceScreen()),
      ),
      GoRoute(
        path: 'privacy',
        pageBuilder: (context, state) =>
            const MaterialPage(child: PrivacyPolicyScreen()),
      ),
    ],
  );
}

GoRoute _buildPlayerSettingsRoute() {
  return GoRoute(
    path: 'player',
    pageBuilder: (context, state) =>
        const MaterialPage(child: PlayerSettingsScreen()),
  );
}

GoRoute _buildSupportSettingsRoute() {
  return GoRoute(
    path: 'support',
    pageBuilder: (context, state) =>
        const MaterialPage(child: HelpSupportScreen()),
  );
}

GoRoute _buildSeeAllRoute() {
  return GoRoute(
    path: '/all/:path',
    pageBuilder: (context, state) => MaterialPage(
      child: SeeAllScreen(
        title: state.uri.queryParameters['title'] ?? 'Untitled',
        path: state.pathParameters['path'] ?? '',
      ),
    ),
  );
}

GoRoute _buildDetailsRoute() {
  return GoRoute(
    path: '/details',
    pageBuilder: (context, state) => MaterialPage(
      child: AnimeDetailsScreen(
        anime: state.extra as Media,
        tag: state.uri.queryParameters['tag'] ?? '',
      ),
    ),
  );
}

GoRoute _buildWatchRoute() {
  return GoRoute(
    path: '/watch/:id',
    pageBuilder: (context, state) {
      return MaterialPage(
        child: PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            showExitConfirmationDialog(context);
          },
          child: WatchScreen(
            animeId: state.pathParameters['id']!,
            animeName: state.uri.queryParameters['animeName']!,
          ),
        ),
      );
    },
  );
}

GoRoute _buildCatchAllRoute() {
  return GoRoute(
    path: '*',
    pageBuilder: (context, state) => MaterialPage(
      child: ErrorScreen(error: Exception('Page not found')),
    ),
  );
}

class AppRouterScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppRouterScreen({super.key, required this.navigationShell});

  @override
  State<AppRouterScreen> createState() => _AppRouterScreenState();
}

class _AppRouterScreenState extends State<AppRouterScreen> {
  DateTime? lastPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        showExitConfirmationDialog(context, isSystemExit: true);
      }, // Handle back button behavior
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: isWideScreen ? 90 : 0,
                bottom: isWideScreen ? 15 : 0,
                top: isWideScreen ? 15 : 0,
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: widget.navigationShell),
            ),
            Positioned(
              left: isWideScreen ? 10 : 0,
              right: isWideScreen ? null : 0,
              top: isWideScreen ? 20 : null,
              bottom: 10,
              child: SafeArea(
                child: isWideScreen
                    ? _buildFloatingSideNav(theme)
                    : _buildCrystalBottomNav(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSideNav(ThemeData theme) {
    return Container(
      width: 75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          final isSelected = widget.navigationShell.currentIndex == index;
          final borderRadius = BorderRadius.only(
            topLeft: index == 0 ? Radius.circular(100) : Radius.zero,
            topRight: index == 0 ? Radius.circular(100) : Radius.zero,
            bottomLeft: index == 2 ? Radius.circular(100) : Radius.zero,
            bottomRight: index == 2 ? Radius.circular(100) : Radius.zero,
          );

          return Expanded(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: InkWell(
                onTap: () => widget.navigationShell.goBranch(index),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  margin: const EdgeInsets.all(5),
                  child: Center(
                    child: Icon(
                      _getIconForIndex(index),
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCrystalBottomNav(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width * 0.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                )),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final isSelected = widget.navigationShell.currentIndex == index;
                return Expanded(
                  child: InkWell(
                    onTap: () => widget.navigationShell.goBranch(index),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: index == 0
                              ? Radius.circular(100)
                              : Radius.circular(5),
                          topRight: index == 2
                              ? Radius.circular(100)
                              : Radius.circular(5),
                          bottomLeft: index == 0
                              ? Radius.circular(100)
                              : Radius.circular(5),
                          bottomRight: index == 2
                              ? Radius.circular(100)
                              : Radius.circular(5),
                        ),
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Icon(
                          _getIconForIndex(index),
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Iconsax.home;
      case 1:
        return Iconsax.discover_1;
      case 2:
        return Iconsax.bookmark;
      // case 3:
      //   return Iconsax.setting;
      default:
        return Iconsax.home;
    }
  }
}

void showExitConfirmationDialog(BuildContext context, {bool isSystemExit = false}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Confirm Exit"),
        content: const Text("Are you sure you want to exit the app?"),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              // Exit the app
              if (isSystemExit) {
                SystemNavigator.pop();
              } else {
                context.pop();
              }
            },
            child: const Text("Exit"),
          ),
        ],
      );
    },
  );
}
