import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/metadata_tags_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class AdvancedSearchSheet extends ConsumerStatefulWidget {
  final String initialQuery;
  final MediaType type;
  final List<String> initialGenres;
  final List<String> initialTags;
  final String? sourceId;
  final void Function(String query, List<String> genres, List<String> tags)
  onApply;

  const AdvancedSearchSheet({
    super.key,
    required this.initialQuery,
    required this.type,
    required this.initialGenres,
    required this.initialTags,
    this.sourceId,
    required this.onApply,
  });

  @override
  ConsumerState<AdvancedSearchSheet> createState() =>
      _AdvancedSearchSheetState();
}

class _AdvancedSearchSheetState extends ConsumerState<AdvancedSearchSheet> {
  late final TextEditingController _queryController;
  late final TextEditingController _tagQueryController;
  late final Set<String> _selectedGenres;
  late final Set<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery);
    _tagQueryController = TextEditingController();
    _selectedGenres = Set.from(widget.initialGenres);
    _selectedTags = Set.from(widget.initialTags);

    _queryController.addListener(() => setState(() {}));
    _tagQueryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _queryController.dispose();
    _tagQueryController.dispose();
    super.dispose();
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (!_selectedGenres.remove(genre)) {
        _selectedGenres.add(genre);
      }
    });
  }

  void _addTag(String tag) {
    setState(() {
      _selectedTags.add(tag);
      _tagQueryController.clear();
    });
  }

  void _removeTag(String tag) => setState(() => _selectedTags.remove(tag));

  void _submit() {
    widget.onApply(
      _queryController.text,
      _selectedGenres.toList(),
      _selectedTags.toList(),
    );
    Navigator.pop(context);
  }

  void _clear() {
    widget.onApply('', [], []);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagsState = ref.watch(
      discoveryFiltersProvider((type: widget.type, sourceId: widget.sourceId)),
    );
    final tagQuery = _tagQueryController.text.trim().toLowerCase();

    return AppBottomSheet(
      title: 'Filters & Search',
      actions: [TextButton(onPressed: _clear, child: const Text('Clear'))],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchBar(
            controller: _queryController,
            hintText: 'Search ${widget.type.name.toLowerCase()}...',
            leading: const Icon(Icons.search),
            trailing: _queryController.text.isNotEmpty
                ? [
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _queryController.clear,
                    ),
                  ]
                : null,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: tagsState.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Failed to load filters: $e',
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (data) {
                  final filteredTags = tagQuery.isEmpty
                      ? const <String>[]
                      : data.tags
                            .where(
                              (t) =>
                                  !_selectedTags.contains(t) &&
                                  t.toLowerCase().contains(tagQuery),
                            )
                            .take(5) // Limit suggestions to keep UI compact
                            .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.genres.isNotEmpty) ...[
                        Text(
                          'Genres',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: data.genres
                              .map(
                                (g) => FilterChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(g),
                                  selected: _selectedGenres.contains(g),
                                  onSelected: (_) => _toggleGenre(g),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (data.tags.isNotEmpty) ...[
                        Text(
                          'Tags',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedTags.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedTags
                                .map(
                                  (t) => InputChip(
                                    label: Text(t),
                                    onDeleted: () => _removeTag(t),
                                    backgroundColor:
                                        theme.colorScheme.tertiaryContainer,
                                    labelStyle: TextStyle(
                                      color:
                                          theme.colorScheme.onTertiaryContainer,
                                    ),
                                    deleteIconColor:
                                        theme.colorScheme.onTertiaryContainer,
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SearchBar(
                          controller: _tagQueryController,
                          hintText: 'Search tags to add...',
                          leading: const Icon(Icons.tag),
                          trailing: _tagQueryController.text.isNotEmpty
                              ? [
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _tagQueryController.clear();
                                      setState(() {});
                                    },
                                  ),
                                ]
                              : null,
                        ),
                        if (filteredTags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: filteredTags
                                  .map(
                                    (t) => ListTile(
                                      title: Text(t),
                                      trailing: const Icon(Icons.add),
                                      onTap: () => _addTag(t),
                                      dense: true,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
