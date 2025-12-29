import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/core/registery/anime_source_registery.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';

const selectedProviderBox = 'selected_provider';
const selectedProviderKey = 'selected_key';

final animeSourceRegistryProvider = Provider<AnimeSourceRegistry>((ref) {
  return AnimeSourceRegistry().initialize();
});

final selectedProviderKeyProvider =
    NotifierProvider<SelectedProviderKeyNotifier, String?>(
  SelectedProviderKeyNotifier.new,
);

class SelectedProviderKeyNotifier extends Notifier<String?> {
  late Box<String> _box;

  @override
  String? build() {
    if (!Hive.isBoxOpen(selectedProviderBox)) {
      Hive.openBox<String>(selectedProviderBox);
    }
    _box = Hive.box<String>(selectedProviderBox);
    AppLogger.d('Selected provider key: ${_box.get(selectedProviderKey)}');
    return _box.get(selectedProviderKey);
  }

  void select(String key) {
    _box.put(selectedProviderKey, key);
    state = key;
  }

  void clear() {
    _box.delete(selectedProviderKey);
    state = null;
  }
}

final selectedAnimeProvider = Provider<AnimeProvider?>((ref) {
  final registry = ref.watch(animeSourceRegistryProvider);
  final key = ref.watch(selectedProviderKeyProvider);
  return key != null ? registry.get(key) : null;
});
