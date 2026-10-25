import 'dart:async';

import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shonenx/features/downloads/utils/download_url_helper.dart';
import 'package:shonenx/source_engine/models/addon_info.dart';

class AddonNotInstalledException implements Exception {
  final String message;
  const AddonNotInstalledException(this.message);

  @override
  String toString() => message;
}

class AddonService {
  bridge.AddonManager get _bridgeManager {
    if (Get.isRegistered<bridge.AddonManager>()) {
      return Get.find<bridge.AddonManager>();
    }
    return Get.put<bridge.AddonManager>(bridge.AddonManager());
  }

  bool isTorrentUrl(String url) => DownloadUrlHelper.isTorrent(url);

  Future<bool> isAddonInstalled(String addonId) async {
    final addon = _bridgeManager.byId(addonId);
    if (addon == null) return false;
    return await addon.isInstalled();
  }

  Future<String> resolveTorrentStream({
    required String url,
    String? episode,
    String? title,
  }) async {
    final addon = _bridgeManager.byId('torrserver');
    if (addon == null || addon is! bridge.TorrServerAddon) {
      throw const AddonNotInstalledException(
        'TorrServer addon is not registered in the addon manager.',
      );
    }

    final installed = await addon.isInstalled();
    if (!installed) {
      throw const AddonNotInstalledException(
        'TorrServer addon is required to play torrent streams. Please install it in Settings > Addons.',
      );
    }

    return await addon.startStream(url: url, title: title, episode: episode);
  }

  Future<void> stopTorrentStream() async {
    try {
      final addon = _bridgeManager.byId('torrserver');
      if (addon is bridge.TorrServerAddon) {
        await addon.stopStream();
      }
    } catch (_) {}
  }
}

final addonServiceProvider = Provider<AddonService>((ref) {
  return AddonService();
});

class AddonListNotifier extends Notifier<List<AddonInfo>> {
  final List<StreamSubscription> _subscriptions = [];

  bridge.AddonManager get _bridgeManager {
    if (Get.isRegistered<bridge.AddonManager>()) {
      return Get.find<bridge.AddonManager>();
    }
    return Get.put<bridge.AddonManager>(bridge.AddonManager());
  }

  @override
  List<AddonInfo> build() {
    ref.onDispose(() {
      for (final sub in _subscriptions) {
        sub.cancel();
      }
      _subscriptions.clear();
    });

    _bindListeners();
    return _mapAddons();
  }

  void _bindListeners() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    for (final addon in _bridgeManager.addons) {
      _subscriptions.add(addon.installed.listen((_) => _syncState()));
      _subscriptions.add(addon.downloading.listen((_) => _syncState()));
      _subscriptions.add(addon.progress.listen((_) => _syncState()));
      _subscriptions.add(addon.hasUpdate.listen((_) => _syncState()));

      addon
          .isInstalled()
          .then((val) {
            addon.installed.value = val;
            _syncState();
          })
          .catchError((_) {});
    }
  }

  void _syncState() {
    state = _mapAddons();
  }

  List<AddonInfo> _mapAddons() {
    return _bridgeManager.addons.map((addon) {
      return AddonInfo(
        id: addon.id,
        name: addon.name,
        description: _getDescription(addon.id),
        icon: addon.icon,
        isInstalled: addon.installed.value,
        isDownloading: addon.downloading.value,
        downloadProgress: addon.progress.value,
        hasUpdate: addon.hasUpdate.value,
      );
    }).toList();
  }

  String _getDescription(String id) {
    switch (id) {
      case 'torrserver':
        return 'Torrent streaming engine';
      default:
        return 'Helper addon';
    }
  }

  Future<void> install(String id) async {
    final addon = _bridgeManager.byId(id);
    if (addon == null) return;
    await addon.install();
    _syncState();
  }

  Future<void> uninstall(String id) async {
    final addon = _bridgeManager.byId(id);
    if (addon == null) return;
    await addon.uninstall();
    _syncState();
  }

  Future<void> update(String id) async {
    final addon = _bridgeManager.byId(id);
    if (addon == null) return;
    await addon.update();
    _syncState();
  }

  Future<void> checkForUpdates() async {
    await _bridgeManager.checkForUpdates();
    _syncState();
  }
}

final addonListProvider = NotifierProvider<AddonListNotifier, List<AddonInfo>>(
  AddonListNotifier.new,
);
