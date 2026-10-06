import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';

import 'reader_image.dart';

/// Simple vertical scrolling view for webtoon-style reading.
class ReaderWebtoonView extends StatefulWidget {
  final List<ChapterPage> pages;
  final int initialPage;
  final ReaderScaleType scaleType;
  final Color textColor;
  final bool doubleTapToZoom;
  final void Function(int) onPageChanged;

  const ReaderWebtoonView({
    super.key,
    required this.pages,
    required this.initialPage,
    required this.scaleType,
    required this.textColor,
    this.doubleTapToZoom = true,
    required this.onPageChanged,
  });

  @override
  State<ReaderWebtoonView> createState() => ReaderWebtoonViewState();
}

class ReaderWebtoonViewState extends State<ReaderWebtoonView>
    with SingleTickerProviderStateMixin {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  final TransformationController _zoomController = TransformationController();
  final Set<int> _activePointers = {};
  bool _isZoomed = false;
  bool _isCtrlPressed = false;
  int _lastReportedPage = -1;
  late bool _isInitialScrollDone;
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  Animation<Matrix4>? _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _lastReportedPage = widget.initialPage;
    _isInitialScrollDone = widget.initialPage == 0;
    _zoomController.addListener(_onZoomChanged);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    _positionsListener.itemPositions.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ReaderWebtoonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pages != widget.pages) {
      _zoomController.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onScroll);
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _zoomAnimation?.removeListener(_onZoomAnimationUpdate);
    _zoomController.removeListener(_onZoomChanged);
    _zoomController.dispose();
    _animationController.dispose();
    _activePointers.clear();
    super.dispose();
  }

  /// Double tap to zoom in/out
  void handleDoubleTap(Offset position) {
    if (!widget.doubleTapToZoom) return;

    final currentScale = _zoomController.value.getMaxScaleOnAxis();
    final Matrix4 targetMatrix;

    if (currentScale > 1.01) {
      targetMatrix = Matrix4.identity();
    } else {
      final size = context.size ?? MediaQuery.of(context).size;
      const targetScale = 2.5;
      final tx = (size.width / 2 - position.dx * targetScale).clamp(
        -size.width * (targetScale - 1),
        0.0,
      );
      final ty = (size.height / 2 - position.dy * targetScale).clamp(
        -size.height * (targetScale - 1),
        0.0,
      );

      targetMatrix = Matrix4.identity()
        ..translate(tx, ty)
        ..scale(targetScale);
    }

    _zoomAnimation?.removeListener(_onZoomAnimationUpdate);
    _zoomAnimation = Matrix4Tween(
      begin: _zoomController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _zoomAnimation!.addListener(_onZoomAnimationUpdate);
    _animationController.forward(from: 0.0);
  }

  void _onZoomAnimationUpdate() {
    if (_zoomAnimation != null) {
      _zoomController.value = _zoomAnimation!.value;
    }
  }

  /// Jump to a page index.
  void jumpToPage(int page) {
    if (page < 0 || page >= widget.pages.length) return;
    if (_isZoomed) {
      _zoomController.value = Matrix4.identity();
    }
    _lastReportedPage = page; // Prevent scroll listener from overriding
    _isInitialScrollDone = true;
    if (_scrollController.isAttached) {
      _scrollController.jumpTo(index: page);
    }
  }

  void _onScroll() {
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    if (!_isInitialScrollDone) {
      final hasReachedInitial = positions.any(
        (p) => p.index == widget.initialPage,
      );
      if (hasReachedInitial) {
        _isInitialScrollDone = true;
      } else {
        return;
      }
    }

    Iterable<ItemPosition> visible = positions.where(
      (p) => p.itemLeadingEdge <= 0.5 && p.itemTrailingEdge > 0.0,
    );
    if (visible.isEmpty) {
      visible = positions.where(
        (p) => p.itemLeadingEdge < 1.0 && p.itemTrailingEdge > 0.0,
      );
    }
    if (visible.isEmpty) return;

    final currentIndex = visible.fold<int>(
      0,
      (max, p) => p.index > max ? p.index : max,
    );

    if (currentIndex != _lastReportedPage) {
      _lastReportedPage = currentIndex;
      widget.onPageChanged(currentIndex);
    }
  }

  bool _onKeyEvent(KeyEvent event) {
    final isCtrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (_isCtrlPressed != isCtrl && mounted) {
      setState(() => _isCtrlPressed = isCtrl);
    }
    return false;
  }

  void _onZoomChanged() {
    final zoomed = _zoomController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed && mounted) {
      setState(() => _isZoomed = zoomed);
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    final hadMultiple = _activePointers.length > 1;
    _activePointers.add(event.pointer);
    final hasMultiple = _activePointers.length > 1;
    if (hadMultiple != hasMultiple && mounted) {
      setState(() {});
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    final hadMultiple = _activePointers.length > 1;
    _activePointers.remove(event.pointer);
    final hasMultiple = _activePointers.length > 1;
    if (hadMultiple != hasMultiple && mounted) {
      setState(() {});
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    final hadMultiple = _activePointers.length > 1;
    _activePointers.remove(event.pointer);
    final hasMultiple = _activePointers.length > 1;
    if (hadMultiple != hasMultiple && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConstrained =
        ResponsiveData.from(context).isDesktop ||
        ResponsiveData.from(context).isTablet;
    final hasMultiplePointers = _activePointers.length > 1;
    final canScroll = !hasMultiplePointers && !_isZoomed && !_isCtrlPressed;
    final scaleEnabled = hasMultiplePointers || _isCtrlPressed;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: InteractiveViewer(
        transformationController: _zoomController,
        minScale: 1.0,
        maxScale: 4.0,
        panEnabled: _isZoomed,
        scaleEnabled: scaleEnabled,
        child: ScrollablePositionedList.builder(
          physics: canScroll
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemScrollController: _scrollController,
          itemPositionsListener: _positionsListener,
          initialScrollIndex: widget.initialPage,
          itemCount: widget.pages.length,
          itemBuilder: (context, index) {
            final page = widget.pages[index];

            Widget imageWidget = ReaderImage(
              key: ValueKey(page.url),
              url: page.url,
              headers: page.headers ?? const {},
              index: index,
              scaleType: widget.scaleType,
              textColor: widget.textColor,
            );

            if (isConstrained) {
              imageWidget = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: imageWidget,
                ),
              );
            }

            return imageWidget;
          },
        ),
      ),
    );
  }
}
