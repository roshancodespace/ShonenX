import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/source_registry.dart';

import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';

import 'package:shonenx/features/extensions/providers/extensions_provider.dart';
import 'widgets/extension_guide_sheet.dart';
import 'widgets/manage_repos_sheet.dart';
import 'widgets/runtime_setup_sheet.dart';
import 'widgets/sources_tab.dart';

class ExtensionsSettingsScreen extends ConsumerStatefulWidget {
  final String? autoAddUrl;
  final String? autoAddType;
  final String? autoAddManager;

  const ExtensionsSettingsScreen({
    super.key,
    this.autoAddUrl,
    this.autoAddType,
    this.autoAddManager,
  });

  @override
  ConsumerState<ExtensionsSettingsScreen> createState() =>
      _ExtensionsSettingsScreenState();
}

class _ExtensionsSettingsScreenState
    extends ConsumerState<ExtensionsSettingsScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedLangFilter = 'All';
  String _selectedEngineFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoAddUrl != null && widget.autoAddUrl!.isNotEmpty) {
        _showManageReposSheet(
          context,
          autoAddUrl: widget.autoAddUrl,
          autoAddType: widget.autoAddType,
          autoAddManager: widget.autoAddManager,
        );
      } else {
        final manager = ref.read(extensionManagerProvider);
        final animeRepos = manager.getReposRx(bridge.ItemType.anime).value;
        final mangaRepos = manager.getReposRx(bridge.ItemType.manga).value;
        if (animeRepos.isEmpty && mangaRepos.isEmpty) {
          ExtensionGuideSheet.show(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = ref.watch(extensionManagerProvider);

    return DefaultTabController(
      length: 6,
      child: AppScaffold(
        title: _isSearching ? null : 'Sources',
        floatingActionButtonLocation: MediaQuery.of(context).size.width < 600
            ? FloatingActionButtonLocation.centerFloat
            : FloatingActionButtonLocation.endFloat,
        titleWidget: _isSearching ? _buildSearchField(theme) : null,
        barBottom: _buildTabBar(),
        actions: _buildActions(context, manager),
        body: TabBarView(
          children: [
            SourcesTab(
              engineFilter: _selectedEngineFilter,
              type: bridge.ItemType.anime,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: true,
            ),
            SourcesTab(
              engineFilter: _selectedEngineFilter,
              type: bridge.ItemType.manga,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: true,
            ),
            SourcesTab(
              engineFilter: _selectedEngineFilter,
              type: bridge.ItemType.novel,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: true,
            ),
            SourcesTab(
              engineFilter: _selectedEngineFilter,
              type: bridge.ItemType.anime,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: false,
            ),
            SourcesTab(
              engineFilter: _selectedEngineFilter,
              type: bridge.ItemType.manga,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: false,
            ),
            SourcesTab(
              engineFilter: _selectedEngineFilter,
              type: bridge.ItemType.novel,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: false,
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) => _buildFab(context, manager, theme),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search extensions...',
        border: InputBorder.none,
        hintStyle: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      style: theme.textTheme.titleMedium,
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    final animeSources = ref.watch(availableAnimeSourcesProvider).value ?? [];
    final mangaSources = ref.watch(availableMangaSourcesProvider).value ?? [];
    final novelSources = ref.watch(availableNovelSourcesProvider).value ?? [];
    final enabledManagers = ref.watch(enabledExtensionManagersProvider);

    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: Expanded(
        child: Obx(() {
          final countInstalledAnime = ExtensionsService.getSourcesTabCount(
            type: bridge.ItemType.anime,
            isInstalled: true,
            engineFilter: _selectedEngineFilter,
            searchQuery: _searchQuery,
            langFilter: _selectedLangFilter,
            animeSources: animeSources,
            mangaSources: mangaSources,
            novelSources: novelSources,
            enabledManagers: enabledManagers.toList(),
          );
          final countInstalledManga = ExtensionsService.getSourcesTabCount(
            type: bridge.ItemType.manga,
            isInstalled: true,
            engineFilter: _selectedEngineFilter,
            searchQuery: _searchQuery,
            langFilter: _selectedLangFilter,
            animeSources: animeSources,
            mangaSources: mangaSources,
            novelSources: novelSources,
            enabledManagers: enabledManagers.toList(),
          );
          final countInstalledNovel = ExtensionsService.getSourcesTabCount(
            type: bridge.ItemType.novel,
            isInstalled: true,
            engineFilter: _selectedEngineFilter,
            searchQuery: _searchQuery,
            langFilter: _selectedLangFilter,
            animeSources: animeSources,
            mangaSources: mangaSources,
            novelSources: novelSources,
            enabledManagers: enabledManagers.toList(),
          );
          final countAvailableAnime = ExtensionsService.getSourcesTabCount(
            type: bridge.ItemType.anime,
            isInstalled: false,
            engineFilter: _selectedEngineFilter,
            searchQuery: _searchQuery,
            langFilter: _selectedLangFilter,
            animeSources: animeSources,
            mangaSources: mangaSources,
            novelSources: novelSources,
            enabledManagers: enabledManagers.toList(),
          );
          final countAvailableManga = ExtensionsService.getSourcesTabCount(
            type: bridge.ItemType.manga,
            isInstalled: false,
            engineFilter: _selectedEngineFilter,
            searchQuery: _searchQuery,
            langFilter: _selectedLangFilter,
            animeSources: animeSources,
            mangaSources: mangaSources,
            novelSources: novelSources,
            enabledManagers: enabledManagers.toList(),
          );
          final countAvailableNovel = ExtensionsService.getSourcesTabCount(
            type: bridge.ItemType.novel,
            isInstalled: false,
            engineFilter: _selectedEngineFilter,
            searchQuery: _searchQuery,
            langFilter: _selectedLangFilter,
            animeSources: animeSources,
            mangaSources: mangaSources,
            novelSources: novelSources,
            enabledManagers: enabledManagers.toList(),
          );

          return TabBar(
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorAnimation: TabIndicatorAnimation.linear,
            tabs: [
              _buildTab('Installed Anime', countInstalledAnime),
              _buildTab('Installed Manga', countInstalledManga),
              _buildTab('Installed Novel', countInstalledNovel),
              _buildTab('Available Anime', countAvailableAnime),
              _buildTab('Available Manga', countAvailableManga),
              _buildTab('Available Novel', countAvailableNovel),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTab(String text, int count) {
    final countStr = count > 100 ? '100+' : count.toString();
    final cs = Theme.of(context).colorScheme;
    final roundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
    );
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(roundness * 0.5),
            ),
            child: Text(
              countStr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, bridge.Extension manager) {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        const SizedBox(width: 10),
      ];
    }

    return [
      _buildEngineFilter(),
      _buildLanguageFilter(),
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () => setState(() => _isSearching = true),
      ),
      IconButton(
        icon: const Icon(Icons.speed_outlined),
        onPressed: () => context.push('/settings/extensions/test'),
      ),
      IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () => ExtensionGuideSheet.show(context),
      ),
      const SizedBox(width: 10),
    ];
  }

  Widget _buildEngineFilter() {
    const engines = [
      'All',
      'Mangayomi',
      'Tachiyomi',
      'CloudStream',
      'Kotatsu',
      'Sora',
    ];
    final cs = Theme.of(context).colorScheme;
    final isAll = _selectedEngineFilter == 'All';
    final roundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Builder(
        builder: (buttonContext) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(roundness),
              onTap: () {
                final RenderBox button =
                    buttonContext.findRenderObject() as RenderBox;
                final RenderBox overlay =
                    Navigator.of(context).overlay!.context.findRenderObject()
                        as RenderBox;
                final RelativeRect position = RelativeRect.fromRect(
                  Rect.fromPoints(
                    button.localToGlobal(
                      Offset(0, button.size.height),
                      ancestor: overlay,
                    ),
                    button.localToGlobal(
                      button.size.bottomRight(Offset.zero),
                      ancestor: overlay,
                    ),
                  ),
                  Offset.zero & overlay.size,
                );

                showMenu<String>(
                  context: context,
                  position: position,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(roundness),
                  ),
                  items: engines.map((e) {
                    final isSelected = _selectedEngineFilter == e;
                    return PopupMenuItem(
                      value: e,
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: isSelected
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            e == 'All' ? 'All Engines' : e,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? cs.primary : cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ).then((val) {
                  if (val != null) {
                    setState(() => _selectedEngineFilter = val);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isAll
                      ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
                      : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(roundness),
                  border: Border.all(
                    color: isAll
                        ? cs.outlineVariant.withValues(alpha: 0.5)
                        : cs.primary,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.extension_rounded,
                      size: 15,
                      color: isAll
                          ? cs.onSurfaceVariant
                          : cs.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedEngineFilter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isAll
                            ? cs.onSurfaceVariant
                            : cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: isAll
                          ? cs.onSurfaceVariant
                          : cs.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageFilter() {
    final sortedLangs = ExtensionsService.getAvailableLanguages();
    final roundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
    );

    return PopupMenuButton<String>(
      icon: Icon(
        _selectedLangFilter == 'All'
            ? Icons.filter_list
            : Icons.filter_list_alt,
        color: _selectedLangFilter == 'All'
            ? null
            : Theme.of(context).colorScheme.primary,
      ),
      tooltip: 'Filter by Language',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(roundness),
      ),
      onSelected: (val) => setState(() => _selectedLangFilter = val),
      itemBuilder: (context) {
        return sortedLangs
            .map(
              (l) => PopupMenuItem(
                value: l,
                child: Text(l == 'All' ? 'All Languages' : l.toUpperCase()),
              ),
            )
            .toList();
      },
    );
  }

  Widget _buildFab(
    BuildContext context,
    bridge.Extension manager,
    ThemeData theme,
  ) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      verticalDirection: VerticalDirection.up,
      children: [
        SizedBox(
          height: 44,
          child: FloatingActionButton.extended(
            heroTag: 'manage_engines_fab',
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            icon: const Icon(Icons.extension_rounded, size: 18),
            label: const Text('Manage Engines', style: TextStyle(fontSize: 13)),
            onPressed: () => _showManageEnginesSheet(context),
          ),
        ),
        SizedBox(
          height: 44,
          child: FloatingActionButton.extended(
            heroTag: 'add_repo_fab',
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: const Icon(Icons.storage_rounded, size: 18),
            label: const Text('Manage Repos', style: TextStyle(fontSize: 13)),
            onPressed: () => _showManageReposSheet(context),
          ),
        ),
      ],
    );
  }

  void _showManageEnginesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final enabled = ref.watch(enabledExtensionManagersProvider);
            final notifier = ref.read(
              enabledExtensionManagersProvider.notifier,
            );
            final cs = Theme.of(context).colorScheme;

            final engines = [
              (
                'mangayomi',
                'Mangayomi',
                'All-in-one Anime & Manga extensions',
                Icons.auto_awesome_mosaic_rounded,
              ),
              (
                'aniyomi',
                'Tachiyomi / Aniyomi',
                'Vast catalog of Manga & Anime extensions',
                Icons.video_library_rounded,
              ),
              (
                'cloudstream',
                'CloudStream',
                'Video streaming & media extensions',
                Icons.cloud_queue_rounded,
              ),
              (
                'kotatsu',
                'Kotatsu',
                'Manga reading extensions',
                Icons.menu_book_rounded,
              ),
              (
                'sora',
                'Sora',
                'Novel & Anime extensions',
                Icons.auto_stories_rounded,
              ),
            ];

            return AppBottomSheet(
              title: 'Manage Extension Engines',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      'Enable or disable extension engines. Enabled engines will appear in your catalogs and discovery feeds.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...engines.map((e) {
                    final id = e.$1;
                    final title = e.$2;
                    final desc = e.$3;
                    final icon = e.$4;
                    final isRuntimeEngine =
                        id == 'aniyomi' ||
                        id == 'cloudstream' ||
                        id == 'kotatsu';
                    final isEnabled =
                        enabled.contains(id) &&
                        (!isRuntimeEngine ||
                            bridge
                                .AnymeXRuntimeBridge
                                .controller
                                .isReady
                                .value);

                    return SettingsSwitchTile(
                      icon: icon,
                      title: title,
                      subtitle: desc,
                      value: isEnabled,
                      onChanged: (val) {
                        if (val &&
                            (id == 'aniyomi' ||
                                id == 'cloudstream' ||
                                id == 'kotatsu')) {
                          if (!bridge
                              .AnymeXRuntimeBridge
                              .controller
                              .isReady
                              .value) {
                            showRuntimeSetupSheet(
                              context,
                              ref,
                              onComplete: () {
                                notifier.toggleManager(id, true);
                                ref.invalidate(availableAnimeSourcesProvider);
                                ref.invalidate(availableMangaSourcesProvider);
                                ref.invalidate(availableNovelSourcesProvider);
                              },
                            );
                            return;
                          }
                        }
                        notifier.toggleManager(id, val);
                        ref.invalidate(availableAnimeSourcesProvider);
                        ref.invalidate(availableMangaSourcesProvider);
                        ref.invalidate(availableNovelSourcesProvider);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showManageReposSheet(
    BuildContext context, {
    String? autoAddUrl,
    String? autoAddType,
    String? autoAddManager,
  }) {
    final manager = ref.watch(extensionManagerProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManageReposSheet(
        manager: manager,
        autoAddUrl: autoAddUrl,
        autoAddType: autoAddType,
        autoAddManager: autoAddManager,
      ),
    );
  }
}
