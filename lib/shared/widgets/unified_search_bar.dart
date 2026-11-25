import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class UnifiedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onBackPressed;
  final VoidCallback onClearPressed;
  final VoidCallback? onFilterPressed;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool hasFilters;
  final String hintText;
  final bool autofocus;
  final Widget? leading;
  final FocusNode? focusNode;
  final double height;
  final EdgeInsetsGeometry margin;
  final bool isExpanded;
  final double? expandedWidth;
  final VoidCallback? onExpand;

  const UnifiedSearchBar({
    super.key,
    required this.controller,
    required this.onBackPressed,
    required this.onClearPressed,
    this.onFilterPressed,
    this.onSubmitted,
    this.onChanged,
    this.hasFilters = false,
    this.hintText = 'Search anime or manga...',
    this.autofocus = true,
    this.leading,
    this.focusNode,
    this.height = 52,
    this.margin = EdgeInsets.zero,
    this.isExpanded = true,
    this.expandedWidth,
    this.onExpand,
  });

  @override
  State<UnifiedSearchBar> createState() => _UnifiedSearchBarState();
}

class _UnifiedSearchBarState extends State<UnifiedSearchBar> {
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant UnifiedSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      if (oldWidget.focusNode == null && _internalFocusNode != null) {
        _internalFocusNode!.removeListener(_handleFocusChange);
        _internalFocusNode!.dispose();
        _internalFocusNode = null;
      }
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final textColor = colorScheme.onSurface;
        final iconColor = colorScheme.onSurfaceVariant;
        final isFocused = _effectiveFocusNode.hasFocus;

        final double horizontalMargin = widget.margin.horizontal;
        final double maxWidth = constraints.hasBoundedWidth
            ? (constraints.maxWidth - horizontalMargin).clamp(0.0, double.infinity)
            : MediaQuery.of(context).size.width * 0.75;

        final double targetWidth = widget.isExpanded
            ? (widget.expandedWidth ?? maxWidth)
            : widget.height;
        final double radiusValue = GlobalUI.uiRoundness.clamp(12.0, 28.0);
        final borderRadius = BorderRadius.circular(radiusValue);

        return Padding(
          padding: widget.margin,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: widget.height,
            width: targetWidth,
            decoration: BoxDecoration(
              color: isFocused
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surfaceContainerHigh,
              borderRadius: borderRadius,
              border: Border.all(
                color: isFocused
                    ? colorScheme.primary.withValues(alpha: 0.75)
                    : colorScheme.outlineVariant.withValues(alpha: 0.25),
                width: isFocused ? 1.5 : 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: widget.isExpanded
                ? _buildExpandedContent(
                    theme,
                    textColor,
                    iconColor,
                    isFocused,
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onExpand,
                      borderRadius: borderRadius,
                      child: Center(
                        child: Icon(
                          Icons.search_rounded,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedContent(
    ThemeData theme,
    Color textColor,
    Color iconColor,
    bool isFocused,
  ) {
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        const SizedBox(width: 6),
        if (widget.leading != null)
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 4),
            child: IconTheme(
              data: IconThemeData(
                color: isFocused ? colorScheme.primary : iconColor,
                size: 20,
              ),
              child: widget.leading!,
            ),
          )
        else
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: iconColor,
            ),
            tooltip: 'Back',
            onPressed: widget.onBackPressed,
          ),
        Expanded(
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent || event is KeyRepeatEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  _effectiveFocusNode.focusInDirection(
                    TraversalDirection.down,
                  );
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  _effectiveFocusNode.focusInDirection(TraversalDirection.up);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: widget.controller,
              focusNode: _effectiveFocusNode,
              autofocus: widget.autofocus,
              textAlignVertical: TextAlignVertical.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: textColor,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                hoverColor: Colors.transparent,
                hintText: widget.hintText,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: iconColor.withValues(alpha: 0.75),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSubmitted,
              onChanged: widget.onChanged,
            ),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            final hasText = value.text.isNotEmpty;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasText)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded, size: 19, color: iconColor),
                    tooltip: 'Clear search',
                    onPressed: widget.onClearPressed,
                  ),
                if (widget.onFilterPressed != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      style: widget.hasFilters
                          ? IconButton.styleFrom(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                            )
                          : null,
                      icon: Badge(
                        isLabelVisible: widget.hasFilters,
                        backgroundColor: colorScheme.primary,
                        smallSize: 7,
                        child: Icon(
                          Icons.tune_rounded,
                          size: 19,
                          color: widget.hasFilters
                              ? colorScheme.onPrimaryContainer
                              : iconColor,
                        ),
                      ),
                      tooltip: 'Filters',
                      onPressed: widget.onFilterPressed,
                    ),
                  ),
                if (widget.onFilterPressed == null) const SizedBox(width: 6),
              ],
            );
          },
        ),
      ],
    );
  }
}
