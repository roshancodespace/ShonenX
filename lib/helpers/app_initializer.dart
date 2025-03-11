import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:window_manager/window_manager.dart';

class AppInitializer {
  static Future<void> initialize() async {
    log("🚀 Main() Called", name: "appInitializer");

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      log("⚠️ Running in test mode, exiting main.", name: "appInitializer");
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();
    log("✅ Flutter bindings initialized.", name: "appInitializer");

    await _initializeMediaKit();
    await _initializeHive();
    await _initializeWindowManager();
  }

  static Future<void> _initializeMediaKit() async {
    try {
      MediaKit.ensureInitialized();
      log("✅ MediaKit initialized.", name: "appInitializer");
    } catch (e) {
      log("❌ MediaKit Initialization Error: $e", name: "appInitializer");
    }
  }

  static Future<void> _initializeHive() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final customPath = '${appDocDir.path}${Platform.pathSeparator}hive_data';

    await Hive.initFlutter(customPath);
    log("✅ Hive initialized at: $customPath", name: "appInitializer");

    Hive.registerAdapter(SettingsModelAdapter());
    Hive.registerAdapter(ProviderSettingsModelAdapter());
    Hive.registerAdapter(ThemeSettingsModelAdapter());
    Hive.registerAdapter(UISettingsModelAdapter());
    Hive.registerAdapter(PlayerSettingsModelAdapter());
    Hive.registerAdapter(AnimeWatchProgressEntryAdapter());
    Hive.registerAdapter(EpisodeProgressAdapter());

    log("✅ Hive adapters registered.", name: "appInitializer");
  }

  static Future<void> _initializeWindowManager() async {
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      try {
        await windowManager.ensureInitialized();

        await windowManager.waitUntilReadyToShow(
          const WindowOptions(
            center: true,
            backgroundColor: Colors.black,
            skipTaskbar: false,
            title: "ShonenX Beta",
          ),
          () async {
            await windowManager.show();
            await windowManager.focus();
          },
        );

        log("✅ Window Manager Initialized", name: "appInitializer");
      } catch (e) {
        log("❌ Window Manager Initialization Error: $e",
            error: true, name: "appInitializer");
      }
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([]);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
      );
      log("✅ System UI Mode set to edge-to-edge.", name: "appInitializer");
    }
  }
}
