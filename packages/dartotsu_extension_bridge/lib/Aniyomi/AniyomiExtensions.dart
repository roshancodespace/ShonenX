import 'dart:io';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:http/http.dart' as http;
import 'package:install_plugin/install_plugin.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AniyomiExtensions extends Extension {
  AniyomiExtensions() {
    initialize();
  }

  static const platform = MethodChannel('aniyomiExtensionBridge');
  final Rx<List<Source>> availableAnimeExtensionsUnmodified = Rx([]);
  final Rx<List<Source>> availableMangaExtensionsUnmodified = Rx([]);
  final Rx<List<Source>> availableNovelExtensionsUnmodified = Rx([]);

  @override
  bool get supportsNovel => false;

  @override
  Future<void> initialize() async {
    if (isInitialized.value) return;
    isInitialized.value = true;
    var settings = isar.bridgeSettings.getSync(26)!;
    getInstalledAnimeExtensions();
    getInstalledMangaExtensions();
    getInstalledNovelExtensions();
    fetchAvailableAnimeExtensions(settings.aniyomiAnimeExtensions);
    fetchAvailableMangaExtensions(settings.aniyomiMangaExtensions);
  }

  @override
  Future<List<Source>> fetchAvailableAnimeExtensions(List<String>? repos) =>
      _fetchAvailable('fetchAnimeExtensions', ItemType.anime, repos);

  @override
  Future<List<Source>> fetchAvailableMangaExtensions(List<String>? repos) =>
      _fetchAvailable('fetchMangaExtensions', ItemType.manga, repos);

  Future<List<Source>> _fetchAvailable(
    String method,
    ItemType type,
    List<String>? repos,
  ) async {
    final settings = isar.bridgeSettings.getSync(26)!;

    switch (type) {
      case ItemType.anime:
        settings.aniyomiAnimeExtensions = repos ?? [];
        break;
      case ItemType.manga:
        settings.aniyomiMangaExtensions = repos ?? [];
        break;
      case ItemType.novel:
        break;
    }
    isar.writeTxnSync(() => isar.bridgeSettings.putSync(settings));

    final sources = await _loadExtensions(method, repos: repos);
    final installedIds = getInstalledRx(type).value.map((e) => e.id).toSet();

    final unmodifiedList = sources.map((e) {
      var map = e.toJson();
      map['extensionType'] = 1;
      return Source.fromJson(map);
    }).toList();
    final list = unmodifiedList
        .where((s) => !installedIds.contains(s.id))
        .toList();
    getAvailableRx(type).value = list;
    getAvailableUnmodified(type).value = unmodifiedList;
    checkForUpdates(type);
    return list;
  }

  @override
  Future<List<Source>> getInstalledAnimeExtensions() {
    return _getInstalled('getInstalledAnimeExtensions', ItemType.anime);
  }

  @override
  Future<List<Source>> getInstalledMangaExtensions() {
    return _getInstalled('getInstalledMangaExtensions', ItemType.manga);
  }

  Future<List<Source>> _getInstalled(String method, ItemType type) async {
    final sources = await _loadExtensions(method);
    getInstalledRx(type).value = sources;
    checkForUpdates(type);
    return sources;
  }

  Future<List<Source>> _loadExtensions(
    String method, {
    List<String>? repos,
  }) async {
    try {
      final List<dynamic> result = await platform.invokeMethod(method, repos);
      final parsed = await compute(_parseSources, result);
      return parsed;
    } catch (e) {
      return [];
    }
  }

  static List<Source> _parseSources(List<dynamic> data) {
    return data.map((e) {
      final map = Map<String, dynamic>.from(e);
      map['apkUrl'] = getAnimeApkUrl(
        map['iconUrl'] ?? '',
        map['apkName'] ?? '',
      );
      map['extensionType'] = 1;
      return Source.fromJson(map);
    }).toList();
  }

  @override
  Future<void> installSource(Source source) async {
    if (source.apkUrl == null) {
      return Future.error('Source APK URL is required for installation.');
    }

    try {
      final packageName = source.apkUrl!.split('/').last.replaceAll('.apk', '');

      final response = await http.get(Uri.parse(source.apkUrl!));

      if (response.statusCode != 200) {
        throw Exception('Failed to download APK: HTTP ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final apkFileName = '$packageName.apk';
      final apkFile = File(path.join(tempDir.path, apkFileName));

      await apkFile.writeAsBytes(response.bodyBytes);

      final result = await InstallPlugin.installApk(
        apkFile.path,
        appId: packageName,
      );

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      if (result['isSuccess'] != true) {
        throw Exception(
          'Installation failed: ${result['errorMessage'] ?? 'Unknown error'}',
        );
      }
      final rx = getAvailableRx(source.itemType!);
      rx.value = rx.value.where((s) => s.id != source.id).toList();
      switch (source.itemType) {
        case ItemType.anime:
          getInstalledAnimeExtensions(); // because it also update extension on kotlin side
          break;
        case ItemType.manga:
          getInstalledMangaExtensions();
          break;
        case ItemType.novel:
          break;
        default:
          throw Exception('Unsupported item type: ${source.itemType}');
      }
      debugPrint('Successfully installed package: $packageName');
    } catch (e) {
      if (kDebugMode) {
        print('Error installing source: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> uninstallSource(Source source) async {
    final packageName = source.id;
    if (packageName == null || packageName.isEmpty) {
      throw Exception('Source ID is required for uninstallation.');
    }

    try {
      final isInstalled = await DeviceApps.isAppInstalled(packageName);
      if (!isInstalled) {
        _removeFromInstalledList(source);
        return;
      }

      final success = await DeviceApps.uninstallApp(packageName);
      if (!success) {
        throw Exception('Failed to initiate uninstallation for: $packageName');
      }

      final timeout = const Duration(seconds: 10);
      final start = DateTime.now();

      while (DateTime.now().difference(start) < timeout) {
        final stillInstalled = await DeviceApps.isAppInstalled(packageName);
        if (!stillInstalled) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final finalCheck = await DeviceApps.isAppInstalled(packageName);
      if (finalCheck) {
        throw Exception('Uninstallation timed out or was cancelled by user.');
      }

      _removeFromInstalledList(source);

      final itemType = source.itemType;
      if (itemType != null) {
        final availableList = getAvailableUnmodified(itemType).value;
        if (availableList.any((s) => s.id == packageName)) {
          getAvailableRx(itemType).update((list) => list?..add(source));
        }
      }

      debugPrint('Successfully uninstalled package: $packageName');
    } catch (e) {
      debugPrint('Error uninstalling $packageName: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateSource(Source source) async {
    if (source.apkUrl == null) {
      return Future.error('Source APK URL is required for installation.');
    }

    try {
      final packageName = source.apkUrl!.split('/').last.replaceAll('.apk', '');

      final response = await http.get(Uri.parse(source.apkUrl!));

      if (response.statusCode != 200) {
        throw Exception('Failed to download APK: HTTP ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final apkFileName = '$packageName.apk';
      final apkFile = File(path.join(tempDir.path, apkFileName));

      await apkFile.writeAsBytes(response.bodyBytes);

      final result = await InstallPlugin.installApk(
        apkFile.path,
        appId: packageName,
      );
      if (result['isSuccess'] != true) {
        debugPrint(
          'Installation failed: ${result['errorMessage'] ?? 'Unknown error'}',
        );
      }
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      switch (source.itemType) {
        case ItemType.anime:
          getInstalledAnimeExtensions(); // because it also update extension on kotlin side
          break;
        case ItemType.manga:
          getInstalledMangaExtensions();
          break;
        case ItemType.novel:
          break;
        default:
          throw Exception('Unsupported item type: ${source.itemType}');
      }
      debugPrint('Successfully update package: $packageName');
    } catch (e) {
      if (kDebugMode) {
        print('Error installing source: $e');
      }
      rethrow;
    }
  }

  void _removeFromInstalledList(Source source) {
    switch (source.itemType) {
      case ItemType.anime:
        installedAnimeExtensions.value = installedAnimeExtensions.value
            .where((e) => e.name != source.name)
            .toList();
        break;
      case ItemType.manga:
        installedMangaExtensions.value = installedMangaExtensions.value
            .where((e) => e.name != source.name)
            .toList();
        break;
      case ItemType.novel:
        installedNovelExtensions.value = installedNovelExtensions.value
            .where((e) => e.name != source.name)
            .toList();
        break;
      case null:
        break;
    }
  }

  Rx<List<Source>> getAvailableUnmodified(ItemType type) {
    switch (type) {
      case ItemType.anime:
        return availableAnimeExtensionsUnmodified;
      case ItemType.manga:
        return availableMangaExtensionsUnmodified;
      case ItemType.novel:
        return availableNovelExtensionsUnmodified;
    }
  }

  Future<void> checkForUpdates(ItemType type) async {
    final availableMap = {
      for (var s in getAvailableUnmodified(type).value) s.id: s,
    };

    final updated = getInstalledRx(type).value.map((installed) {
      final avail = availableMap[installed.id ?? ''];
      if (avail != null &&
          installed.version != null &&
          avail.version != null &&
          compareVersions(installed.version!, avail.version!) < 0) {
        return installed
          ..hasUpdate = true
          ..apkUrl = avail.apkUrl
          ..versionLast = avail.version;
      }
      return installed;
    }).toList();

    getInstalledRx(type).value = updated;
  }

  static String getAnimeApkUrl(String iconUrl, String apkName) {
    if (iconUrl.isEmpty || apkName.isEmpty) return "";

    final baseUrl = iconUrl.replaceFirst('icon/', 'apk/');
    final lastSlash = baseUrl.lastIndexOf('/');
    if (lastSlash == -1) return "";

    final cleanedUrl = baseUrl.substring(0, lastSlash);
    return '$cleanedUrl/$apkName';
  }
}
