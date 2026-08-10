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
                                final isSelected = _selectedSort == sortOpt;
                                return ChoiceChip(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  label: Text(sortOpt.label),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      setState(() => _selectedSort = sortOpt),
                                  backgroundColor: colorScheme
                                      .surfaceContainerHigh
                                      .withValues(alpha: 0.5),
                                  selectedColor: colorScheme.primaryContainer,
                                  labelStyle: theme.textTheme.labelMedium
                                      ?.copyWith(
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outline.withValues(
                                            alpha: 0.2,
                                          ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
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
                                final isSelected = _selectedStatus == statusOpt;
                                return ChoiceChip(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  label: Text(statusOpt.label),
                                  selected: isSelected,
                                  onSelected: (_) => setState(
                                    () => _selectedStatus = statusOpt,
                                  ),
                                  backgroundColor: colorScheme
                                      .surfaceContainerHigh
                                      .withValues(alpha: 0.5),
                                  selectedColor: colorScheme.primaryContainer,
                                  labelStyle: theme.textTheme.labelMedium
                                      ?.copyWith(
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outline.withValues(
                                            alpha: 0.2,
                                          ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
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
                                final isSelected = _selectedFormat == fmtOpt;
                                return ChoiceChip(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  label: Text(fmtOpt.label),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      setState(() => _selectedFormat = fmtOpt),
                                  backgroundColor: colorScheme
                                      .surfaceContainerHigh
                                      .withValues(alpha: 0.5),
                                  selectedColor: colorScheme.primaryContainer,
                                  labelStyle: theme.textTheme.labelMedium
                                      ?.copyWith(
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outline.withValues(
                                            alpha: 0.2,
                                          ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
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
                                      selectedColor:
                                          colorScheme.primaryContainer,
                                      checkmarkColor:
                                          colorScheme.onPrimaryContainer,
                                      labelStyle: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: _selectedGenres.contains(g)
                                                ? colorScheme.onPrimaryContainer
                                                : colorScheme.onSurfaceVariant,
                                            fontWeight:
                                                _selectedGenres.contains(g)
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                      side: BorderSide(
                                        color: _selectedGenres.contains(g)
                                            ? colorScheme.primary
                                            : colorScheme.outline.withValues(
                                                alpha: 0.2,
                                              ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
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
                                        label: Text(t),
                                        onDeleted: () => _removeTag(t),
                                        backgroundColor:
                                            colorScheme.secondaryContainer,
                                        labelStyle: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: colorScheme
                                                  .onSecondaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                        deleteIconColor:
                                            colorScheme.onSecondaryContainer,
                                        side: BorderSide.none,
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
