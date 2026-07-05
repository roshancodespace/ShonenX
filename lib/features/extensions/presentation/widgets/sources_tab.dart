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
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/source_engine/providers/media_source.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'runtime_setup_sheet.dart';

class SourcesTab extends ConsumerStatefulWidget {
  final String engineFilter;
  final bridge.ItemType type;
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
        bridge.ItemType.anime => ref.watch(availableAnimeSourcesProvider),
        bridge.ItemType.manga => ref.watch(availableMangaSourcesProvider),
        bridge.ItemType.novel => ref.watch(availableNovelSourcesProvider),
      };

      return sourcesAsync.when(
        data: (sources) {
          final animeSources = widget.type == bridge.ItemType.anime
              ? sources
              : <SourceInfo>[];
          final mangaSources = widget.type == bridge.ItemType.manga
              ? sources
              : <SourceInfo>[];
          final novelSources = widget.type == bridge.ItemType.novel
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
                ],
              ],
            ],
          ),
        ),
      );
    }

    final prefKey = widget.type == bridge.ItemType.anime
        ? 'source_order_ANIME'
        : (widget.type == bridge.ItemType.manga
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

    final outdatedSources = widget.isInstalled
        ? sources.where((s) => s.hasUpdate).toList()
        : <UnifiedSource>[];
    final outdatedGroups = <String, List<UnifiedSource>>{};
    for (final s in outdatedSources) {
      outdatedGroups.putIfAbsent(s.name, () => []).add(s);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(extensionsControllerProvider.notifier)
            .refreshAll(context);
      },
      child: CustomScrollView(
        slivers: [
          if (widget.isInstalled && outdatedSources.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              sliver: SliverToBoxAdapter(
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    children: outdatedGroups.keys.map((name) {
                      final groupSources = outdatedGroups[name]!;
                      if (groupSources.length == 1) {
                        return _buildItem(context, groupSources.first, false);
                      }
                      return _buildGroupTile(context, name, groupSources);
                    }).toList(),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
            sliver: SliverList.builder(
              itemCount: sortedLangs.length,
              itemBuilder: (context, langIndex) {
                final lang = sortedLangs[langIndex];
                final nameGroups = groupedByLang[lang]!;
                final sortedNames = nameGroups.keys.toList();

                return Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: langIndex == 0,
                    title: Text(
                      lang,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    subtitle: Text(
                      '${nameGroups.length} extensions',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    children: sortedNames.map((name) {
                      final groupSources = nameGroups[name]!;

                      if (groupSources.length == 1) {
                        return _buildItem(context, groupSources.first, false);
                      }

                      return _buildGroupTile(context, name, groupSources);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(
    BuildContext context,
    String name,
    List<UnifiedSource> groupSources,
  ) {
    final isGroupProcessing = ref
        .watch(extensionsControllerProvider)
        .contains(name);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        backgroundColor: groupSources.any((s) => s.effectiveNsfw)
            ? Colors.red.withValues(alpha: 0.06)
            : null,
        collapsedBackgroundColor: groupSources.any((s) => s.effectiveNsfw)
            ? Colors.red.withValues(alpha: 0.06)
            : null,
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isInstalled)
              isGroupProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (groupSources.any((s) => s.hasUpdate))
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => ref
                                  .read(extensionsControllerProvider.notifier)
                                  .updateVariantGroup(
                                    context,
                                    name,
                                    widget.type,
                                  ),
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
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'UPDATE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
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
                              .uninstallVariantGroup(
                                context,
                                name,
                                widget.type,
                              ),
                        ),
                      ],
                    ),
          ],
        ),
        subtitle: Text(
          groupSources.any((s) => s.effectiveNsfw)
              ? '18+ • ${groupSources.length} variants'
              : '${groupSources.length} variants',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: groupSources.any((s) => s.effectiveNsfw)
                ? Colors.red.shade400
                : Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: groupSources.any((s) => s.effectiveNsfw)
                ? FontWeight.w600
                : null,
          ),
        ),
        leading: CachedNetworkImage(
          imageUrl: groupSources.first.iconUrl ?? '',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => const Icon(Icons.extension, size: 40),
        ),
        children: groupSources
            .map((s) => _buildItem(context, s, true))
            .toList(),
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
          ? (source.lang ?? (source.isInbuilt ? 'inbuilt' : 'all'))
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
                final availableList = widget.type == bridge.ItemType.anime
                    ? ref.watch(availableAnimeSourcesProvider).value
                    : (widget.type == bridge.ItemType.manga
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
                : IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => controller.installSource(context, source),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context, SourceInfo sourceInfo) {
    final sourceImpl = widget.type == bridge.ItemType.anime
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
