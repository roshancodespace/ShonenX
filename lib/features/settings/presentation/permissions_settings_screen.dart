import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
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
  PermissionStatus? _batteryOptimizationStatus;

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
    final batteryOpt = Platform.isAndroid
        ? await Permission.ignoreBatteryOptimizations.status
        : PermissionStatus.granted;

    if (mounted) {
      setState(() {
        _notificationStatus = notif;
        _exactAlarmStatus = exactAlarm;
        _storageStatus = storage;
        _manageStorageStatus = manageStorage;
        _batteryOptimizationStatus = batteryOpt;
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

  Widget _buildStatusBadge(
    BuildContext context,
    PermissionStatus? status,
    ColorScheme cs,
  ) {
    final l10n = context.l10n;
    if (status == null) {
      return Text(
        l10n.permissionsChecking,
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      );
    }
    if (status.isGranted) {
      return Text(
        l10n.permissionsGranted,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade500,
        ),
      );
    }
    if (status.isDenied) {
      return Text(
        l10n.permissionsDenied,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.orange.shade500,
        ),
      );
    }
    if (status.isPermanentlyDenied) {
      return Text(
        l10n.permissionsDeniedLocked,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.red.shade500,
        ),
      );
    }
    if (status.isRestricted) {
      return Text(
        l10n.permissionsRestricted,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.amber.shade500,
        ),
      );
    }
    return Text(
      l10n.commonUnknown,
      style: TextStyle(
        fontSize: 12,
        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return AppScaffold(
      title: l10n.settingsPermissions,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          SettingsSection(
            title: l10n.permissionsSystemSection,
            children: [
              SettingsActionTile(
                icon: Icons.notifications_active_outlined,
                title: l10n.settingsNotifications,
                subtitle: l10n.permissionsNotifSubtitle,
                trailing: _buildStatusBadge(context, _notificationStatus, cs),
                onTap: () => _requestPermission(Permission.notification),
              ),
              if (Platform.isAndroid) ...[
                SettingsActionTile(
                  icon: Icons.battery_charging_full_rounded,
                  title: l10n.permissionsBatteryTitle,
                  subtitle: l10n.permissionsBatterySubtitle,
                  trailing: _buildStatusBadge(
                    context,
                    _batteryOptimizationStatus,
                    cs,
                  ),
                  onTap: () =>
                      _requestPermission(Permission.ignoreBatteryOptimizations),
                ),
                SettingsActionTile(
                  icon: Icons.alarm_rounded,
                  title: l10n.permissionsExactAlarmsTitle,
                  subtitle: l10n.permissionsExactAlarmsSubtitle,
                  trailing: _buildStatusBadge(context, _exactAlarmStatus, cs),
                  onTap: () =>
                      _requestPermission(Permission.scheduleExactAlarm),
                ),
                SettingsActionTile(
                  icon: Icons.folder_outlined,
                  title: l10n.permissionsStorageLegacyTitle,
                  subtitle: l10n.permissionsStorageLegacySubtitle,
                  trailing: _buildStatusBadge(context, _storageStatus, cs),
                  onTap: () => _requestPermission(Permission.storage),
                ),
                SettingsActionTile(
                  icon: Icons.manage_search_outlined,
                  title: l10n.permissionsManageStorageTitle,
                  subtitle: l10n.permissionsManageStorageSubtitle,
                  trailing: _buildStatusBadge(
                    context,
                    _manageStorageStatus,
                    cs,
                  ),
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
              l10n.permissionsPermanentlyDeniedNote,
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
