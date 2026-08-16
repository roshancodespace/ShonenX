import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';

import 'package:shonenx/core/utils/extensions.dart';
import 'package:shonenx/features/discovery/domain/models/search_filter_options.dart';
import 'package:shonenx/features/discovery/presentation/widgets/discover/category_tab_feed.dart';
import 'package:shonenx/features/discovery/presentation/widgets/discover/multi_source_search_feed.dart';
import 'package:shonenx/features/discovery/presentation/widgets/discover/paginated_media_grid.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/advanced_search_sheet.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/metadata_tags_provider.dart';
import 'package:shonenx/features/discovery/providers/search_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/unified_search_bar.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class FilteredDiscoverScreen extends ConsumerStatefulWidget {
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

  const FilteredDiscoverScreen({
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
  ConsumerState<FilteredDiscoverScreen> createState() =>
      _FilteredDiscoverScreenState();
}

class _FilteredDiscoverScreenState
    extends ConsumerState<FilteredDiscoverScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  Timer? _debounceTimer;

  late String _query;
  late List<String> _genres;
  late List<String> _tags;
  late String? _source;
  late SearchSort _sort;
  late SearchStatusFilter _status;
  late SearchFormatFilter _format;
  bool _isLoadingMore = false;

  SearchArgs get _searchArgs => SearchArgs(
    query: _query,
    type: widget.type,
    genres: _genres,
    tags: _tags,
    source: _source,
    sort: _sort,
    status: _status,
    format: _format,
  );

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _searchController = TextEditingController(text: _query)
      ..addListener(_onSearchTextChanged);
    _genres = List.from(widget.initialGenres);
    _tags = List.from(widget.initialTags);
    _source = widget.source;
    _sort = widget.initialSort;
    _status = widget.initialStatus;
    _format = widget.initialFormat;
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _debounceTimer?.cancel();
    final text = _searchController.text.trim();
    if (text != _query) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _query = text);
      });
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      if (!_isLoadingMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadNextPage();
        });
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore) return;
    final state = ref.read(searchProvider(_searchArgs));
    if (state.value?.hasNextPage != true) return;

    setState(() => _isLoadingMore = true);
    try {
      await ref.read(searchProvider(_searchArgs).notifier).loadNextPage();
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _openAdvancedSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      constraints: const BoxConstraints(maxWidth: 800),
      builder: (context) {
        return AdvancedSearchSheet(
          initialQuery: _query,
          type: widget.type,
          initialGenres: _genres,
          initialTags: _tags,
          sourceId: _source,
          initialSort: _sort,
          initialStatus: _status,
          initialFormat: _format,
          onApply: (query, genres, tags, sort, status, format) {
            setState(() {
              _query = query.trim();
              _searchController.text = _query;
              _genres = genres;
              _tags = tags;
              _sort = sort;
              _status = status;
              _format = format;
            });
          },
        );
      },
    );
  }

  String get _pageTitle {
    if (widget.customTitle != null) return widget.customTitle!;
    if (widget.category != null && widget.category!.isNotEmpty) {
      return widget.category!;
    }
    if (_source != null && _source!.isNotEmpty) {
      final allAnimeSources =
          ref.watch(availableAnimeSourcesProvider).value ?? [];
      final allMangaSources =
          ref.watch(availableMangaSourcesProvider).value ?? [];
      final allSources = [...allAnimeSources, ...allMangaSources];
      final sourceObj = allSources.firstWhereOrNull((s) => s.id == _source);
      return sourceObj?.name ??
          (_source![0].toUpperCase() + _source!.substring(1));
    }
    if (_genres.isNotEmpty) return _genres.join(', ');
    if (_tags.isNotEmpty) return _tags.join(', ');
    if (_query.isNotEmpty) return 'Search: "$_query"';
    return 'Results';
  }

  String get _pageSubtitle {
    final typeName = widget.type.name.toLowerCase();
    if (widget.category != null && widget.category!.isNotEmpty) {
      return 'Browsing $typeName ${widget.category}';
    }
    if (_source != null && _source!.isNotEmpty) {
      return 'Browsing $typeName catalog';
    }
    if (_genres.isNotEmpty && _tags.isNotEmpty) return _tags.join(', ');
    if (_genres.isNotEmpty) return 'Filtered by genre';
    if (_tags.isNotEmpty) return 'Filtered by tag';
    return 'Browse catalog';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category != null &&
        widget.category!.isNotEmpty &&
        _query.isEmpty &&
        _genres.isEmpty &&
        _tags.isEmpty &&
        _source == null &&
        _sort == SearchSort.popularity &&
        _status == SearchStatusFilter.all &&
        _format == SearchFormatFilter.all) {
      return AppScaffold(
        title: _pageTitle,
        subtitle: _pageSubtitle,
        showBackButton: true,
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: CategoryTabFeed(type: widget.type, category: widget.category!),
        ),
      );
    }

    final searchState = ref.watch(searchProvider(_searchArgs));
    final filtersState = ref.watch(
      discoveryFiltersProvider((type: widget.type, sourceId: _source)),
    );
    final hasFilters =
        (filtersState.value != null &&
            filtersState.value!.options.hasAnyFilter) ||
        _sort != SearchSort.popularity ||
        _status != SearchStatusFilter.all ||
        _format != SearchFormatFilter.all;

    final discoveryMode = ref.watch(
      discoveryPrefsProvider.select((p) => p.mode),
    );

    return AppScaffold(
      title: _pageTitle,
      subtitle: _pageSubtitle,
      showBackButton: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: discoveryMode == MetadataMode.source && _source == null
                ? MultiSourceSearchFeed(
                    type: widget.type,
                    query: _query,
                    genres: _genres,
                    tags: _tags,
                    onSourceSelect: (sourceId) {
                      context.pushFilteredDiscover(
                        query: _query,
                        type: widget.type,
                        genres: _genres,
                        tags: _tags,
                        source: sourceId,
                      );
                    },
                  )
                : PaginatedMediaGrid(
                    state: searchState,
                    scrollController: _scrollController,
                    isLoadingMore: _isLoadingMore,
                    onAutoLoad: _loadNextPage,
                  ),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: UnifiedSearchBar(
              controller: _searchController,
              onBackPressed: () {
                if (_searchController.text.isNotEmpty) {
                  _searchController.clear();
                  setState(() => _query = '');
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              onClearPressed: () => _searchController.clear(),
              onSubmitted: (text) => setState(() => _query = text.trim()),
              hasFilters: hasFilters,
              onFilterPressed: () => _openAdvancedSearch(context),
            ),
          ),
        ],
      ),
    );
  }
}
