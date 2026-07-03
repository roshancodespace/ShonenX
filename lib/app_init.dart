import 'dart:io';

import 'package:anymex_extension_runtime_bridge/Settings/KvStore.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:isar_community/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/core/caching/cache_manager.dart';
import 'package:shonenx/core/caching/domain/cache_entry.dart';
import 'package:shonenx/core/services/notification_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/discovery/domain/media_preference.dart';
import 'package:shonenx/features/discovery/domain/media_source_preference.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/notifications/domain/models/notification_subscription.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fvp/fvp.dart' as fvp;

class AppInit {
  static bool isBridgeInitialized = false;
  static String? pendingDeepLink;

  late final ScopedLogger _log = AppLogger.scope(AppInit);

  late final CacheManager cacheManager;
  late final Isar isar;

  Future<AppInit> init() async {
    final log = _log.child('init');

    log.section('START');

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _initWindowManager();
      log.s('Window manager initialized');
    }

    await _initVideoEngines();
    log.s('Video engines initialized');

    await _initDatabase();
    log.s('Database initialized');

    await _initNotifications();
    log.s('Notifications initialized');

    log.section('DONE');

    return this;
  }

  Future<void> _initWindowManager() async {
    final log = _log.child('_initWindowManager');

    try {
      await windowManager.ensureInitialized();

      bool isTilingWm = false;

      if (Platform.isLinux) {
        final env = Platform.environment;
        final desktop = env['XDG_CURRENT_DESKTOP']?.toLowerCase() ?? '';
        final session = env['DESKTOP_SESSION']?.toLowerCase() ?? '';

        isTilingWm =
            desktop.contains('hyprland') ||
            session.contains('hyprland') ||
            env.containsKey('HYPRLAND_INSTANCE_SIGNATURE') ||
            desktop.contains('niri') ||
            session.contains('niri');
      }

      final windowOptions = WindowOptions(
        center: true,

        backgroundColor: Platform.isWindows
            ? const Color(0xFF000000)
            : Colors.transparent,

        titleBarStyle: isTilingWm ? TitleBarStyle.hidden : null,

        windowButtonVisibility: Platform.isLinux && !isTilingWm,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e, st) {
      log.e('WINDOWMANAGER INIT FAILED', e, st);
      rethrow;
    }
  }

  Future<void> _initDatabase() async {
    final log = _log.child('_initDatabase');

    try {
      final dir = await getDatabaseDirectory('ShonenX');

      isar = await Isar.open(
        [
          CacheEntrySchema,
          LibraryEntrySchema,
          MediaSourcePreferenceSchema,
          MediaPreferenceSchema,
          IsarTrackerLinkSchema,
          WatchHistoryEntrySchema,
          ReadHistoryEntrySchema,
          DownloadTaskSchema,
          NotificationSubscriptionSchema,

          // MSourceSchema,
          // SourcePreferenceSchema,
          // SourcePreferenceStringValueSchema,
          // BridgeSettingsSchema,
          KvEntrySchema,
        ],
        directory: dir.path,
        name: 'shonenx_db',
      );

      // Perform migration from MediaSourcePreference to MediaPreference
      final oldPrefsCount = await isar.mediaSourcePreferences.count();
      if (oldPrefsCount > 0) {
        log.i(
          'Migrating $oldPrefsCount MediaSourcePreferences to MediaPreferences...',
        );
        final oldPrefs = await isar.mediaSourcePreferences.where().findAll();

        final newPrefs = oldPrefs
            .map(
              (old) => MediaPreference()
                ..mediaTitle = old.mediaTitle
                ..preferredSourceId = old.preferredSourceId
                ..preferredSourceName = old.preferredSourceName
                ..preferredSourceType = old.preferredSourceType
                ..manualOverrideId = old.manualOverrideId
                ..manualOverrideTitle = old.manualOverrideTitle,
            )
            .toList();

        await isar.writeTxn(() async {
          await isar.mediaPreferences.putAll(newPrefs);
          await isar.mediaSourcePreferences.clear();
        });
        log.s('Migration complete');
      }

      log.s('Isar opened');
    } catch (e, st) {
      log.e('DB INIT FAILED', e, st);
      rethrow;
    }
  }

  static Future<void> setupBridge(WidgetRef ref) async {
    final log = AppLogger.scope('AppInit').child('setupBridge');

    try {
      await AnymeXExtensionBridge.init(
        getDirectory: AnymeXExtensionBridge.defaultGetDirectory(
          baseDirectory: await getDatabaseDirectory('ShonenX'),
        ),
        projectName: "ShonenX",
      );

      await AnymeXRuntimeBridge.checkAndInitialize();

      final extManager = Get.find<ExtensionManager>();

      int retryCount = 0;
      while (extManager.managers.isEmpty && retryCount < 100) {
        await Future.delayed(const Duration(milliseconds: 50));
        retryCount++;
      }

      await extManager.onRuntimeBridgeInitialization(force: true);

      log.s('Extension bridge ready');
    } catch (e, st) {
      log.e('BRIDGE INIT FAILED', e, st);
      rethrow;
    } finally {
      isBridgeInitialized = true;
    }
  }

  Future<void> _initNotifications() async {
    final log = _log.child('_initNotifications');

    try {
      await NotificationService.instance.init();
      log.s('Notification service initialized');
    } catch (e, st) {
      log.e('NOTIFICATION INIT FAILED', e, st);
      rethrow;
    }
  }

  static Future<Directory> getDatabaseDirectory(String dirName) async {
    final dir = await getApplicationDocumentsDirectory();
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return dir;
    } else {
      String dbDir = p.join(dir.path, dirName, 'databases');
      await Directory(dbDir).create(recursive: true);
      return Directory(dbDir);
    }
  }

  static Future<void> _initVideoEngines() async {
    final log = AppLogger.scope('AppInit').child('initVideoEngines');

    MediaKit.ensureInitialized();
    log.i('MediaKit initialized');

    fvp.registerWith();
    log.i('FVP backend initialized');
  }
}
