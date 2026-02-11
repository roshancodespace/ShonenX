import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/utils/app_logger.dart';

import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';

import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/shared/ui/widgets/shonenx_gridview.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';
import 'package:shonenx/features/browse/model/search_filter.dart';
import 'package:shonenx/features/browse/view/widgets/filter_bottom_sheet.dart';
import 'package:shonenx/features/browse/view/section_screen.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  final String? keyword;
  final SearchFilter? initialFilter;

  const BrowseScreen({super.key, this.keyword, this.initialFilter});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen>
    with SingleTickerProviderStateMixin {
  // Services and controllers
  late final _repo = ref.read(animeRepositoryProvider);
  late final _searchController = TextEditingController(text: widget.keyword);
  late final _scrollController = ScrollController()..addListener(_onScroll);
  late final _animationController = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  );
  Timer? _debounce;

  // State variables
  List<UniversalMedia> _results = [];
  List<UniversalMedia> _trending = [];
  List<UniversalMedia> _popular = [];
  List<UniversalMedia> _upcoming = [];
  late SearchFilter _currentFilter =
      widget.initialFilter ?? const SearchFilter();

  var _currentPage = 1;
  var _isLoading = false;
  var _hasMore = true;
  var _isSearchFocused = false;
  var _isExploreLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController.forward();
    if (widget.keyword?.isNotEmpty == true || !_currentFilter.isEmpty) {
      _search();
    } else {
      _fetchExploreData();
    }
  }

  @override
  void didUpdateWidget(covariant BrowseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.keyword != oldWidget.keyword) {
      _searchController.text = widget.keyword ?? '';
      _search();
    }
    if (widget.initialFilter != oldWidget.initialFilter) {
      setState(() {
        _currentFilter = widget.initialFilter ?? const SearchFilter();
      });
      _search();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchExploreData() async {
    if (mounted) setState(() => _isExploreLoading = true);
    try {
      final results = await Future.wait([
        _repo.getTrendingAnime(),
        _repo.getPopularAnime(),
        _repo.getUpcomingAnime(),
      ]);

      if (mounted) {
        setState(() {
          _trending = results[0];
          _popular = results[1];
          _upcoming = results[2];
          _isExploreLoading = false;
        });
      }
    } catch (e, s) {
      AppLogger.e("Failed to fetch explore data", e, s);
      if (mounted) setState(() => _isExploreLoading = false);
    }
  }

  Future<void> _fetchResults(String keyword, int page) async {
    if (_isLoading || !_hasMore) return;
    // Allow search if keyword is empty BUT filter is present
    if (keyword.isEmpty && _currentFilter.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final results = await _repo.searchAnime(
        keyword,
        page: page,
        perPage: 20,
        filter: _currentFilter,
      );

      if (mounted) {
        setState(() {
          if (page == 1) {
            _results = results;
          } else {
            _results.addAll(results);
          }
          _hasMore = results.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.e("Search error", e, stackTrace);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_results.isNotEmpty &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _fetchResults(_searchController.text, ++_currentPage);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search();
    });
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty && _currentFilter.isEmpty) {
      setState(() {
        _results.clear();
        _isExploreLoading = false; // Show explore content
      });
      return;
    }

    setState(() {
      _currentPage = 1;
      _results.clear();
      _hasMore = true;
    });

    await _fetchResults(_searchController.text, _currentPage);
  }

  void _openFilter() async {
    final result = await showModalBottomSheet<SearchFilter>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(initialFilter: _currentFilter),
    );

    if (result != null) {
      setState(() {
        _currentFilter = result;
      });

      if (_searchController.text.isEmpty && !_currentFilter.isEmpty) {
        _searchController.text = _searchController.text; // no-op
        _search();
      } else if (_searchController.text.isNotEmpty) {
        _search();
      }
    }
  }

  int _getColumnCount() {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 1400
        ? 6
        : width >= 1100
        ? 5
        : width >= 800
        ? 4
        : width >= 420
        ? 3
        : 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _Header(
            controller: _searchController,
            animation: _animationController,
            onSearch: _search,
            onFocusChange: (focused) =>
                setState(() => _isSearchFocused = focused),
            isSearchFocused: _isSearchFocused,
            onSearchChanged: _onSearchChanged,
            onFilter: _openFilter,
            hasFilter: !_currentFilter.isEmpty,
          ),
          Expanded(
            child: _searchController.text.isEmpty && _currentFilter.isEmpty
                ? _ExploreView(
                    trending: _trending,
                    popular: _popular,
                    upcoming: _upcoming,
                    isLoading: _isExploreLoading,
                  )
                : _results.isEmpty && !_isLoading
                ? _EmptyState()
                : _ResultsGrid(
                    results: _results,
                    scrollController: _scrollController,
                    columnCount: _getColumnCount(),
                    isLoading: _isLoading,
                    animation: _animationController,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TextEditingController controller;
  final AnimationController animation;
  final VoidCallback onSearch;
  final ValueChanged<bool> onFocusChange;
  final bool isSearchFocused;
  final Function(String) onSearchChanged;
  final VoidCallback onFilter;
  final bool hasFilter;

  const _Header({
    required this.controller,
    required this.animation,
    required this.onSearch,
    required this.onFocusChange,
    required this.isSearchFocused,
    required this.onSearchChanged,
    required this.onFilter,
    required this.hasFilter,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Anime',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find your next favorite series',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SearchBar(
                    controller: controller,
                    onSearch: onSearch,
                    onFocusChange: onFocusChange,
                    isSearchFocused: isSearchFocused,
                    onSearchChanged: onSearchChanged,
                    onFilter: onFilter,
                    hasFilter: hasFilter,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final ValueChanged<bool> onFocusChange;
  final bool isSearchFocused;
  final Function(String) onSearchChanged;
  final VoidCallback onFilter;
  final bool hasFilter;

  const _SearchBar({
    required this.controller,
    required this.onSearch,
    required this.onFocusChange,
    required this.isSearchFocused,
    required this.onSearchChanged,
    required this.onFilter,
    required this.hasFilter,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSearchFocused
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: isSearchFocused ? 2 : 1,
        ),
      ),
      child: Focus(
        onFocusChange: onFocusChange,
        child: TextField(
          controller: controller,
          onSubmitted: (_) => onSearch(),
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search anime titles...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Iconsax.search_normal,
              color: isSearchFocused
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      onSearchChanged('');
                    },
                  ),
                IconButton(
                  icon: Icon(
                    Iconsax.setting_4,
                    color: hasFilter
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: onFilter,
                ),
                const SizedBox(width: 8),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsGrid extends ConsumerWidget {
  final List<UniversalMedia> results;
  final ScrollController scrollController;
  final int columnCount;
  final bool isLoading;
  final AnimationController animation;

  const _ResultsGrid({
    required this.results,
    required this.scrollController,
    required this.columnCount,
    required this.isLoading,
    required this.animation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(uiSettingsProvider).cardStyle;
    final size = mode.getDimensions(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Opacity(
                opacity: animation.value,
                child: Text(
                  '${results.length} Results',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return FadeTransition(
                opacity: animation,
                child: ShonenXGridView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 100),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  crossAxisExtent: size.width,
                  childAspectRatio: size.width / size.height,
                  itemCount: results.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == results.length) {
                      return const _LoadingIndicator();
                    }
                    final anime = results[index];
                    return GestureDetector(
                      onTap: () => navigateToDetail(
                        context,
                        anime,
                        'browse_grid_${anime.id}',
                      ),
                      child: AnimeCard(
                        anime: anime,
                        mode: mode,
                        tag: 'browse_grid_${anime.id}',
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start Your Search',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter an anime title to discover amazing series',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading more...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreView extends StatelessWidget {
  final List<UniversalMedia> trending;
  final List<UniversalMedia> popular;
  final List<UniversalMedia> upcoming;
  final bool isLoading;

  const _ExploreView({
    required this.trending,
    required this.popular,
    required this.upcoming,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HorizontalSection(title: 'Trending Now', items: trending),
          _HorizontalSection(title: 'All Time Popular', items: popular),
          _HorizontalSection(title: 'Upcoming Seasons', items: upcoming),
        ],
      ),
    );
  }
}

class _HorizontalSection extends ConsumerWidget {
  final String title;
  final List<UniversalMedia> items;

  const _HorizontalSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();

    final mode = ref.watch(uiSettingsProvider).cardStyle;
    final size = mode.getDimensions(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  Iconsax.arrow_right_3,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  final repo = ref.read(animeRepositoryProvider);
                  Future<List<UniversalMedia>> Function({
                    int page,
                    int perPage,
                  })?
                  fetcher;

                  if (title == 'Trending Now') {
                    fetcher = repo.getTrendingAnime;
                  } else if (title == 'All Time Popular') {
                    fetcher = repo.getPopularAnime;
                  } else if (title == 'Upcoming Seasons') {
                    fetcher = repo.getUpcomingAnime;
                  }

                  if (fetcher != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SectionScreen(title: title, fetchItems: fetcher!),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: size.height,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final anime = items[index];
              final tag = 'browse-$title-${anime.id}';
              return SizedBox(
                width: size.width,
                child: GestureDetector(
                  onTap: () => navigateToDetail(context, anime, tag),
                  child: AnimeCard(anime: anime, mode: mode, tag: tag),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
