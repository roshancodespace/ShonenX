import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/metadata_tags_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/unified_search_bar.dart';

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
    final colorScheme = theme.colorScheme;
    final tagsState = ref.watch(
      discoveryFiltersProvider((type: widget.type, sourceId: widget.sourceId)),
    );
    final tagQuery = _tagQueryController.text.trim().toLowerCase();

    return AppBottomSheet(
      title: 'Filters & Search',
      actions: [
        TextButton(
          onPressed: _clear,
          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          child: const Text('Clear'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UnifiedSearchBar(
            controller: _queryController,
            onBackPressed: () => Navigator.pop(context),
            onClearPressed: () => _queryController.clear(),
            onSubmitted: (_) => _submit(),
            autofocus: false,
            hintText: 'Search ${widget.type.name.toLowerCase()}...',
            leading: const Icon(Icons.search_rounded),
          ),
          const SizedBox(height: 20),
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
                      style: TextStyle(color: colorScheme.error),
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
                            .take(5)
                            .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.genres.isNotEmpty) ...[
                        Text(
                          'Genres',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: data.genres
                              .map(
                                (g) => FilterChip(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  label: Text(g),
                                  selected: _selectedGenres.contains(g),
                                  onSelected: (_) => _toggleGenre(g),
                                  backgroundColor: colorScheme
                                      .surfaceContainerHigh
                                      .withValues(alpha: 0.5),
                                  selectedColor: colorScheme.primaryContainer,
                                  checkmarkColor:
                                      colorScheme.onPrimaryContainer,
                                  labelStyle: theme.textTheme.labelMedium
                                      ?.copyWith(
                                        color: _selectedGenres.contains(g)
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: _selectedGenres.contains(g)
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                  side: BorderSide(
                                    color: _selectedGenres.contains(g)
                                        ? colorScheme.primary
                                        : colorScheme.outline.withValues(
                                            alpha: 0.2,
                                          ),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (data.tags.isNotEmpty) ...[
                        Text(
                          'Tags',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedTags.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _selectedTags
                                .map(
                                  (t) => InputChip(
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    label: Text(t),
                                    onDeleted: () => _removeTag(t),
                                    backgroundColor:
                                        colorScheme.secondaryContainer,
                                    labelStyle: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color:
                                              colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    deleteIconColor:
                                        colorScheme.onSecondaryContainer,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                        UnifiedSearchBar(
                          controller: _tagQueryController,
                          onBackPressed: () {
                            _tagQueryController.clear();
                            setState(() {});
                          },
                          onClearPressed: () {
                            _tagQueryController.clear();
                            setState(() {});
                          },
                          autofocus: false,
                          hintText: 'Search tags to add...',
                          leading: const Icon(Icons.tag_rounded),
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
                                      trailing: Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                      onTap: () => _addTag(t),
                                      dense: true,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
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
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 2,
              shadowColor: colorScheme.primary.withValues(alpha: 0.3),
            ),
            child: Text(
              'Apply Filters',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
