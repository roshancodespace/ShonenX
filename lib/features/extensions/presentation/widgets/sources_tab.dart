import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shonenx/features/extensions/models/unified_source.dart';
import 'package:shonenx/features/extensions/providers/extensions_provider.dart';
import 'package:shonenx/features/settings/presentation/source_settings_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/source_engine/providers/media_source.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'extension_beginner_sheet.dart';
import 'runtime_setup_sheet.dart';

class _LangHeaderTile extends StatelessWidget {
  final String lang;
  final int count;
  final bool isExpanded;
  final VoidCallback onTap;

  const _LangHeaderTile(this.lang, this.count, this.isExpanded, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        lang,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      subtitle: Text(
        '$count extensions',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
      ),
      trailing: Icon(
        isExpanded ? Icons.expand_less : Icons.expand_more,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _GroupHeaderTile extends ConsumerWidget {
  final String name;
  final List<UnifiedSource> groupSources;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isInstalled;
  final MediaType type;

  const _GroupHeaderTile(
    this.name,
    this.groupSources,
    this.isExpanded,
    this.onTap,
    this.isInstalled,
    this.type,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGroupProcessing = ref
        .watch(extensionsControllerProvider)
        .contains(name);
    final isNsfw = groupSources.any((s) => s.effectiveNsfw);
    final bgColor = isNsfw ? Colors.red.withValues(alpha: 0.06) : null;

    Widget trailingIcon = Icon(
      isExpanded ? Icons.expand_less : Icons.expand_more,
    );
    Widget trailing = trailingIcon;

    if (isInstalled) {
      if (isGroupProcessing) {
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            trailingIcon,
          ],
        );
      } else {
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (groupSources.any((s) => s.hasUpdate))
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => ref
                      .read(extensionsControllerProvider.notifier)
                      .updateVariantGroup(context, name, type),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 13,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'UPDATE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref
                  .read(extensionsControllerProvider.notifier)
                  .uninstallVariantGroup(context, name, type),
            ),
            trailingIcon,
          ],
        );
      }
    }

    return ListTile(
      tileColor: bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: CachedNetworkImage(
        imageUrl: groupSources.first.iconUrl ?? '',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const Icon(Icons.extension, size: 40),
      ),
      title: Text(
        name,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isNsfw
            ? '18+ • ${groupSources.length} variants'
            : '${groupSources.length} variants',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isNsfw
              ? Colors.red.shade400
              : Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontWeight: isNsfw ? FontWeight.w600 : null,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _UpdatesHeaderTile extends ConsumerWidget {
  final List<UnifiedSource> outdatedSources;
  final bool isExpanded;
  final VoidCallback onTap;

  const _UpdatesHeaderTile(this.outdatedSources, this.isExpanded, this.onTap);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Row(
        children: [
          Icon(
            Icons.system_update_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Updates Available (${outdatedSources.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => ref
                .read(extensionsControllerProvider.notifier)
                .updateAllSources(context),
            icon: const Icon(Icons.update, size: 16),
            label: const Text(
              'Update All',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
      trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
      onTap: onTap,
    );
  }
}

abstract class SourceListItem {}

class LangHeaderItem extends SourceListItem {
  final String lang;
  final int count;
  final bool isExpanded;
  LangHeaderItem(this.lang, this.count, this.isExpanded);
}

class GroupHeaderItem extends SourceListItem {
  final String name;
  final List<UnifiedSource> sources;
  final bool isExpanded;
  final String groupKey;
  GroupHeaderItem(this.name, this.sources, this.isExpanded, this.groupKey);
}

class SingleSourceItem extends SourceListItem {
  final UnifiedSource source;
  final bool isSubItem;
  SingleSourceItem(this.source, this.isSubItem);
}

class UpdatesHeaderItem extends SourceListItem {
  final List<UnifiedSource> outdatedSources;
  final bool isExpanded;
  UpdatesHeaderItem(this.outdatedSources, this.isExpanded);
}

class SourcesTab extends ConsumerStatefulWidget {
  final String engineFilter;
  final MediaType type;
  final String searchQuery;
  final String langFilter;
  final bool isInstalled;

  const SourcesTab({
    super.key,
    this.engineFilter = 'All',
    required this.type,
    required this.searchQuery,
    required this.langFilter,
    required this.isInstalled,
  });

  @override
  ConsumerState<SourcesTab> createState() => _SourcesTabState();
}

class _SourcesTabState extends ConsumerState<SourcesTab> {
  final Set<String> _expandedLangs = {};
  final Set<String> _expandedGroups = {};
  bool _isUpdatesExpanded = true;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _checkRuntimeIfNeeded();
  }

  Future<void> _checkRuntimeIfNeeded() async {
    final isBridgeFilter =
        widget.engineFilter == 'Tachiyomi' ||
        widget.engineFilter == 'CloudStream' ||
        widget.engineFilter == 'Kotatsu';
    if (isBridgeFilter &&
        !bridge.AnymeXRuntimeBridge.controller.isReady.value) {
      final loaded = await bridge.AnymeXRuntimeBridge.isLoaded();
      if (!loaded) {
        await bridge.AnymeXRuntimeBridge.checkAndInitialize();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInstalled) {
      final sourcesAsync = switch (widget.type) {
        MediaType.ANIME => ref.watch(availableAnimeSourcesProvider),
        MediaType.MANGA => ref.watch(availableMangaSourcesProvider),
        MediaType.NOVEL => ref.watch(availableNovelSourcesProvider),
      };

      return sourcesAsync.when(
        data: (sources) {
          final animeSources = widget.type == MediaType.ANIME
              ? sources
              : <SourceInfo>[];
          final mangaSources = widget.type == MediaType.MANGA
              ? sources
              : <SourceInfo>[];
          final novelSources = widget.type == MediaType.NOVEL
              ? sources
              : <SourceInfo>[];
          final enabledManagers = ref.watch(enabledExtensionManagersProvider);

          final unified = ExtensionsService.getFilteredSources(
            type: widget.type,
            isInstalled: true,
            engineFilter: widget.engineFilter,
            searchQuery: widget.searchQuery,
            langFilter: widget.langFilter,
            animeSources: animeSources,
            mangaSources: mangaSources,
            novelSources: novelSources,
            enabledManagers: enabledManagers.toList(),
          );
          return _buildContent(context, unified);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      );
    } else {
      return Obx(() {
        final animeSources =
            ref.watch(availableAnimeSourcesProvider).value ?? [];
        final mangaSources =
            ref.watch(availableMangaSourcesProvider).value ?? [];
        final novelSources =
            ref.watch(availableNovelSourcesProvider).value ?? [];
        final enabledManagers = ref.watch(enabledExtensionManagersProvider);

        final unified = ExtensionsService.getFilteredSources(
          type: widget.type,
          isInstalled: false,
          engineFilter: widget.engineFilter,
          searchQuery: widget.searchQuery,
          langFilter: widget.langFilter,
          animeSources: animeSources,
          mangaSources: mangaSources,
          novelSources: novelSources,
          enabledManagers: enabledManagers.toList(),
        );
        return _buildContent(context, unified);
      });
    }
  }

  Widget _buildContent(BuildContext context, List<UnifiedSource> sources) {
    if (sources.isEmpty) {
      final isRuntimeReady =
          bridge.AnymeXRuntimeBridge.controller.isReady.value;
      final isBridgeFilter =
          widget.engineFilter == 'Tachiyomi' ||
          widget.engineFilter == 'CloudStream' ||
          widget.engineFilter == 'Kotatsu';

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isBridgeFilter && !isRuntimeReady) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.extension_off_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Engine Not Ready',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This engine requires a runtime component to execute extensions. It may take a moment to initialize or require setup.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                showRuntimeSetupSheet(context, ref),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Setup Runtime Bridge'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await bridge
                                  .AnymeXRuntimeBridge.checkAndInitialize();
                              ref.invalidate(availableAnimeSourcesProvider);
                              ref.invalidate(availableMangaSourcesProvider);
                              ref.invalidate(availableNovelSourcesProvider);
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Recheck'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Icon(
                  widget.isInstalled
                      ? Icons.extension_off_outlined
                      : Icons.search_off_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.searchQuery.isEmpty && widget.langFilter == 'All'
                      ? (widget.isInstalled
                            ? 'No extensions installed'
                            : 'No available extensions')
                      : 'No extensions found',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (!widget.isInstalled &&
                    widget.searchQuery.isEmpty &&
                    widget.langFilter == 'All') ...[
                  Text(
                    widget.engineFilter == 'Mangayomi'
                        ? 'Add a Mangayomi repository to fetch and install extensions.'
                        : (widget.engineFilter == 'CloudStream'
                              ? 'Add a CloudStream repository to fetch and install extensions.'
                              : (widget.engineFilter == 'Tachiyomi'
                                    ? 'Add a Tachiyomi repository to fetch and install extensions.'
                                    : 'Add repositories via Manage Repos to fetch and install extensions across all enabled engines.')),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => ExtensionBeginnerSheet.show(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onErrorContainer,
                    ),
                    icon: const Icon(Icons.help_outline_rounded),
                    label: const Text(
                      'Retarded? Interactive Beginner Guide',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    }

    final prefKey = widget.type == MediaType.ANIME
        ? 'source_order_ANIME'
        : (widget.type == MediaType.MANGA
              ? 'source_order_MANGA'
              : 'source_order_NOVEL');
    final prefs = ref.watch(sharedPreferencesProvider);
    final order = prefs.getStringList(prefKey) ?? [];

    final groupedByLang = ExtensionsService.groupSourcesByLanguage(
      sources,
      widget.isInstalled,
      order,
    );
    final sortedLangs = groupedByLang.keys.toList();

    if (_isFirstLoad && sortedLangs.isNotEmpty) {
      _expandedLangs.add(sortedLangs.first);
      _isFirstLoad = false;
    }

    final outdatedSources = widget.isInstalled
        ? sources.where((s) => s.hasUpdate).toList()
        : <UnifiedSource>[];
    final outdatedGroups = <String, List<UnifiedSource>>{};
    for (final s in outdatedSources) {
      outdatedGroups.putIfAbsent(s.name, () => []).add(s);
    }

    // Flatten logic
    final flatList = <SourceListItem>[];

    if (widget.isInstalled && outdatedSources.isNotEmpty) {
      flatList.add(UpdatesHeaderItem(outdatedSources, _isUpdatesExpanded));

      if (_isUpdatesExpanded) {
        for (final name in outdatedGroups.keys) {
          final groupSources = outdatedGroups[name]!;
          if (groupSources.length == 1) {
            flatList.add(SingleSourceItem(groupSources.first, false));
          } else {
            final groupKey = '__UPDATE_GROUP__$name';
            final isGroupExpanded = _expandedGroups.contains(groupKey);
            flatList.add(
              GroupHeaderItem(name, groupSources, isGroupExpanded, groupKey),
            );

            if (isGroupExpanded) {
              for (final s in groupSources) {
                flatList.add(SingleSourceItem(s, true));
              }
            }
          }
        }
      }
    }

    for (final lang in sortedLangs) {
      final nameGroups = groupedByLang[lang]!;
      final sortedNames = nameGroups.keys.toList();
      final isLangExpanded = _expandedLangs.contains(lang);

      flatList.add(LangHeaderItem(lang, nameGroups.length, isLangExpanded));

      if (isLangExpanded) {
        for (final name in sortedNames) {
          final groupSources = nameGroups[name]!;
          if (groupSources.length == 1) {
            flatList.add(SingleSourceItem(groupSources.first, false));
          } else {
            final groupKey = '${lang}_$name';
            final isGroupExpanded = _expandedGroups.contains(groupKey);
            flatList.add(
              GroupHeaderItem(name, groupSources, isGroupExpanded, groupKey),
            );

            if (isGroupExpanded) {
              for (final s in groupSources) {
                flatList.add(SingleSourceItem(s, true));
              }
            }
          }
        }
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(extensionsControllerProvider.notifier)
            .refreshAll(context);
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
            sliver: SliverList.builder(
              itemCount: flatList.length,
              itemBuilder: (context, index) {
                final item = flatList[index];

                if (item is UpdatesHeaderItem) {
                  return _UpdatesHeaderTile(
                    item.outdatedSources,
                    item.isExpanded,
                    () {
                      setState(() {
                        _isUpdatesExpanded = !_isUpdatesExpanded;
                      });
                    },
                  );
                } else if (item is LangHeaderItem) {
                  return _LangHeaderTile(
                    item.lang,
                    item.count,
                    item.isExpanded,
                    () {
                      setState(() {
                        if (item.isExpanded) {
                          _expandedLangs.remove(item.lang);
                        } else {
                          _expandedLangs.add(item.lang);
                        }
                      });
                    },
                  );
                } else if (item is GroupHeaderItem) {
                  return _GroupHeaderTile(
                    item.name,
                    item.sources,
                    item.isExpanded,
                    () {
                      setState(() {
                        if (item.isExpanded) {
                          _expandedGroups.remove(item.groupKey);
                        } else {
                          _expandedGroups.add(item.groupKey);
                        }
                      });
                    },
                    widget.isInstalled,
                    widget.type,
                  );
                } else if (item is SingleSourceItem) {
                  return _buildItem(context, item.source, item.isSubItem);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    UnifiedSource source,
    bool isSubItem,
  ) {
    final isProcessing = ref
        .watch(extensionsControllerProvider)
        .contains(source.id);
    final controller = ref.read(extensionsControllerProvider.notifier);

    return SettingsActionTile(
      title: isSubItem
          ? (source.lang ??
                    (source.sourceInfo?.type == SourceType.inbuilt
                        ? 'inbuilt'
                        : 'all'))
                .toUpperCase()
          : source.name,
      subtitle: isSubItem
          ? (source.effectiveNsfw ? '18+ • ${source.id}' : source.id)
          : (source.lang != null && source.lang != 'all'
                ? (source.effectiveNsfw
                      ? '18+ • ${source.lang} • ${source.id}'
                      : '${source.lang} • ${source.id}')
                : (source.effectiveNsfw ? '18+ • ${source.id}' : source.id)),
      tileColor: source.isInbuilt
          ? Theme.of(context).colorScheme.secondaryContainer
          : (source.effectiveNsfw ? Colors.red.withValues(alpha: 0.06) : null),
      foregroundColor: source.isInbuilt
          ? Theme.of(context).colorScheme.onSecondaryContainer
          : null,
      leading: isSubItem
          ? const SizedBox(width: 40)
          : CachedNetworkImage(
              imageUrl: source.iconUrl ?? '',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.extension, size: 40),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isInstalled && source.sourceInfo != null) ...[
            Builder(
              builder: (context) {
                final availableList = widget.type == MediaType.ANIME
                    ? ref.watch(availableAnimeSourcesProvider).value
                    : (widget.type == MediaType.MANGA
                          ? ref.watch(availableMangaSourcesProvider).value
                          : ref.watch(availableNovelSourcesProvider).value);
                final isDefault = controller.isDefaultSource(
                  source,
                  widget.type,
                  availableList,
                );

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDefault)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        isDefault
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                        size: 20,
                        color: isDefault
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                      ),
                      tooltip: isDefault
                          ? 'Pinned as Default Source'
                          : 'Pin as Default Source',
                      onPressed: () =>
                          controller.setDefaultSource(source, widget.type),
                    ),
                  ],
                );
              },
            ),
            _buildSettingsButton(context, source.sourceInfo!),
            if (source.isInbuilt)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'INBUILT',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              )
            else if (isProcessing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              if (source.hasUpdate)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () =>
                        controller.updateSource(context, source, widget.type),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 13,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            source.versionLast != null
                                ? 'UPDATE ${source.versionLast}'
                                : 'UPDATE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!isSubItem)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      controller.uninstallSource(context, source, widget.type),
                ),
            ],
          ] else if (!widget.isInstalled) ...[
            isProcessing
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : FilledButton.tonalIcon(
                    onPressed: () => controller.installSource(context, source),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text(
                      'Install',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context, SourceInfo sourceInfo) {
    final sourceImpl = widget.type == MediaType.ANIME
        ? ref.read(animeSourceProvider(sourceInfo)) as MediaSource
        : ref.read(mangaSourceProvider(sourceInfo)) as MediaSource;

    return FutureBuilder<List<SourceSetting>>(
      future: sourceImpl.getSettingsSchema(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SourceSettingsSheet(
                source: sourceInfo,
                schema: snapshot.data!,
              ),
            );
          },
        );
      },
    );
  }
}
