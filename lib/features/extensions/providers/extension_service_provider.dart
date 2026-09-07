import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:anymex_extension_runtime_bridge/Settings/KvStore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class ExtRepo {
  final String name;
  final String url;
  final String managerId;

  ExtRepo({required this.name, required this.url, required this.managerId});
}

final extensionAdapterProvider = Provider<ExtensionAdapter>(
  (ref) => ExtensionAdapter(),
);

final activeExtReposProvider = Provider<List<ExtRepo>>((ref) {
  final adapter = ref.watch(extensionAdapterProvider);
  return adapter.getAllRepos();
});

class ExtensionAdapter {
  bridge.ExtensionManager get _bridgeManager =>
      Get.find<bridge.ExtensionManager>();

  static const _repoKeysWithEngine = [
    ('aniyomianimeRepos', 'aniyomi', bridge.ItemType.anime),
    ('aniyomimangaRepos', 'aniyomi', bridge.ItemType.manga),
    ('aniyominovelRepos', 'aniyomi', bridge.ItemType.novel),
    ('aniyomianimeReposV2', 'aniyomi', bridge.ItemType.anime),
    ('aniyomimangaReposV2', 'aniyomi', bridge.ItemType.manga),
    ('mangayomianimeRepos', 'mangayomi', bridge.ItemType.anime),
    ('mangayomimangaRepos', 'mangayomi', bridge.ItemType.manga),
    ('mangayominovelRepos', 'mangayomi', bridge.ItemType.novel),
    ('cloudstreamAnimeRepos', 'cloudstream', bridge.ItemType.anime),
    ('desktopCloudstreamAnimeRepos', 'cloudstream', bridge.ItemType.anime),
    ('kotatsuRepos', 'kotatsu', bridge.ItemType.manga),
    ('desktopKotatsuRepos', 'kotatsu', bridge.ItemType.manga),
    ('soraanimeRepos', 'sora', bridge.ItemType.anime),
    ('soramangaRepos', 'sora', bridge.ItemType.manga),
    ('soranovelRepos', 'sora', bridge.ItemType.novel),
  ];

  static String normalizeRepoUrl(String input, String engineId) {
    var url = input.trim();
    if (url.isEmpty) return url;

    // Convert github web links:
    if (url.startsWith('https://github.com/')) {
      if (url.contains('/blob/')) {
        url = url
            .replaceFirst(
              'https://github.com/',
              'https://raw.githubusercontent.com/',
            )
            .replaceFirst('/blob/', '/');
      } else if (url.contains('/tree/')) {
        url = url
            .replaceFirst(
              'https://github.com/',
              'https://raw.githubusercontent.com/',
            )
            .replaceFirst('/tree/', '/');
      }
    }

    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('cloudstreamrepo://')) {
      url = 'https://$url';
    }

    final lower = url.toLowerCase();
    final cleanEngine = engineId.replaceAll('-desktop', '').toLowerCase();

    if (cleanEngine == 'aniyomi' || cleanEngine == 'tachiyomi') {
      if (!lower.endsWith('.json') &&
          !lower.endsWith('.pb') &&
          !lower.endsWith('.pb.gz')) {
        url = url.endsWith('/')
            ? '${url}index.min.json'
            : '$url/index.min.json';
      }
    } else if (cleanEngine == 'mangayomi') {
      if (!lower.endsWith('.json')) {
        url = url.endsWith('/') ? '${url}index.json' : '$url/index.json';
      }
    } else if (cleanEngine == 'cloudstream') {
      if (url.startsWith('cloudstreamrepo://')) {
        url = url.replaceFirst('cloudstreamrepo://', '');
      }
    }

    return url;
  }

  static String extractRepoDisplayName(String url, [String? fallback]) {
    if (fallback != null && fallback.trim().isNotEmpty) {
      final clean = fallback.trim();
      final lower = clean.toLowerCase();
      final isGenericHostOrUrl =
          lower.startsWith('http://') ||
          lower.startsWith('https://') ||
          lower == 'raw.githubusercontent.com' ||
          lower == 'github.com' ||
          lower == 'gitlab.com' ||
          lower == 'codeberg.org' ||
          lower == 'bitbucket.org' ||
          lower == 'custom repo' ||
          lower.endsWith('.json') ||
          lower.endsWith('.pb') ||
          lower.endsWith('.pb.gz');
      if (!isGenericHostOrUrl) {
        return clean;
      }
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return fallback?.trim().isNotEmpty == true ? fallback! : 'Custom Repo';
    }

    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    // Check for *.github.io or *.gitlab.io user pages (e.g. keiyoushi.github.io)
    if (host.endsWith('.github.io') || host.endsWith('.gitlab.io')) {
      final parts = host.split('.');
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        final username = parts.first;
        if (segments.isNotEmpty &&
            !segments[0].endsWith('.json') &&
            !segments[0].endsWith('.pb') &&
            !segments[0].endsWith('.gz')) {
          return '$username / ${segments[0]}';
        }
        return username;
      }
    }

    // Known Git platforms
    const gitHosts = {
      'github.com',
      'raw.githubusercontent.com',
      'gitlab.com',
      'codeberg.org',
      'bitbucket.org',
      'gist.github.com',
      'gist.githubusercontent.com',
    };

    if (gitHosts.contains(host) && segments.isNotEmpty) {
      final username = segments[0];
      if (username.isNotEmpty) {
        if (segments.length >= 2 &&
            !segments[1].endsWith('.json') &&
            !segments[1].endsWith('.pb') &&
            !segments[1].endsWith('.gz')) {
          return '$username / ${segments[1]}';
        }
        return username;
      }
    }

    return uri.host.isNotEmpty
        ? uri.host
        : (fallback?.trim().isNotEmpty == true ? fallback! : 'Custom Repo');
  }

  void syncAllRepos() {
    for (final entry in _repoKeysWithEngine) {
      final key = entry.$1;
      final engineId = entry.$2;
      final type = entry.$3;

      final encoded = getVal<List<String>>(key);
      if (encoded == null || encoded.isEmpty) continue;

      final targetManager =
          _bridgeManager.findById(engineId) ??
          _bridgeManager.findById('$engineId-desktop');
      if (targetManager == null) continue;

      final parsed = <bridge.Repo>[];
      for (final item in encoded) {
        try {
          final decoded = jsonDecode(item);
          parsed.add(bridge.Repo.fromJson(Map<String, dynamic>.from(decoded)));
        } catch (_) {}
      }

      if (parsed.isNotEmpty) {
        final current = targetManager.getReposRx(type).value;
        final merged = {
          for (final r in current) r.url: r,
          for (final r in parsed) r.url: r,
        }.values.toList(growable: false);
        targetManager.getReposRx(type).value = merged;
      }
    }
  }

  List<ExtRepo> getAllRepos() {
    syncAllRepos();

    final repos = <ExtRepo>[];
    final seenUrls = <String>{};

    // 1. Gather from active bridge managers
    for (final m in _bridgeManager.managers) {
      final mId = m.id.replaceAll('-desktop', '');

      final aRepos = m.getReposRx(bridge.ItemType.anime).value;
      final mRepos = m.getReposRx(bridge.ItemType.manga).value;
      final nRepos = m.getReposRx(bridge.ItemType.novel).value;

      for (final r in [...aRepos, ...mRepos, ...nRepos]) {
        if (seenUrls.add(r.url.toLowerCase())) {
          repos.add(
            ExtRepo(
              name: extractRepoDisplayName(r.url, r.name),
              url: r.url,
              managerId: r.managerId ?? mId,
            ),
          );
        }
      }
    }

    // 2. Also check KvStore entries directly in case any manager failed to load
    for (final entry in _repoKeysWithEngine) {
      final key = entry.$1;
      final engineId = entry.$2;

      final encoded = getVal<List<String>>(key);
      if (encoded == null || encoded.isEmpty) continue;

      for (final item in encoded) {
        try {
          final decoded = jsonDecode(item);
          final r = bridge.Repo.fromJson(Map<String, dynamic>.from(decoded));
          if (seenUrls.add(r.url.toLowerCase())) {
            repos.add(
              ExtRepo(
                name: extractRepoDisplayName(r.url, r.name),
                url: r.url,
                managerId: r.managerId ?? engineId,
              ),
            );
          }
        } catch (_) {}
      }
    }

    return repos;
  }

  Future<bool> addRepo(
    String url,
    String engineId,
    bridge.ItemType type,
  ) async {
    final normalizedUrl = normalizeRepoUrl(url, engineId);
    final targetManager =
        _bridgeManager.findById(engineId) ??
        _bridgeManager.findById('$engineId-desktop');

    if (targetManager == null) {
      final engineName = _getEngineDisplayName(engineId);
      throw Exception(
        '$engineName engine is not initialized. On desktop, please ensure the AnymeX Runtime Host is downloaded and ready.',
      );
    }

    try {
      await targetManager.addRepo(normalizedUrl, type);

      // Verify that the manager updated its getReposRx
      final rx = targetManager.getReposRx(type);
      if (!rx.value.any((r) => r.url == normalizedUrl)) {
        final repo = bridge.Repo(
          url: normalizedUrl,
          managerId: targetManager.id,
        );
        rx.value = [...rx.value, repo];
      }

      // Persist fallback in KvStore
      _persistRepoFallback(normalizedUrl, targetManager.id, type);

      return true;
    } catch (e, st) {
      AppLogger.scope('ExtensionAdapter')
          .child('addRepo')
          .e('Failed to add repo $normalizedUrl to $engineId', e, st);
      if (e.toString().contains('Failed to fetch repo')) {
        throw Exception(
          'Failed to fetch repository from $normalizedUrl. Please verify the URL is valid and accessible.',
        );
      }
      rethrow;
    }
  }

  void _persistRepoFallback(
    String url,
    String managerId,
    bridge.ItemType type,
  ) {
    try {
      final clean = managerId.replaceAll('-desktop', '');
      String key;
      if (clean == 'aniyomi') {
        key = 'aniyomi${type.name}Repos';
      } else if (clean == 'mangayomi') {
        key = 'mangayomi${type.name}Repos';
      } else if (clean == 'cloudstream') {
        key = Platform.isAndroid
            ? 'cloudstreamAnimeRepos'
            : 'desktopCloudstreamAnimeRepos';
      } else if (clean == 'kotatsu') {
        key = Platform.isAndroid ? 'kotatsuRepos' : 'desktopKotatsuRepos';
      } else {
        key = 'sora${type.name}Repos';
      }

      final existing = getVal<List<String>>(key) ?? [];
      final repoObj = bridge.Repo(url: url, managerId: managerId);
      final jsonStr = jsonEncode(repoObj.toJson());
      if (!existing.any((e) => e.contains(url))) {
        setVal(key, [...existing, jsonStr]);
      }
    } catch (_) {}
  }

  Future<bool> removeRepo(String url, String engineId) async {
    final targetManager =
        _bridgeManager.findById(engineId) ??
        _bridgeManager.findById('$engineId-desktop');

    final cleanUrl = url.trim();
    final cleanBase = cleanUrl
        .replaceAll('/index.min.json', '')
        .replaceAll('/index.json', '');

    try {
      if (targetManager != null) {
        for (final type in bridge.ItemType.values) {
          try {
            await targetManager.removeRepo(cleanUrl, type);
          } catch (_) {}
          try {
            await targetManager.removeRepo(cleanBase, type);
          } catch (_) {}

          final rx = targetManager.getReposRx(type);
          rx.value = rx.value
              .where(
                (r) =>
                    r.url != cleanUrl &&
                    r.url != cleanBase &&
                    !r.url.startsWith(cleanBase),
              )
              .toList();
        }
      }

      // Remove from KvStore keys as well
      for (final entry in _repoKeysWithEngine) {
        final key = entry.$1;
        final eId = entry.$2;
        if (eId == engineId.replaceAll('-desktop', '')) {
          final list = getVal<List<String>>(key);
          if (list != null && list.isNotEmpty) {
            final filtered = list
                .where((e) => !e.contains(cleanUrl) && !e.contains(cleanBase))
                .toList();
            setVal(key, filtered);
          }
        }
      }

      return true;
    } catch (e, st) {
      AppLogger.scope('ExtensionAdapter')
          .child('removeRepo')
          .e('Failed to remove repo $url from $engineId', e, st);
      return false;
    }
  }

  Future<void> clearAllRepos() async {
    // 1. Wipe all known repo keys from KvStore
    for (final entry in _repoKeysWithEngine) {
      final key = entry.$1;
      try {
        await KvStore.remove(key);
      } catch (_) {
        setVal(key, <String>[]);
      }
    }

    // 2. Reset in-memory repos and available sources for all active managers
    for (final m in _bridgeManager.managers) {
      for (final type in bridge.ItemType.values) {
        try {
          m.getReposRx(type).value = const [];
        } catch (_) {}
        try {
          m.getAvailableRx(type).value = const [];
          m.getRawAvailableRx(type).value = const [];
        } catch (_) {}
      }
    }
  }

  Future<void> uninstallAllExtensions() async {
    for (final m in _bridgeManager.managers) {
      for (final type in bridge.ItemType.values) {
        final installed = List.of(m.getInstalledRx(type).value);
        for (final source in installed) {
          try {
            await m.uninstallSource(source);
          } catch (_) {}
        }
        m.getInstalledRx(type).value = const [];
      }
    }

    // Clear stored installed list keys in KvStore
    final installedKeys = [
      'mangayomi-Installed-anime',
      'mangayomi-Installed-manga',
      'mangayomi-Installed-novel',
      'sora-Installed-anime',
      'sora-Installed-manga',
      'sora-Installed-novel',
      'kotatsu_active_sources',
    ];
    for (final key in installedKeys) {
      try {
        await KvStore.remove(key);
      } catch (_) {
        setVal(key, <String>[]);
      }
    }
  }

  Future<void> resetExtensionPreferencesAndCache() async {
    try {
      final isar = bridge.AnymeXExtensionBridge.context.isar;
      await isar.writeTxn(() async {
        final allEntries = await isar.kvEntrys.where().findAll();
        final toDelete = allEntries
            .where(
              (e) =>
                  e.key.startsWith('sourcePrefs_') ||
                  e.key.startsWith('cs_meta_') ||
                  e.key.startsWith('desktop_cs_meta_') ||
                  e.key.startsWith('desktop_ext_version_') ||
                  e.key.startsWith('desktop_ext_icon_'),
            )
            .map((e) => e.id)
            .toList();
        await isar.kvEntrys.deleteAll(toDelete);
      });
    } catch (_) {}

    // Re-fetch extensions across all managers
    for (final m in _bridgeManager.managers) {
      try {
        if (m.supportsAnime) unawaited(m.fetchAnimeExtensions());
        if (m.supportsManga) unawaited(m.fetchMangaExtensions());
        if (m.supportsNovel) unawaited(m.fetchNovelExtensions());
      } catch (_) {}
    }
  }

  String _getEngineDisplayName(String id) {
    final clean = id.replaceAll('-desktop', '').toLowerCase();
    switch (clean) {
      case 'mangayomi':
        return 'Mangayomi';
      case 'aniyomi':
        return 'Tachiyomi / Aniyomi';
      case 'cloudstream':
        return 'CloudStream';
      case 'kotatsu':
        return 'Kotatsu';
      case 'sora':
        return 'Sora';
      default:
        return id.toUpperCase();
    }
  }
}
