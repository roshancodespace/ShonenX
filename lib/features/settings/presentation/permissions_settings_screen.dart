import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class PermissionsSettingsScreen extends ConsumerStatefulWidget {
  const PermissionsSettingsScreen({super.key});

  @override
  ConsumerState<PermissionsSettingsScreen> createState() =>
      _PermissionsSettingsScreenState();
}

class _PermissionsSettingsScreenState
    extends ConsumerState<PermissionsSettingsScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _notificationStatus;
  PermissionStatus? _exactAlarmStatus;
  PermissionStatus? _storageStatus;
  PermissionStatus? _manageStorageStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final notif = await Permission.notification.status;
    final exactAlarm = Platform.isAndroid
        ? await Permission.scheduleExactAlarm.status
        : PermissionStatus.granted;
    final storage = Platform.isAndroid
        ? await Permission.storage.status
        : PermissionStatus.granted;
    final manageStorage = Platform.isAndroid
        ? await Permission.manageExternalStorage.status
        : PermissionStatus.granted;

    if (mounted) {
      setState(() {
        _notificationStatus = notif;
        _exactAlarmStatus = exactAlarm;
        _storageStatus = storage;
        _manageStorageStatus = manageStorage;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      _checkPermissions();
    }
  }

  Widget _buildStatusBadge(PermissionStatus? status, ColorScheme cs) {
    if (status == null) {
      return Text(
        'Checking...',
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      );
    }
    if (status.isGranted) {
      return Text(
        'Granted',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade500,
        ),
      );
    }
    if (status.isDenied) {
      return Text(
        'Denied',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.orange.shade500,
        ),
      );
    }
    if (status.isPermanentlyDenied) {
      return Text(
        'Denied (Locked)',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.red.shade500,
        ),
      );
    }
    if (status.isRestricted) {
      return Text(
        'Restricted',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.amber.shade500,
        ),
      );
    }
    return Text(
      'Unknown',
      style: TextStyle(
        fontSize: 12,
        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Permissions',
      body: ListView(
        children: [
          SettingsSection(
            title: 'System Permissions',
            children: [
              SettingsActionTile(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                subtitle: 'Push notifications and episode release reminders',
                trailing: _buildStatusBadge(_notificationStatus, cs),
                onTap: () => _requestPermission(Permission.notification),
              ),
              if (Platform.isAndroid) ...[
                SettingsActionTile(
                  icon: Icons.alarm_rounded,
                  title: 'Exact Alarms (Android 12+)',
                  subtitle:
                      'Scheduling precise airing reminders without system delays',
                  trailing: _buildStatusBadge(_exactAlarmStatus, cs),
                  onTap: () =>
                      _requestPermission(Permission.scheduleExactAlarm),
                ),
                SettingsActionTile(
                  icon: Icons.folder_outlined,
                  title: 'Storage (Android 10 and below)',
                  subtitle: 'Save downloads on older Android versions',
                  trailing: _buildStatusBadge(_storageStatus, cs),
                  onTap: () => _requestPermission(Permission.storage),
                ),
                SettingsActionTile(
                  icon: Icons.manage_search_outlined,
                  title: 'Manage External Storage (Android 11+)',
                  subtitle:
                      'Save downloads to custom directories across device',
                  trailing: _buildStatusBadge(_manageStorageStatus, cs),
                  onTap: () =>
                      _requestPermission(Permission.manageExternalStorage),
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Text(
              'If a permission is permanently denied, tapping on it will open the app settings where you can manually grant the permission.',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
