import 'dart:io';
import 'dart:ui';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/app_init.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/remote_config/ui/remote_config_listener.dart';
import 'package:shonenx/core/theme/app_theme.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/discord/providers/discord_rpc_provider.dart';
import 'package:shonenx/shared/widgets/global_background.dart';

final _log = AppLogger.scope('Main');
final _riverpodLog = AppLogger.scope('RiverpodObserver');

WebViewEnvironment? webViewEnvironment;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    try {
      final availableVersion = await WebViewEnvironment.getAvailableVersion();
      if (availableVersion != null) {
        final document = await getApplicationDocumentsDirectory();
        webViewEnvironment = await WebViewEnvironment.create(
          settings: WebViewEnvironmentSettings(
            userDataFolder: p.join(document.path, 'flutter_inappwebview'),
          ),
        );
      }
    } catch (e) {
      _log.e('Failed to initialize WebViewEnvironment: $e');
    }
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    if (!await FlutterSingleInstance().isFirstInstance()) {
      await FlutterSingleInstance().focus();
      exit(0);
    }
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _log.e(
      'FlutterError: ${details.exception}',
      details.exception,
      details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _log.e('PlatformDispatcherError: $error', error, stack);
    return true;
  };

  final log = _log.child('main');
  try {
    await AppLogger.init();

    log.i('App starting');
    log.i('Args: $args');

    final (init, sharedPreference) = await (
      AppInit().init(),
      SharedPreferences.getInstance(),
    ).wait;
    log.i('AppInit and SharedPreferences ready');

    Uri? startupUri;

    for (final arg in args) {
      final uri = Uri.tryParse(arg);
      if (uri != null && uri.scheme.isNotEmpty) {
        startupUri = uri;
        break;
      }
    }

    runApp(
      ProviderScope(
        observers: [RiverpodLogger()],
        overrides: [
          startupUriProvider.overrideWithValue(startupUri),
          databaseProvider.overrideWith((ref) => init.isar),
          sharedPreferencesProvider.overrideWith((ref) => sharedPreference),
        ],
        child: const ShonenXApp(),
      ),
    );
  } catch (e, st) {
    _log.e(e.toString(), e, st);

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF8B0000),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Initialization Failed:\n\n$e\n\n$st',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShonenXApp extends ConsumerWidget {
  const ShonenXApp({super.key});

  static final _log = AppLogger.scope(ShonenXApp);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = _log.child('build');

    // Eagerly initialize Discord RPC at app startup / hot restart
    ref.listen(discordRpcProvider, (_, __) {});

    final themePrefs = ref.watch(themePrefsProvider);
    log.d('Theme changed: ${themePrefs.themeMode}');

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightTheme = AppTheme.light(
          themePrefs,
          themePrefs.useDynamic ? lightDynamic : null,
        );
        final darkTheme = AppTheme.dark(
          themePrefs,
          themePrefs.useDynamic ? darkDynamic : null,
        );

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'ShonenX',
          themeMode: themePrefs.themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
              PointerDeviceKind.unknown,
            },
          ),
          routerConfig: ref.watch(routerProvider),
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();

            GlobalUI.uiScaleFactor = themePrefs.uiScaleFactor;
            GlobalUI.uiRoundness = themePrefs.uiRoundness;

            final textScaledChild = MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(themePrefs.fontScaleFactor),
              ),
              child: child,
            );

            return RemoteConfigListener(
              child: GlobalBackground(child: textScaledChild),
            );
          },
        );
      },
    );
  }
}

final class RiverpodLogger extends ProviderObserver {
  static final _log = _riverpodLog;

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    final providerName = context.provider.name ?? 'UnknownProvider';

    if (providerName != 'debug') return;

    final log = _log.child(providerName);

    log.section('State Update');
    log.i('Previous: $previousValue');
    log.i('New: $newValue');
  }
}
