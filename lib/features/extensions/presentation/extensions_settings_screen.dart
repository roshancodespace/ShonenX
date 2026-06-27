import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/source_registry.dart';

import 'widgets/manage_repos_sheet.dart';
import 'widgets/sources_tab.dart';

class ExtensionsSettingsScreen extends ConsumerStatefulWidget {
  final String? autoAddUrl;
  final String? autoAddType;

  const ExtensionsSettingsScreen({
    super.key,
    this.autoAddUrl,
    this.autoAddType,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoAddUrl != null && widget.autoAddUrl!.isNotEmpty) {
        _showManageReposSheet(
          context,
          autoAddUrl: widget.autoAddUrl,
          autoAddType: widget.autoAddType,
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
      length: 4,
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
              manager: manager,
              type: bridge.ItemType.anime,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: true,
            ),
            SourcesTab(
              manager: manager,
              type: bridge.ItemType.manga,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: true,
            ),
            SourcesTab(
              manager: manager,
              type: bridge.ItemType.anime,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: false,
            ),
            SourcesTab(
              manager: manager,
              type: bridge.ItemType.manga,
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
            Tab(text: 'Available Anime'),
            Tab(text: 'Available Manga'),
          ],
        ),
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
      _buildLanguageFilter(manager),
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

  Widget _buildLanguageFilter(bridge.Extension manager) {
    final Set<String> langs = {'All'};
    final availableAnime = manager.getAvailableRx(bridge.ItemType.anime).value;
    for (final e in availableAnime) {
      if (e.lang != null) langs.add(e.lang!);
    }
    final installedAnime = manager.getInstalledRx(bridge.ItemType.anime).value;
    for (final e in installedAnime) {
      if (e.lang != null) langs.add(e.lang!);
    }

    final availableManga = manager.getAvailableRx(bridge.ItemType.manga).value;
    for (final e in availableManga) {
      if (e.lang != null) langs.add(e.lang!);
    }
    final installedManga = manager.getInstalledRx(bridge.ItemType.manga).value;
    for (final e in installedManga) {
      if (e.lang != null) langs.add(e.lang!);
    }

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
          height: 48,
          child: SegmentedButton<String>(
            style: SegmentedButton.styleFrom(
              minimumSize: const Size(0, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            segments: const [
              ButtonSegment(
                value: 'mangayomi',
                label: Text('Mangayomi', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: 'aniyomi',
                label: Text('Tachiyomi', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {manager.id.replaceAll('-desktop', '')},
            onSelectionChanged: (selected) {
              ref
                  .read(extensionManagerProvider.notifier)
                  .setManager(selected.first);
              ref.invalidate(availableAnimeSourcesProvider);
              ref.invalidate(availableMangaSourcesProvider);
            },
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

  void _showGuideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
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
                '• Mangayomi: All-in-one ecosystem supporting both anime and manga extensions seamlessly.',
              ),
              const SizedBox(height: 16),
              Text(
                'How to get & install extensions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Toggle between Mangayomi or Tachiyomi/Aniyomi ecosystems at the bottom right.\n2. Tap "Manage Repos" to paste your repository index link or click deep links directly from browser.\n3. Switch to the Available tab to discover extensions.\n4. Tap the + icon to install an extension, then customize your sources!',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Got it!', style: TextStyle(fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}
