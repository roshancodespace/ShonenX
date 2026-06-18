import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/media_card.dart';
import 'package:shonenx/features/discovery/providers/category_search_provider.dart';
import 'package:shonenx/features/discovery/providers/search_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';
import 'package:shonenx/features/discovery/providers/discovery_feed_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/advanced_search_sheet.dart';

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

class _SearchDiscoverScreenState extends ConsumerState<SearchDiscoverScreen> {
  late final ScrollController _scrollController;

  bool _isLoadingMore = false;
  String _query = '';
  List<String> _genres = [];
  List<String> _tags = [];

  SearchArgs get _args => SearchArgs(
    query: _query,
    type: widget.type,
    genres: _genres,
    tags: _tags,
  );

  bool get _hasActiveFilters =>
      _query.isNotEmpty || _genres.isNotEmpty || _tags.isNotEmpty;

  @override
  void initState() {
    super.initState();

    _query = widget.initialQuery?.trim() ?? '';
    _genres = List.from(widget.initialGenres);
    _tags = List.from(widget.initialTags);

    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _openAdvancedSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      constraints: const BoxConstraints(maxWidth: 800),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return AdvancedSearchSheet(
          initialQuery: _query,
          initialGenres: _genres,
          initialTags: _tags,
          onApply: (query, genres, tags) {
            setState(() {
              _query = query.trim();
              _genres = genres;
              _tags = tags;
            });
          },
        );
      },
    );
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
    final state = _hasActiveFilters ? ref.watch(searchProvider(_args)) : null;

    return _DiscoverGridScaffold(
      title: 'Discover',
      subtitle: 'Find your next obsession',
      state: state,
      type: widget.type,
      hasActiveFilters: _hasActiveFilters,
      scrollController: _scrollController,
      isLoadingMore: _isLoadingMore,
      onAutoLoad: _loadNextPage,
      actions: [
        FilledButton.tonalIcon(
          onPressed: () => _openAdvancedSearch(context),
          icon: const Icon(Icons.search),
          label: const Text('Search anime...'),
        ),
        const SizedBox(width: 10),
      ],
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
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
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

    return _DiscoverGridScaffold(
      title: widget.category,
      subtitle: 'Browse ${widget.category}',
      state: state,
      type: widget.type,
      hasActiveFilters: true,
      scrollController: _scrollController,
      isLoadingMore: _isLoadingMore,
      onAutoLoad: _loadNextPage,
    );
  }
}

class _DiscoverGridScaffold extends ConsumerWidget {
  final String title;
  final String subtitle;
  final AsyncValue<PaginatedResult<UnifiedMedia>?>? state;
  final MediaType type;
  final bool hasActiveFilters;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final VoidCallback onAutoLoad;
  final List<Widget>? actions;

  const _DiscoverGridScaffold({
    required this.title,
    required this.subtitle,
    required this.state,
    required this.type,
    required this.hasActiveFilters,
    required this.scrollController,
    required this.isLoadingMore,
    required this.onAutoLoad,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    return AppScaffold(
      title: title,
      subtitle: subtitle,
      actions: actions,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Expanded(
              child: !hasActiveFilters
                  ? _DynamicGenreFeed(type: type)
                  : state!.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
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

                          if (position.maxScrollExtent == 0 &&
                              result.hasNextPage) {
                            onAutoLoad();
                          }
                        });

                        return Stack(
                          children: [
                            GridView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.only(
                                bottom: 120,
                                top: 10,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
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
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
