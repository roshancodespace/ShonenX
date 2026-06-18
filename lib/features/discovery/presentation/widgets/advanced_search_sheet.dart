import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/metadata_tags_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

const _kRadius = 14.0;
const _kAnimDuration = Duration(milliseconds: 200);
const _kAnimCurve = Curves.easeOutCubic;

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
  late final TextEditingController _tagQueryController;
  late final FocusNode _tagFieldFocus;
  late final Set<String> _selectedGenres;
  late final Set<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery);
    _tagQueryController = TextEditingController();
    _tagFieldFocus = FocusNode();
    _selectedGenres = Set.from(widget.initialGenres);
    _selectedTags = Set.from(widget.initialTags);
    _queryController.addListener(_onTextChanged);
    _tagQueryController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _queryController.removeListener(_onTextChanged);
    _tagQueryController.removeListener(_onTextChanged);
    _queryController.dispose();
    _tagQueryController.dispose();
    _tagFieldFocus.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

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
    _tagFieldFocus.requestFocus();
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
    final tagsState = ref.watch(metadataTagsProvider);
    final tagQuery = _tagQueryController.text.trim().toLowerCase();

    return AppBottomSheet(
      title: 'Advanced Search',
      actions: [
        TextButton(
          onPressed: _clear,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          child: const Text('Clear'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchField(
            controller: _queryController,
            theme: theme,
            hint: 'Search anime...',
            icon: Icons.search_rounded,
            autofocus: true,
            onClear: _queryController.clear,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 26),
          Flexible(
            child: SingleChildScrollView(
              child: tagsState.when(
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 22,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Couldn't load filters",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$e',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                    ],
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
                            .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.genres.isNotEmpty) ...[
                        _SectionLabel(text: 'Genres', theme: theme),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: data.genres
                              .map(
                                (g) => _FlatChip(
                                  label: g,
                                  selected: _selectedGenres.contains(g),
                                  theme: theme,
                                  onTap: () => _toggleGenre(g),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 30),
                      ],
                      if (data.tags.isNotEmpty) ...[
                        _SectionLabel(text: 'Tags', theme: theme),
                        const SizedBox(height: 14),
                        if (_selectedTags.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedTags
                                .map(
                                  (t) => _FlatChip(
                                    label: t,
                                    selected: true,
                                    removable: true,
                                    theme: theme,
                                    onTap: () => _removeTag(t),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _SearchField(
                          controller: _tagQueryController,
                          focusNode: _tagFieldFocus,
                          theme: theme,
                          hint: 'Search tags...',
                          icon: Icons.tag_rounded,
                          dense: true,
                          onClear: _tagQueryController.clear,
                        ),
                        AnimatedSize(
                          duration: _kAnimDuration,
                          curve: _kAnimCurve,
                          alignment: Alignment.topCenter,
                          child: filteredTags.isEmpty
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: filteredTags
                                        .take(6)
                                        .map(
                                          (t) => _SuggestionRow(
                                            label: t,
                                            theme: theme,
                                            onTap: () => _addTag(t),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kRadius),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.theme,
    required this.hint,
    required this.icon,
    required this.onClear,
    this.focusNode,
    this.autofocus = false,
    this.dense = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final ThemeData theme;
  final String hint;
  final IconData icon;
  final VoidCallback onClear;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool dense;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.4);
    final hairline = theme.colorScheme.onSurface.withValues(alpha: 0.14);
    final textStyle = dense
        ? theme.textTheme.bodyMedium
        : theme.textTheme.titleMedium;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      style: textStyle,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        isDense: dense,
        hintText: hint,
        hintStyle: textStyle?.copyWith(color: muted),
        prefixIcon: Icon(icon, size: dense ? 18 : 20, color: muted),
        suffixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: controller.text.isEmpty
              ? SizedBox(key: const ValueKey('empty'), width: dense ? 36 : 40)
              : IconButton(
                  key: const ValueKey('filled'),
                  icon: Icon(Icons.close_rounded, size: 17, color: muted),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(
                    width: dense ? 32 : 36,
                    height: dense ? 32 : 36,
                  ),
                ),
        ),
        filled: false,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: dense ? 12 : 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide: BorderSide(color: hairline, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.theme});

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _FlatChip extends StatefulWidget {
  const _FlatChip({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
    this.removable = false,
  });

  final String label;
  final bool selected;
  final ThemeData theme;
  final VoidCallback onTap;
  final bool removable;

  @override
  State<_FlatChip> createState() => _FlatChipState();
}

class _FlatChipState extends State<_FlatChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final selected = widget.selected;
    final hairline = theme.colorScheme.onSurface.withValues(alpha: 0.18);

    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: _kAnimDuration,
            curve: _kAnimCurve,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(_kRadius),
              border: selected ? null : Border.all(color: hairline, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.removable) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatefulWidget {
  const _SuggestionRow({
    required this.label,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  State<_SuggestionRow> createState() => _SuggestionRowState();
}

class _SuggestionRowState extends State<_SuggestionRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: _pressed
                ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(_kRadius),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
