import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

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

  List<ExtRepo> getAllRepos() {
    final repos = <ExtRepo>[];
    final urls = <String>[];

    for (final m in _bridgeManager.managers) {
      final mId = m.id.replaceAll('-desktop', '');

      final aRepos = m.getReposRx(bridge.ItemType.anime).value;
      final mRepos = m.getReposRx(bridge.ItemType.manga).value;
      final nRepos = m.getReposRx(bridge.ItemType.novel).value;

      for (final r in [...aRepos, ...mRepos, ...nRepos]) {
        urls.add(r.url);
        repos.add(
          ExtRepo(
            name: r.name ?? Uri.tryParse(r.url)?.host ?? 'Custom Repo',
            url: r.url,
            managerId: r.managerId ?? mId,
          ),
        );
      }
    }
    return repos;
  }

  Future<bool> addRepo(
    String url,
    String engineId,
    bridge.ItemType type,
  ) async {
    final targetManager =
        _bridgeManager.findById(engineId) ??
        _bridgeManager.findById('$engineId-desktop');
    if (targetManager == null) return false;

    try {
      await targetManager.addRepo(url, type);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeRepo(String url, String engineId) async {
    final targetManager =
        _bridgeManager.findById(engineId) ??
        _bridgeManager.findById('$engineId-desktop');
    if (targetManager == null) return false;

    try {
      await targetManager.removeRepo(url, bridge.ItemType.anime);
      await targetManager.removeRepo(url, bridge.ItemType.manga);
      await targetManager.removeRepo(url, bridge.ItemType.novel);
      return true;
    } catch (_) {
      return false;
    }
  }
}
