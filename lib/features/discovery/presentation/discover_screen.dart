import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/media_card.dart';
import 'package:shonenx/features/discovery/providers/category_search_provider.dart';
import 'package:shonenx/features/discovery/providers/search_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/models/paginated_result.dart';

class DiscoverScreen extends StatelessWidget {
  final String? query;
  final String? category;
  final MediaType type;

  const DiscoverScreen({
    super.key,
    this.query,
    this.category,
    this.type = MediaType.ANIME,
  });

  bool get hasCategory => category != null && category!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (hasCategory) {
      return CategoryDiscoverScreen(category: category!, type: type);
    }

    return SearchDiscoverScreen(initialQuery: query, type: type);
  }
}

class SearchDiscoverScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final MediaType type;

  const SearchDiscoverScreen({
    super.key,
    this.initialQuery,
    required this.type,
  });

  @override
  ConsumerState<SearchDiscoverScreen> createState() =>
      _SearchDiscoverScreenState();
}

class _SearchDiscoverScreenState extends ConsumerState<SearchDiscoverScreen> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;

  bool _isLoadingMore = false;
  String _query = '';

  SearchArgs get _args => SearchArgs(query: _query, type: widget.type);

  @override
  void initState() {
    super.initState();

    _query = widget.initialQuery?.trim() ?? '';

    _controller = TextEditingController(text: widget.initialQuery);

    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.dispose();

    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    super.dispose();
  }

  void _onSearch(String value) {
    final query = value.trim();

    if (query.isEmpty || query == _query) return;

    setState(() {
      _query = query;
    });
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
    final state = ref.watch(searchProvider(_args));

    return _DiscoverGridScaffold(
      title: 'Discover',
      subtitle: 'Find your next obsession',
      searchBar: SearchBar(
        controller: _controller,
        autoFocus: true,
        leading: const Icon(Icons.search),
        hintText: 'Search anime titles...',
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        onSubmitted: _onSearch,
      ),
      state: state,
      scrollController: _scrollController,
      isLoadingMore: _isLoadingMore,
      onAutoLoad: _loadNextPage,
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
      scrollController: _scrollController,
      isLoadingMore: _isLoadingMore,
      onAutoLoad: _loadNextPage,
    );
  }
}

class _DiscoverGridScaffold extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Widget? searchBar;
  final AsyncValue<PaginatedResult<UnifiedMedia>?> state;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final VoidCallback onAutoLoad;

  const _DiscoverGridScaffold({
    required this.title,
    required this.subtitle,
    required this.state,
    required this.scrollController,
    required this.isLoadingMore,
    required this.onAutoLoad,
    this.searchBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    return AppScaffold(
      title: title,
      subtitle: subtitle,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            if (searchBar != null) ...[searchBar!, const SizedBox(height: 10)],
            Expanded(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (result) {
                  if (result == null || result.items.isEmpty) {
                    return const Center(child: Text('No results'));
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
                        padding: const EdgeInsets.only(bottom: 80),
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
                        bottom: isLoadingMore ? 16 : -60,
                        child: const Center(child: CircularProgressIndicator()),
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
