import 'dart:io';

import 'package:anymex_extension_runtime_bridge/Services/Mangayomi/MangayomiExtensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/providers/inbuilt_sources_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

final extensionManagerProvider =
    NotifierProvider<ExtensionManagerNotifier, bridge.Extension>(
      ExtensionManagerNotifier.new,
    );

class ExtensionManagerNotifier extends Notifier<bridge.Extension> {
  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  static const _key = 'currentManager';

  late final bridge.ExtensionManager _manager =
      Get.find<bridge.ExtensionManager>();

  @override
  bridge.Extension build() {
    final saved = _storage.getString(_key);

    if (saved == 'cloudstream' || saved == 'cloudstream-desktop') {
      final ext = _manager.findById(
        Platform.isAndroid ? 'cloudstream' : 'cloudstream-desktop',
      );
      if (ext != null) return ext;
    }

    if (saved == 'aniyomi' || saved == 'aniyomi-desktop' || saved == null) {
      final ext = _manager.findById(
        Platform.isAndroid ? 'aniyomi' : 'aniyomi-desktop',
      );
      if (ext != null) return ext;
    }

    return _manager.get<MangayomiExtensions>();
  }

  void setManager(String id) {
    String effectiveId = id;
    if (!Platform.isAndroid) {
      if (id == 'aniyomi') effectiveId = 'aniyomi-desktop';
      if (id == 'cloudstream') effectiveId = 'cloudstream-desktop';
    }

    if (state.id == effectiveId) {
      return;
    }

    final ext = _manager.findById(effectiveId);
    if (ext != null) {
      state = ext;
    } else {
      state = _manager.get<MangayomiExtensions>();
    }
    _storage.setString(_key, effectiveId);
  }
}

final availableAnimeSourcesProvider = FutureProvider<List<SourceInfo>>(
  retry: (retryCount, error) => null,
  (ref) async {
    final inbuilt = ref
        .read(inbuiltAnimeSourcesProvider)
        .map(
          (s) => SourceInfo(
            id: s.sourceInfo.id,
            name: s.sourceInfo.name,
            type: SourceType.inbuilt,
            mediaType: MediaType.ANIME,
            iconUrl: s.sourceInfo.iconUrl,
          ),
        )
        .toList();

    try {
      final manager = ref.read(extensionManagerProvider);
      final extensionsRaw = manager.getInstalledRx(bridge.ItemType.anime).value;

      final extensions = extensionsRaw
          .map(
            (ext) => SourceInfo(
              id: ext.id ?? "Unknown",
              name: ext.name ?? "Unknown",
              type: SourceType.extension,
              mediaType: MediaType.ANIME,
              iconUrl: ext.iconUrl,
              lang: ext.lang,
              isNsfw: ext.isNsfw ?? false,
            ),
          )
          .toList();

      final allSources = [...inbuilt, ...extensions];
      try {
        final prefs = ref.read(sharedPreferencesProvider);
        final order = prefs.getStringList('source_order_ANIME') ?? [];
        if (order.isNotEmpty) {
          final orderMap = {for (int i = 0; i < order.length; i++) order[i]: i};
          allSources.sort((a, b) {
            final indexA = orderMap[a.id] ?? 9999;
            final indexB = orderMap[b.id] ?? 9999;
            return indexA.compareTo(indexB);
          });
        }
      } catch (_) {}
      return allSources;
    } catch (e) {
      return inbuilt;
    }
  },
  name: 'availableAnimeSourcesProvider',
);

final availableMangaSourcesProvider = FutureProvider<List<SourceInfo>>(
  retry: (retryCount, error) => null,
  (ref) async {
    final inbuilt = ref
        .read(inbuiltMangaSourcesProvider)
        .map(
          (s) => SourceInfo(
            id: s.sourceInfo.id,
            name: s.sourceInfo.name,
            type: SourceType.inbuilt,
            mediaType: MediaType.MANGA,
          ),
        )
        .toList();

    try {
      final manager = ref.read(extensionManagerProvider);
      final extensionsRaw = manager.getInstalledRx(bridge.ItemType.manga).value;

      final extensions = extensionsRaw
          .map(
            (ext) => SourceInfo(
              id: ext.id ?? "Unknown",
              name: ext.name ?? "Unknown",
              type: SourceType.extension,
              mediaType: MediaType.MANGA,
              iconUrl: ext.iconUrl,
              lang: ext.lang,
              isNsfw: ext.isNsfw ?? false,
            ),
          )
          .toList();

      final allSources = [...inbuilt, ...extensions];
      try {
        final prefs = ref.read(sharedPreferencesProvider);
        final order = prefs.getStringList('source_order_MANGA') ?? [];
        if (order.isNotEmpty) {
          final orderMap = {for (int i = 0; i < order.length; i++) order[i]: i};
          allSources.sort((a, b) {
            final indexA = orderMap[a.id] ?? 9999;
            final indexB = orderMap[b.id] ?? 9999;
            return indexA.compareTo(indexB);
          });
        }
      } catch (_) {}
      return allSources;
    } catch (e) {
      return inbuilt;
    }
  },
  name: 'availableMangaSourcesProvider',
);

final allAvailableSourcesProvider = FutureProvider<List<SourceInfo>>((
  ref,
) async {
  final animeSources = await ref.watch(availableAnimeSourcesProvider.future);
  final mangaSources = await ref.watch(availableMangaSourcesProvider.future);
  return [...animeSources, ...mangaSources];
}, name: 'allAvailableSourcesProvider');
