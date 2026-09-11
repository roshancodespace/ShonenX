import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/discovery/domain/models/search_filter_options.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/advanced_search_sheet.dart';
import 'package:shonenx/features/discovery/providers/search_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/navbar_action_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/media_switcher_overlay.dart';
import 'package:shonenx/shared/widgets/unified_search_bar.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Primary Browser and Search screen for discovering anime, manga, and other media.
class DiscoverScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? category;
  final MediaType type;
  final List<String> initialGenres;
  final List<String> initialTags;
  final String? source;
  final String? customTitle;
  final SearchSort initialSort;
  final SearchStatusFilter initialStatus;
  final SearchFormatFilter initialFormat;

  const DiscoverScreen({
    super.key,
    this.initialQuery,
    this.category,
    this.type = MediaType.ANIME,
    this.initialGenres = const [],
    this.initialTags = const [],
    this.source,
    this.customTitle,
    this.initialSort = SearchSort.popularity,
    this.initialStatus = SearchStatusFilter.all,
    this.initialFormat = SearchFormatFilter.all,
  });

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final ScrollController _scrollController;
  late TabController _tabController;

  Timer? _debounceTimer;

  String _query = '';
  late MediaType _selectedType;
  String? _selectedCategory;
  List<String> _selectedGenres = [];
  List<String> _selectedTags = [];
  String? _selectedSource;
  late SearchSort _sort;
  late SearchStatusFilter _status;
  late SearchFormatFilter _format;

  List<MediaType> _supportedMediaTypes = [];
  bool _isLoadingMore = false;

  // Curated quick genre suggestions when browsing without query/filters
  static const List<String> _quickGenres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Romance',
    'Sci-Fi',
    'Supernatural',
    'Mystery',
    'Slice of Life',
    'Sports',
    'Horror',
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _selectedType = widget.type;
    _selectedCategory = widget.category;
    _selectedGenres = List.from(widget.initialGenres);
    _selectedTags = List.from(widget.initialTags);
    _selectedSource = widget.source;
    _sort = widget.initialSort;
    _status = widget.initialStatus;
    _format = widget.initialFormat;

    _searchController = TextEditingController(text: _query)
      ..addListener(_onSearchInputChanged);
    _searchFocusNode = FocusNode();
    _scrollController = ScrollController()..addListener(_onScroll);

    _supportedMediaTypes = ref.read(metadataSourceProvider).supportedMediaTypes;
    int initIndex = _supportedMediaTypes.indexOf(widget.type);
    if (initIndex == -1) initIndex = 0;

    _tabController = TabController(
      length: _supportedMediaTypes.length,
      vsync: this,
      initialIndex: initIndex,
    )..addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _attachOverlay();
    });
  }

  void _attachOverlay() {
    // Attach MediaSwitcherOverlay above bottom nav bar on branch 1
    Future.microtask(() {
      try {
        ref
            .read(navBarProvider.notifier)
            .attachTop(
              MediaSwitcherOverlay(
                controller: _tabController,
                supportedTypes: _supportedMediaTypes,
              ),
              branchIndex: 1,
            );
      } catch (_) {}
    });
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    if (_tabController.index >= 0 &&
        _tabController.index < _supportedMediaTypes.length) {
      final newType = _supportedMediaTypes[_tabController.index];
      if (newType != _selectedType) {
        setState(() => _selectedType = newType);
        _resetScroll();
      }
    }
  }

  void _rebuildTabController(List<MediaType> newTypes) {
    if (!mounted) return;
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();

    setState(() {
      _supportedMediaTypes = newTypes;
      int initIndex = _supportedMediaTypes.indexOf(_selectedType);
      if (initIndex == -1) initIndex = 0;
      _tabController = TabController(
        length: newTypes.length,
        vsync: this,
        initialIndex: initIndex,
      )..addListener(_onTabChanged);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _attachOverlay();
    });
  }

  @override
  void didUpdateWidget(covariant DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery ||
        oldWidget.category != widget.category ||
        oldWidget.type != widget.type ||
        oldWidget.source != widget.source ||
        oldWidget.initialSort != widget.initialSort ||
        oldWidget.initialStatus != widget.initialStatus ||
        oldWidget.initialFormat != widget.initialFormat ||
        !listEquals(oldWidget.initialGenres, widget.initialGenres) ||
        !listEquals(oldWidget.initialTags, widget.initialTags)) {
      setState(() {
        _query = widget.initialQuery?.trim() ?? '';
        _searchController.text = _query;
        _selectedCategory = widget.category;
        _selectedType = widget.type;
        _selectedSource = widget.source;
        _selectedGenres = List.from(widget.initialGenres);
        _selectedTags = List.from(widget.initialTags);
        _sort = widget.initialSort;
        _status = widget.initialStatus;
        _format = widget.initialFormat;

        final typeIndex = _supportedMediaTypes.indexOf(widget.type);
        if (typeIndex != -1 && typeIndex != _tabController.index) {
          _tabController.animateTo(typeIndex);
        }
      });
      _resetScroll();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchInputChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    Future.microtask(() {
      try {
        ref.read(navBarProvider.notifier).clearTop(branchIndex: 1);
      } catch (_) {}
    });

    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _selectedGenres.isNotEmpty ||
      _selectedTags.isNotEmpty ||
      _selectedSource != null ||
      _sort != SearchSort.popularity ||
      _status != SearchStatusFilter.all ||
      _format != SearchFormatFilter.all;

  /// Effective arguments passed to [searchProvider].
  /// When active filters or queries are present, executes a filtered search.
  /// When no search query or filter is active, defaults to category browse (e.g. trending).
  SearchArgs get _currentSearchArgs {
    final query = _query.trim();
    final isSearchingOrFiltering = query.isNotEmpty || _hasActiveFilters;

    return SearchArgs(
      query: query,
      category: isSearchingOrFiltering
          ? null
          : (_selectedCategory ?? TrackerCategory.trending.id),
      type: _selectedType,
      genres: _selectedGenres,
      tags: _selectedTags,
      source: _selectedSource,
      sort: _sort,
      status: _status,
      format: _format,
    );
  }

  void _onSearchInputChanged() {
    final text = _searchController.text.trim();

    // Reset immediately on empty query without debounce delay
    if (text.isEmpty) {
      _debounceTimer?.cancel();
      if (_query.isNotEmpty) {
        setState(() => _query = '');
        _resetScroll();
      }
      return;
    }

    // Skip if unchanged to prevent duplicate requests
    if (text == _query) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final currentText = _searchController.text.trim();
      if (currentText != _query) {
        setState(() => _query = currentText);
        _resetScroll();
      }
    });
  }

  void _onSearchSubmitted(String value) {
    _debounceTimer?.cancel();
    final trimmed = value.trim();
    if (trimmed != _query) {
      setState(() => _query = trimmed);
      _resetScroll();
    }
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    if (_query.isNotEmpty) {
      setState(() => _query = '');
      _resetScroll();
    }
  }

  void _resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 250) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    final state = ref.read(searchProvider(_currentSearchArgs));
    if (state.value?.hasNextPage != true) return;

    setState(() => _isLoadingMore = true);
    try {
      await ref
          .read(searchProvider(_currentSearchArgs).notifier)
          .loadNextPage();
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _openAdvancedSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      constraints: const BoxConstraints(maxWidth: 800),
      builder: (context) {
        return AdvancedSearchSheet(
          initialQuery: _query,
          type: _selectedType,
          initialGenres: _selectedGenres,
          initialTags: _selectedTags,
          sourceId: _selectedSource,
          initialSort: _sort,
          initialStatus: _status,
          initialFormat: _format,
          onApply: (query, genres, tags, sort, status, format) {
            setState(() {
              final trimmed = query.trim();
              if (trimmed != _query) {
                _query = trimmed;
                _searchController.text = trimmed;
              }
              _selectedGenres = genres;
              _selectedTags = tags;
              _sort = sort;
              _status = status;
              _format = format;
            });
            _resetScroll();
          },
        );
      },
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedGenres.clear();
      _selectedTags.clear();
      _selectedSource = null;
      _selectedCategory = null;
      _sort = SearchSort.popularity;
      _status = SearchStatusFilter.all;
      _format = SearchFormatFilter.all;
    });
    _resetScroll();
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
    _resetScroll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uiRoundness = GlobalUI.uiRoundness;
    final searchState = ref.watch(searchProvider(_currentSearchArgs));
    final canPop = Navigator.of(context).canPop();

    // Listen for metadata source changes to rebuild tab controller if types change
    ref.listen(metadataSourceProvider, (prev, next) {
      if (prev?.supportedMediaTypes != next.supportedMediaTypes) {
        _rebuildTabController(next.supportedMediaTypes);
      }
    });

    return AppScaffold(
      showBackButton: false,
      bottomNavigationBar: canPop && _supportedMediaTypes.length > 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MediaSwitcherOverlay(
                  controller: _tabController,
                  supportedTypes: _supportedMediaTypes,
                ),
              ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Unified Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
              child: UnifiedSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: false,
                leading: canPop ? null : const Icon(Icons.search_rounded),
                hintText:
                    'Search ${_selectedType.displayName.toLowerCase()}...',
                hasFilters: _hasActiveFilters,
                onBackPressed: () => Navigator.of(context).maybePop(),
                onClearPressed: _clearSearch,
                onSubmitted: _onSearchSubmitted,
                onFilterPressed: _openAdvancedSearch,
                margin: EdgeInsets.zero,
              ),
            ),

            // Active Filter Chips or Quick Genre Suggestions
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _hasActiveFilters
                  ? _buildActiveFilterChips(colorScheme, uiRoundness)
                  : _buildQuickGenreChips(colorScheme, uiRoundness),
            ),

            // Results Grid / State handling
            Expanded(
              child: searchState.when(
                loading: () => _buildSkeletonGrid(),
                error: (e, _) => _buildErrorState(colorScheme, e),
                data: (result) {
                  final items = result?.items ?? [];
                  if (items.isEmpty) {
                    return _buildEmptyState(colorScheme);
                  }
                  return _buildMediaGrid(items, result?.hasNextPage ?? false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips(ColorScheme colorScheme, double uiRoundness) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          ..._selectedGenres.map(
            (genre) => _buildRemovableChip(
              label: genre,
              onDeleted: () => _toggleGenre(genre),
              colorScheme: colorScheme,
              uiRoundness: uiRoundness,
            ),
          ),
          ..._selectedTags.map(
            (tag) => _buildRemovableChip(
              label: '#$tag',
              onDeleted: () {
                setState(() => _selectedTags.remove(tag));
                _resetScroll();
              },
              colorScheme: colorScheme,
              uiRoundness: uiRoundness,
            ),
          ),
          if (_selectedSource != null)
            _buildRemovableChip(
              label: 'Source: ${_getSourceName(_selectedSource!)}',
              onDeleted: () {
                setState(() => _selectedSource = null);
                _resetScroll();
              },
              colorScheme: colorScheme,
              uiRoundness: uiRoundness,
            ),
          if (_sort != SearchSort.popularity)
            _buildRemovableChip(
              label: 'Sort: ${_sort.label}',
              onDeleted: () {
                setState(() => _sort = SearchSort.popularity);
                _resetScroll();
              },
              colorScheme: colorScheme,
              uiRoundness: uiRoundness,
            ),
          if (_status != SearchStatusFilter.all)
            _buildRemovableChip(
              label: 'Status: ${_status.label}',
              onDeleted: () {
                setState(() => _status = SearchStatusFilter.all);
                _resetScroll();
              },
              colorScheme: colorScheme,
              uiRoundness: uiRoundness,
            ),
          if (_format != SearchFormatFilter.all)
            _buildRemovableChip(
              label: 'Format: ${_format.label}',
              onDeleted: () {
                setState(() => _format = SearchFormatFilter.all);
                _resetScroll();
              },
              colorScheme: colorScheme,
              uiRoundness: uiRoundness,
            ),
          TextButton(
            onPressed: _clearAllFilters,
            child: const Text('Clear all', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildRemovableChip({
    required String label,
    required VoidCallback onDeleted,
    required ColorScheme colorScheme,
    required double uiRoundness,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InputChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close_rounded, size: 14),
        onDeleted: onDeleted,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(uiRoundness),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickGenreChips(ColorScheme colorScheme, double uiRoundness) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _quickGenres.map((genre) {
          final isSelected = _selectedGenres.contains(genre);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              label: Text(genre),
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              backgroundColor: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(uiRoundness),
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              visualDensity: VisualDensity.compact,
              onPressed: () => _toggleGenre(genre),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMediaGrid(List<UnifiedMedia> items, bool hasNextPage) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));
    final isWideMode = ref.watch(
      uiPrefsProvider.select((s) => s.isMediaCardWide(style.name)),
    );
    final scale = GlobalUI.uiScaleFactor;
    final layout = style.getScaledLayout(scale, isWideMode: isWideMode);

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 160),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMinCrossAxisExtent(
              minCrossAxisExtent: layout.width,
              childAspectRatio: layout.aspectRatio,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final media = items[index];
              return MediaCard(
                tag: 'browse-${media.id}',
                format: media.format,
                score: media.score,
                status: media.status,
                genres: media.genres,
                year: media.season,
                title: media.title.availableTitle,
                imageUrl: media.cover ?? media.banner ?? '',
                style: style,
                onTap: () => context.pushDetails(
                  mediaType: media.type,
                  media: media,
                  tag: 'browse-${media.id}',
                ),
              );
            }, childCount: items.length),
          ),
        ),
        if (_isLoadingMore && hasNextPage)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSkeletonGrid() {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));
    final isWideMode = ref.watch(
      uiPrefsProvider.select((s) => s.isMediaCardWide(style.name)),
    );
    final scale = GlobalUI.uiScaleFactor;
    final layout = style.getScaledLayout(scale, isWideMode: isWideMode);

    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 160),
        gridDelegate: SliverGridDelegateWithMinCrossAxisExtent(
          minCrossAxisExtent: layout.width,
          childAspectRatio: layout.aspectRatio,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          return MediaCard(
            tag: 'skeleton-$index',
            title: 'Placeholder Title',
            imageUrl: '',
            style: style,
            format: 'TV',
            score: 8.5,
            year: '2026',
            onTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              _query.isNotEmpty
                  ? 'No results for "$_query"'
                  : 'No media matches the current filters',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search term or clear active filters',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_query.isNotEmpty || _hasActiveFilters) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  _clearSearch();
                  _clearAllFilters();
                },
                child: const Text('Reset All'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: colorScheme.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load results',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              onPressed: () =>
                  ref.invalidate(searchProvider(_currentSearchArgs)),
            ),
          ],
        ),
      ),
    );
  }

  String _getSourceName(String sourceId) {
    final animeSources = ref.read(availableAnimeSourcesProvider).value ?? [];
    final mangaSources = ref.read(availableMangaSourcesProvider).value ?? [];
    final allSources = [...animeSources, ...mangaSources];
    final match = allSources.firstWhereOrNull((s) => s.id == sourceId);
    return match?.name ?? sourceId;
  }
}
