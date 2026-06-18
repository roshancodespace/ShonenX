import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/metadata_tags_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class AdvancedSearchSheet extends ConsumerStatefulWidget {
  final String initialQuery;
  final List<String> initialGenres;
  final List<String> initialTags;
  final void Function(String query, List<String> genres, List<String> tags)
  onApply;

  const AdvancedSearchSheet({
    super.key,
    required this.initialQuery,
    required this.initialGenres,
    required this.initialTags,
    required this.onApply,
  });

  @override
  ConsumerState<AdvancedSearchSheet> createState() =>
      _AdvancedSearchSheetState();
}

class _AdvancedSearchSheetState extends ConsumerState<AdvancedSearchSheet> {
  late final TextEditingController _queryController;
  late final Set<String> _selectedGenres;
  late final Set<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery);
    _selectedGenres = Set.from(widget.initialGenres);
    _selectedTags = Set.from(widget.initialTags);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagsState = ref.watch(metadataTagsProvider);

    return AppBottomSheet(
      title: 'Advanced Search',
      actions: [
        TextButton(
          onPressed: () {
            widget.onApply('', [], []);
            Navigator.pop(context);
          },
          child: const Text(
            'Clear',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Input
          TextField(
            controller: _queryController,
            autofocus: true,
            style: theme.textTheme.titleMedium,
            decoration: InputDecoration(
              hintText: 'Search anime...',
              hintStyle: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              suffixIcon: _queryController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _queryController.clear();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() {}),
            onSubmitted: (_) {
              widget.onApply(
                _queryController.text,
                _selectedGenres.toList(),
                _selectedTags.toList(),
              );
              Navigator.pop(context);
            },
          ),

          const SizedBox(height: 16),

          // Scrollable Filters
          Flexible(
            child: SingleChildScrollView(
              child: tagsState.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    Center(child: Text('Failed to load filters: $e')),
                data: (data) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.genres.isNotEmpty) ...[
                        Text(
                          'Genres',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: data.genres.map((g) {
                            final isSelected = _selectedGenres.contains(g);
                            return FilterChip(
                              label: Text(g),
                              selected: isSelected,
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onSelected: (_) => _toggleGenre(g),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      if (data.tags.isNotEmpty) ...[
                        Text(
                          'Tags',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedTags.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedTags.map((t) {
                              return InputChip(
                                label: Text(t),
                                onDeleted: () => _toggleTag(t),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return data.tags.where((String option) {
                              return option.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              );
                            });
                          },
                          onSelected: (String selection) {
                            if (!_selectedTags.contains(selection)) {
                              _toggleTag(selection);
                            }
                          },
                          fieldViewBuilder:
                              (
                                context,
                                controller,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  style: theme.textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: 'Search tags...',
                                    hintStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                    prefixIcon: const Icon(Icons.tag, size: 20),
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                  ),
                                  onSubmitted: (value) => onFieldSubmitted(),
                                );
                              },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(16),
                                color: theme.colorScheme.surfaceContainerHigh,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: 160,
                                    maxWidth:
                                        MediaQuery.of(context).size.width - 48,
                                  ),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          final String option = options
                                              .elementAt(index);
                                          return ListTile(
                                            dense: true,
                                            title: Text(option),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),

          // Bottom Actions
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(
                  _queryController.text,
                  _selectedGenres.toList(),
                  _selectedTags.toList(),
                );
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
