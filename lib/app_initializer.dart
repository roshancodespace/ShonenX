import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';

import 'package:shonenx/core/utils/app_logger.dart';

import 'package:shonenx/features/home/model/home_page.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';
import 'package:shonenx/features/settings/model/experimental_model.dart';
import 'package:shonenx/features/settings/model/player_model.dart';
import 'package:shonenx/features/settings/model/subtitle_appearance_model.dart';
import 'package:shonenx/features/settings/model/theme_model.dart';
import 'package:shonenx/features/settings/model/download_settings_model.dart';
import 'package:shonenx/features/settings/model/content_settings_model.dart';
import 'package:shonenx/core/models/universal/universal_news.dart';
import 'package:shonenx/core/services/notification_service.dart';
import 'package:shonenx/features/settings/model/ui_model.dart';
import 'package:shonenx/helpers/ui.dart';
import 'package:shonenx/hive/hive_registrar.g.dart';

import 'package:window_manager/window_manager.dart';
import 'package:workmanager/workmanager.dart';

import 'package:shonenx/background_handler.dart';

import 'main.dart';

class AppInitializer {
  static Future<void> initialize() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      AppLogger.w("⚠️ Running in test mode, exiting main.");
      return;
    }

    AppLogger.section('App Initialization');

    await AppLogger.init();

    await _initializeBackgroundService();

    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.success('Flutter bindings initialized');

    await _initializeHive();
    await _initializeSharedPrefs();
    await _initializeWindowManager();
    await _initializeMediaKit();
    await NotificationService().initialize();
    AppLogger.section('Initialization Complete');
  }

  static Future<void> _initializeSharedPrefs() async {
    AppLogger.section('Shared Preferences');
    try {
      sharedPrefs = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      );
      AppLogger.success('Shared Preferences initialized');
    } catch (e, st) {
      AppLogger.fail('Shared Preferences initialization failed');
      AppLogger.e('Shared Preferences Error', e, st);
    }
  }

  static Future<void> _initializeBackgroundService() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    AppLogger.section('Background services');
    Workmanager().initialize(callbackDispatcher);
    AppLogger.success('Background services initialized');
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

      Hive
        ..init(customPath)
        ..registerAdapters();

      AppLogger.success('Hive initialized');

      AppLogger.section('Hive Boxes');

      final boxesToOpen = <String, Future<void> Function()>{
        'theme_settings': () => Hive.openBox<ThemeModel>('theme_settings'),
        'themedata': () => Hive.openBox('themedata'),
        'subtitle_appearance': () =>
            Hive.openBox<SubtitleAppearanceModel>('subtitle_appearance'),
        'home_page': () => Hive.openBox<HomePageModel>('home_page'),
        'ui_settings': () => Hive.openBox<UiSettings>('ui_settings'),
        'selected_provider': () => Hive.openBox<String>('selected_provider'),
        'player_settings': () => Hive.openBox<PlayerModel>('player_settings'),
        'anime_watch_progress': () =>
            Hive.openBox<AnimeWatchProgressEntry>('anime_watch_progress'),
        'experimental_features': () =>
            Hive.openBox<ExperimentalFeaturesModel>('experimental_features'),
        'downloads': () => Hive.openBox<DownloadItem>('downloads'),
        'settings': () => Hive.openBox('settings'),
        'onboard': () => Hive.openBox('onboard'),
        'download_settings': () =>
            Hive.openBox<DownloadSettingsModel>('download_settings'),
        'content_settings': () =>
            Hive.openBox<ContentSettingsModel>('content_settings'),
        'news_cache': () => Hive.openBox<UniversalNews>('news_cache'),
        'news_read_status': () => Hive.openBox<String>('news_read_status'),
        'home_layout': () => Hive.openBox('home_layout'),
        'http_cache_v1': () => Hive.openBox('http_cache_v1'),
      };

      for (final entry in boxesToOpen.entries) {
        try {
          AppLogger.i('Opening box: ${entry.key}');
          await entry.value();
        } catch (e) {
          AppLogger.fail('Failed to open box [${entry.key}]: $e');
          AppLogger.warning(
            'Deleting corrupted box: ${entry.key} and retrying...',
          );
          try {
            await Hive.deleteBoxFromDisk(entry.key);
            await entry.value();
            AppLogger.success('Successfully recovered box: ${entry.key}');
          } catch (e2) {
            AppLogger.fail(
              'CRITICAL: Failed to recover box [${entry.key}]: $e2',
            );
          }
        }
      }

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
            title: 'ShonenX',
          ),
          () async {
            await windowManager.show();
            await windowManager.focus();
            if (!Platform.isLinux) {
              await windowManager.setHasShadow(true);
            }
          },
        );

        AppLogger.success('Window manager initialized');
      } catch (e, st) {
        AppLogger.fail('Window manager initialization failed');
        AppLogger.e('Window Manager Error', e, st);
      }
    } else {
      await UIHelper.exitImmersiveMode();
      await UIHelper.enableAutoRotate();
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      );

      AppLogger.success('Mobile system UI configured');
    }
  }
}
