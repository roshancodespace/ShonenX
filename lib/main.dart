import 'dart:ui';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:shonenx/shared/widgets/global_background.dart';

final _log = AppLogger.scope('Main');
final _riverpodLog = AppLogger.scope('RiverpodObserver');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();

  final log = _log.child('main');

  log.i('App starting');

  final init = await AppInit().init();
  log.i('AppInit completed');

  final sharedPreference = await SharedPreferences.getInstance();
  log.i('SharedPreferences ready');

  runApp(
    ProviderScope(
      observers: [RiverpodLogger()],
      overrides: [
        databaseProvider.overrideWith((ref) => init.isar),
        sharedPreferencesProvider.overrideWith((ref) => sharedPreference),
      ],
      child: const ShonenXApp(),
    ),
  );
}

class ShonenXApp extends ConsumerWidget {
  const ShonenXApp({super.key});

  static final _log = AppLogger.scope(ShonenXApp);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = _log.child('build');

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

    if (providerName != 'episodeTabProvider') return;

    final log = _log.child(providerName);

    log.section('State Update');
    log.i('Previous: $previousValue');
    log.i('New: $newValue');
  }
}
