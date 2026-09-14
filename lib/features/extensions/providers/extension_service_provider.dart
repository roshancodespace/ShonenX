import 'dart:async';

import 'package:anymex_extension_runtime_bridge/Settings/KvStore.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
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

  static final _log = AppLogger.scope('ExtensionAdapter');

  // --- URL helpers ---

  /// Canonical key for deduplication/comparison.
  static String repoKey(String url) {
    var key = url.trim().toLowerCase();
    // Strip trailing slashes and fragments/query.
    final uri = Uri.tryParse(key);
    if (uri != null && uri.hasScheme) {
      key = uri.replace(fragment: '', query: '').toString();
    }
    if (key.endsWith('/')) key = key.substring(0, key.length - 1);
    return key;
  }

  static String normalizeRepoUrl(String input, String engineId) {
    var url = input.trim();
    if (url.isEmpty) return url;

    // GitHub blob/tree → raw.
    if (url.startsWith('https://github.com/')) {
      url = url
          .replaceFirst(
            'https://github.com/',
            'https://raw.githubusercontent.com/',
          )
          .replaceFirst('/blob/', '/')
          .replaceFirst('/tree/', '/');
    }

    // Ensure scheme.
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('cloudstreamrepo://')) {
      url = 'https://$url';
    }

    final lower = url.toLowerCase();
    final engine = engineId.replaceAll('-desktop', '').toLowerCase();

    if (engine == 'aniyomi' || engine == 'tachiyomi') {
      if (!lower.endsWith('.json') &&
          !lower.endsWith('.pb') &&
          !lower.endsWith('.pb.gz')) {
        url = url.endsWith('/')
            ? '${url}index.min.json'
            : '$url/index.min.json';
      }
    } else if (engine == 'mangayomi') {
      if (!lower.endsWith('.json')) {
        url = url.endsWith('/') ? '${url}index.json' : '$url/index.json';
      }
    } else if (engine == 'cloudstream') {
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

    // *.github.io or *.gitlab.io user pages.
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

    // Known Git platforms.
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

  // --- Repo CRUD ---

  List<ExtRepo> getAllRepos() {
    final seen = <String>{};
    final repos = <ExtRepo>[];

    for (final m in _bridgeManager.managers) {
      final mId = m.id.replaceAll('-desktop', '');

      for (final type in bridge.ItemType.values) {
        for (final r in m.getReposRx(type).value) {
          if (seen.add(repoKey(r.url))) {
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
    }

    return repos;
  }

  Future<bool> addRepo(
    String url,
    String engineId,
    bridge.ItemType type,
  ) async {
    final normalizedUrl = normalizeRepoUrl(url, engineId);
    final manager = _resolveManager(engineId);

    if (manager == null) {
      final name = _getEngineDisplayName(engineId);
      throw Exception(
        '$name engine is not initialized. '
        'On desktop, please ensure the AnymeX Runtime Host is downloaded and ready.',
      );
    }

    try {
      await manager.addRepo(normalizedUrl, type);
      return true;
    } catch (e, st) {
      _log
          .child('addRepo')
          .e('Failed to add $normalizedUrl to $engineId', e, st);
      if (e.toString().contains('Failed to fetch repo')) {
        throw Exception(
          'Failed to fetch repository from $normalizedUrl. '
          'Please verify the URL is valid and accessible.',
        );
      }
      rethrow;
    }
  }

  Future<bool> removeRepo(
    String url,
    String engineId, [
    bridge.ItemType? type,
  ]) async {
    final manager = _resolveManager(engineId);
    if (manager == null) {
      _log.child('removeRepo').w('Manager not found for $engineId');
      return false;
    }

    final cleanUrl = url.trim();

    try {
      if (type != null) {
        await manager.removeRepo(cleanUrl, type);
      } else {
        // Type unknown — try each. Bridge removeRepo is safe for non-existent URLs.
        for (final t in bridge.ItemType.values) {
          final repos = manager.getReposRx(t).value;
          if (repos.any((r) => repoKey(r.url) == repoKey(cleanUrl))) {
            await manager.removeRepo(cleanUrl, t);
          }
        }
      }
      return true;
    } catch (e, st) {
      _log.child('removeRepo').e('Failed to remove $url from $engineId', e, st);
      return false;
    }
  }

  Future<void> clearAllRepos() async {
    for (final m in _bridgeManager.managers) {
      for (final type in bridge.ItemType.values) {
        final repos = List.of(m.getReposRx(type).value);
        for (final r in repos) {
          try {
            await m.removeRepo(r.url, type);
          } catch (e) {
            _log.child('clearAllRepos').w('Failed to remove ${r.url}: $e');
          }
        }
        // Ensure Rx is empty even if removeRepo didn't clear it fully.
        m.getReposRx(type).value = const [];
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
          } catch (e) {
            _log
                .child('uninstallAllExtensions')
                .w('Failed to uninstall ${source.name}: $e');
          }
        }
        m.getInstalledRx(type).value = const [];
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
    } catch (e, st) {
      _log
          .child('resetExtensionPreferencesAndCache')
          .e('Failed to clear Isar entries', e, st);
    }

    for (final m in _bridgeManager.managers) {
      try {
        if (m.supportsAnime) unawaited(m.fetchAnimeExtensions());
        if (m.supportsManga) unawaited(m.fetchMangaExtensions());
        if (m.supportsNovel) unawaited(m.fetchNovelExtensions());
      } catch (e) {
        _log
            .child('resetExtensionPreferencesAndCache')
            .w('Re-fetch failed for ${m.id}: $e');
      }
    }
  }

  // --- Internals ---

  bridge.Extension? _resolveManager(String engineId) {
    return _bridgeManager.findById(engineId) ??
        _bridgeManager.findById('$engineId-desktop');
  }

  String _getEngineDisplayName(String id) {
    final clean = id.replaceAll('-desktop', '').toLowerCase();
    return switch (clean) {
      'mangayomi' => 'Mangayomi',
      'aniyomi' => 'Tachiyomi / Aniyomi',
      'cloudstream' => 'CloudStream',
      'kotatsu' => 'Kotatsu',
      'sora' => 'Sora',
      _ => id.toUpperCase(),
    };
  }
}
