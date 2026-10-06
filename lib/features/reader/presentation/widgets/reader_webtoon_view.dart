import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';

import 'reader_image.dart';

/// Continuous scrolling view for webtoon-style reading.
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

  double _scale = 1.0;
  double _panX = 0.0;
  bool _isCtrlPressed = false;
  int _lastReportedPage = -1;
  late bool _isInitialScrollDone;

  // Multi-touch tracking
  final Map<int, Offset> _pointerPositions = {};
  double _baseScale = 1.0;
  double _baseEffectivePanX = 0.0;
  double _initialPinchDistance = 0.0;
  Offset _initialPinchCenter = Offset.zero;
  int? _pinchAnchorIndex;
  double _pinchItemLeadingEdge0 = 0.0;
  double _pinchItemHeightFraction0 = 1.0;
  double _pinchFractionInItem = 0.0;

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  Animation<double>? _scaleAnimation;
  Animation<double>? _panAnimation;
  Animation<double>? _alignmentAnimation;
  int? _targetIndex;

  @override
  void initState() {
    super.initState();
    _lastReportedPage = widget.initialPage;
    _isInitialScrollDone = widget.initialPage == 0;
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    _positionsListener.itemPositions.addListener(_onScroll);
    _animationController.addListener(_onAnimationUpdate);
    _animationController.addStatusListener(_onAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant ReaderWebtoonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pages != widget.pages) {
      _scale = 1.0;
      _panX = 0.0;
      _pointerPositions.clear();
    }
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onScroll);
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _animationController.removeListener(_onAnimationUpdate);
    _animationController.removeStatusListener(_onAnimationStatus);
    _animationController.dispose();
    _pointerPositions.clear();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _targetIndex = null;
      _alignmentAnimation = null;
    }
  }

  void _onAnimationUpdate() {
    if (!mounted) return;
    if (_scaleAnimation != null) {
      _scale = _scaleAnimation!.value;
    }
    if (_panAnimation != null) {
      _panX = _panAnimation!.value;
    }
    if (_targetIndex != null &&
        _alignmentAnimation != null &&
        _scrollController.isAttached) {
      _scrollController.jumpTo(
        index: _targetIndex!,
        alignment: _alignmentAnimation!.value,
      );
    }
    setState(() {});
  }

  /// Double tap to zoom in/out
  void handleDoubleTap(Offset position) {
    if (!widget.doubleTapToZoom) return;

    if (_animationController.isAnimating) {
      _animationController.stop();
      _targetIndex = null;
      _alignmentAnimation = null;
    }

    final size = context.size ?? MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    final isConstrained =
        ResponsiveData.from(context).isDesktop ||
        ResponsiveData.from(context).isTablet;
    final baseWidth = isConstrained
        ? (screenWidth > 800 ? 800.0 : screenWidth)
        : screenWidth;

    final currentColumnWidth = baseWidth * _scale;
    final currentMaxPanX =
        (currentColumnWidth - screenWidth).clamp(0.0, double.infinity);
    final currentCenterOffset = (screenWidth - currentColumnWidth) / 2;
    final currentEffectivePanX = currentColumnWidth <= screenWidth
        ? currentCenterOffset
        : _panX.clamp(-currentMaxPanX, 0.0);

    if (_scale > 1.05) {
      // Zoom out to 1.0 anchored around tap position
      final positions = _positionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final tapFraction = (position.dy / screenHeight).clamp(0.0, 1.0);
        ItemPosition? tappedItem;
        for (final p in positions) {
          if (p.itemLeadingEdge <= tapFraction &&
              p.itemTrailingEdge >= tapFraction) {
            tappedItem = p;
            break;
          }
        }
        tappedItem ??= positions.reduce((a, b) {
          final distA = (a.itemLeadingEdge - tapFraction).abs();
          final distB = (b.itemLeadingEdge - tapFraction).abs();
          return distA < distB ? a : b;
        });

        final itemHeightFraction =
            tappedItem.itemTrailingEdge - tappedItem.itemLeadingEdge;
        final fractionInItem = itemHeightFraction > 0
            ? ((tapFraction - tappedItem.itemLeadingEdge) / itemHeightFraction)
                .clamp(0.0, 1.0)
            : 0.0;

        final newItemHeightFraction =
            itemHeightFraction * (1.0 / _scale);
        final targetLeadingEdge =
            tapFraction - (newItemHeightFraction * fractionInItem);

        _targetIndex = tappedItem.index;
        _alignmentAnimation = Tween<double>(
          begin: tappedItem.itemLeadingEdge,
          end: targetLeadingEdge,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ));
      } else {
        _targetIndex = null;
        _alignmentAnimation = null;
      }

      _scaleAnimation = Tween<double>(
        begin: _scale,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));

      _panAnimation = Tween<double>(
        begin: _panX,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));

      _animationController.forward(from: 0.0);
    } else {
      // Zoom in target
      const targetScale = 2.5;
      final targetColumnWidth = baseWidth * targetScale;
      final maxPanX =
          (targetColumnWidth - screenWidth).clamp(0.0, double.infinity);
      final rx = targetScale / _scale;
      final targetPanX =
          (position.dx - ((position.dx - currentEffectivePanX) * rx))
              .clamp(-maxPanX, 0.0);
      final positions = _positionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final tapFraction = (position.dy / screenHeight).clamp(0.0, 1.0);

        ItemPosition? tappedItem;
        for (final p in positions) {
          if (p.itemLeadingEdge <= tapFraction &&
              p.itemTrailingEdge >= tapFraction) {
            tappedItem = p;
            break;
          }
        }

        tappedItem ??= positions.reduce((a, b) {
          final distA = (a.itemLeadingEdge - tapFraction).abs();
          final distB = (b.itemLeadingEdge - tapFraction).abs();
          return distA < distB ? a : b;
        });

        final itemHeightFraction =
            tappedItem.itemTrailingEdge - tappedItem.itemLeadingEdge;
        final fractionInItem = itemHeightFraction > 0
            ? ((tapFraction - tappedItem.itemLeadingEdge) / itemHeightFraction)
                .clamp(0.0, 1.0)
            : 0.0;

        final newItemHeightFraction =
            itemHeightFraction * (targetScale / _scale);
        final targetLeadingEdge =
            tapFraction - (newItemHeightFraction * fractionInItem);

        _targetIndex = tappedItem.index;
        _alignmentAnimation = Tween<double>(
          begin: tappedItem.itemLeadingEdge,
          end: targetLeadingEdge,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ));
      } else {
        _targetIndex = null;
        _alignmentAnimation = null;
      }

      _scaleAnimation = Tween<double>(
        begin: _scale,
        end: targetScale,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));

      _panAnimation = Tween<double>(
        begin: _panX,
        end: targetPanX,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));

      _animationController.forward(from: 0.0);
    }
  }

  /// Jump to a page index.
  void jumpToPage(int page) {
    if (page < 0 || page >= widget.pages.length) return;
    if (_scale > 1.01) {
      _scale = 1.0;
      _panX = 0.0;
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

  void _onPointerDown(PointerDownEvent event) {
    if (_animationController.isAnimating) {
      _animationController.stop();
      _targetIndex = null;
      _alignmentAnimation = null;
    }
    _pointerPositions[event.pointer] = event.position;
    if (_pointerPositions.length == 2) {
      final p1 = _pointerPositions.values.first;
      final p2 = _pointerPositions.values.last;
      _initialPinchDistance = (p1 - p2).distance;
      _initialPinchCenter = (p1 + p2) / 2;
      _baseScale = _scale;

      final size = context.size ?? MediaQuery.of(context).size;
      final isConstrained =
          ResponsiveData.from(context).isDesktop ||
          ResponsiveData.from(context).isTablet;
      final baseWidth = isConstrained
          ? (size.width > 800 ? 800.0 : size.width)
          : size.width;
      final currentColumnWidth = baseWidth * _scale;
      final currentMaxPanX =
          (currentColumnWidth - size.width).clamp(0.0, double.infinity);
      final currentCenterOffset = (size.width - currentColumnWidth) / 2;
      _baseEffectivePanX = currentColumnWidth <= size.width
          ? currentCenterOffset
          : _panX.clamp(-currentMaxPanX, 0.0);
      final positions = _positionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final tapFraction0 =
            (_initialPinchCenter.dy / size.height).clamp(0.0, 1.0);
        ItemPosition? tappedItem;
        for (final p in positions) {
          if (p.itemLeadingEdge <= tapFraction0 &&
              p.itemTrailingEdge >= tapFraction0) {
            tappedItem = p;
            break;
          }
        }
        tappedItem ??= positions.reduce((a, b) {
          final distA = (a.itemLeadingEdge - tapFraction0).abs();
          final distB = (b.itemLeadingEdge - tapFraction0).abs();
          return distA < distB ? a : b;
        });

        _pinchAnchorIndex = tappedItem.index;
        _pinchItemLeadingEdge0 = tappedItem.itemLeadingEdge;
        final h = tappedItem.itemTrailingEdge - tappedItem.itemLeadingEdge;
        _pinchItemHeightFraction0 = h > 0 ? h : 1.0;
        _pinchFractionInItem =
            ((tapFraction0 - _pinchItemLeadingEdge0) / _pinchItemHeightFraction0)
                .clamp(0.0, 1.0);
      } else {
        _pinchAnchorIndex = null;
      }
    }
    if (mounted) setState(() {});
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointerPositions.containsKey(event.pointer)) return;
    _pointerPositions[event.pointer] = event.position;

    if (_pointerPositions.length == 2 && _initialPinchDistance > 10) {
      final p1 = _pointerPositions.values.first;
      final p2 = _pointerPositions.values.last;
      final currentDistance = (p1 - p2).distance;
      final currentCenter = (p1 + p2) / 2;

      final scaleFactor = currentDistance / _initialPinchDistance;
      final newScale = (_baseScale * scaleFactor).clamp(1.0, 4.0);

      final size = context.size ?? MediaQuery.of(context).size;
      final isConstrained =
          ResponsiveData.from(context).isDesktop ||
          ResponsiveData.from(context).isTablet;
      final baseWidth = isConstrained
          ? (size.width > 800 ? 800.0 : size.width)
          : size.width;
      final newColumnWidth = baseWidth * newScale;
      final maxPanX =
          (newColumnWidth - size.width).clamp(0.0, double.infinity);

      // Focal point zoom
      final rx = newScale / _baseScale;
      final targetLeft =
          currentCenter.dx - ((_initialPinchCenter.dx - _baseEffectivePanX) * rx);
      final newPanX = targetLeft.clamp(-maxPanX, 0.0);

      // Vertical focal point zoom
      if (_pinchAnchorIndex != null && _scrollController.isAttached) {
        final currentTapFraction =
            (currentCenter.dy / size.height).clamp(0.0, 1.0);
        final newItemHeightFraction = _pinchItemHeightFraction0 * rx;
        final newLeadingEdge = currentTapFraction -
            (newItemHeightFraction * _pinchFractionInItem);
        _scrollController.jumpTo(
          index: _pinchAnchorIndex!,
          alignment: newLeadingEdge,
        );
      }

      setState(() {
        _scale = newScale;
        _panX = newPanX;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerPositions.remove(event.pointer);
    if (_pointerPositions.isEmpty) {
      _pinchAnchorIndex = null;
      if (_scale < 1.05) {
        _animateResetZoom();
      }
    }
    if (mounted) setState(() {});
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerPositions.remove(event.pointer);
    if (_pointerPositions.isEmpty) {
      _pinchAnchorIndex = null;
      if (_scale < 1.05) {
        _animateResetZoom();
      }
    }
    if (mounted) setState(() {});
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _isCtrlPressed) {
      final size = context.size ?? MediaQuery.of(context).size;
      final zoomDelta = event.scrollDelta.dy > 0 ? -0.2 : 0.2;
      final newScale = (_scale + zoomDelta).clamp(1.0, 4.0);
      if (newScale != _scale) {
        final isConstrained =
            ResponsiveData.from(context).isDesktop ||
            ResponsiveData.from(context).isTablet;
        final baseWidth = isConstrained
            ? (size.width > 800 ? 800.0 : size.width)
            : size.width;
        final newColumnWidth = baseWidth * newScale;
        final maxPanX =
            (newColumnWidth - size.width).clamp(0.0, double.infinity);
        setState(() {
          _scale = newScale;
          _panX = _panX.clamp(-maxPanX, 0.0);
        });
      }
    }
  }

  void _animateResetZoom() {
    _targetIndex = null;
    _alignmentAnimation = null;

    _scaleAnimation = Tween<double>(
      begin: _scale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _panAnimation = Tween<double>(
      begin: _panX,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isConstrained = ResponsiveData.from(context).isDesktop ||
        ResponsiveData.from(context).isTablet;
    final baseWidth = isConstrained
        ? (size.width > 800 ? 800.0 : size.width)
        : size.width;
    final columnWidth = baseWidth * _scale;
    final maxPanX = (columnWidth - size.width).clamp(0.0, double.infinity);

    final centerOffset = (size.width - columnWidth) / 2;
    final effectivePanX = columnWidth <= size.width
        ? centerOffset
        : _panX.clamp(-maxPanX, 0.0);

    final hasMultiplePointers = _pointerPositions.length > 1;
    final canScroll = !hasMultiplePointers;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        onHorizontalDragUpdate: _scale > 1.01 && maxPanX > 0
            ? (details) {
                setState(() {
                  _panX = (_panX + details.delta.dx).clamp(-maxPanX, 0.0);
                });
              }
            : null,
        child: ClipRect(
          child: SizedBox.expand(
            child: OverflowBox(
              minWidth: columnWidth,
              maxWidth: columnWidth,
              minHeight: size.height,
              maxHeight: size.height,
              alignment: Alignment.topLeft,
              child: Transform.translate(
                offset: Offset(effectivePanX, 0),
                child: SizedBox(
                  width: columnWidth,
                  height: size.height,
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
                      return ReaderImage(
                        key: ValueKey(page.url),
                        url: page.url,
                        headers: page.headers ?? const {},
                        index: index,
                        scaleType: widget.scaleType,
                        textColor: widget.textColor,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
