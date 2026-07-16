import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/app_init.dart';
import 'package:shonenx/features/extensions/providers/extension_service_provider.dart';
import 'package:shonenx/features/extensions/providers/extensions_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/source_registry.dart';

import 'widgets/extension_beginner_sheet.dart';
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
        final repos = ref.read(activeExtReposProvider);
        if (repos.isEmpty) {
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

    return DefaultTabController(
      length: 6,
      child: AppScaffold(
        title: _isSearching ? null : 'Sources',
        subtitle: _isSearching ? null : 'Extensions & Catalogs',
        floatingActionButtonLocation: MediaQuery.of(context).size.width < 600
            ? FloatingActionButtonLocation.centerFloat
            : FloatingActionButtonLocation.endFloat,
        titleWidget: _isSearching ? _buildSearchField(theme) : null,
        barBottom: _buildBarBottom(),
        actions: _buildActions(context),
        body: TabBarView(
          children: [
            SourcesTab(
              engineFilter: _selectedEngineFilter,
              type: MediaType.ANIME,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: true,
            ),
            SourcesTab(
              engineFilter: _selectedEngineFilter,
              type: MediaType.MANGA,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: true,
            ),
            SourcesTab(
              engineFilter: _selectedEngineFilter,
              type: MediaType.NOVEL,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: true,
            ),
            SourcesTab(
              engineFilter: _selectedEngineFilter,
              type: MediaType.ANIME,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: false,
            ),
            SourcesTab(
              engineFilter: _selectedEngineFilter,
              type: MediaType.MANGA,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: false,
            ),
            SourcesTab(
              engineFilter: _selectedEngineFilter,
              type: MediaType.NOVEL,
              searchQuery: _searchQuery,
              langFilter: _selectedLangFilter,
              isInstalled: false,
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) => _buildFab(context, theme),
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

  PreferredSizeWidget _buildBarBottom() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(88),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildFilterBar(), _buildTabBarContent()],
      ),
    );
  }

  Widget _buildFilterBar() {
    final cs = Theme.of(context).colorScheme;
    final roundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _buildEngineCapsule(cs, roundness),
          const SizedBox(width: 8),
          _buildLanguageCapsule(cs, roundness),
          if (_selectedEngineFilter != 'All' ||
              _selectedLangFilter != 'All') ...[
            const SizedBox(width: 8),
            _buildResetCapsule(cs, roundness),
          ],
        ],
      ),
    );
  }

  Widget _buildEngineCapsule(ColorScheme cs, double roundness) {
    const engines = [
      'All',
      'Mangayomi',
      'Tachiyomi',
      'CloudStream',
      'Kotatsu',
      'Sora',
    ];
    final isAll = _selectedEngineFilter == 'All';

    return PopupMenuButton<String>(
      initialValue: _selectedEngineFilter,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(roundness),
      ),
      onSelected: (val) => setState(() => _selectedEngineFilter = val),
      itemBuilder: (context) {
        return engines.map((e) {
          final isSelected = _selectedEngineFilter == e;
          return PopupMenuItem<String>(
            value: e,
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
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
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAll
              ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
              : cs.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAll
                ? Colors.transparent
                : cs.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.extension_rounded,
              size: 16,
              color: isAll ? cs.onSurfaceVariant : cs.onPrimaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              isAll ? 'All Engines' : _selectedEngineFilter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isAll ? FontWeight.w500 : FontWeight.bold,
                color: isAll ? cs.onSurfaceVariant : cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isAll ? cs.onSurfaceVariant : cs.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCapsule(ColorScheme cs, double roundness) {
    final sortedLangs = ExtensionsService.getAvailableLanguages();
    final isAll = _selectedLangFilter == 'All';

    return PopupMenuButton<String>(
      initialValue: _selectedLangFilter,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(roundness),
      ),
      onSelected: (val) => setState(() => _selectedLangFilter = val),
      itemBuilder: (context) {
        return sortedLangs.map((l) {
          final isSelected = _selectedLangFilter == l;
          return PopupMenuItem<String>(
            value: l,
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(
                  l == 'All' ? 'All Languages' : l.toUpperCase(),
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
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAll
              ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
              : cs.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAll
                ? Colors.transparent
                : cs.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 16,
              color: isAll ? cs.onSurfaceVariant : cs.onPrimaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              isAll ? 'All Languages' : _selectedLangFilter.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isAll ? FontWeight.w500 : FontWeight.bold,
                color: isAll ? cs.onSurfaceVariant : cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isAll ? cs.onSurfaceVariant : cs.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetCapsule(ColorScheme cs, double roundness) {
    return InkWell(
      onTap: () => setState(() {
        _selectedEngineFilter = 'All';
        _selectedLangFilter = 'All';
      }),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 14, color: cs.onErrorContainer),
            const SizedBox(width: 4),
            Text(
              'Reset',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarContent() {
    final animeSources = ref.watch(availableAnimeSourcesProvider).value ?? [];
    final mangaSources = ref.watch(availableMangaSourcesProvider).value ?? [];
    final novelSources = ref.watch(availableNovelSourcesProvider).value ?? [];
    final enabledManagers = ref.watch(enabledExtensionManagersProvider);

    // 5. Removed Obx entirely. Riverpod's `ref.watch` already triggers rebuilds.
    final countInstalledAnime = ExtensionsService.getSourcesTabCount(
      type: MediaType.ANIME,
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
      type: MediaType.MANGA,
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
      type: MediaType.NOVEL,
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
      type: MediaType.ANIME,
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
      type: MediaType.MANGA,
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
      type: MediaType.NOVEL,
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
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      tabs: [
        _buildTab('Installed Anime', countInstalledAnime),
        _buildTab('Installed Manga', countInstalledManga),
        _buildTab('Installed Novel', countInstalledNovel),
        _buildTab('Available Anime', countAvailableAnime),
        _buildTab('Available Manga', countAvailableManga),
        _buildTab('Available Novel', countAvailableNovel),
      ],
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

  List<Widget> _buildActions(BuildContext context) {
    if (_isSearching) {
      return [
        if (_searchQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            tooltip: 'Clear',
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close Search',
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        const SizedBox(width: 4),
      ];
    }

    return [
      TextButton(
        onPressed: () => ExtensionBeginnerSheet.show(context),
        child: Text(
          'Retarded?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.search_rounded),
        tooltip: 'Search Extensions',
        onPressed: () => setState(() => _isSearching = true),
      ),
      IconButton(
        icon: const Icon(Icons.speed_rounded),
        tooltip: 'Test Extensions',
        onPressed: () => context.push('/settings/extensions/test'),
      ),
      IconButton(
        icon: const Icon(Icons.info_outline_rounded),
        tooltip: 'Extension Guide',
        onPressed: () => ExtensionGuideSheet.show(context),
      ),
      const SizedBox(width: 4),
    ];
  }

  Widget _buildFab(BuildContext context, ThemeData theme) {
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

            final isRuntimeReady = AppInit.isBridgeInitialized;
            final cs = Theme.of(context).colorScheme;

            final engines = [
              (
                'mangayomi',
                'Mangayomi Engine',
                'External runtime engine for Anime & Manga extensions',
                Icons.auto_awesome_mosaic_rounded,
              ),
              (
                'aniyomi',
                'Tachiyomi / Aniyomi Engine',
                'External runtime engine for Manga & Anime extensions',
                Icons.video_library_rounded,
              ),
              (
                'cloudstream',
                'CloudStream Engine',
                'External runtime engine for Video streaming extensions',
                Icons.cloud_queue_rounded,
              ),
              (
                'kotatsu',
                'Kotatsu Engine',
                'External runtime engine for Manga reading extensions',
                Icons.menu_book_rounded,
              ),
              (
                'sora',
                'Sora Engine',
                'External runtime engine for Novel & Anime extensions',
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
                      'Enable or disable external extension runtime engines. Enabled engines will appear in your catalogs and discovery feeds alongside your native inbuilt sources.',
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
                    final isRuntimeEngine = [
                      'mangayomi',
                      'aniyomi',
                      'cloudstream',
                      'kotatsu',
                      'sora',
                    ].contains(id);

                    final isEnabled =
                        enabled.contains(id) &&
                        (!isRuntimeEngine || isRuntimeReady);

                    return SettingsSwitchTile(
                      icon: e.$4,
                      title: title,
                      subtitle: desc,
                      value: isEnabled,
                      onChanged: (val) {
                        if (val && isRuntimeEngine) {
                          if (!isRuntimeReady) {
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManageReposSheet(
        managerId: 'aniyomi',
        autoAddUrl: autoAddUrl,
        autoAddType: autoAddType,
        autoAddManager: autoAddManager,
      ),
    );
  }
}
