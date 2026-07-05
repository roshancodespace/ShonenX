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
          _showGuideSheet(context);
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
        body: Column(
          children: [
            _buildEngineFilterBar(theme),
            Expanded(
              child: TabBarView(
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
    return const PreferredSize(
      preferredSize: Size.fromHeight(40),
      child: Expanded(
        child: TabBar(
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorAnimation: TabIndicatorAnimation.linear,
          tabs: [
            Tab(text: 'Installed Anime'),
            Tab(text: 'Installed Manga'),
            Tab(text: 'Installed Novel'),
            Tab(text: 'Available Anime'),
            Tab(text: 'Available Manga'),
            Tab(text: 'Available Novel'),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineFilterBar(ThemeData theme) {
    const engines = [
      'All',
      'Mangayomi',
      'Tachiyomi',
      'CloudStream',
      'Kotatsu',
      'Sora',
    ];
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: engines.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final engine = engines[index];
          final isSelected = _selectedEngineFilter == engine;
          return FilterChip(
            label: Text(engine),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _selectedEngineFilter = engine);
            },
            showCheckmark: false,
            labelStyle: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withOpacity(0.3),
            selectedColor: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
          );
        },
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
        onPressed: () => _showGuideSheet(context),
      ),
      const SizedBox(width: 10),
    ];
  }

  Widget _buildLanguageFilter() {
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

    final sortedLangs = langs.toList()..sort();

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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: cs.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Enable or disable extension engines. Enabled engines will appear in your catalogs and discovery feeds.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurface, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...engines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final e = entry.value;
                    final id = e.$1;
                    final title = e.$2;
                    final desc = e.$3;
                    final icon = e.$4;
                    final isEnabled = enabled.contains(id);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.25),
                          ),
                        SettingsSwitchTile(
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
                                    ref.invalidate(
                                      availableAnimeSourcesProvider,
                                    );
                                    ref.invalidate(
                                      availableMangaSourcesProvider,
                                    );
                                    ref.invalidate(
                                      availableNovelSourcesProvider,
                                    );
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
                        ),
                      ],
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

  void _showGuideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final isRuntimeReady =
            bridge.AnymeXRuntimeBridge.controller.isReady.value;

        return AppBottomSheet(
          title: 'Extensions Guide',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates_rounded, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recommended: Use Aniyomi repositories for Anime streaming extensions, and Tachiyomi/Keiyoushi repositories for Manga reading.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Runtime Bridge Requirement',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'IMPORTANT: Aniyomi and CloudStream will NOT work without loading the Runtime Bridge first. Separation is intentional — it avoids bundling heavy native dependencies directly into the app.\n\nShonenX uses a minimal customized fork of AnymeXExtensionRuntimeBridge originally created by RyanYuuki.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showRuntimeSetupSheet(context, ref);
                },
                icon: Icon(
                  isRuntimeReady
                      ? Icons.check_circle_rounded
                      : Icons.download_rounded,
                  color: isRuntimeReady ? Colors.green : cs.primary,
                ),
                label: Text(
                  isRuntimeReady
                      ? 'Runtime Bridge Installed (Tap to Manage)'
                      : 'Setup Aniyomi & CloudStream Runtime',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRuntimeReady ? Colors.green : cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Repository Types & Recommendations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Aniyomi (Highly Recommended for Anime): High-speed video streaming extensions curated specifically for anime sources.',
              ),
              const SizedBox(height: 6),
              const Text(
                '• Tachiyomi / Keiyoushi (Recommended for Manga): Vast catalog of manga extensions with multi-language support.',
              ),
              const SizedBox(height: 6),
              const Text(
                '• CloudStream: Rich ecosystem of video streaming extensions.',
              ),
              const SizedBox(height: 6),
              const Text(
                '• Mangayomi: All-in-one ecosystem supporting both anime and manga extensions out of the box.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
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
