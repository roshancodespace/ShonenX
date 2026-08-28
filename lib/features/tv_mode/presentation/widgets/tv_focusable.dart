import 'package:flutter/material.dart';

class TvFocusable extends StatefulWidget {
  final Widget? child;
  final Widget Function(BuildContext context, bool isFocused, bool isHovered)?
  builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final bool autofocus;
  final bool canRequestFocus;
  final FocusNode? focusNode;
  final double scaleFactor;
  final bool autoScroll;
  final double scrollAlignment;

  const TvFocusable({
    super.key,
    this.child,
    this.builder,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.onHoverChange,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.focusNode,
    this.scaleFactor = 1.04,
    this.autoScroll = true,
    this.scrollAlignment = 0.5,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  FocusNode? _internalNode;
  FocusNode get _node => widget.focusNode ?? (_internalNode ??= FocusNode());

  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void dispose() {
    _internalNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged(bool hasFocus) {
    if (mounted) setState(() => _isFocused = hasFocus);
    widget.onFocusChange?.call(hasFocus);
    if (hasFocus && widget.autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.ensureVisible(
          context,
          alignment: widget.scrollAlignment,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  void _onHoverChanged(bool isHovered) {
    if (mounted) {
      setState(() {
        _isFocused = false;
        _isHovered = isHovered;
      });
    }
    widget.onHoverChange?.call(isHovered);
  }

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;

    return FocusableActionDetector(
      focusNode: _node,
      autofocus: widget.autofocus,
      enabled: widget.canRequestFocus,
      onFocusChange: _onFocusChanged,
      onShowHoverHighlight: _onHoverChanged,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: () {
          _node.requestFocus();
          widget.onTap?.call();
        },
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: active ? widget.scaleFactor : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: widget.builder != null
              ? widget.builder!(context, _isFocused, _isHovered)
              : widget.child!,
        ),
      ),
    );
  }
}
