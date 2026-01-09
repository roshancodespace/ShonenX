import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';

import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';

import 'package:shonenx/core/utils/app_logger.dart';

import 'package:shonenx/features/home/model/home_page.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/settings/model/experimental_model.dart';
import 'package:shonenx/features/settings/model/player_model.dart';
import 'package:shonenx/features/settings/model/subtitle_appearance_model.dart';
import 'package:shonenx/features/settings/model/theme_model.dart';
import 'package:shonenx/features/settings/model/ui_model.dart';
import 'package:shonenx/features/settings/model/download_settings_model.dart';
import 'package:shonenx/features/settings/model/content_settings_model.dart';

import 'package:window_manager/window_manager.dart';

class AppInitializer {
  static Future<void> initialize() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      AppLogger.w("⚠️ Running in test mode, exiting main.");
      return;
    }

    AppLogger.section('App Initialization');

    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.success('Flutter bindings initialized');

    await _initializeHive();
    await _initializeWindowManager();
    await _initializeMediaKit();

    AppLogger.section('Initialization Complete');
  }

  static Future<void> _initializeMediaKit() async {
    AppLogger.section('MediaKit');

    try {
      MediaKit.ensureInitialized();
      AppLogger.success('MediaKit initialized');
    } catch (e, st) {
      AppLogger.fail('MediaKit initialization failed');
      AppLogger.e('MediaKit Initialization Error', e, st);
    }
  }

  static Future<void> _initializeHive() async {
    AppLogger.section('Hive Database');

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final customPath =
          '${appDocDir.path}${Platform.pathSeparator}ShonenX/appdata';

      AppLogger.infoPair('Hive Path', customPath);

      await Hive.initFlutter(customPath);
      AppLogger.success('Hive initialized');

      // --- Register adapters ---
      AppLogger.section('Hive Adapters');

      Hive
        ..registerAdapter(ThemeModelAdapter())
        ..registerAdapter(SubtitleAppearanceModelAdapter())
        ..registerAdapter(HomePageModelAdapter())
        ..registerAdapter(UiModelAdapter())
        ..registerAdapter(PlayerModelAdapter())
        ..registerAdapter(AnimeWatchProgressEntryAdapter())
        ..registerAdapter(EpisodeProgressAdapter())
        ..registerAdapter(ExperimentalFeaturesModelAdapter())
        ..registerAdapter(DownloadItemAdapter())
        ..registerAdapter(DownloadStatusAdapter())
        ..registerAdapter(DownloadSettingsModelAdapter())
        ..registerAdapter(ContentSettingsModelAdapter());

      AppLogger.success('Hive adapters registered');

      // --- Open boxes ---
      AppLogger.section('Hive Boxes');

      await Future.wait([
        Hive.openBox<ThemeModel>('theme_settings'),
        Hive.openBox('themedata'),
        Hive.openBox<SubtitleAppearanceModel>('subtitle_appearance'),
        Hive.openBox<HomePageModel>('home_page'),
        Hive.openBox<String>('selected_provider'),
        Hive.openBox<UiModel>('ui_settings'),
        Hive.openBox<PlayerModel>('player_settings'),
        Hive.openBox<AnimeWatchProgressEntry>('anime_watch_progress'),
        Hive.openBox<ExperimentalFeaturesModel>('experimental_features'),
        Hive.openBox<DownloadItem>('downloads'),
        Hive.openBox('settings'),
        Hive.openBox('onboard'),
        Hive.openBox<DownloadSettingsModel>('download_settings'),
        Hive.openBox<ContentSettingsModel>('content_settings'),
      ]);

      AppLogger.success('Hive boxes opened');
    } catch (e, st) {
      AppLogger.fail('Hive initialization failed');
      AppLogger.e('Hive Initialization Error', e, st);
    }
  }

  static Future<void> _initializeWindowManager() async {
    AppLogger.section('Window / System UI');

    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      AppLogger.infoPair('Platform', Platform.operatingSystem);

      try {
        await windowManager.ensureInitialized();

        await windowManager.waitUntilReadyToShow(
          const WindowOptions(
            center: true,
            backgroundColor: Colors.black,
            skipTaskbar: false,
            title: 'ShonenX Beta',
          ),
          () async {
            await windowManager.show();
            await windowManager.focus();
          },
        );

        AppLogger.success('Window manager initialized');
      } catch (e, st) {
        AppLogger.fail('Window manager initialization failed');
        AppLogger.e('Window Manager Error', e, st);
      }
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([]);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      );

      AppLogger.success('Mobile system UI configured');
    }
  }
}
