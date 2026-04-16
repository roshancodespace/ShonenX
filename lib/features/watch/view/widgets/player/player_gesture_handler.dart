import 'package:flutter/material.dart';

class PlayerGestureHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Function(bool isForward) onDoubleTap;
  final VoidCallback onLongPressStart;
  final Function(double diff) onLongPressUpdate;
  final VoidCallback onLongPressEnd;
  final VoidCallback? onEpisodesPressed;

  const PlayerGestureHandler({
    super.key,
    required this.child,
    required this.onTap,
    required this.onDoubleTap,
    required this.onLongPressStart,
    required this.onLongPressUpdate,
    required this.onLongPressEnd,
    required this.onEpisodesPressed,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final Function(DragStartDetails)? onVerticalDragStart;
  final Function(DragUpdateDetails)? onVerticalDragUpdate;
  final Function(DragEndDetails)? onVerticalDragEnd;

  @override
  State<PlayerGestureHandler> createState() => _PlayerGestureHandlerState();
}

class _PlayerGestureHandlerState extends State<PlayerGestureHandler> {
  double _dragStartY = 0.0;
  bool _isLongPressing = false;

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
    return GestureDetector(
      onTap: widget.onTap,
      onSecondaryTap: widget.onEpisodesPressed,
      onDoubleTapDown: _onDoubleTapDown,
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressUpdate,
      onLongPressEnd: _onLongPressEnd,
      onVerticalDragStart: widget.onVerticalDragStart,
      onVerticalDragUpdate: widget.onVerticalDragUpdate,
      onVerticalDragEnd: widget.onVerticalDragEnd,
      onLongPressUp: () {
        if (_isLongPressing) _onLongPressEnd(const LongPressEndDetails());
      },
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
