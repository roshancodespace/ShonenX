import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core_new/models/source.dart';
import 'package:shonenx/features/anime/view/watch_screen.dart';
import 'package:shonenx/features/browse/view/browse_screen.dart';
import 'package:shonenx/features/details/view/details_screen.dart';
import 'package:shonenx/features/error/view/error_screen.dart';
import 'package:shonenx/features/settings/view/about_screen.dart';
import 'package:shonenx/features/settings/view/account_settings_screen.dart';
import 'package:shonenx/features/settings/view/anime_sources_settings_screen.dart';
import 'package:shonenx/features/settings/view/experimental_screen.dart';
import 'package:shonenx/features/settings/view/extension_preference_screen.dart';
import 'package:shonenx/features/settings/view/extensions_list_screen.dart';
import 'package:shonenx/features/settings/view/player_settings_screen.dart';
import 'package:shonenx/features/settings/view/settings_screen.dart';
import 'package:shonenx/features/settings/view/subtitle_customization_screen.dart';
import 'package:shonenx/features/settings/view/temporary/demo_screen.dart';
import 'package:shonenx/features/settings/view/theme_settings_screen.dart';
import 'package:shonenx/features/settings/view/ui_settings_screen.dart';
import 'package:shonenx/router/router.dart';
import 'package:shonenx/features/onboarding/view/onboarding_screen.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/features/home/view/watch_history_screen.dart';

final routerConfig = GoRouter(
  errorBuilder: (context, state) => ErrorScreen(error: state.error),
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppRouterScreen(navigationShell: navigationShell),
      branches: navItems.asMap().entries.map((entry) {
        final item = entry.value;
        return StatefulShellBranch(
          routes: [
            GoRoute(
              path: item.path,
              builder: (context, state) {
                if (item.path == '/browse') {
                  return BrowseScreen(
                    key: ValueKey(state.uri.toString()),
                    keyword: state.uri.queryParameters['keyword'],
                  );
                }
                return item.screen;
              },
            ),
          ],
        );
      }).toList(),
    ),

    // Standalone routes
    _buildSettingsRoute(),
    GoRoute(
      path: '/details',
      builder: (context, state) => AnimeDetailsScreen(
        anime: state.extra as Media,
        tag: state.uri.queryParameters['tag'] ?? '',
        forceFetch: state.uri.queryParameters['forceFetch'] == 'true',
      ),
    ),
    GoRoute(
      path: '/watch/:id',
      builder: (context, state) => WatchScreen(
        mediaId: state.pathParameters['id']!,
        animeId: state.uri.queryParameters['animeId'],
        animeName: state.uri.queryParameters['animeName']!,
        animeFormat: state.uri.queryParameters['animeFormat']!,
        animeCover: state.uri.queryParameters['animeCover']!,
        episode: int.tryParse(state.uri.queryParameters['episode'] ?? '1') ?? 1,
        startAt: Duration(
          seconds:
              int.tryParse(state.uri.queryParameters['startAt'] ?? '0') ?? 0,
        ),
        episodes: state.extra as List<EpisodeDataModel>,
      ),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
  ],
  redirect: (context, state) {
    final box = Hive.box('onboard');
    final isOnboarded = box.get('is_onboarded', defaultValue: false);
    final isGoingToOnboarding = state.matchedLocation == '/onboarding';

    if (!isOnboarded && !isGoingToOnboarding) {
      return '/onboarding';
    }

    if (isOnboarded && isGoingToOnboarding) {
      return '/';
    }

    return null;
  },
);

GoRoute _buildSettingsRoute() {
  return GoRoute(
    path: '/settings',
    builder: (context, state) => const SettingsScreen(),
    routes: [
      GoRoute(
        path: 'account',
        builder: (context, state) => const AccountSettingsScreen(),
        routes: [],
      ),
      GoRoute(
        path: 'anime-sources',
        builder: (context, state) => const AnimeSourcesSettingsScreen(),
      ),
      GoRoute(
        path: 'theme',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: 'ui',
        builder: (context, state) => const UiSettingsScreen(),
      ),
      GoRoute(
        path: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
          path: 'player',
          builder: (context, state) => const PlayerSettingsScreen(),
          routes: [
            GoRoute(
              path: 'subtitles',
              builder: (context, state) => const SubtitleCustomizationScreen(),
            ),
          ]),
      GoRoute(
        path: 'extensions',
        builder: (context, state) => const ExtensionsListScreen(),
        routes: [
          GoRoute(
            path: 'demo',
            builder: (context, state) => const DemoScreen(),
          ),
          GoRoute(
            path: 'extension-preference',
            builder: (context, state) {
              final source = state.extra as Source;
              return ExtensionPreferenceScreen(
                source: source,
              );
            },
          )
        ],
      ),
      GoRoute(
        path: 'experimental',
        builder: (context, state) => ExperimentalScreen(),
      ),
      GoRoute(
        path: 'watch-history',
        builder: (context, state) => const WatchHistoryScreen(),
      ),
    ],
  );
}
