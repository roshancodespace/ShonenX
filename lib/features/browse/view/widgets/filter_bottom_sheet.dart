import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/features/browse/model/search_filter.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  final SearchFilter initialFilter;

  const FilterBottomSheet({super.key, required this.initialFilter});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late SearchFilter _filter;
  List<String> _genres = [];
  List<String> _tags = [];
  bool _isLoadingMetadata = true;
  final _tagSearchController = TextEditingController();
  List<String> _filteredTags = [];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter.copyWith(
      genres: List.from(widget.initialFilter.genres),
      tags: List.from(widget.initialFilter.tags),
    );
    _fetchMetadata();
  }

  @override
  void dispose() {
    _tagSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadata() async {
    try {
      final repo = ref.read(animeRepositoryProvider);
      final results = await Future.wait([repo.getGenres(), repo.getTags()]);

      if (!mounted) return;

      setState(() {
        _genres = results[0];
        _tags = results[1];
        _isLoadingMetadata = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMetadata = false);
      }
    }
  }

  void _onTagSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTags = [];
      } else {
        _filteredTags = _tags
            .where((t) => t.toLowerCase().contains(query.toLowerCase()))
            .where((t) => !_filter.tags.contains(t))
            .take(30)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_isLoadingMetadata) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildHandle(context),
              _buildHeader(context),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  children: [
                    const SizedBox(height: 16),
                    _buildSectionPadding(_buildSortSection(theme)),
                    _sectionGap,
                    _buildSectionPadding(_buildSeasonYearRow(theme)),
                    _sectionGap,
                    _buildSectionPadding(_buildCommonFilters(theme)),
                    _sectionGap,
                    _buildExpansionCategory(
                      context,
                      title: 'Genres',
                      count: _filter.genres.length,
                      child: _buildGenreSelect(theme),
                    ),
                    _buildExpansionCategory(
                      context,
                      title: 'Tags',
                      count: _filter.tags.length,
                      child: _buildTagSelect(theme),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              _buildFooter(context),
            ],
          ),
        );
      },
    );
  }

  static const _sectionGap = SizedBox(height: 24);

  Widget _buildSectionPadding(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: child,
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      width: 48,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Filters',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _filter = const SearchFilter();
                _tagSearchController.clear();
                _filteredTags = [];
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSortSection(ThemeData theme) {
    final sorts = [
      'POPULARITY_DESC',
      'SCORE_DESC',
      'TRENDING_DESC',
      'FAVOURITES_DESC',
      'START_DATE_DESC',
    ];
    final labels = ['Popularity', 'Score', 'Trending', 'Favorites', 'Newest'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Sort By'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(sorts.length, (i) {
            final selected = _filter.sort == sorts[i];
            return ChoiceChip(
              label: Text(labels[i]),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  _filter = _filter.copyWith(
                    sort: v ? sorts[i] : null,
                    resetSort: !v,
                  );
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSeasonYearRow(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(theme, 'Season'),
                  _buildSeasonDropdown(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(theme, 'Year'),
                  _buildYearDropdown(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeasonDropdown() {
    const seasons = ['WINTER', 'SPRING', 'SUMMER', 'FALL'];
    return DropdownButtonFormField<String>(
      initialValue: _filter.season,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      hint: const Text("Any"),
      items: [
        const DropdownMenuItem(value: null, child: Text("Any")),
        ...seasons.map((s) => DropdownMenuItem(value: s, child: Text(s))),
      ],
      onChanged: (v) => setState(
        () => _filter = _filter.copyWith(season: v, resetSeason: v == null),
      ),
    );
  }

  Widget _buildYearDropdown() {
    final currentYear = DateTime.now().year + 1;
    final years = List.generate(60, (i) => currentYear - i);

    return DropdownButtonFormField<int>(
      initialValue: _filter.year,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      hint: const Text("Any"),
      items: [
        const DropdownMenuItem(value: null, child: Text("Any")),
        ...years.map((y) => DropdownMenuItem(value: y, child: Text("$y"))),
      ],
      onChanged: (v) => setState(
        () => _filter = _filter.copyWith(year: v, resetYear: v == null),
      ),
    );
  }

  Widget _buildCommonFilters(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(theme, 'Options'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...['TV', 'MOVIE', 'OVA', 'SPECIAL'].map(
              (f) => FilterChip(
                label: Text(f),
                selected: _filter.format == f,
                onSelected: (v) => setState(
                  () => _filter = _filter.copyWith(
                    format: v ? f : null,
                    resetFormat: !v,
                  ),
                ),
              ),
            ),
            ...['RELEASING', 'FINISHED'].map(
              (s) => FilterChip(
                label: Text(s),
                selected: _filter.status == s,
                onSelected: (v) => setState(
                  () => _filter = _filter.copyWith(
                    status: v ? s : null,
                    resetStatus: !v,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpansionCategory(
    BuildContext context, {
    required String title,
    required int count,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: count > 0
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text("$count selected", style: theme.textTheme.labelSmall),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        children: [child],
      ),
    );
  }

  Widget _buildGenreSelect(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _genres.map((g) {
        final selected = _filter.genres.contains(g);
        return FilterChip(
          label: Text(g),
          selected: selected,
          onSelected: (v) {
            setState(() {
              final list = List<String>.from(_filter.genres);
              v ? list.add(g) : list.remove(g);
              _filter = _filter.copyWith(genres: list);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTagSelect(ThemeData theme) {
    final selectedTags = _tags.where((t) => _filter.tags.contains(t)).toList();
    final suggestions = _tagSearchController.text.isEmpty
        ? _tags.where((t) => !_filter.tags.contains(t)).take(20).toList()
        : _filteredTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _tagSearchController,
            onChanged: _onTagSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search tags...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
        if (selectedTags.isNotEmpty) ...[
          Text(
            "Selected",
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedTags.map((t) {
              return FilterChip(
                label: Text(t),
                selected: true,
                onSelected: (_) {
                  setState(() {
                    final list = List<String>.from(_filter.tags);
                    list.remove(t);
                    _filter = _filter.copyWith(tags: list);
                    _onTagSearchChanged(_tagSearchController.text);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
        ],
        Text(
          _tagSearchController.text.isEmpty ? "Popular Tags" : "Matches",
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((t) {
            return FilterChip(
              label: Text(t),
              selected: false,
              onSelected: (_) {
                setState(() {
                  final list = List<String>.from(_filter.tags);
                  list.add(t);
                  _filter = _filter.copyWith(tags: list);
                  _tagSearchController.clear();
                  _onTagSearchChanged('');
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.pop(context, _filter),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Apply Filters',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
