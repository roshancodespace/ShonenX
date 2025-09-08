import 'dart:async';
import 'dart:io';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/app_initializer.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/settings/view_model/theme_notifier.dart';
import 'package:shonenx/shared/providers/router_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shonenx/storage_provider.dart';

late Isar isar;
WebViewEnvironment? webViewEnvironment;
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
void main(List<String> args) async {
  await dotenv.load(fileName: '.env');
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
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: FlexThemeData.light(
        swapColors: theme.swapColors,
        blendLevel: theme.blendLevel,
        scheme: theme.flexSchemeEnum,
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      darkTheme: FlexThemeData.dark(
        swapColors: theme.swapColors,
        blendLevel: theme.blendLevel,
        scheme: theme.flexSchemeEnum,
        darkIsTrueBlack: theme.amoled,
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      themeMode: theme.themeMode == 'light'
          ? ThemeMode.light
          : theme.themeMode == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system,
      routerConfig: router,
    );
  }
}

void showAppSnackBar(String message) {
  final messenger = scaffoldMessengerKey.currentState;
  if (messenger != null) {
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
