import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Set<int> _scheduledIds = {};

  final ScopedLogger _log = AppLogger.scope('NotificationService');

  Future<void> init() async {
    _log.i('Initializing NotificationService...');
    try {
      tz.initializeTimeZones();
      final TimezoneInfo timeZoneInfo =
          await FlutterTimezone.getLocalTimezone();
      String timeZoneName = timeZoneInfo.identifier;

      const aliases = {
        'Asia/Calcutta': 'Asia/Kolkata',
        'Asia/Rangoon': 'Asia/Yangon',
        'Asia/Katmandu': 'Asia/Kathmandu',
        'Asia/Saigon': 'Asia/Ho_Chi_Minh',
        'US/Eastern': 'America/New_York',
        'US/Central': 'America/Chicago',
        'US/Mountain': 'America/Denver',
        'US/Pacific': 'America/Los_Angeles',
        'US/Alaska': 'America/Anchorage',
        'US/Hawaii': 'Pacific/Honolulu',
      };

      if (aliases.containsKey(timeZoneName)) {
        timeZoneName = aliases[timeZoneName]!;
      }

      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        _log.d('Timezone configured: $timeZoneName');
      } catch (e) {
        _log.e('Failed to load timezone $timeZoneName, falling back to UTC', e);
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher_monochrome');
      const windows = WindowsInitializationSettings(
        appName: 'ShonenX',
        appUserModelId: 'com.example.shonenx',
        guid: '123e4567-e89b-12d3-a456-426614174000',
      );
      const linux = LinuxInitializationSettings(defaultActionName: 'ShonenX');

      const settings = InitializationSettings(
        android: android,
        windows: windows,
        linux: linux,
      );

      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (_) {
          _log.d('Notification tapped by user');
        },
      );

      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        final pending = await _plugin.pendingNotificationRequests();
        _scheduledIds.addAll(pending.map((e) => e.id));
        _log.d('Restored ${_scheduledIds.length} pending notification IDs');
      }

      _log.s('Initialization complete');
    } catch (e, st) {
      _log.e('Failed to initialize NotificationService', e, st);
    }
  }

  Future<bool> requestPermissions() async {
    _log.i('Requesting notification permissions manually...');
    bool granted = false;

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final notificationsGranted =
            await androidPlugin.requestNotificationsPermission() ?? false;
        final alarmsGranted =
            await androidPlugin.requestExactAlarmsPermission() ?? false;

        granted = notificationsGranted;
        _log.d(
          'Android permissions requested. Notifications: $notificationsGranted, Alarms: $alarmsGranted',
        );
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        granted =
            await iosPlugin.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    }

    return granted;
  }

  static int generateId(String type, String refId, String variant) =>
      '$type:$refId:$variant'.hashCode;

  Future<bool> isScheduled(int id) async => _scheduledIds.contains(id);

  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduleTime,
  }) async {
    _log.d('Attempting to schedule notification [$id] for $scheduleTime');

    try {
      if (await isScheduled(id)) {
        _log.warning('Notification [$id] is already scheduled. Skipping.');
        return false;
      }

      if (scheduleTime.isBefore(DateTime.now())) {
        _log.warning(
          'Cannot schedule notification [$id] in the past ($scheduleTime).',
        );
        return false;
      }

      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.exactAllowWhileIdle;
      if (Platform.isAndroid) {
        final canScheduleExact = await Permission.scheduleExactAlarm.isGranted;
        if (!canScheduleExact) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          _log.d(
            'Exact alarms permission is not granted. Falling back to inexact scheduling.',
          );
        }
      }

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduleTime, tz.local),
        notificationDetails: _getNotificationDetails(),
        androidScheduleMode: scheduleMode,
      );

      _scheduledIds.add(id);
      _log.s('Successfully scheduled notification [$id]');
      return true;
    } catch (e, st) {
      _log.e('Failed to schedule notification [$id]', e, st);
      return false;
    }
  }

  Future<void> cancel(int id) async {
    _log.d('Attempting to cancel notification [$id]');
    try {
      await _plugin.cancel(id: id);
      _scheduledIds.remove(id);
      _log.s('Successfully canceled notification [$id]');
    } catch (e, st) {
      _log.e('Failed to cancel notification [$id]', e, st);
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    _log.d('Attempting to show immediate notification [$id]');
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _getNotificationDetails(),
      );
      _log.s('Successfully showed immediate notification [$id]');
    } catch (e, st) {
      _log.e('Failed to show notification [$id]', e, st);
    }
  }

  NotificationDetails _getNotificationDetails() {
    const android = AndroidNotificationDetails(
      'app_reminders',
      'App Reminders',
      channelDescription: 'General notifications for your anime & manga',
      importance: Importance.high,
      priority: Priority.high,
    );
    const windows = WindowsNotificationDetails();
    const linux = LinuxNotificationDetails();

    return const NotificationDetails(
      android: android,
      windows: windows,
      linux: linux,
    );
  }

  // Download notifications
  Future<void> showDownloadProgress({
    required int id,
    required String title,
    required double progress,
  }) async {
    final int maxProgress = 100;
    final int currentProgress = progress < 0
        ? 0
        : (progress * 100).clamp(0, 100).toInt();
    final bool indeterminate = progress < 0;

    final String body = indeterminate
        ? 'Preparing download…'
        : '$currentProgress% complete';

    _log.d('Download notification [$id] progress: $currentProgress%');
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'downloads',
            'Downloads',
            channelDescription: 'Progress updates for active downloads',
            importance: Importance.low,
            priority: Priority.low,
            showProgress: true,
            maxProgress: maxProgress,
            progress: currentProgress,
            indeterminate: indeterminate,
            onlyAlertOnce: true,
            ongoing: true,
            autoCancel: false,
            styleInformation: BigTextStyleInformation(body),
          ),
          windows: const WindowsNotificationDetails(),
          linux: const LinuxNotificationDetails(),
        ),
      );
    } catch (e, st) {
      _log.e('Failed to show download progress notification [$id]', e, st);
    }
  }

  Future<void> showDownloadComplete({
    required int id,
    required String title,
  }) async {
    _log.d('Download complete notification [$id]');
    try {
      await _plugin.cancel(id: id);
      await _plugin.show(
        id: id,
        title: '✅ Download complete',
        body: title,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'downloads',
            'Downloads',
            channelDescription: 'Progress updates for active downloads',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            autoCancel: true,
          ),
          windows: WindowsNotificationDetails(),
          linux: LinuxNotificationDetails(),
        ),
      );
    } catch (e, st) {
      _log.e('Failed to show download complete notification [$id]', e, st);
    }
  }

  Future<void> showDownloadFailed({
    required int id,
    required String title,
  }) async {
    _log.d('Download failed notification [$id]');
    try {
      await _plugin.cancel(id: id);
      await _plugin.show(
        id: id,
        title: '❌ Download failed',
        body: title,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'downloads',
            'Downloads',
            channelDescription: 'Progress updates for active downloads',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            autoCancel: true,
          ),
          windows: WindowsNotificationDetails(),
          linux: LinuxNotificationDetails(),
        ),
      );
    } catch (e, st) {
      _log.e('Failed to show download failed notification [$id]', e, st);
    }
  }

  Future<void> cancelDownloadNotification(int id) async {
    _log.d('Canceling download notification [$id]');
    try {
      await _plugin.cancel(id: id);
    } catch (e, st) {
      _log.e('Failed to cancel download notification [$id]', e, st);
    }
  }
}
