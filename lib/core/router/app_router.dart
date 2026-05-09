import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/router/complex_extra_codec.dart';
import 'package:shonenx/core/router/scaffold_with_nav_bar.dart';
import 'package:shonenx/features/discovery/presentation/details_screen.dart';
import 'package:shonenx/features/discovery/presentation/home_screen.dart';
import 'package:shonenx/features/discovery/presentation/search_screen.dart';
import 'package:shonenx/features/downloads/presentation/downloads_screen.dart';
import 'package:shonenx/features/extensions/presentation/extensions_settings_screen.dart';
import 'package:shonenx/features/library/presentation/library_screen.dart';
import 'package:shonenx/features/player/presentation/player_screen.dart';
import 'package:shonenx/features/settings/presentation/cache_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/download_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/home_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/player_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/settings_screen.dart';
import 'package:shonenx/features/settings/presentation/theme_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/tracking_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/ui_settings_screen.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _libraryNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'library');
final _searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: true,
    extraCodec: const ComplexExtraCodec(),
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri.toString()}')),
    ),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _searchNavigatorKey,
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _libraryNavigatorKey,
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/details/:mediaType',
        builder: (context, state) {
          final mediaType = MediaType.values.firstWhere(
            (e) => e.id == state.pathParameters['mediaType'],
          );
          final tag = state.uri.queryParameters['tag'];
          final media = state.extra as UnifiedMedia;

          return DetailsScreen(
            media: media,
            mediaType: mediaType,
            tag: tag ?? 'details',
          );
        },
      ),
      // GoRoute(
      //     path: AppRoutes.sourceSettings,
      //     builder: (context, state) => const SourceSettingsScreen(),
      //   ),
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final params = state.extra as PlayerParams;
          final source = ref.read(animeSourceProvider(params.sourceInfo));

          return PlayerScreen(params: params, source: source);
        },
      ),
      GoRoute(
        path: '/downloads',
        builder: (context, state) => const DownloadsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'downloads',
            builder: (context, state) => const DownloadSettingsScreen(),
          ),
          GoRoute(
            path: 'tracking',
            builder: (context, state) => const TrackingSettingsScreen(),
          ),
          GoRoute(
            path: 'extensions',
            builder: (context, state) => const ExtensionsSettingsScreen(),
          ),
          GoRoute(
            path: 'theme',
            builder: (context, state) => const ThemeSettingsScreen(),
          ),
          GoRoute(
            path: 'home',
            builder: (context, state) => const HomeSettingsScreen(),
          ),
          GoRoute(
            path: 'player',
            builder: (context, state) => const PlayerSettingsScreen(),
          ),
          GoRoute(
            path: 'cache',
            builder: (context, state) => const CacheSettingsScreen(),
          ),
          GoRoute(
            path: 'ui',
            builder: (context, state) => const UiSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
