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

  String _getCurrentRoutePath() {
    try {
      final router = ref.read(routerProvider);
      return router.routerDelegate.currentConfiguration.uri.path;
    } catch (_) {
      return '/splash';
    }
  }

  Future<void> _initRemoteConfig() async {
    final service = ref.read(remoteConfigServiceProvider);
    await service.init();

    if (!mounted) return;

    setState(() {
      _initialized = true;
    });

    await _checkUpdatesAndAnnouncements();
  }

  Future<void> _checkUpdatesAndAnnouncements() async {
    final service = ref.read(remoteConfigServiceProvider);
    final config = service.config;

    if (config == null) return;

    // 1. If application is disabled globally, build() replaces the entire app UI.
    if (!config.applicationEnabled) return;

    // Wait until splash screen / initial loading navigation completes so bottom sheets don't get dismissed by GoRouter
    final stopwatch = Stopwatch()..start();
    while (mounted && stopwatch.elapsed < const Duration(seconds: 8)) {
      final path = _getCurrentRoutePath();
      if (path != '/splash' && path != '/') {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }

    // Brief delay to allow route transition animation to settle cleanly
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;

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
        return;
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
    final service = ref.watch(remoteConfigServiceProvider);
    final config = service.config;

    if (config != null && !config.applicationEnabled) {
      return RemoteConfigUI.buildApplicationDisabledScreen(context);
    }

    return widget.child;
  }
}
