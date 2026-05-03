import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/providers/storage_provider.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart'
    as bridge;
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/providers/inbuilt_sources_provider.dart';

final extensionManagerProvider = Provider<bridge.ExtensionManager>((ref) {
  final manager = Get.find<bridge.ExtensionManager>();
  final type = ref.watch(managerTypeProvider);
  manager.setCurrentManager(type);
  return manager;
}, name: 'extensionManagerProvider');

final managerTypeProvider =
    NotifierProvider<ManagerTypeNotifier, bridge.ExtensionType>(
      ManagerTypeNotifier.new,
      name: 'managerTypeProvider',
    );

class ManagerTypeNotifier extends Notifier<bridge.ExtensionType> {
  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  bridge.ExtensionType build() {
    final saved = _storage.getString('currentManager');
    if (saved != null) {
      return bridge.ExtensionType.fromString(saved);
    }
    return bridge.ExtensionType.mangayomi;
  }

  void setType(bridge.ExtensionType type) {
    if (!Platform.isAndroid && type == bridge.ExtensionType.aniyomi) return;
    state = type;
    _saveDb();
  }

  void _saveDb() {
    _storage.setString('currentManager', state.toString());
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
          ),
        )
        .toList();

    try {
      final manager = ref.read(extensionManagerProvider);
      final extensionsRaw =
          manager.currentManager.installedAnimeExtensions.value;

      final extensions = extensionsRaw
          .map(
            (ext) => SourceInfo(
              id: ext.id ?? "Unknown",
              name: ext.name ?? "Unknown",
              type: SourceType.extension,
              iconUrl: ext.iconUrl,
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
