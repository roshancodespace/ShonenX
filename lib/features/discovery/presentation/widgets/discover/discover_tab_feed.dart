import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/search_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

import 'dynamic_genre_feed.dart';
import 'dynamic_source_feed.dart';
import 'multi_source_search_feed.dart';
import 'paginated_media_grid.dart';

class DiscoverTabFeed extends ConsumerStatefulWidget {
  final MediaType type;
  final String query;
  final List<String> genres;
  final List<String> tags;
  final String? source;
  final ValueChanged<String>? onGenreSelect;
  final ValueChanged<String>? onSourceSelect;

  const DiscoverTabFeed({
    super.key,
    required this.type,
    required this.query,
    required this.genres,
    required this.tags,
    this.source,
    this.onGenreSelect,
    this.onSourceSelect,
  });

  @override
  ConsumerState<DiscoverTabFeed> createState() => _DiscoverTabFeedState();
}

class _DiscoverTabFeedState extends ConsumerState<DiscoverTabFeed> {
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
      if (!_isLoadingMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadNextPage();
        });
      }
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
        return DynamicSourceFeed(
          type: widget.type,
          onSourceSelect: widget.onSourceSelect,
        );
      }
      return DynamicGenreFeed(
        type: widget.type,
        onGenreSelect: widget.onGenreSelect,
      );
    }

    final discoveryMode = ref.watch(
      discoveryPrefsProvider.select((p) => p.mode),
    );

    if (discoveryMode == MetadataMode.source && widget.source == null) {
      return MultiSourceSearchFeed(
        type: widget.type,
        query: widget.query,
        genres: widget.genres,
        tags: widget.tags,
        onSourceSelect: widget.onSourceSelect,
      );
    }

    final state = ref.watch(searchProvider(_args));

    return PaginatedMediaGrid(
      state: state,
      scrollController: _scrollController,
      isLoadingMore: _isLoadingMore,
      onAutoLoad: _loadNextPage,
    );
  }
}
