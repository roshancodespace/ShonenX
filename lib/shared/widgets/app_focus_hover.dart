import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef InteractionStateBuilder =
    Widget Function(BuildContext context, bool isFocused, bool isHovered);

class AppFocusHover extends StatefulWidget {
  final Widget? child;
  final InteractionStateBuilder? builder;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final GestureLongPressStartCallback? onLongPressStart;
  final VoidCallback? onSecondaryTap;
  final GestureTapDownCallback? onSecondaryTapDown;
  final ValueChanged<bool>? onFocusChange;
  final ValueChanged<bool>? onHoverChange;
  final bool autofocus;
  final bool canRequestFocus;
  final bool requestFocusOnTap;
  final FocusNode? focusNode;
  final double scaleFactor;
  final Duration duration;
  final Curve curve;
  final bool autoScroll;
  final double scrollAlignment;
  final MouseCursor? cursor;
  final HitTestBehavior behavior;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;

  const AppFocusHover({
    super.key,
    this.child,
    this.builder,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onLongPressStart,
    this.onSecondaryTap,
    this.onSecondaryTapDown,
    this.onFocusChange,
    this.onHoverChange,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.requestFocusOnTap = false,
    this.focusNode,
    this.scaleFactor = 1.0,
    this.duration = const Duration(milliseconds: 160),
    this.curve = Curves.easeOutCubic,
    this.autoScroll = true,
    this.scrollAlignment = 0.5,
    this.cursor,
    this.behavior = HitTestBehavior.opaque,
    this.shortcuts,
    this.actions,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  @override
  State<AppFocusHover> createState() => _AppFocusHoverState();
}

class _AppFocusHoverState extends State<AppFocusHover> {
  FocusNode? _internalNode;
  FocusNode get _node => widget.focusNode ?? (_internalNode ??= FocusNode());

  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void didUpdateWidget(AppFocusHover oldWidget) {
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

  void _onShowFocusHighlight(bool showHighlight) {
    if (!mounted) return;

    if (showHighlight) {
      if (_isHovered) {
        _isHovered = false;
        widget.onHoverChange?.call(false);
      }
      if (!_isFocused) {
        setState(() => _isFocused = true);
        widget.onFocusChange?.call(true);
      }
      if (widget.autoScroll) {
        _safeEnsureVisible();
      }
    } else {
      if (_isFocused) {
        setState(() => _isFocused = false);
        widget.onFocusChange?.call(false);
      }
    }
  }

  void _onHoverChanged(bool isHovered) {
    if (!mounted) return;

    if (isHovered) {
      if (_isFocused) {
        if (_node.hasFocus) {
          _node.unfocus();
        }
        _isFocused = false;
        widget.onFocusChange?.call(false);
      }
      if (!_isHovered) {
        _isHovered = true;
        widget.onHoverChange?.call(true);
      }
      setState(() {});
    } else {
      if (_isHovered) {
        setState(() => _isHovered = false);
        widget.onHoverChange?.call(false);
      }
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
            duration: widget.duration,
            curve: widget.curve,
            child: childWidget,
          )
        : childWidget;

    final effectiveCursor =
        widget.cursor ??
        (widget.onTap != null || widget.onLongPress != null
            ? SystemMouseCursors.click
            : MouseCursor.defer);

    return FocusableActionDetector(
      focusNode: _node,
      autofocus: widget.autofocus,
      enabled: widget.canRequestFocus,
      onShowFocusHighlight: _onShowFocusHighlight,
      onShowHoverHighlight: _onHoverChanged,
      onFocusChange: (hasFocus) {
        if (!hasFocus && _isFocused) {
          setState(() => _isFocused = false);
        }
        widget.onFocusChange?.call(hasFocus);
      },
      mouseCursor: effectiveCursor,
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.select):
            const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.numpadEnter):
            const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.gameButtonA):
            const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        ...?widget.shortcuts,
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
        ...?widget.actions,
      },
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: () {
          if (widget.requestFocusOnTap &&
              !_node.hasFocus &&
              widget.canRequestFocus) {
            _node.requestFocus();
          } else if (_node.hasFocus) {
            _node.unfocus();
          }
          _handleActivate();
        },
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.onLongPress,
        onLongPressStart: widget.onLongPressStart,
        onSecondaryTap: widget.onSecondaryTap,
        onSecondaryTapDown: widget.onSecondaryTapDown,
        child: scaledChild,
      ),
    );
  }
}
