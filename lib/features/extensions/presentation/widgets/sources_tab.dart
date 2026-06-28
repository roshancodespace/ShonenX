import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

import 'package:shonenx/features/settings/presentation/source_settings_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/confirmation_bottom_sheet.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/source_engine/providers/media_source.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class _UnifiedSource {
  final String id;
  final String name;
  final String? lang;
  final String? iconUrl;
  final bool isInbuilt;
  final bool isNsfw;
  final SourceInfo? sourceInfo;
  final bridge.Source? bridgeSource;

  _UnifiedSource.fromSourceInfo(this.sourceInfo)
    : id = sourceInfo!.id,
      name = sourceInfo.name,
      lang = sourceInfo.lang,
      iconUrl = sourceInfo.iconUrl,
      isInbuilt = sourceInfo.type == SourceType.inbuilt,
      isNsfw = sourceInfo.isNsfw,
      bridgeSource = null;

  _UnifiedSource.fromBridgeSource(this.bridgeSource)
    : id = bridgeSource!.id ?? '',
      name = bridgeSource.name ?? 'N/A',
      lang = bridgeSource.lang,
      iconUrl = bridgeSource.iconUrl,
      isInbuilt = false,
      isNsfw = bridgeSource.isNsfw ?? false,
      sourceInfo = null;

  bool get effectiveNsfw {
    if (isNsfw) return true;
    final lowerName = name.toLowerCase();
    final lowerId = id.toLowerCase();
    const keywords = [
      '18+',
      'nsfw',
      'hentai',
      'doujin',
      'porn',
      'xvideos',
      'xnxx',
      'hanime',
      'nhentai',
      'rule34',
      'erotic',
      'smut',
    ];
    for (final kw in keywords) {
      if (lowerName.contains(kw) || lowerId.contains(kw)) return true;
    }
    return false;
  }
}

class SourcesTab extends ConsumerStatefulWidget {
  final bridge.Extension manager;
  final bridge.ItemType type;
  final String searchQuery;
  final String langFilter;
  final bool isInstalled;

  const SourcesTab({
    super.key,
    required this.manager,
    required this.type,
    required this.searchQuery,
    required this.langFilter,
    required this.isInstalled,
  });

  @override
  ConsumerState<SourcesTab> createState() => _SourcesTabState();
}

class _SourcesTabState extends ConsumerState<SourcesTab> {
  final Set<String> _processingIds = {};

  @override
  Widget build(BuildContext context) {
    if (widget.isInstalled) {
      final sourcesAsync = widget.type == bridge.ItemType.anime
          ? ref.watch(availableAnimeSourcesProvider)
          : ref.watch(availableMangaSourcesProvider);

      return Obx(() {
        final installedRx = widget.manager.getInstalledRx(widget.type).value;
        final installedIds = installedRx.map((e) => e.id ?? '').toSet();

        return sourcesAsync.when(
          data: (sources) {
            final validSources = sources
                .where(
                  (s) =>
                      s.type == SourceType.inbuilt ||
                      installedIds.contains(s.id),
                )
                .toList();
            final unified = validSources
                .map((s) => _UnifiedSource.fromSourceInfo(s))
                .toList();
            return _buildContent(context, unified);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      });
    } else {
      return Obx(() {
        final available = widget.manager.getAvailableRx(widget.type).value;
        final installed = widget.manager.getInstalledRx(widget.type).value;
        final installedIds = installed.map((e) => e.id ?? '').toSet();

        final uninstalledAvailable = available
            .where((s) => !installedIds.contains(s.id))
            .toList();

        final unified = uninstalledAvailable
            .map((s) => _UnifiedSource.fromBridgeSource(s))
            .toList();
        return _buildContent(context, unified);
      });
    }
  }

  Widget _buildContent(BuildContext context, List<_UnifiedSource> sources) {
    var filteredSources = sources.where((s) {
      final name = s.name.toLowerCase();
      final id = s.id.toLowerCase();
      final query = widget.searchQuery.toLowerCase();
      if (widget.langFilter != 'All') {
        final sLang = s.lang ?? 'all';
        if (sLang.toLowerCase() != widget.langFilter.toLowerCase()) {
          return false;
        }
      }
      return name.contains(query) || id.contains(query);
    }).toList();

    final Map<String, _UnifiedSource> uniqueSources = {};
    for (final s in filteredSources) {
      uniqueSources[s.id] = s;
    }
    filteredSources = uniqueSources.values.toList();

    if (filteredSources.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.extension_off_outlined,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                widget.searchQuery.isEmpty && widget.langFilter == 'All'
                    ? (widget.isInstalled
                          ? 'No extensions installed'
                          : 'No available extensions')
                    : 'No extensions found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (!widget.isInstalled &&
                  widget.searchQuery.isEmpty &&
                  widget.langFilter == 'All') ...[
                const SizedBox(height: 8),
                Text(
                  widget.manager.id == 'mangayomi'
                      ? 'Add a Mangayomi repository to fetch and install extensions.'
                      : 'Add a Tachiyomi repository to fetch and install extensions.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final Map<String, List<_UnifiedSource>> groupedByName = {};
    for (final s in filteredSources) {
      groupedByName.putIfAbsent(s.name, () => []).add(s);
    }

    final Map<String, Map<String, List<_UnifiedSource>>> groupedByLang = {};

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

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
          sliver: SliverList.builder(
            itemCount: sortedLangs.length,
            itemBuilder: (context, langIndex) {
              final lang = sortedLangs[langIndex];
              final nameGroups = groupedByLang[lang]!;
              final prefKey = widget.type == bridge.ItemType.anime
                  ? 'source_order_ANIME'
                  : 'source_order_MANGA';
              final prefs = ref.watch(sharedPreferencesProvider);
              final order = prefs.getStringList(prefKey) ?? [];
              final orderMap = {
                for (int i = 0; i < order.length; i++) order[i]: i,
              };

              final sortedNames = nameGroups.keys.toList();
              if (widget.isInstalled && order.isNotEmpty) {
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

                    final isGroupProcessing = _processingIds.contains(name);

                    return Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        backgroundColor:
                            groupSources.any((s) => s.effectiveNsfw)
                            ? Colors.red.withValues(alpha: 0.06)
                            : null,
                        collapsedBackgroundColor:
                            groupSources.any((s) => s.effectiveNsfw)
                            ? Colors.red.withValues(alpha: 0.06)
                            : null,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
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
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () =>
                                          _uninstallVariantGroup(context, name),
                                    ),
                          ],
                        ),
                        subtitle: Text(
                          groupSources.any((s) => s.effectiveNsfw)
                              ? '18+ • ${groupSources.length} variants'
                              : '${groupSources.length} variants',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: groupSources.any((s) => s.effectiveNsfw)
                                    ? Colors.red.shade400
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                fontWeight:
                                    groupSources.any((s) => s.effectiveNsfw)
                                    ? FontWeight.w600
                                    : null,
                              ),
                        ),
                        leading: CachedNetworkImage(
                          imageUrl: groupSources.first.iconUrl ?? '',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.extension, size: 40),
                        ),
                        children: groupSources
                            .map((s) => _buildItem(context, s, true))
                            .toList(),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    _UnifiedSource source,
    bool isSubItem,
  ) {
    final isProcessing = _processingIds.contains(source.id);

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
                final prefKey = widget.type == bridge.ItemType.anime
                    ? 'source_order_ANIME'
                    : 'source_order_MANGA';
                final prefs = ref.watch(sharedPreferencesProvider);
                final order = prefs.getStringList(prefKey) ?? [];
                final availableList = widget.type == bridge.ItemType.anime
                    ? ref.watch(availableAnimeSourcesProvider).value
                    : ref.watch(availableMangaSourcesProvider).value;
                final isDefault = order.isNotEmpty
                    ? order.first == source.id
                    : (availableList != null &&
                          availableList.isNotEmpty &&
                          availableList.first.id == source.id);

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
                      onPressed: () async {
                        final newOrder = [
                          source.id,
                          ...order.where((id) => id != source.id),
                        ];
                        await prefs.setStringList(prefKey, newOrder);
                        ref.invalidate(availableAnimeSourcesProvider);
                        ref.invalidate(availableMangaSourcesProvider);
                      },
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
            else if (!isSubItem)
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
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _uninstallSource(context, source),
                    ),
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
                    onPressed: () => _installSource(context, source),
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

  Future<void> _installSource(
    BuildContext context,
    _UnifiedSource source,
  ) async {
    if (source.bridgeSource == null) return;
    setState(() => _processingIds.add(source.id));
    try {
      await widget.manager.installSource(source.bridgeSource!);
      ref.invalidate(availableAnimeSourcesProvider);
      ref.invalidate(availableMangaSourcesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${source.name} installed successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to install ${source.name}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(source.id));
    }
  }

  void _uninstallVariantGroup(BuildContext context, String name) {
    ConfirmationBottomSheet.show(
      context,
      title: 'Uninstall Extension',
      message: 'Are you sure you want to uninstall all variants of $name?',
      confirmText: 'Uninstall',
      isDestructive: true,
      onConfirm: () async {
        setState(() => _processingIds.add(name));
        try {
          final installed = widget.manager.getInstalledRx(widget.type).value;
          final variants = installed
              .where((e) => (e.name ?? 'N/A') == name)
              .toList();

          await Future.wait(
            variants.map((e) => widget.manager.uninstallSource(e)),
          );

          ref.invalidate(availableAnimeSourcesProvider);
          ref.invalidate(availableMangaSourcesProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Uninstalled all variants of $name'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _processingIds.remove(name));
        }
      },
    );
  }

  void _uninstallSource(BuildContext context, _UnifiedSource source) {
    ConfirmationBottomSheet.show(
      context,
      title: 'Uninstall Extension',
      message: 'Are you sure you want to uninstall ${source.name}?',
      confirmText: 'Uninstall',
      isDestructive: true,
      onConfirm: () async {
        setState(() => _processingIds.add(source.id));
        try {
          final installed = widget.manager.getInstalledRx(widget.type).value;
          final extSource = installed.firstWhere((e) => e.id == source.id);
          await widget.manager.uninstallSource(extSource);

          ref.invalidate(availableAnimeSourcesProvider);
          ref.invalidate(availableMangaSourcesProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${source.name} uninstalled'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (_) {
        } finally {
          if (mounted) setState(() => _processingIds.remove(source.id));
        }
      },
    );
  }
}
