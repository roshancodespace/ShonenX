import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/domain/models/search_filter_options.dart';
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

  late SearchArgs _args;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim() ?? '';
    _args = SearchArgs(
      query: initialQuery,
      category: widget.category,
      type: widget.type,
      genres: widget.initialGenres,
      tags: widget.initialTags,
      source: widget.source,
      sort: widget.initialSort,
      status: widget.initialStatus,
      format: widget.initialFormat,
    );

    _searchController = TextEditingController(text: initialQuery)
      ..addListener(_onSearchTextChanged);
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
    if (text != _args.query) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _args = _args.copyWith(query: text);
          });
        }
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
    final state = ref.read(searchProvider(_args));
    if (state.value?.hasNextPage != true) return;

    setState(() => _isLoadingMore = true);
    try {
      await ref.read(searchProvider(_args).notifier).loadNextPage();
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
          initialQuery: _args.query,
          type: _args.type,
          initialGenres: _args.genres,
          initialTags: _args.tags,
          sourceId: _args.source,
          initialSort: _args.sort,
          initialStatus: _args.status,
          initialFormat: _args.format,
          onApply: (query, genres, tags, sort, status, format) {
            setState(() {
              final trimmedQuery = query.trim();
              _searchController.text = trimmedQuery;
              _args = _args.copyWith(
                query: trimmedQuery,
                genres: genres,
                tags: tags,
                sort: sort,
                status: status,
                format: format,
              );
            });
          },
        );
      },
    );
  }

  String get _pageTitle {
    if (widget.customTitle != null) return widget.customTitle!;
    if (_args.category != null && _args.category!.isNotEmpty) {
      return _args.category!;
    }
    if (_args.source != null && _args.source!.isNotEmpty) {
      final allAnimeSources =
          ref.watch(availableAnimeSourcesProvider).value ?? [];
      final allMangaSources =
          ref.watch(availableMangaSourcesProvider).value ?? [];
      final allSources = [...allAnimeSources, ...allMangaSources];
      final sourceObj = allSources.firstWhereOrNull(
        (s) => s.id == _args.source,
      );
      return sourceObj?.name ??
          (_args.source![0].toUpperCase() + _args.source!.substring(1));
    }
    if (_args.genres.isNotEmpty) return _args.genres.join(', ');
    if (_args.tags.isNotEmpty) return _args.tags.join(', ');
    if (_args.query.isNotEmpty) return 'Search: "${_args.query}"';
    return 'Results';
  }

  String get _pageSubtitle {
    final typeName = _args.type.name.toLowerCase();
    if (_args.category != null && _args.category!.isNotEmpty) {
      return 'Browsing $typeName ${_args.category}';
    }
    if (_args.source != null && _args.source!.isNotEmpty) {
      return 'Browsing $typeName catalog';
    }
    if (_args.genres.isNotEmpty && _args.tags.isNotEmpty) {
      return _args.tags.join(', ');
    }
    if (_args.genres.isNotEmpty) return 'Filtered by genre';
    if (_args.tags.isNotEmpty) return 'Filtered by tag';
    return 'Browse catalog';
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider(_args));
    final filtersState = ref.watch(
      discoveryFiltersProvider((type: _args.type, sourceId: _args.source)),
    );
    final hasFilters =
        (filtersState.value != null &&
            filtersState.value!.options.hasAnyFilter) ||
        _args.sort != SearchSort.popularity ||
        _args.status != SearchStatusFilter.all ||
        _args.format != SearchFormatFilter.all;

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
            child: discoveryMode == MetadataMode.source && _args.source == null
                ? MultiSourceSearchFeed(
                    type: _args.type,
                    query: _args.query,
                    genres: _args.genres,
                    tags: _args.tags,
                    onSourceSelect: (sourceId) {
                      context.pushFilteredDiscover(
                        query: _args.query,
                        type: _args.type,
                        genres: _args.genres,
                        tags: _args.tags,
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
                  setState(() => _args = _args.copyWith(query: ''));
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              onClearPressed: () => _searchController.clear(),
              onSubmitted: (text) => setState(() {
                _args = _args.copyWith(query: text.trim());
              }),
              hasFilters: hasFilters,
              onFilterPressed: () => _openAdvancedSearch(context),
            ),
          ),
        ],
      ),
    );
  }
}
