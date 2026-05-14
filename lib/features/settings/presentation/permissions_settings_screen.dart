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
    final storage = await Permission.storage.status;
    final manageStorage = Platform.isAndroid
        ? await Permission.manageExternalStorage.status
        : PermissionStatus.granted;

    if (mounted) {
      setState(() {
        _notificationStatus = notif;
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

  String _getStatusText(PermissionStatus? status) {
    if (status == null) return 'Checking...';
    if (status.isGranted) return 'Granted';
    if (status.isDenied) return 'Denied';
    if (status.isPermanentlyDenied) return 'Permanently Denied';
    if (status.isRestricted) return 'Restricted';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Permissions',
      body: ListView(
        children: [
          SettingsSection(
            title: 'System Permissions',
            children: [
              SettingsActionTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: _getStatusText(_notificationStatus),
                onTap: () => _requestPermission(Permission.notification),
              ),
              if (Platform.isAndroid) ...[
                SettingsActionTile(
                  icon: Icons.folder_outlined,
                  title: 'Storage (Android 10 and below)',
                  subtitle: _getStatusText(_storageStatus),
                  onTap: () => _requestPermission(Permission.storage),
                ),
                SettingsActionTile(
                  icon: Icons.manage_search_outlined,
                  title: 'Manage External Storage (Android 11+)',
                  subtitle: _getStatusText(_manageStorageStatus),
                  onTap: () =>
                      _requestPermission(Permission.manageExternalStorage),
                ),
              ],
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'If a permission is permanently denied, tapping on it will open the app settings where you can manually grant the permission.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
