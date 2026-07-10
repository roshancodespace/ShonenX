import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/providers/category_search_provider.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/search_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/providers/navbar_action_provider.dart';
import 'package:shonenx/shared/widgets/media_switcher_overlay.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/features/discovery/providers/discovery_feed_provider.dart';
import 'package:shonenx/features/discovery/providers/metadata_tags_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/advanced_search_sheet.dart';
import 'package:shonenx/core/utils/responsive.dart';

class DiscoverScreen extends StatelessWidget {
  final String? query;
  final String? category;
  final MediaType type;
  final List<String> genres;
  final List<String> tags;
  final String? source;

  const DiscoverScreen({
    super.key,
    this.query,
    this.category,
    this.type = MediaType.ANIME,
    this.genres = const [],
    this.tags = const [],
    this.source,
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
      source: source,
    );
  }
}

class SearchDiscoverScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final MediaType type;
  final List<String> initialGenres;
  final List<String> initialTags;
  final String? source;

  const SearchDiscoverScreen({
    super.key,
    this.initialQuery,
    required this.type,
    this.initialGenres = const [],
    this.initialTags = const [],
    this.source,
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
  String? _source;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _searchController = TextEditingController(text: _query);
    _genres = List.from(widget.initialGenres);
    _tags = List.from(widget.initialTags);
    _source = widget.source;

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.type == MediaType.ANIME ? 0 : 1,
    );

    _attachOverlay();
  }

  @override
  void didUpdateWidget(SearchDiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _source = widget.source;
    }
    if (oldWidget.initialQuery != widget.initialQuery) {
      _query = widget.initialQuery?.trim() ?? '';
      _searchController.text = _query;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == true) {
      _attachOverlay();
    }
  }

  void _attachOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        ref
            .read(navBarProvider.notifier)
            .attachTop(
              MediaSwitcherOverlay(controller: _tabController),
              branchIndex: 1,
            );
      }
    });
  }

  @override
  void dispose() {
    try {
      ref.read(navBarProvider.notifier).clearTop(branchIndex: 1);
    } catch (_) {}
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _openAdvancedSearch(BuildContext context) {
    final currentType = _tabController.index == 0
        ? MediaType.ANIME
        : MediaType.MANGA;
    final filtersState = ref.read(
      discoveryFiltersProvider((type: currentType, sourceId: widget.source)),
    );
    final hasFilters =
        filtersState.value != null &&
        (filtersState.value!.genres.isNotEmpty ||
            filtersState.value!.tags.isNotEmpty);
    if (!hasFilters) return;

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
          sourceId: widget.source,
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
    final colorScheme = theme.colorScheme;
    final currentType = _tabController.index == 0
        ? MediaType.ANIME
        : MediaType.MANGA;
    final filtersState = ref.watch(
      discoveryFiltersProvider((type: currentType, sourceId: widget.source)),
    );
    final hasFilters =
        filtersState.value != null &&
        (filtersState.value!.genres.isNotEmpty ||
            filtersState.value!.tags.isNotEmpty);

    String pageTitle = 'Discover';
    String pageSubtitle = 'Find your next anime or manga';

    if (widget.source != null && widget.source!.isNotEmpty) {
      final allAnimeSources =
          ref.watch(availableAnimeSourcesProvider).value ?? [];
      final allMangaSources =
          ref.watch(availableMangaSourcesProvider).value ?? [];
      final allSources = [...allAnimeSources, ...allMangaSources];
      final sourceObj = allSources
          .where((s) => s.id == widget.source)
          .firstOrNull;
      final sourceName =
          sourceObj?.name ??
          (widget.source![0].toUpperCase() + widget.source!.substring(1));
      pageTitle = sourceName;
      pageSubtitle = 'Browsing ${currentType.name.toLowerCase()} catalog';
    } else if (_genres.isNotEmpty) {
      pageTitle = _genres.join(', ');
      pageSubtitle = 'Browsing ${currentType.name.toLowerCase()} by genre';
    } else if (_tags.isNotEmpty) {
      pageTitle = _tags.join(', ');
      pageSubtitle = 'Browsing ${currentType.name.toLowerCase()} by tag';
    }

    return AppScaffold(
      title: pageTitle,
      subtitle: pageSubtitle,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search anime or manga...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                      if (hasFilters)
                        IconButton(
                          icon: const Icon(Icons.tune, size: 20),
                          tooltip: 'Advanced Filters',
                          onPressed: () => _openAdvancedSearch(context),
                        ),
                    ],
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: theme.textTheme.bodyMedium,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  setState(() {
                    _query = value.trim();
                  });
                },
              ),
            ),
            if (_genres.isNotEmpty || _tags.isNotEmpty || _source != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_source != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          label: Text('Source: $_source'),
                          onDeleted: () {
                            setState(() {
                              _source = null;
                            });
                          },
                          backgroundColor: theme.colorScheme.primaryContainer,
                          labelStyle: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          deleteIconColor: theme.colorScheme.onPrimaryContainer,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
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
                          labelStyle: theme.textTheme.labelMedium?.copyWith(
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
                          labelStyle: theme.textTheme.labelMedium?.copyWith(
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
                    source: _source,
                    onGenreSelect: (g) {
                      setState(() {
                        _genres = [g];
                      });
                    },
                    onSourceSelect: (sId) {
                      setState(() {
                        _source = sId;
                      });
                    },
                  ),
                  _DiscoverTabFeed(
                    type: MediaType.MANGA,
                    query: _query,
                    genres: _genres,
                    tags: _tags,
                    source: _source,
                    onGenreSelect: (g) {
                      setState(() {
                        _genres = [g];
                      });
                    },
                    onSourceSelect: (sId) {
                      setState(() {
                        _source = sId;
                      });
                    },
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
  final String? source;
  final ValueChanged<String>? onGenreSelect;
  final ValueChanged<String>? onSourceSelect;

  const _DiscoverTabFeed({
    required this.type,
    required this.query,
    required this.genres,
    required this.tags,
    this.source,
    this.onGenreSelect,
    this.onSourceSelect,
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
    source: widget.source,
  );

  bool get _hasActiveFilters =>
      widget.query.isNotEmpty ||
      widget.genres.isNotEmpty ||
      widget.tags.isNotEmpty ||
      widget.source != null;

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
      final discoveryMode = ref.watch(
        discoveryPrefsProvider.select((p) => p.mode),
      );
      if (discoveryMode == MetadataMode.source) {
        return _DynamicSourceFeed(
          type: widget.type,
          onSourceSelect: widget.onSourceSelect,
        );
      }
      return _DynamicGenreFeed(
        type: widget.type,
        onGenreSelect: widget.onGenreSelect,
      );
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

          if (position.maxScrollExtent == 0 &&
              result.hasNextPage &&
              !isLoadingMore) {
            onAutoLoad();
          }
        });

        return Stack(
          children: [
            GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 200, top: 10),
              gridDelegate: SliverGridDelegateWithMinCrossAxisExtent(
                minCrossAxisExtent: style.layout.width,
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
  final ValueChanged<String>? onGenreSelect;

  const _DynamicGenreFeed({required this.type, this.onGenreSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresState = ref.watch(discoveryFeedGenresProvider);

    return genresState.when(
      data: (genres) {
        if (genres.isEmpty) {
          return const Center(child: Text('No categories available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 200),
          itemCount: genres.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: _GenreFeedRow(
                type: type,
                genre: genres[index],
                onGenreSelect: onGenreSelect,
              ),
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
  final ValueChanged<String>? onGenreSelect;

  const _GenreFeedRow({
    required this.type,
    required this.genre,
    this.onGenreSelect,
  });

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
          onMoreTap: () {
            if (onGenreSelect != null) {
              onGenreSelect!(genre);
            } else {
              context.push('/discover?genres=$genre&type=${type.id}');
            }
          },
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

final _sourceDiscoverFeedProvider = FutureProvider.autoDispose
    .family<List<UnifiedMedia>, ({SourceInfo info, MediaType type})>((
      ref,
      arg,
    ) async {
      ref.keepAlive();
      if (arg.type == MediaType.ANIME) {
        final source = ref.read(animeSourceProvider(arg.info));
        try {
          final trending = await source.getTrending();
          if (trending.isNotEmpty) return trending;
        } catch (_) {}
        return await source.search('', arg.type, page: 1);
      } else {
        final source = ref.read(mangaSourceProvider(arg.info));
        try {
          final trending = await source.getTrending();
          if (trending.isNotEmpty) return trending;
        } catch (_) {}
        return await source.search('', arg.type, page: 1);
      }
    });

class _DynamicSourceFeed extends ConsumerWidget {
  final MediaType type;
  final ValueChanged<String>? onSourceSelect;
  const _DynamicSourceFeed({required this.type, this.onSourceSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(discoveryPrefsProvider);
    final sourcesAsync = type == MediaType.ANIME
        ? ref.watch(availableAnimeSourcesProvider)
        : ref.watch(availableMangaSourcesProvider);

    return sourcesAsync.when(
      data: (allSources) {
        final active = allSources
            .where((s) => prefs.activeSources.contains(s.id))
            .toList();
        if (active.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.extension_off_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No active ${type.name.toLowerCase()} sources',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enable extension sources in Discovery settings.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 120),
          itemCount: active.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SourceFeedRow(
                type: type,
                info: active[index],
                onSourceSelect: onSourceSelect,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load sources: $e')),
    );
  }
}

class _SourceFeedRow extends ConsumerWidget {
  final MediaType type;
  final SourceInfo info;
  final ValueChanged<String>? onSourceSelect;
  const _SourceFeedRow({
    required this.type,
    required this.info,
    this.onSourceSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = (info: info, type: type);
    final catalogState = ref.watch(_sourceDiscoverFeedProvider(arg));
    final style = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));

    return catalogState.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return HorizontalSection(
          title: info.name,
          height: style.layout.height,
          onMoreTap: () {
            if (onSourceSelect != null) {
              onSourceSelect!(info.id);
            } else {
              context.push('/discover?source=${info.id}&type=${type.id}');
            }
          },
          data: AsyncValue.data(items),
          itemBuilder: (context, item) {
            return MediaCard(
              tag: 'src-${info.id}-${item.id}',
              format: item.format,
              title: item.title.availableTitle,
              imageUrl: item.cover ?? '',
              style: style,
              onTap: () => context.push(
                '/details/${item.type.id}?tag=src-${info.id}-${item.id}',
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
              child: Text(
                info.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
