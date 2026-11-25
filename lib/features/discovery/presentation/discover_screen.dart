import 'dart:async';

import 'package:shonenx/shared/widgets/smart_image.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/discovery/domain/models/search_filter_options.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/advanced_search_sheet.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/metadata_tags_provider.dart';
import 'package:shonenx/features/discovery/providers/search_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/navbar_action_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/media_switcher_overlay.dart';
import 'package:shonenx/shared/widgets/unified_search_bar.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';

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
  List<String> _selectedGenres = [];
  List<String> _selectedTags = [];
  String? _selectedSource;
  List<String> _selectedSources = [];
  late SearchSort _sort;
  late SearchStatusFilter _status;
  late SearchFormatFilter _format;

  List<MediaType> _supportedMediaTypes = [];
  bool _isLoadingMore = false;
  bool? _wasBranchActive;

  int _selectedQuickTileSection = 0;

  void _requestSearchFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (TickerMode.valuesOf(context).enabled &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isBranchActive = TickerMode.valuesOf(context).enabled;
    if (_wasBranchActive == null) {
      _wasBranchActive = isBranchActive;
      if (isBranchActive &&
          widget.initialQuery == null &&
          widget.initialGenres.isEmpty &&
          widget.initialTags.isEmpty &&
          widget.category == null) {
        _requestSearchFocus();
      }
    } else if (_wasBranchActive != isBranchActive) {
      _wasBranchActive = isBranchActive;
      if (isBranchActive) {
        _requestSearchFocus();
      } else {
        _searchFocusNode.unfocus();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _selectedType = widget.type;
    _selectedGenres = List.from(widget.initialGenres);
    _selectedTags = List.from(widget.initialTags);
    _selectedSource = widget.source;
    _selectedSources = widget.source != null ? [widget.source!] : [];
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
    Future.microtask(() {
      try {
        if (!mounted || Navigator.of(context).canPop()) return;
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
        setState(() {
          _selectedType = newType;
          _selectedSources.clear();
          _selectedSource = null;
        });
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
        _selectedType = widget.type;
        _selectedSource = widget.source;
        _selectedSources = widget.source != null ? [widget.source!] : [];
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
      _hasActiveNonTileFilters ||
      _selectedSources.isNotEmpty ||
      _selectedSource != null;

  bool get _hasActiveNonTileFilters =>
      _selectedGenres.isNotEmpty ||
      _selectedTags.isNotEmpty ||
      _sort != SearchSort.popularity ||
      _status != SearchStatusFilter.all ||
      _format != SearchFormatFilter.all;

  bool get _hasLocalChanges =>
      _query.trim() != (widget.initialQuery?.trim() ?? '') ||
      !listEquals(_selectedGenres, widget.initialGenres) ||
      !listEquals(_selectedTags, widget.initialTags) ||
      _selectedSource != widget.source ||
      _selectedSources.length > (widget.source != null ? 1 : 0) ||
      _sort != widget.initialSort ||
      _status != widget.initialStatus ||
      _format != widget.initialFormat;

  bool get _isSearchingOrFiltering =>
      _query.trim().isNotEmpty ||
      _hasActiveFilters ||
      widget.category != null ||
      widget.initialQuery != null;

  SearchArgs? get _currentSearchArgs {
    if (!_isSearchingOrFiltering) return null;

    final query = _query.trim();

    return SearchArgs(
      query: query,
      category: widget.category,
      type: _selectedType,
      genres: _selectedGenres,
      tags: _selectedTags,
      source: _selectedSources.length == 1
          ? _selectedSources.first
          : _selectedSource,
      sources: _selectedSources,
      sort: _sort,
      status: _status,
      format: _format,
    );
  }

  void _onSearchInputChanged() {
    final text = _searchController.text.trim();

    if (text.isEmpty) {
      _debounceTimer?.cancel();
      if (_query.isNotEmpty) {
        setState(() => _query = '');
        _resetScroll();
      }
      return;
    }

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
    final initial = widget.initialQuery ?? '';
    _searchController.text = initial;
    if (_query != initial) {
      setState(() => _query = initial);
      _resetScroll();
    }
  }

  void _resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onScroll({bool isAutomatic = false}) {
    if (!_scrollController.hasClients || _isLoadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 250) {
      _loadNextPage(isAutomatic: isAutomatic);
    }
  }

  Future<void> _loadNextPage({bool isAutomatic = false}) async {
    final args = _currentSearchArgs;
    if (args == null || !_scrollController.hasClients || _isLoadingMore) return;
    final state = ref.read(searchProvider(args));
    if (state.value?.hasNextPage != true) return;

    setState(() => _isLoadingMore = true);
    try {
      if (isAutomatic) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
      if (!mounted) return;
      await ref.read(searchProvider(args).notifier).loadNextPage();
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
          sourceId: _selectedSources.length == 1
              ? _selectedSources.first
              : _selectedSource,
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
      _selectedGenres = List.from(widget.initialGenres);
      _selectedTags = List.from(widget.initialTags);
      _selectedSource = widget.source;
      _selectedSources = widget.source != null ? [widget.source!] : [];
      _sort = widget.initialSort;
      _status = widget.initialStatus;
      _format = widget.initialFormat;
    });
    _resetScroll();
  }

  void _toggleSource(String sourceId) {
    setState(() {
      if (_selectedSources.contains(sourceId)) {
        _selectedSources.remove(sourceId);
      } else {
        _selectedSources.add(sourceId);
      }
      _selectedSource = _selectedSources.length == 1
          ? _selectedSources.first
          : null;
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

  void _onQuickTileTap(String name, {required bool isTag}) {
    setState(() {
      if (isTag) {
        _selectedTags = [name];
        _selectedGenres.clear();
      } else {
        _selectedGenres = [name];
        _selectedTags.clear();
      }
    });
    _resetScroll();
  }

  void _handleBack() {
    if (_hasLocalChanges) {
      _clearSearch();
      _clearAllFilters();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uiRoundness = GlobalUI.uiRoundness;
    final prefs = ref.watch(discoveryPrefsProvider);
    final isTrackerMode = prefs.mode == MetadataMode.tracker;
    final filtersAsync = isTrackerMode
        ? ref.watch(
            discoveryFiltersProvider((type: _selectedType, sourceId: null)),
          )
        : null;
    final searchArgs = _currentSearchArgs;
    final searchState = searchArgs != null
        ? ref.watch(searchProvider(searchArgs))
        : null;
    final canPop = Navigator.of(context).canPop();

    ref.listen(metadataSourceProvider, (prev, next) {
      if (prev?.supportedMediaTypes != next.supportedMediaTypes) {
        _rebuildTabController(next.supportedMediaTypes);
      }
    });

    if (searchArgs != null) {
      ref.listen(searchProvider(searchArgs), (prev, next) {
        if (!next.isLoading && next.hasValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onScroll(isAutomatic: true);
          });
        }
      });
    }

    final showBack = canPop || _hasLocalChanges;

    return PopScope(
      canPop: canPop && !_hasLocalChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: AppScaffold(
        showBackButton: false,
        bottomNavigationBar: null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: UnifiedSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: false,
                leading: showBack ? null : const Icon(Icons.search_rounded),
                hintText: widget.customTitle != null
                    ? 'Search in ${widget.customTitle}...'
                    : 'Search ${_selectedType.displayName.toLowerCase()}...',
                hasFilters: _hasActiveFilters,
                onBackPressed: _handleBack,
                onClearPressed: _clearSearch,
                onSubmitted: _onSearchSubmitted,
                onFilterPressed: _openAdvancedSearch,
                margin: EdgeInsets.zero,
              ),
            ),
            if (!isTrackerMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSourceFilterTiles(
                  context,
                  prefs,
                  colorScheme,
                  uiRoundness,
                ),
              ),
            if (_hasActiveNonTileFilters)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildActiveFilterChips(colorScheme, uiRoundness),
              ),
            Expanded(
              child: searchState == null
                  ? (isTrackerMode
                        ? _buildGenreGridView(
                            context,
                            colorScheme,
                            uiRoundness,
                            filtersAsync!,
                          )
                        : _buildSourceGridView(
                            context,
                            prefs,
                            colorScheme,
                            uiRoundness,
                          ))
                  : searchState.when(
                      loading: () => _buildSkeletonGrid(),
                      error: (e, _) => _buildErrorState(colorScheme, e),
                      data: (result) {
                        final items = result?.items ?? [];
                        if (items.isEmpty) {
                          return _buildEmptyState(colorScheme);
                        }
                        return _buildMediaGrid(
                          items,
                          result?.hasNextPage ?? false,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreGridView(
    BuildContext context,
    ColorScheme colorScheme,
    double uiRoundness,
    AsyncValue<MetadataTagsState> filtersAsync,
  ) {
    final tracker = ref.watch(metadataSourceProvider);

    return filtersAsync.when(
      loading: () =>
          _buildQuickTilesSkeleton(context, colorScheme, uiRoundness),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.category_outlined, size: 44, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load genres from ${tracker.type.displayName}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                onPressed: () => ref.invalidate(
                  discoveryFiltersProvider((
                    type: _selectedType,
                    sourceId: null,
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (filterState) {
        final genres = filterState.genres;
        final tags = filterState.tags;

        if (genres.isEmpty && tags.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No genres available for ${tracker.type.displayName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the search bar above to find media directly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final isShowingGenres = _selectedQuickTileSection == 0 || tags.isEmpty;
        final items = isShowingGenres ? genres : tags;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Text(
                      isShowingGenres ? 'Genres' : 'Tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(
                          uiRoundness.clamp(6.0, 12.0),
                        ),
                      ),
                      child: Text(
                        '${items.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (tags.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(
                            uiRoundness.clamp(8.0, 20.0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _DiscoverModeTab(
                              label: 'Genres',
                              selected: isShowingGenres,
                              radius: (uiRoundness - 2).clamp(6.0, 18.0),
                              onTap: () =>
                                  setState(() => _selectedQuickTileSection = 0),
                            ),
                            _DiscoverModeTab(
                              label: 'Tags',
                              selected: !isShowingGenres,
                              radius: (uiRoundness - 2).clamp(6.0, 18.0),
                              onTap: () =>
                                  setState(() => _selectedQuickTileSection = 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 136),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < items.length; i++)
                      _buildQuickTileCard(
                        context: context,
                        name: items[i],
                        isTag: !isShowingGenres,
                        uiRoundness: uiRoundness,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickTilesSkeleton(
    BuildContext context,
    ColorScheme colorScheme,
    double uiRoundness,
  ) {
    const dummyItems = [
      'Action',
      'Adventure',
      'Comedy',
      'Drama',
      'Fantasy',
      'Horror',
      'Romance',
      'Sci-Fi',
      'Slice of Life',
      'Supernatural',
      'Mystery',
      'Sports',
    ];

    return Skeletonizer(
      enabled: true,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.category_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Browse Genres',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 136),
            sliver: SliverToBoxAdapter(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in dummyItems)
                    _buildQuickTileCard(
                      context: context,
                      name: item,
                      isTag: false,
                      uiRoundness: uiRoundness,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTileCard({
    required BuildContext context,
    required String name,
    required bool isTag,
    required double uiRoundness,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(uiRoundness.clamp(10.0, 24.0));

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onQuickTileTap(name, isTag: isTag),
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            isTag ? '#$name' : name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  List<SourceInfo> _resolveSources(
    List<SourceInfo> allSources,
    DiscoveryPrefs prefs,
  ) {
    final active = allSources
        .where((s) => prefs.activeSources.contains(s.id))
        .toList();
    return active.isNotEmpty ? active : allSources;
  }

  Widget _buildSourceIcon(
    SourceInfo source,
    ColorScheme colorScheme, {
    double size = 20,
    double radius = 4,
    Color? fallbackColor,
  }) {
    final icon = source.type == SourceType.inbuilt
        ? Icons.home_rounded
        : Icons.extension_rounded;
    final color = fallbackColor ?? colorScheme.primary;

    if (source.iconUrl != null && source.iconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SmartImage(
          imageUrl: source.iconUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Icon(icon, size: size, color: color),
        ),
      );
    }
    return Icon(icon, size: size, color: color);
  }

  Widget _buildSourceGridView(
    BuildContext context,
    DiscoveryPrefs prefs,
    ColorScheme colorScheme,
    double uiRoundness,
  ) {
    final sourcesAsync = ref.watch(_selectedType.availableSourcesProvider);

    return sourcesAsync.when(
      data: (allSources) {
        final sources = _resolveSources(allSources, prefs);

        if (sources.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.extension_off_rounded,
                    size: 48,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No sources available',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Install extensions to discover content directly from sources',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.extension_rounded, size: 16),
                    label: const Text('Manage Extensions'),
                    onPressed: () => context.pushSettingsExtensions(),
                  ),
                ],
              ),
            ),
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'Sources',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Select to browse',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 136),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final source in sources)
                      _buildSourceGridCard(
                        context: context,
                        source: source,
                        isSelected: _selectedSources.contains(source.id),
                        colorScheme: colorScheme,
                        uiRoundness: uiRoundness,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
      error: (e, _) => Center(child: Text('Failed to load sources: $e')),
    );
  }

  Widget _buildSourceGridCard({
    required BuildContext context,
    required SourceInfo source,
    required bool isSelected,
    required ColorScheme colorScheme,
    required double uiRoundness,
  }) {
    final radius = BorderRadius.circular(uiRoundness.clamp(10.0, 24.0));

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHigh,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _toggleSource(source.id),
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSourceIcon(
                source,
                colorScheme,
                size: 18,
                radius: (uiRoundness * 0.4).clamp(4.0, 8.0),
              ),
              const SizedBox(width: 8),
              Text(
                source.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceFilterTiles(
    BuildContext context,
    DiscoveryPrefs prefs,
    ColorScheme colorScheme,
    double uiRoundness,
  ) {
    final sourcesAsync = ref.watch(_selectedType.availableSourcesProvider);

    return sourcesAsync.when(
      data: (allSources) {
        final sources = _resolveSources(allSources, prefs);

        if (sources.isEmpty) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.extension_rounded, size: 14),
                  label: const Text(
                    'Manage Extensions',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: () => context.pushSettingsExtensions(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(uiRoundness),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              if (_selectedSources.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      'Clear (${_selectedSources.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    backgroundColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(uiRoundness),
                      side: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _selectedSources.clear();
                        _selectedSource = null;
                      });
                      _resetScroll();
                    },
                  ),
                ),
              ...sources.map((source) {
                final isSelected = _selectedSources.contains(source.id);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(uiRoundness),
                    child: InkWell(
                      onTap: () => _toggleSource(source.id),
                      borderRadius: BorderRadius.circular(uiRoundness),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(uiRoundness),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                            ] else ...[
                              _buildSourceIcon(
                                source,
                                colorScheme,
                                size: 15,
                                radius: uiRoundness * 0.3,
                                fallbackColor: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              source.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 36,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActiveFilterChips(ColorScheme colorScheme, double uiRoundness) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 136),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMinCrossAxisExtent(
              minCrossAxisExtent: layout.width,
              childAspectRatio: layout.aspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final media = items[index];
              return MediaCard(
                media: media,
                tag: 'browse-${media.id}',
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 136),
        gridDelegate: SliverGridDelegateWithMinCrossAxisExtent(
          minCrossAxisExtent: layout.width,
          childAspectRatio: layout.aspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          return MediaCard(
            media: UnifiedMedia(
              id: 'skeleton-$index',
              type: MediaType.ANIME,
              title: const MediaTitle(english: 'Placeholder Title'),
              format: 'TV',
              score: 8.5,
              year: 2026,
            ),
            tag: 'skeleton-$index',
            style: style,
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
              onPressed: () {
                final args = _currentSearchArgs;
                if (args != null) {
                  ref.invalidate(searchProvider(args));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final double radius;
  final VoidCallback onTap;

  const _DiscoverModeTab({
    required this.label,
    required this.selected,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
