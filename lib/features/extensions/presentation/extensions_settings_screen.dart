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
  const ExtensionsSettingsScreen({super.key});

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
        return AppBottomSheet(
          title: 'Extensions Guide',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'This app supports installing external community extensions to fetch content from various sources.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Repository Types',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Mangayomi: A modern extension ecosystem. Recommended for best compatibility.',
              ),
              const SizedBox(height: 4),
              const Text(
                '• Tachiyomi / Aniyomi: The classic extension ecosystem. Available for backward compatibility.',
              ),
              const SizedBox(height: 16),
              Text(
                'How to use',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Select your preferred extension ecosystem from the top toggle.\n2. Click the Manage Repos button at the bottom to add or delete repository URLs.\n3. Once added, the available extensions will appear in the Available tab.\n4. Click the + icon to install an extension and start watching!',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it!'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showManageReposSheet(BuildContext context) {
    final manager = ref.watch(extensionManagerProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManageReposSheet(manager: manager),
    );
  }
}
