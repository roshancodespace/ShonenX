import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.scaleFactor = 1.0,
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
  void didUpdateWidget(TvFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null && _internalNode != null) {
        _internalNode?.dispose();
        _internalNode = null;
      }
    }
  }

  @override
  void dispose() {
    _internalNode?.dispose();
    _internalNode = null;
    super.dispose();
  }

  void _onFocusChanged(bool hasFocus) {
    if (!mounted) return;

    if (_isFocused != hasFocus) {
      setState(() => _isFocused = hasFocus);
      widget.onFocusChange?.call(hasFocus);
    }

    if (hasFocus && widget.autoScroll) {
      _safeEnsureVisible();
    }
  }

  void _onHoverChanged(bool isHovered) {
    if (!mounted) return;

    if (_isHovered != isHovered) {
      setState(() => _isHovered = isHovered);
      widget.onHoverChange?.call(isHovered);
    }
  }

  void _safeEnsureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final scrollable = Scrollable.maybeOf(context);
        if (scrollable != null && context.mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: widget.scrollAlignment,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          );
        }
      } catch (_) {}
    });
  }

  void _handleActivate() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;

    final childWidget = widget.builder != null
        ? widget.builder!(context, _isFocused, _isHovered)
        : widget.child!;

    final scaledChild = (widget.scaleFactor != 1.0)
        ? AnimatedScale(
            scale: active ? widget.scaleFactor : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: childWidget,
          )
        : childWidget;

    return FocusableActionDetector(
      focusNode: _node,
      autofocus: widget.autofocus,
      enabled: widget.canRequestFocus,
      onFocusChange: _onFocusChanged,
      onShowHoverHighlight: _onHoverChanged,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _handleActivate();
            return null;
          },
        ),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (_) {
            _handleActivate();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: () {
          if (!_node.hasFocus && widget.canRequestFocus) {
            _node.requestFocus();
          }
          _handleActivate();
        },
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.opaque,
        child: scaledChild,
      ),
    );
  }
}
