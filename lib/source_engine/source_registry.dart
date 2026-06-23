import 'dart:io';

import 'package:anymex_extension_runtime_bridge/Services/Aniyomi/AniyomiExtensions.dart';
import 'package:anymex_extension_runtime_bridge/Services/AniyomiDesktop/DesktopAniyomiExtensions.dart';
import 'package:anymex_extension_runtime_bridge/Services/Mangayomi/MangayomiExtensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/providers/storage_provider.dart';
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

    if (saved == 'aniyomi' || saved == 'aniyomi-desktop') {
      return Platform.isAndroid
          ? _manager.get<AniyomiExtensions>()
          : _manager.get<DesktopAniyomiExtensions>();
    }

    return _manager.get<MangayomiExtensions>();
  }

  void setManager(String id) {
    final effectiveId = (!Platform.isAndroid && id == 'aniyomi')
        ? 'aniyomi-desktop'
        : id;

    if (state.id == effectiveId) {
      return;
    }

    final newExtension = id.contains('mangayomi')
        ? _manager.get<MangayomiExtensions>()
        : (Platform.isAndroid
              ? _manager.get<AniyomiExtensions>()
              : _manager.get<DesktopAniyomiExtensions>());

    state = newExtension;
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
            ),
          )
          .toList();

      return [...inbuilt, ...extensions];
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
            ),
          )
          .toList();

      return [...inbuilt, ...extensions];
    } catch (e) {
      return inbuilt;
    }
  },
  name: 'availableMangaSourcesProvider',
);

final allAvailableSourcesProvider = FutureProvider<List<SourceInfo>>((ref) async {
  final animeSources = await ref.watch(availableAnimeSourcesProvider.future);
  final mangaSources = await ref.watch(availableMangaSourcesProvider.future);
  return [...animeSources, ...mangaSources];
}, name: 'allAvailableSourcesProvider');
