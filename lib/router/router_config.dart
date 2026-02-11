import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/extensions/view/extension_preference_screen.dart';
import 'package:shonenx/main.dart';

// Core & Models
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';

// Features
import 'package:shonenx/features/anime/view/watch_screen.dart';
import 'package:shonenx/features/browse/view/browse_screen.dart';
import 'package:shonenx/features/browse/model/search_filter.dart';
import 'package:shonenx/features/details/view/details_screen.dart';
import 'package:shonenx/features/error/view/error_screen.dart';
import 'package:shonenx/features/home/view/watch_history_screen.dart';
import 'package:shonenx/features/news/view/news_screen.dart';
import 'package:shonenx/features/onboarding/view/onboarding_screen.dart';
import 'package:shonenx/features/extensions/view/extensions_screen.dart';

// Settings Features
import 'package:shonenx/features/settings/view/screens/about_screen.dart';
import 'package:shonenx/features/settings/view/screens/account_settings_screen.dart';
import 'package:shonenx/features/settings/view/screens/anime_sources_settings_screen.dart';
import 'package:shonenx/features/settings/view/screens/download_settings_screen.dart';
import 'package:shonenx/features/settings/view/screens/experimental_screen.dart';
import 'package:shonenx/features/settings/view/screens/player_settings_screen.dart';
import 'package:shonenx/features/settings/view/screens/advanced_player_settings_screen.dart';
import 'package:shonenx/features/settings/view/screens/profile_settings_screen.dart';
import 'package:shonenx/features/settings/view/screens/settings_screen.dart';
import 'package:shonenx/features/settings/view/screens/subtitle_customization_screen.dart';
import 'package:shonenx/features/settings/view/screens/theme_settings_screen.dart';
import 'package:shonenx/features/settings/view/screens/ui_settings_screen.dart';
import 'package:shonenx/features/settings/view/screens/tracking_settings_screen.dart';
import 'package:shonenx/features/settings/view/screens/content_settings_screen.dart';
import 'package:shonenx/features/debug/view/debug_screen.dart';
import 'package:shonenx/router/router_wrapper.dart';

class AnimatedGoRoute extends GoRoute {
  AnimatedGoRoute({
    required super.path,
    required Widget Function(BuildContext, GoRouterState) contentBuilder,
    super.routes = const <RouteBase>[],
    super.redirect,
  }) : super(
         pageBuilder: (context, state) => CustomTransitionPage(
           key: state.pageKey,
           child: contentBuilder(context, state),
           transitionsBuilder: (context, animation, secondaryAnimation, child) {
             return SlideTransition(
               position: animation.drive(
                 Tween<Offset>(
                   begin: const Offset(0, 1),
                   end: Offset.zero,
                 ).chain(CurveTween(curve: Curves.easeOutCubic)),
               ),
               child: child,
             );
           },
         ),
       );
}

final routerConfig = GoRouter(
  errorBuilder: (context, state) => ErrorScreen(error: state.error),
  initialLocation: '/',
  redirect: (context, state) {
    final isOnboarded = sharedPrefs.getBool('is_onboarded') ?? false;
    final isGoingToOnboarding = state.matchedLocation == '/onboarding';
    if (!isOnboarded && !isGoingToOnboarding) return '/onboarding';
    if (isOnboarded && isGoingToOnboarding) return '/';
    return null;
  },
  routes: [
    StatefulShellRoute(
      navigatorContainerBuilder: (context, navigationShell, children) {
        return AppRouterScreen(
          navigationShell: navigationShell,
          children: children,
        );
      },
      builder: (context, state, navigationShell) {
        return navigationShell;
      },
      branches: navItems.map((item) {
        return StatefulShellBranch(
          routes: [
            AnimatedGoRoute(
              path: item.path,
              contentBuilder: (context, state) => item.path == '/browse'
                  ? BrowseScreen(
                      key: ValueKey(state.uri.toString()),
                      keyword: state.uri.queryParameters['keyword'],
                      initialFilter: state.extra as SearchFilter?,
                    )
                  : item.screen,
            ),
          ],
        );
      }).toList(),
    ),
    AnimatedGoRoute(
      path: '/extensions',
      contentBuilder: (_, _) => const ExtensionScreen(),
    ),
    AnimatedGoRoute(
      path: '/news',
      contentBuilder: (_, _) => const NewsScreen(),
    ),
    AnimatedGoRoute(
      path: '/onboarding',
      contentBuilder: (_, _) => const OnboardingScreen(),
    ),
    AnimatedGoRoute(
      path: '/details',
      contentBuilder: (context, state) => AnimeDetailsScreen(
        anime: state.extra as UniversalMedia,
        tag: state.uri.queryParameters['tag'] ?? '',
        forceFetch: state.uri.queryParameters['forceFetch'] == 'true',
      ),
    ),
    AnimatedGoRoute(
      path: '/watch/:id',
      contentBuilder: (context, state) => WatchScreen(
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
    AnimatedGoRoute(
      path: '/settings',
      contentBuilder: (_, __) => const SettingsScreen(),
      routes: [
        AnimatedGoRoute(
          path: 'debug',
          contentBuilder: (_, _) => const DebugScreen(),
        ),
        AnimatedGoRoute(
          path: 'account',
          contentBuilder: (_, _) => const AccountSettingsScreen(),
          routes: [
            AnimatedGoRoute(
              path: 'profile',
              contentBuilder: (_, _) => const ProfileSettingsScreen(),
            ),
          ],
        ),
        AnimatedGoRoute(
          path: 'anime-sources',
          contentBuilder: (_, _) => const AnimeSourcesSettingsScreen(),
        ),
        AnimatedGoRoute(
          path: 'downloads',
          contentBuilder: (_, _) => const DownloadSettingsScreen(),
        ),
        AnimatedGoRoute(
          path: 'theme',
          contentBuilder: (_, _) => const ThemeSettingsScreen(),
        ),
        AnimatedGoRoute(
          path: 'ui',
          contentBuilder: (_, _) => const UiSettingsScreen(),
        ),
        AnimatedGoRoute(
          path: 'content',
          contentBuilder: (_, _) => const ContentSettingsScreen(),
        ),
        AnimatedGoRoute(
          path: 'about',
          contentBuilder: (_, _) => const AboutScreen(),
        ),
        AnimatedGoRoute(
          path: 'watch-history',
          contentBuilder: (_, _) => const WatchHistoryScreen(),
        ),
        AnimatedGoRoute(
          path: 'tracking',
          contentBuilder: (_, _) => const TrackingSettingsScreen(),
        ),
        AnimatedGoRoute(
          path: 'player',
          contentBuilder: (_, _) => const PlayerSettingsScreen(),
          routes: [
            AnimatedGoRoute(
              path: 'subtitles',
              contentBuilder: (_, _) => const SubtitleCustomizationScreen(),
            ),
            AnimatedGoRoute(
              path: 'advanced',
              contentBuilder: (_, _) => const AdvancedPlayerSettingsScreen(),
            ),
          ],
        ),
        AnimatedGoRoute(
          path: 'extensions',
          contentBuilder: (_, _) => const ExtensionScreen(),
          routes: [
            AnimatedGoRoute(
              path: 'extension-preference',
              contentBuilder: (_, state) =>
                  ExtensionPreferenceScreen(source: state.extra as Source),
            ),
          ],
        ),
        AnimatedGoRoute(
          path: 'experimental',
          contentBuilder: (_, _) => ExperimentalScreen(),
        ),
      ],
    ),
  ],
);
