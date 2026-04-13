import 'package:get/get.dart';

import '../Models/Source.dart';

abstract class Extension extends GetxController {
  var isInitialized = false.obs;

  bool get supportsAnime => true;
  bool get supportsManga => true;
  bool get supportsNovel => true;

  final Rx<List<Source>> installedAnimeExtensions = Rx([]);
  final Rx<List<Source>> installedMangaExtensions = Rx([]);
  final Rx<List<Source>> installedNovelExtensions = Rx([]);
  final Rx<List<Source>> availableAnimeExtensions = Rx([]);
  final Rx<List<Source>> availableMangaExtensions = Rx([]);
  final Rx<List<Source>> availableNovelExtensions = Rx([]);

  Future<List<Source>> getInstalledAnimeExtensions() => Future.value([]);

  Future<List<Source>> fetchAvailableAnimeExtensions(List<String>? repos) =>
      Future.value([]);

  Future<List<Source>> getInstalledMangaExtensions() => Future.value([]);

  Future<List<Source>> fetchAvailableMangaExtensions(List<String>? repos) =>
      Future.value([]);

  Future<List<Source>> getInstalledNovelExtensions() => Future.value([]);

  Future<List<Source>> fetchAvailableNovelExtensions(List<String>? repos) =>
      Future.value([]);

  Future<void> initialize();

  Future<void> installSource(Source source);

  Future<void> uninstallSource(Source source);

  Future<void> updateSource(Source source);

  Future<void> onRepoSaved(List<String> repoUrl, ItemType type) async {
    if (repoUrl.isEmpty) return;
    switch (type) {
      case ItemType.anime:
        await fetchAvailableAnimeExtensions(repoUrl);
        break;
      case ItemType.manga:
        await fetchAvailableMangaExtensions(repoUrl);
        break;
      case ItemType.novel:
        await fetchAvailableNovelExtensions(repoUrl);
        break;
    }
  }

  Rx<List<Source>> getSortedInstalledExtension(ItemType itemType) {
    switch (itemType) {
      case ItemType.anime:
        return installedAnimeExtensions;
      case ItemType.manga:
        return installedMangaExtensions;
      case ItemType.novel:
        return installedNovelExtensions;
    }
  }

  Rx<List<Source>> getAvailableRx(ItemType type) {
    switch (type) {
      case ItemType.anime:
        return availableAnimeExtensions;
      case ItemType.manga:
        return availableMangaExtensions;
      case ItemType.novel:
        return availableNovelExtensions;
    }
  }

  Rx<List<Source>> getInstalledRx(ItemType type) {
    switch (type) {
      case ItemType.anime:
        return installedAnimeExtensions;
      case ItemType.manga:
        return installedMangaExtensions;
      case ItemType.novel:
        return installedNovelExtensions;
    }
  }

  int compareVersions(String v1, String v2) {
    final a = v1.split('.').map(int.tryParse).toList();
    final b = v2.split('.').map(int.tryParse).toList();

    for (int i = 0; i < a.length || i < b.length; i++) {
      final n1 = i < a.length ? a[i] ?? 0 : 0;
      final n2 = i < b.length ? b[i] ?? 0 : 0;
      if (n1 != n2) return n1.compareTo(n2);
    }
    return 0;
  }
}
