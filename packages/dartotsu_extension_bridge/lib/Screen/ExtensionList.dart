import 'package:dartotsu_extension_bridge/Settings/Settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ExtensionManager.dart';
import '../Models/Source.dart';
import '../extension_bridge.dart';

abstract class ExtensionConfig {
  ItemType get itemType;
  bool get isInstalled;
  String get searchQuery;
  String get selectedLanguage;
}

abstract class ExtensionList<T extends StatefulWidget> extends State<T> {
  final ScrollController controller = ScrollController();

  final manager = Get.find<ExtensionManager>().currentManager;

  late List<String> sortedList;

  ExtensionConfig get config => widget as ExtensionConfig;

  ItemType get itemType => config.itemType;
  bool get isInstalled => config.isInstalled;
  String get searchQuery => config.searchQuery;
  String get selectedLanguage => config.selectedLanguage;

  @override
  void initState() {
    super.initState();

    final settings = isar.bridgeSettings.getSync(26) ?? BridgeSettings();

    sortedList = switch (itemType) {
      ItemType.anime => settings.sortedAnimeExtensions,
      ItemType.manga => settings.sortedMangaExtensions,
      ItemType.novel => settings.sortedNovelExtensions,
    };
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {}

  List<Source> _getBaseList() {
    return switch (itemType) {
      ItemType.anime =>
        isInstalled
            ? manager.installedAnimeExtensions.value
            : manager.availableAnimeExtensions.value,
      ItemType.manga =>
        isInstalled
            ? manager.installedMangaExtensions.value
            : manager.availableMangaExtensions.value,
      ItemType.novel =>
        isInstalled
            ? manager.installedNovelExtensions.value
            : manager.availableNovelExtensions.value,
    };
  }

  List<Source> _applyFilters(List<Source> list) {
    final query = searchQuery.toLowerCase();
    final langFilter = (selectedLanguage.toLowerCase() == 'all')
        ? null
        : selectedLanguage;

    return list.where((source) {
      final lang = source.lang ?? 'Unknown';

      if (langFilter != null && lang != langFilter) return false;

      if (query.isNotEmpty) {
        final name = (source.name ?? '').toLowerCase();
        if (!name.contains(query)) return false;
      }

      return true;
    }).toList();
  }

  List<({bool isHeader, String lang, Source? source})> _buildFlattened(
    List<Source> list,
  ) {
    final Map<String, List<Source>> grouped = {};

    for (final source in list) {
      final lang = source.lang ?? 'Unknown';
      grouped.putIfAbsent(lang, () => []).add(source);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) {
        if (a.key == 'all') return -1;
        if (b.key == 'all') return 1;
        if (a.key == 'en') return -1;
        if (b.key == 'en') return 1;
        return a.key.compareTo(b.key);
      });

    final result = <({bool isHeader, String lang, Source? source})>[];

    for (final entry in entries) {
      result.add((isHeader: true, lang: entry.key, source: null));
      for (final source in entry.value) {
        result.add((isHeader: false, lang: entry.key, source: source));
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final baseList = _getBaseList();
      final filtered = _applyFilters(baseList);
      final flattened = _buildFlattened(filtered);

      return RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = flattened[index];
                  return extensionItem(item.isHeader, item.lang, item.source);
                }, childCount: flattened.length),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget extensionItem(bool isHeader, String lang, Source? source);
}
