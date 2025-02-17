import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/data/hive/models/continue_watching_model.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:shonenx/providers/hive/appearance_provider.dart';
import 'package:shonenx/router/router.dart';
import 'package:window_manager/window_manager.dart';

bool windowManagerInitialized = false;

class AppInitializer {
  static Future<void> initialize() async {
    log("🚀 Main() Called");

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      log("⚠️ Running in test mode, exiting main.");
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();
    log("✅ Flutter bindings initialized.");

    await _initializeMediaKit();
    await _initializeHive();
    await _initializeWindowManager();
  }

  static Future<void> _initializeMediaKit() async {
    MediaKit.ensureInitialized();
    log("✅ MediaKit initialized.");
  }

  static Future<void> _initializeHive() async {
  String customPath;

  if (Platform.isWindows) {
    // Custom folder inside the user's Documents directory (or any path you prefer)
    customPath = '${Directory.current.path}\\hive_data'; // Or any other path
  } else {
    // Default for other platforms
    customPath = (await getApplicationDocumentsDirectory()).path;
  }

  Hive.init(customPath);
  log("✅ Hive initialized at: $customPath");

  // Register your adapters as usual
  Hive.registerAdapter(SettingsModelAdapter());
  Hive.registerAdapter(ProviderSettingsModelAdapter());
  Hive.registerAdapter(AppearanceSettingsModelAdapter());
  Hive.registerAdapter(PlayerSettingsModelAdapter());
  Hive.registerAdapter(ContinueWatchingEntryAdapter());

  log("✅ Hive adapters registered.");
}


  static Future<void> _initializeWindowManager() async {
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      try {
        if (!windowManagerInitialized) {
          await windowManager.ensureInitialized();
          windowManagerInitialized = true;

          WindowOptions windowOptions = WindowOptions(
            center: true,
            backgroundColor: Colors.black,
            skipTaskbar: false,
            title: "ShonenX Beta",
          );

          await windowManager.waitUntilReadyToShow(windowOptions, () async {
            await windowManager.show();
            await windowManager.focus();
          });

          log("✅ Window Manager Initialized");
        }
      } catch (e) {
        log("❌ Window Manager Initialization Error: $e");
      }
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      log("✅ System UI Mode set to edge-to-edge.");
    }
  }
}

void main(List<String> args) async {
  await AppInitializer.initialize();
  log("🏃 Running App");
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearanceState = ref.watch(appearanceProvider).appearanceSettings;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: appearanceState?.themeMode == 'light'
            ? Brightness.light
            : Brightness.dark,
        textTheme: GoogleFonts.montserratTextTheme(
            appearanceState?.themeMode == 'light'
                ? ThemeData.light().textTheme
                : ThemeData.dark().textTheme),
        iconTheme: const IconThemeData(color: Colors.white),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lime,
          brightness: appearanceState?.themeMode == 'light'
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      routerConfig: router,
    );
  }
}
