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

    // Check for Update
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentUpdateId = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (service.shouldShowUpdate(currentUpdateId)) {
        final channelConfig = config.getChannelConfig(service.currentChannel);
        if (channelConfig != null && mounted) {
          final navContext = rootNavigatorKey.currentContext;
          if (navContext != null && navContext.mounted) {
            await RemoteConfigUI.showUpdateSheet(
              navContext,
              config: channelConfig,
            );
            await service.markUpdateAsSeen();
          }
        }
      }
    } catch (e) {
      // Ignore package info errors
    }

    if (!mounted) return;

    // Check for Announcement
    if (service.shouldShowAnnouncement()) {
      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        await RemoteConfigUI.showAnnouncementSheet(
          navContext,
          announcement: config.announcement!,
        );
        await service.markAnnouncementAsSeen();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
