import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/category_search_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

import 'paginated_media_grid.dart';

class CategoryTabFeed extends ConsumerStatefulWidget {
  final MediaType type;
  final String category;

  const CategoryTabFeed({
    super.key,
    required this.type,
    required this.category,
  });

  @override
  ConsumerState<CategoryTabFeed> createState() => _CategoryTabFeedState();
}

class _CategoryTabFeedState extends ConsumerState<CategoryTabFeed> {
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
      if (!_isLoadingMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadNextPage();
        });
      }
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

    return PaginatedMediaGrid(
      state: state,
      scrollController: _scrollController,
      isLoadingMore: _isLoadingMore,
      onAutoLoad: _loadNextPage,
      paddingTop: 0,
    );
  }
}
