import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/features/extensions/models/unified_source.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/shared/widgets/confirmation_bottom_sheet.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';

final extensionsControllerProvider =
    NotifierProvider<ExtensionsController, Set<String>>(
      ExtensionsController.new,
    );

class ExtensionsController extends Notifier<Set<String>> {
  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  Set<String> build() {
    _checkForUpdatesInBackground();
    return {};
  }

  void _checkForUpdatesInBackground() {
    Future.microtask(() async {
      try {
        final bridgeManager = Get.find<bridge.ExtensionManager>();
        await bridgeManager.refreshExtensions(refreshAvailableSource: true);
        ref.invalidate(availableAnimeSourcesProvider);
        ref.invalidate(availableMangaSourcesProvider);
        ref.invalidate(availableNovelSourcesProvider);
        ref.invalidate(allAvailableSourcesProvider);
      } catch (_) {}
    });
  }

  Future<void> installSource(BuildContext context, UnifiedSource source) async {
    if (source.bridgeSource == null) return;
    state = {...state, source.id};
    try {
      await bridge
          .getSourceManager(source.bridgeSource!)
          .installSource(source.bridgeSource!);
      ref.invalidate(availableAnimeSourcesProvider);
      ref.invalidate(availableMangaSourcesProvider);
      ref.invalidate(availableNovelSourcesProvider);
      ref.invalidate(allAvailableSourcesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${source.name} installed successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to install ${source.name}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      state = {...state}..remove(source.id);
    }
  }

  void uninstallVariantGroup(
    BuildContext context,
    String name,
    bridge.ItemType type,
  ) {
    ConfirmationBottomSheet.show(
      context,
      title: 'Uninstall Extension',
      message: 'Are you sure you want to uninstall all variants of $name?',
      confirmText: 'Uninstall',
      isDestructive: true,
      onConfirm: () async {
        state = {...state, name};
        try {
          final bridgeManager = Get.find<bridge.ExtensionManager>();
          final installed = switch (type) {
            bridge.ItemType.anime => bridgeManager.installedAnimeExtensions,
            bridge.ItemType.manga => bridgeManager.installedMangaExtensions,
            bridge.ItemType.novel => bridgeManager.installedNovelExtensions,
          };
          final variants = installed
              .where((e) => (e.name ?? 'N/A') == name)
              .toList();

          await Future.wait(
            variants.map((e) => bridge.getSourceManager(e).uninstallSource(e)),
          );

          ref.invalidate(availableAnimeSourcesProvider);
          ref.invalidate(availableMangaSourcesProvider);
          ref.invalidate(availableNovelSourcesProvider);
          ref.invalidate(allAvailableSourcesProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Uninstalled all variants of $name'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } finally {
          state = {...state}..remove(name);
        }
      },
    );
  }

  void uninstallSource(
    BuildContext context,
    UnifiedSource source,
    bridge.ItemType type,
  ) {
    ConfirmationBottomSheet.show(
      context,
      title: 'Uninstall Extension',
      message: 'Are you sure you want to uninstall ${source.name}?',
      confirmText: 'Uninstall',
      isDestructive: true,
      onConfirm: () async {
        state = {...state, source.id};
        try {
          final bridgeManager = Get.find<bridge.ExtensionManager>();
          final installed = switch (type) {
            bridge.ItemType.anime => bridgeManager.installedAnimeExtensions,
            bridge.ItemType.manga => bridgeManager.installedMangaExtensions,
            bridge.ItemType.novel => bridgeManager.installedNovelExtensions,
          };
          final extSource = installed.firstWhere((e) => e.id == source.id);
          await bridge.getSourceManager(extSource).uninstallSource(extSource);

          ref.invalidate(availableAnimeSourcesProvider);
          ref.invalidate(availableMangaSourcesProvider);
          ref.invalidate(availableNovelSourcesProvider);
          ref.invalidate(allAvailableSourcesProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${source.name} uninstalled'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (_) {
        } finally {
          state = {...state}..remove(source.id);
        }
      },
    );
  }

  Future<void> updateSource(
    BuildContext context,
    UnifiedSource source,
    bridge.ItemType type,
  ) async {
    bridge.Source? extSource = source.bridgeSource;
    if (extSource == null) {
      try {
        final bridgeManager = Get.find<bridge.ExtensionManager>();
        final installed = switch (type) {
          bridge.ItemType.anime => bridgeManager.installedAnimeExtensions,
          bridge.ItemType.manga => bridgeManager.installedMangaExtensions,
          bridge.ItemType.novel => bridgeManager.installedNovelExtensions,
        };
        extSource = installed.firstWhereOrNull((e) => e.id == source.id);
      } catch (_) {}
    }
    if (extSource == null) return;
    state = {...state, source.id};
    try {
      await bridge.getSourceManager(extSource).updateSource(extSource);
      ref.invalidate(availableAnimeSourcesProvider);
      ref.invalidate(availableMangaSourcesProvider);
      ref.invalidate(availableNovelSourcesProvider);
      ref.invalidate(allAvailableSourcesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${source.name} updated successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ${source.name}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      state = {...state}..remove(source.id);
    }
  }

  Future<void> updateVariantGroup(
    BuildContext context,
    String name,
    bridge.ItemType type,
  ) async {
    state = {...state, name};
    try {
      final bridgeManager = Get.find<bridge.ExtensionManager>();
      final installed = switch (type) {
        bridge.ItemType.anime => bridgeManager.installedAnimeExtensions,
        bridge.ItemType.manga => bridgeManager.installedMangaExtensions,
        bridge.ItemType.novel => bridgeManager.installedNovelExtensions,
      };
      final variants = installed
          .where((e) => (e.name ?? 'N/A') == name && (e.hasUpdate ?? false))
          .toList();

      await Future.wait(
        variants.map((e) => bridge.getSourceManager(e).updateSource(e)),
      );

      ref.invalidate(availableAnimeSourcesProvider);
      ref.invalidate(availableMangaSourcesProvider);
      ref.invalidate(availableNovelSourcesProvider);
      ref.invalidate(allAvailableSourcesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated all variants of $name'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update $name: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      state = {...state}..remove(name);
    }
  }

  Future<void> updateAllSources(BuildContext context) async {
    try {
      final bridgeManager = Get.find<bridge.ExtensionManager>();
      await bridgeManager.updateAll();
      ref.invalidate(availableAnimeSourcesProvider);
      ref.invalidate(availableMangaSourcesProvider);
      ref.invalidate(availableNovelSourcesProvider);
      ref.invalidate(allAvailableSourcesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Updated all extensions!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update extensions: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> refreshAll(BuildContext context) async {
    try {
      final bridgeManager = Get.find<bridge.ExtensionManager>();
      await bridgeManager.refreshExtensions(refreshAvailableSource: true);
      ref.invalidate(availableAnimeSourcesProvider);
      ref.invalidate(availableMangaSourcesProvider);
      ref.invalidate(availableNovelSourcesProvider);
      ref.invalidate(allAvailableSourcesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked for extension updates'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check for updates: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> setDefaultSource(
    UnifiedSource source,
    bridge.ItemType type,
  ) async {
    final prefKey = type == bridge.ItemType.anime
        ? 'source_order_ANIME'
        : (type == bridge.ItemType.manga
              ? 'source_order_MANGA'
              : 'source_order_NOVEL');
    final order = _storage.getStringList(prefKey) ?? [];
    final newOrder = [source.id, ...order.where((id) => id != source.id)];
    await _storage.setStringList(prefKey, newOrder);
    ref.invalidate(availableAnimeSourcesProvider);
    ref.invalidate(availableMangaSourcesProvider);
    ref.invalidate(availableNovelSourcesProvider);
  }

  bool isDefaultSource(
    UnifiedSource source,
    bridge.ItemType type,
    List<SourceInfo>? availableList,
  ) {
    final prefKey = type == bridge.ItemType.anime
        ? 'source_order_ANIME'
        : (type == bridge.ItemType.manga
              ? 'source_order_MANGA'
              : 'source_order_NOVEL');
    final order = _storage.getStringList(prefKey) ?? [];
    if (order.isNotEmpty) {
      return order.first == source.id;
    }
    return availableList != null &&
        availableList.isNotEmpty &&
        availableList.first.id == source.id;
  }
}

class ExtensionsService {
  static List<String> getAvailableLanguages() {
    final Set<String> langs = {'All'};
    try {
      final bridgeManager = Get.find<bridge.ExtensionManager>();
      for (final e in [
        ...bridgeManager.availableAnimeExtensions,
        ...bridgeManager.installedAnimeExtensions,
        ...bridgeManager.availableMangaExtensions,
        ...bridgeManager.installedMangaExtensions,
        ...bridgeManager.availableNovelExtensions,
        ...bridgeManager.installedNovelExtensions,
      ]) {
        if (e.lang != null) langs.add(e.lang!);
      }
    } catch (_) {}
    return langs.toList()..sort();
  }

  static List<UnifiedSource> getFilteredSources({
    required bridge.ItemType type,
    required bool isInstalled,
    required String engineFilter,
    required String searchQuery,
    required String langFilter,
    required List<SourceInfo> animeSources,
    required List<SourceInfo> mangaSources,
    required List<SourceInfo> novelSources,
    required List<String> enabledManagers,
  }) {
    final bridgeManager = Get.find<bridge.ExtensionManager>();
    List<UnifiedSource> unified = [];

    if (isInstalled) {
      final sources = switch (type) {
        bridge.ItemType.anime => animeSources,
        bridge.ItemType.manga => mangaSources,
        bridge.ItemType.novel => novelSources,
      };
      final installedRx = switch (type) {
        bridge.ItemType.anime => bridgeManager.installedAnimeExtensions,
        bridge.ItemType.manga => bridgeManager.installedMangaExtensions,
        bridge.ItemType.novel => bridgeManager.installedNovelExtensions,
      };
      final installedMap = {for (final e in installedRx) e.id ?? '': e};
      final validSources = sources
          .where(
            (s) =>
                s.type == SourceType.inbuilt || installedMap.containsKey(s.id),
          )
          .toList();
      unified = validSources
          .map((s) => UnifiedSource.fromSourceInfo(s, installedMap[s.id]))
          .toList();
    } else {
      final available = switch (type) {
        bridge.ItemType.anime => bridgeManager.availableAnimeExtensions,
        bridge.ItemType.manga => bridgeManager.availableMangaExtensions,
        bridge.ItemType.novel => bridgeManager.availableNovelExtensions,
      };
      final installed = switch (type) {
        bridge.ItemType.anime => bridgeManager.installedAnimeExtensions,
        bridge.ItemType.manga => bridgeManager.installedMangaExtensions,
        bridge.ItemType.novel => bridgeManager.installedNovelExtensions,
      };
      final installedIds = installed.map((e) => e.id ?? '').toSet();

      final uninstalledAvailable = available.where((s) {
        if (installedIds.contains(s.id)) return false;
        final mId = (s.managerId ?? bridge.getSourceManager(s).id).replaceAll(
          '-desktop',
          '',
        );
        return enabledManagers.contains(mId);
      }).toList();

      unified = uninstalledAvailable
          .map((s) => UnifiedSource.fromBridgeSource(s))
          .toList();
    }

    var filteredSources = unified.where((s) {
      final name = s.name.toLowerCase();
      final id = s.id.toLowerCase();
      final query = searchQuery.toLowerCase();
      if (langFilter != 'All') {
        final sLang = s.lang ?? 'all';
        if (sLang.toLowerCase() != langFilter.toLowerCase()) {
          return false;
        }
      }
      if (engineFilter != 'All') {
        String mId = '';
        if (s.sourceInfo != null) {
          if (s.isInbuilt) {
            if (engineFilter != 'Mangayomi') return false;
            mId = 'mangayomi';
          } else {
            final allInst = [
              ...bridgeManager.installedAnimeExtensions,
              ...bridgeManager.installedMangaExtensions,
              ...bridgeManager.installedNovelExtensions,
            ];
            final match = allInst.firstWhereOrNull(
              (e) => e.id == s.id || e.name == s.name,
            );
            if (match != null) {
              mId = (match.managerId ?? bridge.getSourceManager(match).id)
                  .replaceAll('-desktop', '');
            }
          }
        } else if (s.bridgeSource != null) {
          mId =
              (s.bridgeSource!.managerId ??
                      bridge.getSourceManager(s.bridgeSource!).id)
                  .replaceAll('-desktop', '');
        }
        String targetId = engineFilter.toLowerCase();
        if (targetId == 'tachiyomi') targetId = 'aniyomi';
        if (mId.isNotEmpty && !mId.toLowerCase().contains(targetId)) {
          return false;
        }
      }
      return name.contains(query) || id.contains(query);
    }).toList();

    final Map<String, UnifiedSource> uniqueSources = {};
    for (final s in filteredSources) {
      uniqueSources[s.id] = s;
    }
    return uniqueSources.values.toList();
  }

  static int getSourcesTabCount({
    required bridge.ItemType type,
    required bool isInstalled,
    required String engineFilter,
    required String searchQuery,
    required String langFilter,
    required List<SourceInfo> animeSources,
    required List<SourceInfo> mangaSources,
    required List<SourceInfo> novelSources,
    required List<String> enabledManagers,
  }) {
    return getFilteredSources(
      type: type,
      isInstalled: isInstalled,
      engineFilter: engineFilter,
      searchQuery: searchQuery,
      langFilter: langFilter,
      animeSources: animeSources,
      mangaSources: mangaSources,
      novelSources: novelSources,
      enabledManagers: enabledManagers,
    ).length;
  }

  static Map<String, Map<String, List<UnifiedSource>>> groupSourcesByLanguage(
    List<UnifiedSource> filteredSources,
    bool isInstalled,
    List<String> order,
  ) {
    final Map<String, List<UnifiedSource>> groupedByName = {};
    for (final s in filteredSources) {
      groupedByName.putIfAbsent(s.name, () => []).add(s);
    }

    final Map<String, Map<String, List<UnifiedSource>>> groupedByLang = {};

    for (final name in groupedByName.keys) {
      final sources = groupedByName[name]!;
      String groupLang = 'All';

      if (sources.length > 1) {
        final allVariant = sources
            .where(
              (s) =>
                  s.lang?.toLowerCase() == 'all' ||
                  s.lang?.toLowerCase() == 'multi',
            )
            .firstOrNull;
        if (allVariant != null) {
          groupLang = allVariant.lang!;
        }

        sources.removeWhere(
          (s) =>
              s.lang?.toLowerCase() == 'all' ||
              s.lang?.toLowerCase() == 'multi',
        );
      } else {
        groupLang = sources.first.lang ?? 'All';
      }

      final displayLang =
          (groupLang.toLowerCase() == 'all' ||
              groupLang.toLowerCase() == 'multi')
          ? 'All'
          : groupLang.toUpperCase();

      groupedByLang.putIfAbsent(displayLang, () => {})[name] = sources;
    }

    final sortedLangs = groupedByLang.keys.toList()
      ..sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;
        return a.compareTo(b);
      });

    final Map<String, Map<String, List<UnifiedSource>>> sortedResult = {};
    for (final lang in sortedLangs) {
      final nameGroups = groupedByLang[lang]!;
      final sortedNames = nameGroups.keys.toList();
      if (isInstalled && order.isNotEmpty) {
        final orderMap = {for (int i = 0; i < order.length; i++) order[i]: i};
        sortedNames.sort((a, b) {
          final minA = nameGroups[a]!
              .map((s) => orderMap[s.id] ?? 9999)
              .reduce((v, e) => v < e ? v : e);
          final minB = nameGroups[b]!
              .map((s) => orderMap[s.id] ?? 9999)
              .reduce((v, e) => v < e ? v : e);
          return minA.compareTo(minB);
        });
      } else {
        sortedNames.sort();
      }
      final Map<String, List<UnifiedSource>> sortedNameGroups = {};
      for (final name in sortedNames) {
        sortedNameGroups[name] = nameGroups[name]!;
      }
      sortedResult[lang] = sortedNameGroups;
    }

    return sortedResult;
  }
}
