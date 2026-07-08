import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/features/reader/providers/reader_provider.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';

import 'reader_image.dart';

class ReaderContent extends ConsumerWidget {
  final AsyncValue<ReaderState> stateAsync;
  final ReaderPrefState prefs;
  final Color textColor;
  final int initialPage;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final PageController pageController;
  final void Function(int) onTotalPagesUpdated;
  final void Function(int) onPageChanged;
  final VoidCallback onRetry;

  const ReaderContent({
    super.key,
    required this.stateAsync,
    required this.prefs,
    required this.textColor,
    required this.initialPage,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.pageController,
    required this.onTotalPagesUpdated,
    required this.onPageChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return stateAsync.when(
      data: (state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return _buildErrorState(state.error!);
        }
        if (state.pages.isEmpty) {
          return Center(
            child: Text('No pages found.', style: TextStyle(color: textColor)),
          );
        }

        onTotalPagesUpdated(state.pages.length);

        final isWebtoon = prefs.direction == ReaderDirection.webtoon;
        final Widget content = isWebtoon
            ? _ZoomableWebtoonList(
                pages: state.pages,
                initialPage: initialPage,
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
                scaleType: prefs.scaleType,
                textColor: textColor,
              )
            : _buildPageView(state.pages);

        if (isWebtoon &&
            (ResponsiveData.from(context).isDesktop ||
                ResponsiveData.from(context).isTablet)) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: content,
            ),
          );
        }

        return content;
      },
      error: (err, _) => Center(
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load pages:\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildPageView(List<ChapterPage> pages) {
    return PageView.builder(
      controller: pageController,
      reverse: prefs.direction == ReaderDirection.rtl,
      itemCount: pages.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        final page = pages[index];
        return _ZoomablePage(
          key: ValueKey(page.url),
          page: page,
          index: index,
          pageController: pageController,
          scaleType: prefs.scaleType,
          textColor: textColor,
        );
      },
    );
  }
}

class _ZoomableWebtoonList extends StatefulWidget {
  final List<ChapterPage> pages;
  final int initialPage;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final ReaderScaleType scaleType;
  final Color textColor;

  const _ZoomableWebtoonList({
    required this.pages,
    required this.initialPage,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.scaleType,
    required this.textColor,
  });

  @override
  State<_ZoomableWebtoonList> createState() => _ZoomableWebtoonListState();
}

class _ZoomableWebtoonListState extends State<_ZoomableWebtoonList> {
  final ScrollOffsetController _scrollOffsetController =
      ScrollOffsetController();
  final Map<int, Offset> _activePointers = {};

  double _scale = 1.0;
  double _baseScale = 1.0;
  double _baseDistance = 1.0;
  double _horizontalOffset = 0.0;
  Offset? _prevFocalPoint;
  Offset? _lastPointerPosition;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final key = event.logicalKey;
      final isControl = HardwareKeyboard.instance.logicalKeysPressed.any(
        (k) =>
            k == LogicalKeyboardKey.controlLeft ||
            k == LogicalKeyboardKey.controlRight ||
            k == LogicalKeyboardKey.metaLeft ||
            k == LogicalKeyboardKey.metaRight,
      );

      final focalPoint =
          _lastPointerPosition ??
          Offset(
            MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 2,
          );

      if (key == LogicalKeyboardKey.equal ||
          key == LogicalKeyboardKey.add ||
          key == LogicalKeyboardKey.numpadAdd ||
          (event.character == '+') ||
          (isControl &&
              (key == LogicalKeyboardKey.equal ||
                  key == LogicalKeyboardKey.add))) {
        _applyZoom(_scale * 1.25, focalPoint);
        return true;
      } else if (key == LogicalKeyboardKey.minus ||
          key == LogicalKeyboardKey.numpadSubtract ||
          (event.character == '-') ||
          (isControl && key == LogicalKeyboardKey.minus)) {
        _applyZoom(_scale * 0.8, focalPoint);
        return true;
      } else if (key == LogicalKeyboardKey.digit0 ||
          key == LogicalKeyboardKey.numpad0 ||
          (isControl && key == LogicalKeyboardKey.digit0)) {
        _applyZoom(1.0, focalPoint);
        return true;
      }
    }
    return false;
  }

  void _applyZoom(double targetScale, Offset focalPoint) {
    final newScale = targetScale.clamp(1.0, 4.0);
    if (newScale == _scale) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final zoomFactor = newScale / _scale;

    final focalX = focalPoint.dx - (screenWidth / 2);
    final maxHorizontalOffset = (screenWidth * (newScale - 1.0)) / 2;
    var nextHorizontalOffset = (_horizontalOffset - focalX * (zoomFactor - 1.0))
        .clamp(-maxHorizontalOffset, maxHorizontalOffset);
    if (newScale == 1.0) nextHorizontalOffset = 0.0;

    final focalY = focalPoint.dy - (screenHeight / 2);
    final deltaY = focalY * (zoomFactor - 1.0);
    if (deltaY.abs() > 0.1 && widget.itemScrollController.isAttached) {
      _scrollOffsetController.animateScroll(
        offset: deltaY,
        duration: const Duration(milliseconds: 1),
      );
    }

    setState(() {
      _scale = newScale;
      _horizontalOffset = nextHorizontalOffset;
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    _lastPointerPosition = event.localPosition;
    _activePointers[event.pointer] = event.localPosition;
    if (_activePointers.length == 2) {
      final pointers = _activePointers.values.toList();
      _baseDistance = (pointers[0] - pointers[1]).distance;
      if (_baseDistance < 1.0) _baseDistance = 1.0;
      _baseScale = _scale;
      _prevFocalPoint = (pointers[0] + pointers[1]) / 2;
    } else if (_activePointers.length == 1) {
      _prevFocalPoint = event.localPosition;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _lastPointerPosition = event.localPosition;
    if (!_activePointers.containsKey(event.pointer)) return;
    _activePointers[event.pointer] = event.localPosition;

    if (_activePointers.length == 2) {
      final pointers = _activePointers.values.toList();
      final currentDistance = (pointers[0] - pointers[1]).distance;
      final currentFocalPoint = (pointers[0] + pointers[1]) / 2;

      final newScale = (_baseScale * (currentDistance / _baseDistance)).clamp(
        1.0,
        4.0,
      );

      if (_prevFocalPoint != null) {
        final deltaY = currentFocalPoint.dy - _prevFocalPoint!.dy;
        final deltaX = currentFocalPoint.dx - _prevFocalPoint!.dx;

        if (deltaY.abs() > 0.1 && widget.itemScrollController.isAttached) {
          _scrollOffsetController.animateScroll(
            offset: -deltaY,
            duration: const Duration(milliseconds: 1),
          );
        }

        if (newScale > 1.0 && deltaX.abs() > 0.1) {
          final maxHorizontalOffset =
              (MediaQuery.of(context).size.width * (newScale - 1.0)) / 2;
          _horizontalOffset = (_horizontalOffset + deltaX).clamp(
            -maxHorizontalOffset,
            maxHorizontalOffset,
          );
        }
      }

      _prevFocalPoint = currentFocalPoint;
      if (newScale != _scale) {
        setState(() {
          _scale = newScale;
          if (_scale == 1.0) _horizontalOffset = 0.0;
        });
      }
    } else if (_activePointers.length == 1 && _scale > 1.0) {
      final currentPoint = event.localPosition;
      if (_prevFocalPoint != null) {
        final deltaX = currentPoint.dx - _prevFocalPoint!.dx;
        if (deltaX.abs() > 0.5) {
          final maxHorizontalOffset =
              (MediaQuery.of(context).size.width * (_scale - 1.0)) / 2;
          setState(() {
            _horizontalOffset = (_horizontalOffset + deltaX).clamp(
              -maxHorizontalOffset,
              maxHorizontalOffset,
            );
          });
        }
      }
      _prevFocalPoint = currentPoint;
    }
  }

  void _onPointerUp(PointerEvent event) {
    _lastPointerPosition = event.localPosition;
    _activePointers.remove(event.pointer);
    if (_activePointers.length == 1) {
      _prevFocalPoint = _activePointers.values.first;
    } else if (_activePointers.isEmpty) {
      _prevFocalPoint = null;
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    _lastPointerPosition = details.localPosition;
    if (_scale > 1.01) {
      _applyZoom(1.0, details.localPosition);
    } else {
      _applyZoom(2.0, details.localPosition);
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    _lastPointerPosition = event.localPosition;
    if (event is PointerScrollEvent) {
      final isControl = HardwareKeyboard.instance.logicalKeysPressed.any(
        (k) =>
            k == LogicalKeyboardKey.controlLeft ||
            k == LogicalKeyboardKey.controlRight ||
            k == LogicalKeyboardKey.metaLeft ||
            k == LogicalKeyboardKey.metaRight,
      );
      if (isControl) {
        final zoomFactor = (event.scrollDelta.dy < 0) ? 1.15 : 0.85;
        _applyZoom(_scale * zoomFactor, event.localPosition);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _lastPointerPosition = event.localPosition,
      child: GestureDetector(
        onDoubleTapDown: _handleDoubleTap,
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerUp,
          onPointerSignal: _onPointerSignal,
          child: ScrollablePositionedList.builder(
            itemCount: widget.pages.length,
            initialScrollIndex: widget.initialPage.clamp(
              0,
              widget.pages.isEmpty ? 0 : widget.pages.length - 1,
            ),
            itemScrollController: widget.itemScrollController,
            itemPositionsListener: widget.itemPositionsListener,
            scrollOffsetController: _scrollOffsetController,
            itemBuilder: (context, index) {
              final page = widget.pages[index];
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translate(_horizontalOffset, 0.0)
                  ..scale(_scale, _scale),
                child: ReaderImage(
                  url: page.url,
                  headers: page.headers ?? const {},
                  index: index,
                  scaleType: widget.scaleType,
                  textColor: widget.textColor,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ZoomablePage extends StatefulWidget {
  final ChapterPage page;
  final int index;
  final PageController pageController;
  final ReaderScaleType scaleType;
  final Color textColor;

  const _ZoomablePage({
    super.key,
    required this.page,
    required this.index,
    required this.pageController,
    required this.scaleType,
    required this.textColor,
  });

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> {
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;
  Offset? _lastPointerPosition;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onScaleChanged);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  void _onScaleChanged() {
    final zoomed = _transformationController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed && mounted) {
      setState(() => _isZoomed = zoomed);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _transformationController.removeListener(_onScaleChanged);
    _transformationController.dispose();
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (widget.pageController.hasClients) {
      final currentPage =
          widget.pageController.page?.round() ??
          widget.pageController.initialPage;
      if (currentPage != widget.index) return false;
    }

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final key = event.logicalKey;
      final isControl = HardwareKeyboard.instance.logicalKeysPressed.any(
        (k) =>
            k == LogicalKeyboardKey.controlLeft ||
            k == LogicalKeyboardKey.controlRight ||
            k == LogicalKeyboardKey.metaLeft ||
            k == LogicalKeyboardKey.metaRight,
      );

      final currentScale = _transformationController.value.getMaxScaleOnAxis();
      final focalPoint =
          _lastPointerPosition ??
          Offset(
            MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 2,
          );

      if (key == LogicalKeyboardKey.equal ||
          key == LogicalKeyboardKey.add ||
          key == LogicalKeyboardKey.numpadAdd ||
          (event.character == '+') ||
          (isControl &&
              (key == LogicalKeyboardKey.equal ||
                  key == LogicalKeyboardKey.add))) {
        _zoomToPoint((currentScale * 1.25).clamp(1.0, 4.0), focalPoint);
        return true;
      } else if (key == LogicalKeyboardKey.minus ||
          key == LogicalKeyboardKey.numpadSubtract ||
          (event.character == '-') ||
          (isControl && key == LogicalKeyboardKey.minus)) {
        _zoomToPoint((currentScale * 0.8).clamp(1.0, 4.0), focalPoint);
        return true;
      } else if (key == LogicalKeyboardKey.digit0 ||
          key == LogicalKeyboardKey.numpad0 ||
          (isControl && key == LogicalKeyboardKey.digit0)) {
        _transformationController.value = Matrix4.identity();
        return true;
      }
    }
    return false;
  }

  void _zoomToPoint(double targetScale, Offset focalPoint) {
    if (targetScale <= 1.01) {
      _transformationController.value = Matrix4.identity();
    } else {
      final scenePoint = _transformationController.toScene(focalPoint);
      _transformationController.value = Matrix4.identity()
        ..translate(focalPoint.dx, focalPoint.dy)
        ..scale(targetScale)
        ..translate(-scenePoint.dx, -scenePoint.dy);
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    _lastPointerPosition = details.localPosition;
    if (_isZoomed) {
      _transformationController.value = Matrix4.identity();
    } else {
      _zoomToPoint(2.0, details.localPosition);
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    _lastPointerPosition = event.localPosition;
    if (event is PointerScrollEvent) {
      final isControl = HardwareKeyboard.instance.logicalKeysPressed.any(
        (k) =>
            k == LogicalKeyboardKey.controlLeft ||
            k == LogicalKeyboardKey.controlRight ||
            k == LogicalKeyboardKey.metaLeft ||
            k == LogicalKeyboardKey.metaRight,
      );
      if (isControl) {
        final zoomFactor = (event.scrollDelta.dy < 0) ? 1.15 : 0.85;
        final currentScale = _transformationController.value
            .getMaxScaleOnAxis();
        final newScale = (currentScale * zoomFactor).clamp(1.0, 4.0);
        if (newScale != currentScale) {
          _zoomToPoint(newScale, event.localPosition);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _lastPointerPosition = event.localPosition,
      child: Center(
        child: GestureDetector(
          onDoubleTapDown: _handleDoubleTap,
          child: Listener(
            onPointerSignal: _onPointerSignal,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              panEnabled: _isZoomed,
              scaleEnabled: true,
              child: ReaderImage(
                url: widget.page.url,
                headers: widget.page.headers ?? const {},
                index: widget.index,
                scaleType: widget.scaleType,
                textColor: widget.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
