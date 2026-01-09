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

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter.copyWith(
      genres: List.from(widget.initialFilter.genres),
      tags: List.from(widget.initialFilter.tags),
    );
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    try {
      final repo = ref.read(animeRepositoryProvider);
      final results = await Future.wait([
        repo.getGenres(),
        repo.getTags(),
      ]);

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoadingMetadata) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildHandle(context),
                _buildHeader(context),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      _buildSortSection(),
                      _sectionGap,
                      _buildSectionTitle('Format'),
                      _buildFormatSelect(),
                      _sectionGap,
                      _buildSectionTitle('Status'),
                      _buildStatusSelect(),
                      _sectionGap,
                      _buildSectionTitle('Season'),
                      _buildSeasonSelect(),
                      _sectionGap,
                      _buildSectionTitle('Year'),
                      _buildYearSelect(),
                      _sectionGap,
                      _buildSectionTitle('Genres'),
                      _buildGenreSelect(),
                      _sectionGap,
                      _buildSectionTitle('Tags'),
                      _buildTagSelect(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                _buildFooter(context),
              ],
            ),
          ),
        );
      },
    );
  }

  static const _sectionGap = SizedBox(height: 28);

  Widget _buildHandle(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Filters',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSortSection() {
    final sorts = [
      'POPULARITY_DESC',
      'SCORE_DESC',
      'TRENDING_DESC',
      'FAVOURITES_DESC',
      'START_DATE_DESC'
    ];

    final labels = ['Popularity', 'Score', 'Trending', 'Favorites', 'Newest'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Sort By'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(sorts.length, (i) {
            final selected = _filter.sort == sorts[i];
            return ChoiceChip(
              label: Text(labels[i]),
              selected: selected,
              showCheckmark: false,
              onSelected: (v) {
                setState(() {
                  _filter = _filter.copyWith(
                    sort: v ? sorts[i] : null,
                  );
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFormatSelect() {
    const formats = ['TV', 'TV_SHORT', 'MOVIE', 'SPECIAL', 'OVA', 'ONA'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: formats.map((f) {
        final selected = _filter.format == f;
        return ChoiceChip(
          label: Text(f.replaceAll('_', ' ')),
          selected: selected,
          onSelected: (v) {
            setState(() {
              _filter = _filter.copyWith(format: v ? f : null);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildStatusSelect() {
    const statuses = ['RELEASING', 'FINISHED', 'NOT_YET_RELEASED', 'CANCELLED'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((s) {
        final selected = _filter.status == s;
        return ChoiceChip(
          label: Text(s.replaceAll('_', ' ')),
          selected: selected,
          onSelected: (v) {
            setState(() {
              _filter = _filter.copyWith(status: v ? s : null);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSeasonSelect() {
    const seasons = ['WINTER', 'SPRING', 'SUMMER', 'FALL'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: seasons.map((s) {
        final selected = _filter.season == s;
        return ChoiceChip(
          label: Text(s),
          selected: selected,
          onSelected: (v) {
            setState(() {
              _filter = _filter.copyWith(season: v ? s : null);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildYearSelect() {
    final currentYear = DateTime.now().year;
    final years = List.generate(30, (i) => currentYear - i + 1);

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final year = years[i];
          final selected = _filter.year == year;
          return ChoiceChip(
            label: Text('$year'),
            selected: selected,
            onSelected: (v) {
              setState(() {
                _filter = _filter.copyWith(year: v ? year : null);
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildGenreSelect() {
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

  Widget _buildTagSelect() {
    final displayTags = _tags.take(30);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: displayTags.map((t) {
        final selected = _filter.tags.contains(t);
        return FilterChip(
          label: Text(t),
          selected: selected,
          onSelected: (v) {
            setState(() {
              final list = List<String>.from(_filter.tags);
              v ? list.add(t) : list.remove(t);
              _filter = _filter.copyWith(tags: list);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _filter = const SearchFilter();
                });
              },
              child: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _filter),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
