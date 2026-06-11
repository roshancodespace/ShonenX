import 'dart:io';

import 'package:dartotsu_extension_bridge/Mangayomi/Eval/dart/model/source_preference.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shonenx/core/caching/cache_manager.dart';
import 'package:shonenx/core/caching/domain/cache_entry.dart';
import 'package:shonenx/core/services/notification_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/discovery/domain/media_source_preference.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/notifications/domain/models/notification_subscription.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:window_manager/window_manager.dart';

class AppInit {
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

    MediaKit.ensureInitialized();
    log.s('MediaKit initialized');

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

      const windowOptions = WindowOptions(
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
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
          IsarTrackerLinkSchema,
          WatchHistoryEntrySchema,
          DownloadTaskSchema,
          NotificationSubscriptionSchema,

          MSourceSchema,
          SourcePreferenceSchema,
          SourcePreferenceStringValueSchema,
          BridgeSettingsSchema,
        ],
        directory: dir.path,
        name: 'shonenx_db',
      );

      log.s('Isar opened');

      await _setupBridge(isar);
      log.s('Bridge initialized');
    } catch (e, st) {
      log.e('DB INIT FAILED', e, st);
      rethrow;
    }
  }

  Future<void> _setupBridge(Isar instance) async {
    final log = _log.child('_setupBridge');

    try {
      await DartotsuExtensionBridge().init(instance, 'ShonenX');
      log.s('Extension bridge ready');
    } catch (e, st) {
      log.e('BRIDGE INIT FAILED', e, st);
      rethrow;
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
}
