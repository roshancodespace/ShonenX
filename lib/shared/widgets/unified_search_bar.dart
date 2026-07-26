import 'dart:ui';
import 'package:flutter/material.dart';
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
    this.height = 48,
    this.margin = const EdgeInsetsDirectional.all(4),
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
            ? constraints.maxWidth - horizontalMargin
            : MediaQuery.of(context).size.width * 0.75;

        final double targetWidth = widget.isExpanded
            ? (widget.expandedWidth ?? maxWidth)
            : widget.height;

        return ClipRRect(
          borderRadius: BorderRadius.circular(GlobalUI.uiRoundness * 1.5),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              height: widget.height,
              width: targetWidth,
              padding: widget.isExpanded
                  ? const EdgeInsets.symmetric(horizontal: 4)
                  : EdgeInsets.zero,
              margin: widget.margin,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(GlobalUI.uiRoundness * 1.3),
                border: Border.all(
                  color: isFocused
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.5),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: widget.isExpanded
                  ? _buildExpandedContent(
                      theme,
                      textColor,
                      iconColor,
                      targetWidth,
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.search_rounded, color: iconColor),
                      onPressed: widget.onExpand,
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
    double targetWidth,
  ) {
    Widget content = Row(
      children: [
        const SizedBox(width: 4),
        widget.leading != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IconTheme(
                  data: IconThemeData(color: iconColor, size: 20),
                  child: widget.leading!,
                ),
              )
            : IconButton(
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: iconColor,
                ),
                tooltip: 'Back',
                onPressed: widget.onBackPressed,
              ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: widget.controller,
              focusNode: _effectiveFocusNode,
              autofocus: widget.autofocus,
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: true,
                fillColor: Colors.transparent,
                hoverColor: Colors.transparent,
                hintText: widget.hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
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
                    icon: const Icon(
                      Icons.clear_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                    tooltip: 'Clear search',
                    onPressed: widget.onClearPressed,
                  ),
                if (widget.hasFilters && widget.onFilterPressed != null)
                  IconButton(
                    icon: Icon(Icons.tune_rounded, size: 18, color: iconColor),
                    tooltip: 'Filters',
                    onPressed: widget.onFilterPressed,
                  ),
              ],
            );
          },
        ),
      ],
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        width: targetWidth - (widget.isExpanded ? 8 : 0),
        child: content,
      ),
    );
  }
}
