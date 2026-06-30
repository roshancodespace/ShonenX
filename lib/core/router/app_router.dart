import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/app_init.dart';
import 'package:shonenx/core/router/complex_extra_codec.dart';
import 'package:shonenx/core/router/scaffold_with_nav_bar.dart';
import 'package:shonenx/features/discovery/presentation/details_screen.dart';
import 'package:shonenx/features/onboarding/presentation/onboarding_screen.dart';
import 'package:shonenx/features/discovery/presentation/home_screen.dart';
import 'package:shonenx/features/splash/presentation/splash_screen.dart';
import 'package:shonenx/features/discovery/presentation/discover_screen.dart';
import 'package:shonenx/features/downloads/presentation/downloads_screen.dart';
import 'package:shonenx/features/extensions/presentation/extensions_settings_screen.dart';
import 'package:shonenx/features/extensions/presentation/extension_tester_screen.dart';
import 'package:shonenx/core/remote_config/ui/remote_config_editor_screen.dart';
import 'package:shonenx/features/history/presentation/continue_history_screen.dart';
import 'package:shonenx/features/library/presentation/library_screen.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/player/presentation/player_screen.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/reader/presentation/reader_screen.dart';
import 'package:shonenx/features/settings/presentation/cache_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/download_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/home_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/permissions_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/player_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/settings_screen.dart';
import 'package:shonenx/features/settings/presentation/reader_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/theme_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/tracking_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/ui_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/backup_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/import_preview_screen.dart';
import 'package:shonenx/features/settings/presentation/debug_settings_screen.dart';
import "package:shonenx/features/notifications/presentation/notifications_settings_screen.dart";
import 'package:shonenx/features/settings/presentation/content_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/logs_screen.dart';
import 'package:shonenx/features/settings/presentation/about_screen.dart';
import 'package:shonenx/features/settings/presentation/update_settings_screen.dart';
import 'package:shonenx/features/settings/presentation/troubleshoot_settings_screen.dart';
import 'package:shonenx/core/services/backup_service.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/core/network/cf_client.dart';


final rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _libraryNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'library');
final _searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search');

final routerProvider = Provider<GoRouter>((ref) {
  CFClient.navigatorKey = rootNavigatorKey;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    extraCodec: const ComplexExtraCodec(),
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri.toString()}')),
    ),
    redirect: (context, state) {
      final uri = state.uri;
      if (((uri.scheme == 'aniyomi' ||
                  uri.scheme == 'tachiyomi' ||
                  uri.scheme == 'mangayomi') &&
              uri.host == 'add-repo') ||
          uri.path.contains('add-repo')) {
        final url = uri.queryParameters['url'];
        final isAnime = uri.scheme == 'aniyomi';
        final target = (url != null)
            ? '/settings/extensions?autoAddUrl=${Uri.encodeComponent(url)}&autoAddType=${isAnime ? "anime" : "manga"}'
            : '/settings/extensions';

        if (!AppInit.isBridgeInitialized) {
          AppInit.pendingDeepLink = target;
          return '/splash';
        }
        return target;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
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
                path: '/discover',
                builder: (context, state) {
                  final query = state.uri.queryParameters['query'];
                  final source = state.uri.queryParameters['source'];
                  final type = MediaType.values.firstWhere(
                    (e) => e.id == state.uri.queryParameters['type'],
                    orElse: () => MediaType.ANIME,
                  );
                  final genres = state.uri.queryParametersAll['genres'] ?? [];
                  final tags = state.uri.queryParametersAll['tags'] ?? [];

                  return DiscoverScreen(
                    query: query,
                    category: state.uri.queryParameters['category'],
                    type: type,
                    genres: genres,
                    tags: tags,
                    source: source,
                  );
                },
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
          final mode = state.extra as PlayerMode;
          return PlayerScreen(mode: mode);
        },
      ),
      GoRoute(
        path: '/reader',
        builder: (context, state) {
          final mode = state.extra as ReaderModeOnline;
          return ReaderScreen(mode: mode);
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
            path: 'permissions',
            builder: (context, state) => const PermissionsSettingsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsSettingsScreen(),
          ),
          GoRoute(
            path: 'tracking',
            builder: (context, state) => const TrackingSettingsScreen(),
          ),
          GoRoute(
            path: 'extensions',
            builder: (context, state) {
              final autoAddUrl = state.uri.queryParameters['autoAddUrl'];
              final autoAddType = state.uri.queryParameters['autoAddType'];
              return ExtensionsSettingsScreen(
                autoAddUrl: autoAddUrl,
                autoAddType: autoAddType,
              );
            },
            routes: [
              GoRoute(
                path: 'test',
                builder: (context, state) => const ExtensionTesterScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'remote_config_editor',
            builder: (context, state) => const RemoteConfigEditorScreen(),
          ),
          GoRoute(
            path: 'content',
            builder: (context, state) => const ContentSettingsScreen(),
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
            path: 'reader',
            builder: (context, state) => const ReaderSettingsScreen(),
          ),
          GoRoute(
            path: 'cache',
            builder: (context, state) => const CacheSettingsScreen(),
          ),
          GoRoute(
            path: 'ui',
            builder: (context, state) => const UiSettingsScreen(),
          ),
          GoRoute(
            path: 'backup',
            builder: (context, state) => const BackupSettingsScreen(),
            routes: [
              GoRoute(
                path: 'preview',
                builder: (context, state) {
                  final manifest = state.extra as BackupManifest;
                  return ImportPreviewScreen(manifest: manifest);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'troubleshoot',
            builder: (context, state) => const TroubleshootSettingsScreen(),
          ),
          GoRoute(
            path: 'debug',
            builder: (context, state) => const DebugSettingsScreen(),
          ),
          GoRoute(
            path: 'logs',
            builder: (context, state) => const LogsScreen(),
          ),
          GoRoute(
            path: 'updates',
            builder: (context, state) => const UpdateSettingsScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/category/:name',
        builder: (context, state) {
          final category = state.pathParameters['name'];
          final type = MediaType.values.firstWhere(
            (e) => e.id == state.uri.queryParameters['type'],
            orElse: () => MediaType.ANIME,
          );

          return DiscoverScreen(type: type, category: category);
        },
      ),
      GoRoute(
        path: '/continue/:mediaType',
        builder: (context, state) {
          final mediaType = MediaType.values.firstWhere(
            (e) => e.id == state.pathParameters['mediaType'],
            orElse: () => MediaType.ANIME,
          );
          return ContinueHistoryScreen(type: mediaType);
        },
        routes: [
          GoRoute(
            path: ':mediaId',
            builder: (context, state) {
              final mediaType = MediaType.values.firstWhere(
                (e) => e.id == state.pathParameters['mediaType'],
                orElse: () => MediaType.ANIME,
              );
              final mediaId = state.pathParameters['mediaId']!;
              return ContinueHistoryItemsScreen(
                type: mediaType,
                mediaId: mediaId,
              );
            },
          ),
        ],
      ),
    ],
  );
});
