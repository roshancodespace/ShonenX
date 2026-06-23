import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shonenx/core/remote_config/providers/remote_config_provider.dart';
import 'package:shonenx/core/remote_config/ui/remote_config_ui.dart';
import 'package:shonenx/core/router/app_router.dart';

class RemoteConfigListener extends ConsumerStatefulWidget {
  final Widget child;

  const RemoteConfigListener({super.key, required this.child});

  @override
  ConsumerState<RemoteConfigListener> createState() =>
      _RemoteConfigListenerState();
}

class _RemoteConfigListenerState extends ConsumerState<RemoteConfigListener> {
  // ignore: unused_field
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initRemoteConfig();
  }

  Future<void> _initRemoteConfig() async {
    final service = ref.read(remoteConfigServiceProvider);
    await service.init();

    if (!mounted) return;

    await _checkUpdatesAndAnnouncements();

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  Future<void> _checkUpdatesAndAnnouncements() async {
    final service = ref.read(remoteConfigServiceProvider);
    final config = service.config;

    if (config == null) return;

    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;

    // 1. Check if application is disabled globally
    if (!config.applicationEnabled) {
      await RemoteConfigUI.showApplicationDisabledSheet(navContext);
      return; // Stop further checks since app is disabled
    }

    // 2. Check for Updates
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (service.shouldShowUpdate(currentVersion)) {
        await RemoteConfigUI.showUpdateSheet(
          navContext,
          minimumVersion: config.minimumVersion,
          onDownload: () {
            service.markUpdateAsDownloaded(config.minimumVersion);
          },
        );
        return; // Stop further checks since they are forced to update
      }
    } catch (e) {
      // Ignore package info errors
    }

    if (!mounted || !navContext.mounted) return;

    // 3. Check for active app announcement
    final activeAnnouncement = service.getActiveAppAnnouncement();
    if (activeAnnouncement != null) {
      await RemoteConfigUI.showAnnouncementSheet(
        navContext,
        announcement: activeAnnouncement,
      );
      await service.markAnnouncementAsSeen(activeAnnouncement.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
