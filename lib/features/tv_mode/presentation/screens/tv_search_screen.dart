import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/utils/focus_hover_detector.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/metadata_tags_provider.dart';
import 'package:shonenx/features/discovery/providers/search_provider.dart';
import 'package:shonenx/features/tv_mode/presentation/screens/tv_home_screen.dart';
import 'package:shonenx/features/tv_mode/presentation/tv_scale.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_backdrop_background.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_smart_image.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';

class TvSearchScreen extends ConsumerStatefulWidget {
  const TvSearchScreen({super.key});

  @override
  ConsumerState<TvSearchScreen> createState() => _TvSearchScreenState();
}

class _TvSearchScreenState extends ConsumerState<TvSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  String _query = '';
  MediaType _selectedType = MediaType.ANIME;
  String? _selectedGenre;
  String? _selectedTag;
  String? _selectedSource;
  int _selectedQuickTileSection = 0;
  Timer? _debounceTimer;

  static const List<List<Color>> _tileGradients = [
    [Color(0xFFE53935), Color(0xFFFF7043)],
    [Color(0xFF8E24AA), Color(0xFFBA68C8)],
    [Color(0xFF1E88E5), Color(0xFF42A5F5)],
    [Color(0xFF00897B), Color(0xFF4DB6AC)],
    [Color(0xFFF4511E), Color(0xFFFF8A65)],
    [Color(0xFF3949AB), Color(0xFF5C6BC0)],
    [Color(0xFF00ACC1), Color(0xFF26C6DA)],
    [Color(0xFFD81B60), Color(0xFFFF4081)],
    [Color(0xFF43A047), Color(0xFF66BB6A)],
    [Color(0xFF5E35B1), Color(0xFF7E57C2)],
    [Color(0xFFFB8C00), Color(0xFFFFB74D)],
    [Color(0xFF546E7A), Color(0xFF78909C)],
  ];

  static const _genreIconMap = <(List<String>, IconData)>[
    (['action', 'act'], Icons.bolt_rounded),
    (['advent'], Icons.explore_rounded),
    (['comed'], Icons.sentiment_very_satisfied_rounded),
    (['drama'], Icons.masks_rounded),
    (['fant'], Icons.auto_awesome_rounded),
    (['roman'], Icons.favorite_rounded),
    (['sci', 'space', 'cyber'], Icons.rocket_launch_rounded),
    (['supernatural', 'magic', 'demon'], Icons.visibility_rounded),
    (['myster'], Icons.search_rounded),
    (['slice', 'life'], Icons.coffee_rounded),
    (['sport'], Icons.sports_basketball_rounded),
    (['horror', 'gore', 'thrill'], Icons.dark_mode_rounded),
    (['psych'], Icons.psychology_rounded),
    (['music'], Icons.music_note_rounded),
    (['mecha', 'robot'], Icons.precision_manufacturing_rounded),
    (['isekai'], Icons.swap_horiz_rounded),
    (['shounen', 'shonen'], Icons.local_fire_department_rounded),
    (['shoujo', 'shojo'], Icons.spa_rounded),
    (['military', 'war'], Icons.shield_rounded),
    (['game', 'gaming'], Icons.sports_esports_rounded),
    (['school'], Icons.school_rounded),
    (['history', 'historical'], Icons.history_edu_rounded),
    (['ecchi'], Icons.whatshot_rounded),
    (['martial'], Icons.sports_martial_arts_rounded),
    (['police', 'crime'], Icons.local_police_rounded),
  ];

  List<Color> _gradientForText(String text) {
    final hash = text.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return _tileGradients[hash % _tileGradients.length];
  }

  IconData _iconForName(String name) {
    final lower = name.toLowerCase();
    for (final (keywords, icon) in _genreIconMap) {
      if (keywords.any(lower.contains)) return icon;
    }
    return Icons.category_rounded;
  }

  bool get _isSearchingOrFiltering =>
      _query.trim().isNotEmpty ||
      _selectedGenre != null ||
      _selectedTag != null ||
      _selectedSource != null;

  SearchArgs get _currentSearchArgs => SearchArgs(
    query: _query.trim(),
    type: _selectedType,
    genres: _selectedGenre != null ? [_selectedGenre!] : const [],
    tags: _selectedTag != null ? [_selectedTag!] : const [],
    source: _selectedSource,
    sources: _selectedSource != null ? [_selectedSource!] : const [],
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      if (_isSearchingOrFiltering) {
        ref.read(searchProvider(_currentSearchArgs).notifier).loadNextPage();
      }
    }
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted && _query != value.trim()) {
        setState(() => _query = value.trim());
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() => _query = '');
  }

  void _clearAllFilters() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedGenre = null;
      _selectedTag = null;
      _selectedSource = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final padding = context.tvPadding;
    final searchArgs = _currentSearchArgs;
    final searchState = _isSearchingOrFiltering
        ? ref.watch(searchProvider(searchArgs))
        : null;

    final isTrackerMode = ref.watch(
      discoveryPrefsProvider.select((p) => p.mode == MetadataMode.tracker),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const TvBackdropBackground(),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding.left,
                  16,
                  padding.right,
                  14,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(cs),
                      if (_isSearchingOrFiltering) ...[
                        const SizedBox(height: 12),
                        _buildActiveFilterChips(cs),
                      ],
                    ],
                  ),
                ),
              ),
              if (!_isSearchingOrFiltering) ...[
                if (isTrackerMode)
                  _buildTrackerQuickTilesGrid(cs, padding)
                else
                  _buildSourceQuickTilesGrid(cs, padding),
              ] else ...[
                searchState!.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: cs.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load search results',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Retry'),
                            onPressed: () =>
                                ref.invalidate(searchProvider(searchArgs)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (result) {
                    final items = result?.items ?? [];
                    if (items.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: cs.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No titles found',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try a different keyword or clear active filters',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('Clear Search & Filters'),
                                onPressed: _clearAllFilters,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        padding.left,
                        4,
                        padding.right,
                        60,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              childAspectRatio: 0.62,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final media = items[index];
                          return _TvPosterCard(
                            media: media,
                            onTap: () {
                              context.pushDetails(
                                mediaType: media.type,
                                media: media,
                              );
                            },
                            onFocused: () {
                              ref
                                  .read(tvFocusedBackdropProvider.notifier)
                                  .setBackdrop(media.banner ?? media.cover);
                            },
                          );
                        }, childCount: items.length),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    final radius = GlobalUI.uiRoundness;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onQueryChanged,
              onSubmitted: (val) => setState(() => _query = val.trim()),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Search ${_selectedType.displayName.toLowerCase()}...',
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: cs.primary,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _TvTypeToggle(
          selectedType: _selectedType,
          onTypeChanged: (type) {
            setState(() {
              _selectedType = type;
              _selectedGenre = null;
              _selectedTag = null;
              _selectedSource = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActiveFilterChips(ColorScheme cs) {
    return Row(
      children: [
        if (_query.trim().isNotEmpty)
          _buildFilterChip(
            label: '"$_query"',
            icon: Icons.search_rounded,
            color: cs.primary,
            onRemove: _clearSearch,
          ),
        if (_selectedGenre != null) ...[
          if (_query.trim().isNotEmpty) const SizedBox(width: 8),
          _buildFilterChip(
            label: _selectedGenre!,
            icon: Icons.category_rounded,
            color: cs.primary,
            onRemove: () => setState(() => _selectedGenre = null),
          ),
        ],
        if (_selectedTag != null) ...[
          if (_query.trim().isNotEmpty || _selectedGenre != null)
            const SizedBox(width: 8),
          _buildFilterChip(
            label: _selectedTag!,
            icon: Icons.tag_rounded,
            color: cs.tertiary,
            onRemove: () => setState(() => _selectedTag = null),
          ),
        ],
        if (_selectedSource != null) ...[
          if (_query.trim().isNotEmpty ||
              _selectedGenre != null ||
              _selectedTag != null)
            const SizedBox(width: 8),
          _buildFilterChip(
            label: _selectedSource!,
            icon: Icons.extension_rounded,
            color: cs.secondary,
            onRemove: () => setState(() => _selectedSource = null),
          ),
        ],
        const Spacer(),
        TextButton.icon(
          icon: const Icon(Icons.clear_all_rounded, size: 16),
          label: const Text('Clear All'),
          onPressed: _clearAllFilters,
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onRemove,
  }) {
    final radius = GlobalUI.uiRoundness;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          AppFocusHover(
            onTap: onRemove,
            builder: (context, isFocused, isHovered) {
              return Icon(
                Icons.close_rounded,
                size: 14,
                color: isFocused ? Colors.white : color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerQuickTilesGrid(ColorScheme cs, EdgeInsets padding) {
    final filtersAsync = ref.watch(
      discoveryFiltersProvider((type: _selectedType, sourceId: null)),
    );

    return filtersAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SliverFillRemaining(
        child: Center(child: Text('Failed to load genres: $err')),
      ),
      data: (MetadataTagsState state) {
        final genres = state.genres;
        final tags = state.tags;

        if (genres.isEmpty && tags.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('No genres or tags available')),
          );
        }

        final isShowingGenres = _selectedQuickTileSection == 0 || tags.isEmpty;
        final items = isShowingGenres ? genres : tags;

        return SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(
                      isShowingGenres
                          ? Icons.category_rounded
                          : Icons.tag_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isShowingGenres ? 'Explore Genres' : 'Explore Tags',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (tags.isNotEmpty)
                      _TvSectionPillToggle(
                        currentIndex: isShowingGenres ? 0 : 1,
                        genreCount: genres.length,
                        tagCount: tags.length,
                        onChanged: (idx) {
                          setState(() => _selectedQuickTileSection = idx);
                        },
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 60),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 1.55,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final name = items[index];
                  final gradient = _gradientForText(name);
                  final icon = _iconForName(name);

                  return _TvQuickTileCard(
                    name: name,
                    icon: icon,
                    gradient: gradient,
                    onTap: () {
                      setState(() {
                        if (isShowingGenres) {
                          _selectedGenre = name;
                          _selectedTag = null;
                        } else {
                          _selectedTag = name;
                          _selectedGenre = null;
                        }
                      });
                    },
                  );
                }, childCount: items.length),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSourceQuickTilesGrid(ColorScheme cs, EdgeInsets padding) {
    final sourcesAsync = ref.watch(_selectedType.availableSourcesProvider);

    return sourcesAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SliverFillRemaining(
        child: Center(child: Text('Failed to load sources: $err')),
      ),
      data: (List<SourceInfo> sources) {
        if (sources.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('No sources available')),
          );
        }

        return SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(Icons.extension_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Browse by Source (${sources.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 60),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final source = sources[index];
                  return _TvSourceQuickTileCard(
                    source: source,
                    onTap: () {
                      setState(() {
                        _selectedSource = source.id;
                        _selectedGenre = null;
                        _selectedTag = null;
                      });
                    },
                  );
                }, childCount: sources.length),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TvSectionPillToggle extends StatelessWidget {
  final int currentIndex;
  final int genreCount;
  final int tagCount;
  final ValueChanged<int> onChanged;

  const _TvSectionPillToggle({
    required this.currentIndex,
    required this.genreCount,
    required this.tagCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            context,
            index: 0,
            label: 'Genres ($genreCount)',
            icon: Icons.category_rounded,
          ),
          const SizedBox(width: 4),
          _buildItem(
            context,
            index: 1,
            label: 'Tags ($tagCount)',
            icon: Icons.tag_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required int index,
    required String label,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final radius = (GlobalUI.uiRoundness - 4).clamp(0.0, double.infinity);
    final isSelected = currentIndex == index;

    return AppFocusHover(
      onTap: () => onChanged(index),
      scaleFactor: 1.03,
      builder: (context, isFocused, isHovered) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isFocused
                ? cs.onSurface
                : (isSelected ? cs.primary : Colors.transparent),
            borderRadius: BorderRadius.circular(radius),
            border: isFocused ? Border.all(color: cs.primary, width: 2) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isFocused
                    ? cs.surface
                    : (isSelected ? cs.onPrimary : cs.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isFocused
                      ? cs.surface
                      : (isSelected ? cs.onPrimary : cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TvTypeToggle extends StatelessWidget {
  final MediaType selectedType;
  final ValueChanged<MediaType> onTypeChanged;

  const _TvTypeToggle({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TvTypePill(
            label: 'Anime',
            icon: Icons.movie_outlined,
            isSelected: selectedType == MediaType.ANIME,
            onTap: () => onTypeChanged(MediaType.ANIME),
          ),
          const SizedBox(width: 4),
          _TvTypePill(
            label: 'Manga',
            icon: Icons.menu_book_outlined,
            isSelected: selectedType == MediaType.MANGA,
            onTap: () => onTypeChanged(MediaType.MANGA),
          ),
        ],
      ),
    );
  }
}

class _TvTypePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TvTypePill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = (GlobalUI.uiRoundness - 4).clamp(0.0, double.infinity);

    return AppFocusHover(
      onTap: onTap,
      scaleFactor: 1.03,
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isFocused
                ? cs.onSurface
                : (isSelected ? cs.primary : Colors.transparent),
            borderRadius: BorderRadius.circular(radius),
            border: isFocused ? Border.all(color: cs.primary, width: 2) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isFocused
                    ? cs.surface
                    : (isSelected ? cs.onPrimary : cs.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active || isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isFocused
                      ? cs.surface
                      : (isSelected ? cs.onPrimary : cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TvQuickTileCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _TvQuickTileCard({
    required this.name,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = GlobalUI.uiRoundness;

    return AppFocusHover(
      onTap: onTap,
      scaleFactor: 1.05,
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradient[0].withValues(alpha: 0.9),
                gradient[1].withValues(alpha: 0.7),
              ],
            ),
            border: Border.all(
              color: isFocused
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.15),
              width: isFocused ? 2.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withValues(alpha: active ? 0.45 : 0.2),
                blurRadius: active ? 16 : 6,
                offset: Offset(0, active ? 5 : 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  icon,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: Colors.white),
                    ),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TvSourceQuickTileCard extends StatelessWidget {
  final SourceInfo source;
  final VoidCallback onTap;

  const _TvSourceQuickTileCard({required this.source, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    return AppFocusHover(
      onTap: onTap,
      scaleFactor: 1.05,
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFocused
                ? cs.onSurface
                : cs.surfaceContainerHighest.withValues(
                    alpha: isHovered ? 0.75 : 0.45,
                  ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: isFocused
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.2),
              width: isFocused ? 2.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: active ? 0.4 : 0.15),
                blurRadius: active ? 14 : 4,
                offset: Offset(0, active ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isFocused
                          ? Colors.black.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        (radius * 0.5).clamp(0.0, double.infinity),
                      ),
                    ),
                    child: source.iconUrl != null && source.iconUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: source.iconUrl!,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.extension_rounded,
                              size: 18,
                              color: isFocused ? Colors.black : cs.primary,
                            ),
                          )
                        : Icon(
                            Icons.extension_rounded,
                            size: 18,
                            color: isFocused ? Colors.black : cs.primary,
                          ),
                  ),
                  if (source.lang != null && source.lang!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isFocused
                            ? Colors.black.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          (radius * 0.4).clamp(0.0, double.infinity),
                        ),
                      ),
                      child: Text(
                        source.lang!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isFocused ? Colors.black87 : Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                source.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isFocused ? cs.surface : cs.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TvPosterCard extends StatelessWidget {
  final UnifiedMedia media;
  final VoidCallback onTap;
  final VoidCallback onFocused;

  const _TvPosterCard({
    required this.media,
    required this.onTap,
    required this.onFocused,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    return AppFocusHover(
      scaleFactor: 1.05,
      onTap: onTap,
      onFocusChange: (focused) {
        if (focused) onFocused();
      },
      onHoverChange: (hovered) {
        if (hovered) onFocused();
      },
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: isFocused
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.2),
                    width: isFocused ? 2.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: active ? 0.6 : 0.2),
                      blurRadius: active ? 16 : 6,
                      offset: Offset(0, active ? 5 : 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    (radius - 1).clamp(0.0, double.infinity),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TvSmartImage(
                        imageUrl: media.cover ?? '',
                        fit: BoxFit.cover,
                      ),
                      if (media.score != null && media.score! > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(
                                (radius * 0.4).clamp(0.0, double.infinity),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  media.score!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (media.format != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(
                                (radius * 0.4).clamp(0.0, double.infinity),
                              ),
                            ),
                            child: Text(
                              media.format!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              media.title.availableTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                color: active ? cs.primary : cs.onSurface,
              ),
            ),
            if (media.year != null || media.status != null)
              Text(
                [
                  if (media.year != null) '${media.year}',
                  if (media.status != null) media.status!,
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
          ],
        );
      },
    );
  }
}
