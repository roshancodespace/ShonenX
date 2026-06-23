import 'package:flutter/material.dart';

typedef InteractionStateBuilder =
    Widget Function(BuildContext context, bool isFocused, bool isHovered);

class FocusHoverDetector extends StatefulWidget {
  final Widget Function(BuildContext context, bool isFocused, bool isHovered)
  builder;

  final VoidCallback? onTap;

  final Map<Type, Action<Intent>>? actions;

  final MouseCursor cursor;

  const FocusHoverDetector({
    super.key,
    required this.builder,
    this.onTap,
    this.actions,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<FocusHoverDetector> createState() => _FocusHoverDetectorState();
}

class _FocusHoverDetectorState extends State<FocusHoverDetector> {
  bool _isFocused = false;
  bool _isHovered = false;

  void _setFocused(bool value) {
    setState(() {
      _isFocused = value;

      if (value) {
        _isHovered = false;
      }
    });
  }

  void _setHovered(bool value) {
    setState(() {
      _isHovered = value;

      if (value) {
        _isFocused = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: _setFocused,
      onShowHoverHighlight: _setHovered,
      mouseCursor: widget.cursor,
      actions: widget.actions,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(context, _isFocused, _isHovered),
      ),
    );
  }
}
