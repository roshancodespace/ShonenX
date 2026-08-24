import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/discover/dynamic_genre_feed.dart';
import 'package:shonenx/features/discovery/presentation/widgets/discover/dynamic_source_feed.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/search_provider.dart';
import 'package:shonenx/features/tv_mode/presentation/tv_scale.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/unified_search_bar.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TvSearchScreen extends ConsumerStatefulWidget {
  const TvSearchScreen({super.key});

  @override
  ConsumerState<TvSearchScreen> createState() => _TvSearchScreenState();
}

class _TvSearchScreenState extends ConsumerState<TvSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  Timer? _debounceTimer;
  MediaType _selectedType = MediaType.ANIME;
  String _currentQuery = '';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  SearchArgs get _args => SearchArgs(query: _currentQuery, type: _selectedType);

  bool get _hasActiveSearch => _currentQuery.isNotEmpty;

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      if (_currentQuery.isNotEmpty) {
        setState(() => _currentQuery = '');
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _currentQuery != trimmed) {
        setState(() => _currentQuery = trimmed);
      }
    });
  }

  void _onSearchSubmitted(String val) {
    _debounceTimer?.cancel();
    final trimmed = val.trim();
    if (_currentQuery != trimmed) {
      setState(() => _currentQuery = trimmed);
    }
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _controller.clear();
    if (_currentQuery.isNotEmpty) {
      setState(() => _currentQuery = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.tvScale;
    final discoveryMode = ref.watch(
      discoveryPrefsProvider.select((p) => p.mode),
    );

    final horizontalPad = (32.0 * scale).clamp(24.0, 56.0);
    final searchBarHeight = (48.0 * scale).clamp(44.0, 60.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: UnifiedSearchBar(
                  controller: _controller,
                  focusNode: _inputFocusNode,
                  autofocus: false,
                  margin: EdgeInsets.zero,
                  height: searchBarHeight,
                  hintText: 'Search title, keyword, or character...',
                  onBackPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _clearSearch();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                  onClearPressed: _clearSearch,
                  onSubmitted: _onSearchSubmitted,
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),
              _TvTypeFilterChip(
                label: 'Anime',
                isSelected: _selectedType == MediaType.ANIME,
                onTap: () {
                  setState(() => _selectedType = MediaType.ANIME);
                },
              ),
              const SizedBox(width: 8),
              _TvTypeFilterChip(
                label: 'Manga',
                isSelected: _selectedType == MediaType.MANGA,
                onTap: () {
                  setState(() => _selectedType = MediaType.MANGA);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: !_hasActiveSearch
                ? (discoveryMode == MetadataMode.source
                      ? DynamicSourceFeed(
                          type: _selectedType,
                          padding: const EdgeInsets.only(top: 4, bottom: 80),
                          onSourceSelect: (sourceId) {
                            context.pushDiscover(
                              source: sourceId,
                              type: _selectedType,
                            );
                          },
                        )
                      : DynamicGenreFeed(
                          type: _selectedType,
                          padding: const EdgeInsets.only(top: 4, bottom: 80),
                          onGenreSelect: (genre) {
                            context.pushDiscover(
                              category: genre,
                              genres: [genre],
                              type: _selectedType,
                            );
                          },
                        ))
                : _TvSearchResultsView(args: _args),
          ),
        ],
      ),
    );
  }
}

class _TvTypeFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TvTypeFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TvTypeFilterChip> createState() => _TvTypeFilterChipState();
}

class _TvTypeFilterChipState extends State<_TvTypeFilterChip> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = widget.isSelected;

    return FocusableActionDetector(
      focusNode: _focusNode,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: AnimatedScale(
        scale: _isFocused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: InkWell(
          canRequestFocus: false,
          onTap: () {
            _focusNode.requestFocus();
            widget.onTap();
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary
                  : (_isFocused
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused
                    ? Colors.white
                    : (isSelected
                          ? cs.primary
                          : Colors.white.withValues(alpha: 0.12)),
                width: _isFocused ? 1.8 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.15),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected || _isFocused
                    ? FontWeight.bold
                    : FontWeight.w500,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TvSearchResultsView extends ConsumerStatefulWidget {
  final SearchArgs args;

  const _TvSearchResultsView({required this.args});

  @override
  ConsumerState<_TvSearchResultsView> createState() =>
      _TvSearchResultsViewState();
}

class _TvSearchResultsViewState extends ConsumerState<_TvSearchResultsView> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= max - 300 && !_isLoadingMore) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    final searchAsync = ref.read(searchProvider(widget.args));
    if (searchAsync.value?.hasNextPage != true) return;

    setState(() => _isLoadingMore = true);
    try {
      await ref.read(searchProvider(widget.args).notifier).loadNextPage();
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchProvider(widget.args));
    final cardStyle = ref.watch(uiPrefsProvider.select((p) => p.cardStyle));
    final isWide = ref.watch(
      uiPrefsProvider.select((p) => p.isMediaCardWide(cardStyle.name)),
    );
    final size = MediaQuery.sizeOf(context);
    final cardLayout = cardStyle.getLayout(isWideMode: isWide);
    final childAspectRatio = cardLayout.width / cardLayout.height;

    final crossAxisCount = (size.width / (cardLayout.width + 20)).floor().clamp(
      3,
      8,
    );

    return searchAsync.when(
      data: (paginated) {
        final items = paginated?.items ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 54,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 14),
                Text(
                  'No results found',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 80, top: 4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: items.length + (_isLoadingMore ? crossAxisCount : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return Skeletonizer(
                enabled: true,
                child: MediaCard(
                  tag: 'skeleton-tv-search-more-$index',
                  title: 'Placeholder Title',
                  imageUrl: '',
                  style: cardStyle,
                  onTap: () {},
                ),
              );
            }

            final media = items[index];
            return MediaCard(
              title: media.title.availableTitle,
              tag: 'tv-search-${media.id}',
              imageUrl: media.cover ?? '',
              score: media.score,
              format: media.format,
              year: media.season,
              status: media.status,
              genres: media.genres,
              style: cardStyle,
              onTap: () {
                context.pushDetails(
                  mediaType: media.type,
                  media: media,
                  tag: 'tv-search-${media.id}',
                );
              },
            );
          },
        );
      },
      loading: () => Skeletonizer(
        enabled: true,
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 80, top: 4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: crossAxisCount * 2,
          itemBuilder: (context, index) => MediaCard(
            tag: 'skeleton-tv-search-$index',
            title: 'Placeholder Title',
            imageUrl: '',
            style: cardStyle,
            onTap: () {},
          ),
        ),
      ),
      error: (e, _) => Center(
        child: Text(
          'Search error: $e',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
