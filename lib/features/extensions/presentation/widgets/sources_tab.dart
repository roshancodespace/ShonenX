import 'dart:io';

import 'package:anymex_extension_runtime_bridge/Services/Aniyomi/Models/Source.dart';
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
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
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
      trailing: AnimatedRotation(
        turns: isExpanded ? 0.5 : 0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        child: Icon(
          Icons.expand_more,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _SourceSettingsButton extends ConsumerWidget {
  final SourceInfo sourceInfo;
  final MediaType type;
  final double iconSize;

  const _SourceSettingsButton({
    required this.sourceInfo,
    required this.type,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceImpl = type == MediaType.ANIME
        ? ref.read(animeSourceProvider(sourceInfo)) as MediaSource
        : ref.read(mangaSourceProvider(sourceInfo)) as MediaSource;

    return FutureBuilder<List<SourceSetting>>(
      future: sourceImpl.getSettingsSchema(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.settings_outlined, size: iconSize),
          padding: EdgeInsets.all(iconSize <= 16 ? 4 : 8),
          constraints: iconSize <= 16 ? const BoxConstraints() : null,
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

class _GroupHeaderTile extends ConsumerWidget {
  final String name;
  final List<UnifiedSource> groupSources;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isInstalled;
  final MediaType type;

  const _GroupHeaderTile({
    required this.name,
    required this.groupSources,
    required this.isExpanded,
    required this.onTap,
    required this.isInstalled,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isGroupProcessing = ref
        .watch(extensionsControllerProvider)
        .contains(name);
    final isNsfw = groupSources.any((s) => s.effectiveNsfw);
    final controller = ref.read(extensionsControllerProvider.notifier);
    final availableList = type == MediaType.ANIME
        ? ref.watch(availableAnimeSourcesProvider).value
        : (type == MediaType.MANGA
              ? ref.watch(availableMangaSourcesProvider).value
              : ref.watch(availableNovelSourcesProvider).value);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          tileColor: isNsfw ? Colors.red.withValues(alpha: 0.05) : null,
          leading: CachedNetworkImage(
            imageUrl: groupSources.first.iconUrl ?? '',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => const Icon(Icons.extension, size: 40),
          ),
          title: Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          subtitle: Text(
            isNsfw
                ? '18+ • ${groupSources.length} variants'
                : '${groupSources.length} variants',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isNsfw
                  ? Colors.red.shade400
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: isNsfw ? FontWeight.w600 : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isInstalled && isGroupProcessing)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (isInstalled) ...[
                if (groupSources.any((s) => s.hasUpdate))
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () =>
                          controller.updateVariantGroup(context, name, type),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'UPDATE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => controller.uninstallVariantGroup(
                    context,
                    name,
                    groupSources,
                    type,
                  ),
                ),
              ] else if (!isInstalled) ...[
                if (isGroupProcessing)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilledButton.tonalIcon(
                      onPressed: () => controller.installVariantGroup(
                        context,
                        name,
                        groupSources,
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text(
                        'Install All',
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
                  ),
              ],
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                child: Icon(
                  Icons.expand_more,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          onTap: onTap,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 10,
                    top: 2,
                    bottom: 6,
                  ),
                  child: Container(
                    padding: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.4,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        int crossAxisCount = 1;
                        if (width >= 1050) {
                          crossAxisCount = 4;
                        } else if (width >= 720) {
                          crossAxisCount = 3;
                        } else if (width >= 420) {
                          crossAxisCount = 2;
                        }

                        if (crossAxisCount == 1) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: groupSources.map((source) {
                              return _buildVariantSubItem(
                                context,
                                source,
                                controller,
                                availableList,
                              );
                            }).toList(),
                          );
                        }

                        final columns = List.generate(
                          crossAxisCount,
                          (_) => <UnifiedSource>[],
                        );
                        for (int i = 0; i < groupSources.length; i++) {
                          columns[i % crossAxisCount].add(groupSources[i]);
                        }

                        final rowChildren = <Widget>[];
                        for (int i = 0; i < crossAxisCount; i++) {
                          rowChildren.add(
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: columns[i].map((source) {
                                  return _buildVariantSubItem(
                                    context,
                                    source,
                                    controller,
                                    availableList,
                                  );
                                }).toList(),
                              ),
                            ),
                          );

                          if (i < crossAxisCount - 1) {
                            rowChildren.add(
                              Container(
                                width: 1.5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.outline.withValues(
                                    alpha: 0.6,
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            );
                          }
                        }

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: rowChildren,
                          ),
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildVariantSubItem(
    BuildContext context,
    UnifiedSource source,
    ExtensionsController controller,
    List<SourceInfo>? availableList,
  ) {
    final theme = Theme.of(context);
    final isDefault = controller.isDefaultSource(source, type, availableList);
    final langStr =
        (source.lang ??
                (source.sourceInfo?.type == SourceType.inbuilt
                    ? 'inbuilt'
                    : 'all'))
            .toUpperCase();
    final versionStr = source.version ?? source.versionLast;

    String? engineStr;
    if (source.isInbuilt) {
      engineStr = 'INBUILT';
    } else if (source.bridgeSource != null) {
      final typeStr = source.bridgeSource.runtimeType.toString().toLowerCase();
      if (typeStr.contains('aniyomi') || typeStr.contains('anymex')) {
        engineStr = 'ANIYOMI';
      } else if (typeStr.contains('tachiyomi')) {
        engineStr = 'TACHIYOMI';
      } else if (typeStr.contains('cloudstream')) {
        engineStr = 'CLOUDSTREAM';
      } else if (typeStr.contains('kotatsu')) {
        engineStr = 'KOTATSU';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          // Left Pill: Info Container (Lang + Version + Engine)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDefault
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : theme.colorScheme.surfaceContainerHigh.withValues(
                      alpha: 0.5,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDefault
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Language Tag Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    langStr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                // Version Badge (if available)
                if (versionStr != null && versionStr.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      source.hasUpdate &&
                              source.versionLast != null &&
                              source.version != null &&
                              source.version != source.versionLast
                          ? 'v${source.version} → v${source.versionLast}'
                          : 'v$versionStr',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
                // Extension Engine Badge (if available)
                if (engineStr != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      engineStr,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),
          if (isInstalled && source.sourceInfo != null) ...[
            if (isDefault)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DEFAULT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            IconButton(
              icon: Icon(
                isDefault ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                size: 18,
                color: isDefault
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              tooltip: isDefault
                  ? 'Pinned as Default Source'
                  : 'Pin as Default Source',
              onPressed: () => controller.setDefaultSource(source, type),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            _SourceSettingsButton(
              sourceInfo: source.sourceInfo!,
              type: type,
              iconSize: 18,
            ),
          ] else if (!isInstalled) ...[
            Consumer(
              builder: (context, ref, _) {
                final isProcessing = ref
                    .watch(extensionsControllerProvider)
                    .contains(source.id);
                return isProcessing
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : FilledButton.tonalIcon(
                        onPressed: () {
                          if (Platform.isAndroid &&
                              source.bridgeSource is ASource) {
                            showInstallMethodSheet(context, source, controller);
                          } else {
                            controller.installSource(context, source);
                          }
                        },
                        icon: const Icon(Icons.download_rounded, size: 14),
                        label: const Text(
                          'Install',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          minimumSize: const Size(0, 28),
                        ),
                      );
              },
            ),
          ],
        ],
      ),
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
              'Updates (${outdatedSources.length})',
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
  final VoidCallback? onBrowseAvailable;

  const SourcesTab({
    super.key,
    this.engineFilter = 'All',
    required this.type,
    required this.searchQuery,
    required this.langFilter,
    required this.isInstalled,
    this.onBrowseAvailable,
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
        _ => ref.watch(availableAnimeSourcesProvider),
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
                if (widget.isInstalled &&
                    widget.searchQuery.isEmpty &&
                    widget.langFilter == 'All') ...[
                  Text(
                    'Explore the online catalog to find and install ${widget.type == MediaType.ANIME ? 'anime' : (widget.type == MediaType.MANGA ? 'manga' : 'novel')} sources.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.onBrowseAvailable != null)
                    FilledButton.icon(
                      onPressed: widget.onBrowseAvailable,
                      icon: const Icon(Icons.explore_outlined),
                      label: Text(
                        'Get ${widget.type == MediaType.ANIME ? 'Anime' : (widget.type == MediaType.MANGA ? 'Manga' : 'Novel')} Extensions',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
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

    final sectionWidgets = <Widget>[];

    if (!widget.isInstalled && sources.isNotEmpty) {
      sectionWidgets.add(_buildCatalogInfoBanner(context));
    }

    if (widget.isInstalled && outdatedSources.isNotEmpty) {
      sectionWidgets.add(
        _buildUpdatesSection(context, outdatedSources, outdatedGroups),
      );
    }

    for (final lang in sortedLangs) {
      final nameGroups = groupedByLang[lang]!;
      sectionWidgets.add(_buildLanguageSection(context, lang, nameGroups));
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
              itemCount: sectionWidgets.length,
              itemBuilder: (context, index) => sectionWidgets[index],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogInfoBanner(BuildContext context) {
    final theme = Theme.of(context);
    final roundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(roundness * 0.5),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Online Catalog — extensions here are not installed yet. Tap "Install" to add them to your sources.',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesSection(
    BuildContext context,
    List<UnifiedSource> outdatedSources,
    Map<String, List<UnifiedSource>> outdatedGroups,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _UpdatesHeaderTile(outdatedSources, _isUpdatesExpanded, () {
          setState(() {
            _isUpdatesExpanded = !_isUpdatesExpanded;
          });
        }),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: _isUpdatesExpanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: outdatedGroups.keys.map((name) {
                    final groupSources = outdatedGroups[name]!;
                    if (groupSources.length == 1) {
                      return _buildItem(context, groupSources.first, false);
                    } else {
                      final groupKey = '__UPDATE_GROUP__$name';
                      final isGroupExpanded = _expandedGroups.contains(
                        groupKey,
                      );
                      return _GroupHeaderTile(
                        name: name,
                        groupSources: groupSources,
                        isExpanded: isGroupExpanded,
                        onTap: () {
                          setState(() {
                            if (isGroupExpanded) {
                              _expandedGroups.remove(groupKey);
                            } else {
                              _expandedGroups.add(groupKey);
                            }
                          });
                        },
                        isInstalled: widget.isInstalled,
                        type: widget.type,
                      );
                    }
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(
    BuildContext context,
    String lang,
    Map<String, List<UnifiedSource>> nameGroups,
  ) {
    final isLangExpanded = _expandedLangs.contains(lang);
    final sortedNames = nameGroups.keys.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LangHeaderTile(lang, nameGroups.length, isLangExpanded, () {
          setState(() {
            if (isLangExpanded) {
              _expandedLangs.remove(lang);
            } else {
              _expandedLangs.add(lang);
            }
          });
        }),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: isLangExpanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: sortedNames.map((name) {
                    final groupSources = nameGroups[name]!;
                    if (groupSources.length == 1) {
                      return _buildItem(context, groupSources.first, false);
                    } else {
                      final groupKey = '${lang}_$name';
                      final isGroupExpanded = _expandedGroups.contains(
                        groupKey,
                      );
                      return _GroupHeaderTile(
                        name: name,
                        groupSources: groupSources,
                        isExpanded: isGroupExpanded,
                        onTap: () {
                          setState(() {
                            if (isGroupExpanded) {
                              _expandedGroups.remove(groupKey);
                            } else {
                              _expandedGroups.add(groupKey);
                            }
                          });
                        },
                        isInstalled: widget.isInstalled,
                        type: widget.type,
                      );
                    }
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
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
    final versionStr = source.version ?? source.versionLast;

    String? engineStr;
    if (source.isInbuilt) {
      engineStr = 'INBUILT';
    } else if (source.bridgeSource != null) {
      final typeStr = source.bridgeSource.runtimeType.toString().toLowerCase();
      if (typeStr.contains('aniyomi') || typeStr.contains('anymex')) {
        engineStr = 'ANIYOMI';
      } else if (typeStr.contains('tachiyomi')) {
        engineStr = 'TACHIYOMI';
      } else if (typeStr.contains('cloudstream')) {
        engineStr = 'CLOUDSTREAM';
      } else if (typeStr.contains('kotatsu')) {
        engineStr = 'KOTATSU';
      }
    }

    final subtitleParts = <String>[];
    if (source.effectiveNsfw) subtitleParts.add('18+');
    if (source.lang != null &&
        source.lang!.toLowerCase() != 'all' &&
        source.lang!.toLowerCase() != 'multi') {
      subtitleParts.add(source.lang!.toUpperCase());
    }
    if (source.hasUpdate &&
        source.versionLast != null &&
        source.version != null &&
        source.version != source.versionLast) {
      subtitleParts.add('v${source.version} → v${source.versionLast}');
    } else if (versionStr != null && versionStr.isNotEmpty) {
      subtitleParts.add('v$versionStr');
    }
    if (engineStr != null) {
      subtitleParts.add(engineStr);
    }
    final subtitleText = subtitleParts.isNotEmpty
        ? subtitleParts.join(' • ')
        : null;

    return SettingsActionTile(
      title: isSubItem
          ? (source.lang ??
                    (source.sourceInfo?.type == SourceType.inbuilt
                        ? 'inbuilt'
                        : 'all'))
                .toUpperCase()
          : source.name,
      subtitle: subtitleText,
      subtitleMaxLines: 1,
      subtitleOverflow: TextOverflow.ellipsis,
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
                      visualDensity: VisualDensity.compact,
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
              if (!isSubItem)
                IconButton(
                  visualDensity: VisualDensity.compact,
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
                    onPressed: () {
                      if (Platform.isAndroid &&
                          source.bridgeSource is ASource) {
                        showInstallMethodSheet(context, source, controller);
                      } else {
                        controller.installSource(context, source);
                      }
                    },
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
          visualDensity: VisualDensity.compact,
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

void showInstallMethodSheet(
  BuildContext context,
  UnifiedSource source,
  ExtensionsController controller,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Install ${source.name}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'How would you like to install this extension?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.apps_rounded),
              title: const Text('App (Normal)'),
              subtitle: const Text('Installs as a standard Android app.'),
              onTap: () {
                Navigator.pop(context);
                (source.bridgeSource as ASource).isPrivate = false;
                controller.installSource(context, source);
              },
            ),
            ListTile(
              leading: const Icon(Icons.security_rounded),
              title: const Text('Private / Internal'),
              subtitle: const Text(
                'Installs internally. Does not show up in device settings or launcher.',
              ),
              onTap: () {
                Navigator.pop(context);
                (source.bridgeSource as ASource).isPrivate = true;
                controller.installSource(context, source);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
