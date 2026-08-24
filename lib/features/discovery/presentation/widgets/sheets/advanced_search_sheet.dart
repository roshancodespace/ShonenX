import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/domain/models/search_filter_options.dart';
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
  final SearchSort initialSort;
  final SearchStatusFilter initialStatus;
  final SearchFormatFilter initialFormat;
  final void Function(
    String query,
    List<String> genres,
    List<String> tags,
    SearchSort sort,
    SearchStatusFilter status,
    SearchFormatFilter format,
  )
  onApply;

  const AdvancedSearchSheet({
    super.key,
    required this.initialQuery,
    required this.type,
    required this.initialGenres,
    required this.initialTags,
    this.sourceId,
    this.initialSort = SearchSort.popularity,
    this.initialStatus = SearchStatusFilter.all,
    this.initialFormat = SearchFormatFilter.all,
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
  late SearchSort _selectedSort;
  late SearchStatusFilter _selectedStatus;
  late SearchFormatFilter _selectedFormat;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery);
    _tagQueryController = TextEditingController();
    _selectedGenres = Set.from(widget.initialGenres);
    _selectedTags = Set.from(widget.initialTags);
    _selectedSort = widget.initialSort;
    _selectedStatus = widget.initialStatus;
    _selectedFormat = widget.initialFormat;

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
      _selectedSort,
      _selectedStatus,
      _selectedFormat,
    );
    Navigator.pop(context);
  }

  void _clear() {
    widget.onApply(
      '',
      [],
      [],
      SearchSort.popularity,
      SearchStatusFilter.all,
      SearchFormatFilter.all,
    );
    Navigator.pop(context);
  }

  Widget _buildSectionHeader(
    String title,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return ChoiceChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
      selectedColor: colorScheme.primaryContainer,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected
            ? colorScheme.primary
            : colorScheme.outline.withValues(alpha: 0.2),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected
            ? colorScheme.primary
            : colorScheme.outline.withValues(alpha: 0.2),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
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
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tagsState.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (data) {
                      final options = data.options;

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
                          if (!options.hasAnyFilter)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24.0,
                              ),
                              child: Center(
                                child: Text(
                                  'No additional search filters available for this source.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          // Sort By Section
                          if (options.supportsSorts) ...[
                            _buildSectionHeader('Sort By', theme, colorScheme),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: options.sorts.map((sortOpt) {
                                return _buildChoiceChip(
                                  label: sortOpt.label,
                                  selected: _selectedSort == sortOpt,
                                  onSelected: (_) =>
                                      setState(() => _selectedSort = sortOpt),
                                  theme: theme,
                                  colorScheme: colorScheme,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Status Section
                          if (options.supportsStatuses) ...[
                            _buildSectionHeader('Status', theme, colorScheme),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: options.statuses.map((statusOpt) {
                                return _buildChoiceChip(
                                  label: statusOpt.label,
                                  selected: _selectedStatus == statusOpt,
                                  onSelected: (_) => setState(
                                    () => _selectedStatus = statusOpt,
                                  ),
                                  theme: theme,
                                  colorScheme: colorScheme,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Format Section
                          if (options.supportsFormats) ...[
                            _buildSectionHeader('Format', theme, colorScheme),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: options.formats.map((fmtOpt) {
                                return _buildChoiceChip(
                                  label: fmtOpt.label,
                                  selected: _selectedFormat == fmtOpt,
                                  onSelected: (_) =>
                                      setState(() => _selectedFormat = fmtOpt),
                                  theme: theme,
                                  colorScheme: colorScheme,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (data.genres.isNotEmpty) ...[
                            _buildSectionHeader('Genres', theme, colorScheme),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: data.genres
                                  .map(
                                    (g) => _buildFilterChip(
                                      label: g,
                                      selected: _selectedGenres.contains(g),
                                      onSelected: (_) => _toggleGenre(g),
                                      theme: theme,
                                      colorScheme: colorScheme,
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (data.tags.isNotEmpty) ...[
                            _buildSectionHeader('Tags', theme, colorScheme),
                            if (_selectedTags.isNotEmpty) ...[
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _selectedTags
                                    .map(
                                      (t) => InputChip(
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        label: Text(t),
                                        onDeleted: () => _removeTag(t),
                                        deleteIconColor: colorScheme.primary,
                                        backgroundColor:
                                            colorScheme.primaryContainer,
                                        labelStyle: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 8),
                            ],
                            TextField(
                              controller: _tagQueryController,
                              decoration: InputDecoration(
                                hintText: 'Type to filter & add tags...',
                                prefixIcon: const Icon(
                                  Icons.tag_rounded,
                                  size: 20,
                                ),
                                suffixIcon: _tagQueryController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () =>
                                            _tagQueryController.clear(),
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            if (filteredTags.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: filteredTags
                                    .map(
                                      (t) => ActionChip(
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        avatar: const Icon(Icons.add, size: 14),
                                        label: Text(t),
                                        onPressed: () => _addTag(t),
                                        backgroundColor: colorScheme
                                            .surfaceContainerHigh
                                            .withValues(alpha: 0.5),
                                        labelStyle: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Apply Filters'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
