import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/providers/category_search_provider.dart';
import 'package:shonenx/features/discovery/providers/search_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';
import 'package:shonenx/features/discovery/providers/discovery_feed_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/advanced_search_sheet.dart';

class DiscoverScreen extends StatelessWidget {
  final String? query;
  final String? category;
  final MediaType type;
  final List<String> genres;
  final List<String> tags;

  const DiscoverScreen({
    super.key,
    this.query,
    this.category,
    this.type = MediaType.ANIME,
    this.genres = const [],
    this.tags = const [],
  });

  bool get hasCategory => category != null && category!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (hasCategory) {
      return CategoryDiscoverScreen(category: category!, type: type);
    }

    return SearchDiscoverScreen(
      initialQuery: query,
      type: type,
      initialGenres: genres,
      initialTags: tags,
    );
  }
}

class SearchDiscoverScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final MediaType type;
  final List<String> initialGenres;
  final List<String> initialTags;

  const SearchDiscoverScreen({
    super.key,
    this.initialQuery,
    required this.type,
    this.initialGenres = const [],
    this.initialTags = const [],
  });

  @override
  ConsumerState<SearchDiscoverScreen> createState() =>
      _SearchDiscoverScreenState();
}

class _SearchDiscoverScreenState extends ConsumerState<SearchDiscoverScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late TabController _tabController;

  String _query = '';
  List<String> _genres = [];
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _searchController = TextEditingController(text: _query);
    _genres = List.from(widget.initialGenres);
    _tags = List.from(widget.initialTags);

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.type == MediaType.ANIME ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
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
          type: _tabController.index == 0 ? MediaType.ANIME : MediaType.MANGA,
          initialGenres: _genres,
          initialTags: _tags,
          onApply: (query, genres, tags) {
            setState(() {
              _query = query.trim();
              _searchController.text = _query;
              _genres = genres;
              _tags = tags;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: null,
      subtitle: null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Anime'),
                Tab(text: 'Manga'),
              ],
            ),
            const SizedBox(height: 10),
            SearchBar(
              constraints: BoxConstraints(minWidth: double.maxFinite),
              controller: _searchController,
              hintText: 'Search...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Advanced Filters',
                  onPressed: () => _openAdvancedSearch(context),
                ),
              ],
              onSubmitted: (value) {
                setState(() {
                  _query = value.trim();
                });
              },
            ),
            if (_genres.isNotEmpty || _tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._genres.map(
                      (g) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          label: Text(g),
                          onDeleted: () {
                            setState(() {
                              _genres.remove(g);
                            });
                          },
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          deleteIconColor:
                              theme.colorScheme.onSecondaryContainer,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    ..._tags.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          label: Text(t),
                          onDeleted: () {
                            setState(() {
                              _tags.remove(t);
                            });
                          },
                          backgroundColor: theme.colorScheme.tertiaryContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                          deleteIconColor:
                              theme.colorScheme.onTertiaryContainer,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DiscoverTabFeed(
                    type: MediaType.ANIME,
                    query: _query,
                    genres: _genres,
                    tags: _tags,
                  ),
                  _DiscoverTabFeed(
                    type: MediaType.MANGA,
                    query: _query,
                    genres: _genres,
                    tags: _tags,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryDiscoverScreen extends ConsumerStatefulWidget {
  final String category;
  final MediaType type;

  const CategoryDiscoverScreen({
    super.key,
    required this.category,
    required this.type,
  });

  @override
  ConsumerState<CategoryDiscoverScreen> createState() =>
      _CategoryDiscoverScreenState();
}

class _CategoryDiscoverScreenState
    extends ConsumerState<CategoryDiscoverScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.category,
      subtitle: 'Browse ${widget.category}',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: _CategoryTabFeed(type: widget.type, category: widget.category),
      ),
    );
  }
}

class _DiscoverTabFeed extends ConsumerStatefulWidget {
  final MediaType type;
  final String query;
  final List<String> genres;
  final List<String> tags;

  const _DiscoverTabFeed({
    required this.type,
    required this.query,
    required this.genres,
    required this.tags,
  });

  @override
  ConsumerState<_DiscoverTabFeed> createState() => _DiscoverTabFeedState();
}

class _DiscoverTabFeedState extends ConsumerState<_DiscoverTabFeed> {
  late final ScrollController _scrollController;
  bool _isLoadingMore = false;

  SearchArgs get _args => SearchArgs(
    query: widget.query,
    type: widget.type,
    genres: widget.genres,
    tags: widget.tags,
  );

  bool get _hasActiveFilters =>
      widget.query.isNotEmpty ||
      widget.genres.isNotEmpty ||
      widget.tags.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasActiveFilters) return;

    final state = ref.read(searchProvider(_args));
    if (state.value?.hasNextPage != true) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await ref.read(searchProvider(_args).notifier).loadNextPage();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasActiveFilters) {
      return _DynamicGenreFeed(type: widget.type);
    }

    final state = ref.watch(searchProvider(_args));

    return _PaginatedMediaGrid(
      state: state,
      scrollController: _scrollController,
      isLoadingMore: _isLoadingMore,
      onAutoLoad: _loadNextPage,
    );
  }
}

class _CategoryTabFeed extends ConsumerStatefulWidget {
  final MediaType type;
  final String category;

  const _CategoryTabFeed({required this.type, required this.category});

  @override
  ConsumerState<_CategoryTabFeed> createState() => _CategoryTabFeedState();
}

class _CategoryTabFeedState extends ConsumerState<_CategoryTabFeed> {
  late final ScrollController _scrollController;
  bool _isLoadingMore = false;

  CategorySearchArgs get _args =>
      CategorySearchArgs(category: widget.category, type: widget.type);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore) return;

    final state = ref.read(categorySearchProvider(_args));
    if (state.value?.hasNextPage != true) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await ref.read(categorySearchProvider(_args).notifier).loadNextPage();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categorySearchProvider(_args));

    return _PaginatedMediaGrid(
      state: state,
      scrollController: _scrollController,
      isLoadingMore: _isLoadingMore,
      onAutoLoad: _loadNextPage,
    );
  }
}

class _PaginatedMediaGrid extends ConsumerWidget {
  final AsyncValue<PaginatedResult<UnifiedMedia>?> state;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final VoidCallback onAutoLoad;

  const _PaginatedMediaGrid({
    required this.state,
    required this.scrollController,
    required this.isLoadingMore,
    required this.onAutoLoad,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (result) {
        if (result == null || result.items.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!scrollController.hasClients) {
            return;
          }

          final position = scrollController.position;

          if (position.maxScrollExtent == 0 && result.hasNextPage) {
            onAutoLoad();
          }
        });

        return Stack(
          children: [
            GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 120, top: 10),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: style.layout.width + 10,
                mainAxisExtent: style.layout.height,
                childAspectRatio: style.layout.aspectRatio,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: result.items.length,
              itemBuilder: (context, index) {
                final media = result.items[index];

                return MediaCard(
                  tag: 'media-${media.id}',
                  title: media.title.availableTitle,
                  imageUrl: media.cover ?? media.banner ?? '',
                  style: style,
                  onTap: () {
                    context.push(
                      '/details/${media.type.id}?tag=media-${media.id}',
                      extra: media,
                    );
                  },
                );
              },
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: isLoadingMore ? 80 : -60,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      },
    );
  }
}

class _DynamicGenreFeed extends ConsumerWidget {
  final MediaType type;

  const _DynamicGenreFeed({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresState = ref.watch(discoveryFeedGenresProvider);

    return genresState.when(
      data: (genres) {
        if (genres.isEmpty) {
          return const Center(child: Text('No categories available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 120),
          itemCount: genres.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GenreFeedRow(type: type, genre: genres[index]),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load feed: $e')),
    );
  }
}

class _GenreFeedRow extends ConsumerWidget {
  final MediaType type;
  final String genre;

  const _GenreFeedRow({required this.type, required this.genre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = (type: type, genre: genre);
    final feedState = ref.watch(genreFeedProvider(arg));
    final style = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));

    return feedState.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return HorizontalSection(
          title: genre,
          height: style.layout.height,
          onMoreTap: () =>
              context.push('/discover?genres=$genre&type=${type.id}'),
          data: AsyncValue.data(items),
          itemBuilder: (context, item) {
            return MediaCard(
              tag: 'feed-$genre-${item.id}',
              format: item.format,
              title: item.title.availableTitle,
              imageUrl: item.cover ?? '',
              style: style,
              onTap: () => context.push(
                '/details/${item.type.id}?tag=feed-$genre-${item.id}',
                extra: item,
              ),
            );
          },
        );
      },
      loading: () => SizedBox(
        height: style.layout.height + 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(genre, style: Theme.of(context).textTheme.titleLarge),
            ),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
