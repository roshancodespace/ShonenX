import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerGestureHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Function(bool isForward) onDoubleTap;
  final VoidCallback onLongPressStart;
  final Function(double diff) onLongPressUpdate;
  final VoidCallback onLongPressEnd;
  final VoidCallback onSpacePressed;
  final VoidCallback onLeftArrowPressed;
  final VoidCallback onRightArrowPressed;
  final VoidCallback onMKeyPressed;

  const PlayerGestureHandler({
    super.key,
    required this.child,
    required this.onTap,
    required this.onDoubleTap,
    required this.onLongPressStart,
    required this.onLongPressUpdate,
    required this.onLongPressEnd,
    required this.onSpacePressed,
    required this.onLeftArrowPressed,
    required this.onRightArrowPressed,
    required this.onMKeyPressed,
  });

  @override
  State<PlayerGestureHandler> createState() => _PlayerGestureHandlerState();
}

class _PlayerGestureHandlerState extends State<PlayerGestureHandler> {
  late FocusNode _focusNode;
  double _dragStartY = 0.0;
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final w = MediaQuery.of(context).size.width;
    final forward = details.globalPosition.dx > w / 2;
    widget.onDoubleTap(forward);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (details.globalPosition.dx > MediaQuery.of(context).size.width / 2) {
      _isLongPressing = true;
      _dragStartY = details.globalPosition.dy;
      widget.onLongPressStart();
    }
  }

  void _onLongPressUpdate(LongPressMoveUpdateDetails details) {
    if (_isLongPressing) {
      final diff = _dragStartY - details.globalPosition.dy;
      widget.onLongPressUpdate(diff);
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_isLongPressing) {
      _isLongPressing = false;
      widget.onLongPressEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): widget.onSpacePressed,
        const SingleActivator(LogicalKeyboardKey.keyK): widget.onSpacePressed,
        const SingleActivator(LogicalKeyboardKey.keyJ):
            widget.onLeftArrowPressed,
        const SingleActivator(LogicalKeyboardKey.keyL):
            widget.onRightArrowPressed,
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            widget.onLeftArrowPressed,
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            widget.onRightArrowPressed,
        const SingleActivator(LogicalKeyboardKey.keyM): widget.onMKeyPressed,
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: GestureDetector(
          onTap: widget.onTap,
          onDoubleTapDown: _onDoubleTapDown,
          onLongPressStart: _onLongPressStart,
          onLongPressMoveUpdate: _onLongPressUpdate,
          onLongPressEnd: _onLongPressEnd,
          onLongPressUp: () {
            if (_isLongPressing) _onLongPressEnd(const LongPressEndDetails());
          },
          behavior: HitTestBehavior.translucent,
          child: widget.child,
        ),
      ),
    );
  }
}
