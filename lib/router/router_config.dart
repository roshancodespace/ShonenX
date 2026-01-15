import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

// Core & Models
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core_new/models/source.dart';

// Features
import 'package:shonenx/features/anime/view/watch_screen.dart';
import 'package:shonenx/features/browse/view/browse_screen.dart';
import 'package:shonenx/features/details/view/details_screen.dart';
import 'package:shonenx/features/error/view/error_screen.dart';
import 'package:shonenx/features/home/view/watch_history_screen.dart';
import 'package:shonenx/features/onboarding/view/onboarding_screen.dart';

// Settings Features
import 'package:shonenx/features/settings/view/about_screen.dart';
import 'package:shonenx/features/settings/view/account_settings_screen.dart';
import 'package:shonenx/features/settings/view/anime_sources_settings_screen.dart';
import 'package:shonenx/features/settings/view/download_settings_screen.dart';
import 'package:shonenx/features/settings/view/experimental_screen.dart';
import 'package:shonenx/features/settings/view/extension_preference_screen.dart';
import 'package:shonenx/features/settings/view/extensions_list_screen.dart';
import 'package:shonenx/features/settings/view/player_settings_screen.dart';
import 'package:shonenx/features/settings/view/profile_settings_screen.dart';
import 'package:shonenx/features/settings/view/settings_screen.dart';
import 'package:shonenx/features/settings/view/subtitle_customization_screen.dart';
import 'package:shonenx/features/settings/view/temporary/demo_screen.dart';
import 'package:shonenx/features/settings/view/theme_settings_screen.dart';
import 'package:shonenx/features/settings/view/ui_settings_screen.dart';
import 'package:shonenx/router/router.dart';

final routerConfig = GoRouter(
  errorBuilder: (context, state) => ErrorScreen(error: state.error),
  initialLocation: '/',
  redirect: (context, state) {
    final isOnboarded = Hive.box(
      'onboard',
    ).get('is_onboarded', defaultValue: false);
    final isGoingToOnboarding = state.matchedLocation == '/onboarding';

    if (!isOnboarded && !isGoingToOnboarding) return '/onboarding';
    if (isOnboarded && isGoingToOnboarding) return '/';
    return null;
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          AppRouterScreen(navigationShell: shell),
      branches: navItems.map((item) {
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
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/details',
      builder: (context, state) => AnimeDetailsScreen(
        anime: state.extra as UniversalMedia,
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
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'account',
          builder: (context, state) => const AccountSettingsScreen(),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (context, state) => const ProfileSettingsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: 'anime-sources',
          builder: (context, state) => const AnimeSourcesSettingsScreen(),
        ),
        GoRoute(
          path: 'downloads',
          builder: (context, state) => const DownloadSettingsScreen(),
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
          path: 'watch-history',
          builder: (context, state) => const WatchHistoryScreen(),
        ),
        GoRoute(
          path: 'player',
          builder: (context, state) => const PlayerSettingsScreen(),
          routes: [
            GoRoute(
              path: 'subtitles',
              builder: (context, state) => const SubtitleCustomizationScreen(),
            ),
          ],
        ),
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
              builder: (context, state) =>
                  ExtensionPreferenceScreen(source: state.extra as Source),
            ),
          ],
        ),
        GoRoute(
          path: 'experimental',
          builder: (context, state) => ExperimentalScreen(),
        ),
      ],
    ),
  ],
);
