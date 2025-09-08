import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';

import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/data/hive/models/settings/provider_model.dart';

import 'package:shonenx/core/utils/app_logger.dart';

import 'package:shonenx/features/home/model/home_page.dart';
import 'package:shonenx/features/settings/model/player_model.dart';
import 'package:shonenx/features/settings/model/subtitle_appearance_model.dart';
import 'package:shonenx/features/settings/model/theme_model.dart';
import 'package:shonenx/features/settings/model/ui_model.dart';

import 'package:window_manager/window_manager.dart';

class AppInitializer {
  static Future<void> initialize() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      AppLogger.w("⚠️ Running in test mode, exiting main.");
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.i("✅ Flutter bindings initialized.");

    await _initializeHive();
    await _initializeWindowManager();
    await _initializeMediaKit();
  }

  static Future<void> _initializeMediaKit() async {
    try {
      MediaKit.ensureInitialized();
      AppLogger.i("✅ MediaKit initialized.");
    } catch (e, st) {
      AppLogger.e("❌ MediaKit Initialization Error", e, st);
    }
  }

  static Future<void> _initializeHive() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final customPath = '${appDocDir.path}${Platform.pathSeparator}shonenx';

      await Hive.initFlutter(customPath);
      AppLogger.i("✅ Hive initialized at: $customPath");

      Hive.registerAdapter(ThemeModelAdapter());
      Hive.registerAdapter(SubtitleAppearanceModelAdapter());
      Hive.registerAdapter(HomePageModelAdapter());
      Hive.registerAdapter(UiModelAdapter());
      Hive.registerAdapter(ProviderSettingsAdapter());
      Hive.registerAdapter(PlayerModelAdapter());
      Hive.registerAdapter(AnimeWatchProgressEntryAdapter());
      Hive.registerAdapter(EpisodeProgressAdapter());

      await Future.wait([
        Hive.openBox<ThemeModel>('theme_settings'),
        Hive.openBox('themedata'),
        Hive.openBox<SubtitleAppearanceModel>('subtitle_appearance'),
        Hive.openBox<HomePageModel>('home_page'),
        Hive.openBox<String>('selected_provider'),
        Hive.openBox<UiModel>('ui_settings'),
        Hive.openBox<ProviderSettings>('provider_settings'),
        Hive.openBox<PlayerModel>('player_settings'),
        Hive.openBox<AnimeWatchProgressEntry>('anime_watch_progress'),
      ]);

      AppLogger.i("✅ Hive adapters registered and boxes opened.");
    } catch (e, st) {
      AppLogger.e("❌ Hive Initialization Error", e, st);
    }
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

        AppLogger.i("✅ Window Manager Initialized");
      } catch (e, st) {
        AppLogger.e("❌ Window Manager Initialization Error", e, st);
      }
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([]);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
      );
      AppLogger.i("✅ System UI Mode set to edge-to-edge.");
    }
  }
}
