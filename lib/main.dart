import 'dart:async';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/app_initializer.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/settings/view_model/theme_notifier.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/router/router_config.dart';
import 'package:shonenx/storage_provider.dart';

late Isar isar;
late SharedPreferencesWithCache sharedPrefs;
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    AppLogger.i('Starting app initialization');
    isar = await StorageProvider().initDB(null, inspector: kDebugMode);
    final bridge = DartotsuExtensionBridge();
    await bridge.init(isar, 'ShonenX');
    await AppInitializer.initialize();
  } catch (e) {
    AppLogger.e('Error initializing app: $e');
    runApp(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Initialization failed'))),
      ),
    );
    return;
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
  unawaited(_postLaunchInit());
}

Future<void> _postLaunchInit() async {
  await StorageProvider().requestPermission();
  await StorageProvider().deleteBtDirectory();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeSettingsProvider);
    final scale = ref.watch(uiSettingsProvider.select((s) => s.scale));
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ColorScheme? lightScheme =
            (theme.useDynamicColors && lightDynamic != null)
            ? lightDynamic
            : null;
        final ColorScheme? darkScheme =
            (theme.useDynamicColors && darkDynamic != null)
            ? darkDynamic
            : null;

        final lightTheme = FlexThemeData.light(
          colorScheme: lightScheme,
          swapColors: theme.swapColors,
          blendLevel: theme.blendLevel,
          scheme: lightScheme != null ? null : theme.flexSchemeEnum,
          useMaterial3: theme.useMaterial3,
          textTheme: GoogleFonts.montserratTextTheme(),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android:
                  PredictiveBackFullscreenPageTransitionsBuilder(),
              TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
            },
          ),
        );

        final darkTheme = FlexThemeData.dark(
          colorScheme: darkScheme,
          swapColors: theme.swapColors,
          blendLevel: theme.blendLevel,
          scheme: darkScheme != null ? null : theme.flexSchemeEnum,
          darkIsTrueBlack: theme.amoled,
          useMaterial3: theme.useMaterial3,
          textTheme: GoogleFonts.montserratTextTheme(),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android:
                  PredictiveBackFullscreenPageTransitionsBuilder(),
              TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
            },
          ),
        );

        final themeMode = theme.themeMode == 'light'
            ? ThemeMode.light
            : theme.themeMode == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          routerConfig: routerConfig,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final scaledSize = mediaQuery.size / scale;
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(scale),
                size: scaledSize,
              ),
              child: child!,
            );
          },
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
        );
      },
    );
  }
}

void showAppSnackBar(
  String title,
  String message, {
  ContentType type = ContentType.success,
}) {
  final messenger = scaffoldMessengerKey.currentState;
  if (messenger != null) {
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: title,
            message: message,
            contentType: type,
          ),
        ),
      );
  }
}
