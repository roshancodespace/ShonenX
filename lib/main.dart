import 'dart:async';
import 'dart:io';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/app_initializer.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/settings/view_model/theme_notifier.dart';
import 'package:shonenx/shared/providers/router_provider.dart';
import 'package:shonenx/storage_provider.dart';
import 'package:shonenx/core/utils/env_loader.dart';

late Isar isar;
WebViewEnvironment? webViewEnvironment;
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main(List<String> args) async {
  await Env.init();
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux && runWebViewTitleBarWidget(args)) return;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    final availableVersion = await WebViewEnvironment.getAvailableVersion();
    if (availableVersion != null) {
      final document = await getApplicationDocumentsDirectory();
      webViewEnvironment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(
          userDataFolder: p.join(document.path, 'flutter_inappwebview'),
        ),
      );
    }
  }
  try {
    AppLogger.i('Starting app initialization');
    await AppInitializer.initialize();
  } catch (e) {
    AppLogger.e('Error initializing app: $e');
    runApp(const MaterialApp(
      home: Scaffold(body: Center(child: Text('Initialization failed'))),
    ));
    return;
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false),
  );

  isar = await StorageProvider().initDB(null, inspector: kDebugMode);

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
        );

        final darkTheme = FlexThemeData.dark(
          colorScheme: darkScheme,
          swapColors: theme.swapColors,
          blendLevel: theme.blendLevel,
          scheme: darkScheme != null ? null : theme.flexSchemeEnum,
          darkIsTrueBlack: theme.amoled,
          useMaterial3: theme.useMaterial3,
          textTheme: GoogleFonts.montserratTextTheme(),
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
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
        );
      },
    );
  }
}

void showAppSnackBar(String title, String message,
    {ContentType type = ContentType.success}) {
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
