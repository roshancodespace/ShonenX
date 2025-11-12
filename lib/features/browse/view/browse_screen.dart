import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/features/watchlist/view/widget/shonenx_gridview.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  final String? keyword;
  const BrowseScreen({super.key, this.keyword});

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

  // State variables
  List<Media> _results = [];
  var _currentPage = 1;
  var _isLoading = false;
  var _hasMore = true;
  var _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController.forward();
    if (widget.keyword?.isNotEmpty == true) {
      _search();
    }
  }

  @override
  void didUpdateWidget(covariant BrowseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.keyword != oldWidget.keyword) {
      _searchController.text = widget.keyword ?? '';
      _search();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchResults(String keyword, int page) async {
    if (_isLoading || !_hasMore || keyword.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final results = await _repo.searchAnime(keyword, page: page, perPage: 20);

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchResults(_searchController.text, ++_currentPage);
    }
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _currentPage = 1;
      _results.clear();
      _hasMore = true;
    });

    await _fetchResults(_searchController.text, _currentPage);
  }

  int _getColumnCount() {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 1400
        ? 6
        : width >= 1100
            ? 5
            : width >= 800
                ? 4
                : width >= 500
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
          ),
          Expanded(
            child: _results.isEmpty && !_isLoading
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

  const _Header({
    required this.controller,
    required this.animation,
    required this.onSearch,
    required this.onFocusChange,
    required this.isSearchFocused,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 24),
                  _SearchBar(
                    controller: controller,
                    onSearch: onSearch,
                    onFocusChange: onFocusChange,
                    isSearchFocused: isSearchFocused,
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

  const _SearchBar({
    required this.controller,
    required this.onSearch,
    required this.onFocusChange,
    required this.isSearchFocused,
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
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => controller.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsGrid extends ConsumerWidget {
  final List<Media> results;
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
    final cardStyle = ref.watch(uiSettingsProvider).cardStyle;
    final mode = AnimeCardMode.values.firstWhere((e) => e.name == cardStyle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Opacity(
                opacity: animation.value,
                child: Text(
                  '${results.length} Results',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                  crossAxisCount: columnCount,
                  items: [
                    ...results.map((anime) => AnimatedAnimeCard(
                          onTap: () => navigateToDetail(
                              context, anime, anime.id.toString()),
                          anime: anime ,
                          mode: mode,
                          tag: anime.id.toString(),
                        )),
                    if (isLoading) const _LoadingIndicator(),
                  ],
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter an anime title to discover amazing series',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}
