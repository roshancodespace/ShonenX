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
  final void Function(int) onPageChanged;

  const ReaderWebtoonView({
    super.key,
    required this.pages,
    required this.initialPage,
    required this.scaleType,
    required this.textColor,
    required this.onPageChanged,
  });

  @override
  State<ReaderWebtoonView> createState() => ReaderWebtoonViewState();
}

class ReaderWebtoonViewState extends State<ReaderWebtoonView> {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  final TransformationController _zoomController = TransformationController();
  bool _isZoomed = false;
  int _pointerCount = 0;
  bool _isCtrlPressed = false;
  int _lastReportedPage = -1;
  late bool _isInitialScrollDone;

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
    if (oldWidget.initialPage != widget.initialPage) {
      _lastReportedPage = widget.initialPage;
      _isInitialScrollDone = widget.initialPage == 0;
    }
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_onScroll);
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _zoomController.removeListener(_onZoomChanged);
    _zoomController.dispose();
    super.dispose();
  }

  /// Jump to a page index.
  void jumpToPage(int page) {
    if (page < 0 || page >= widget.pages.length) return;
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

    final visible = positions.where(
      (p) => p.itemLeadingEdge <= 0.5 && p.itemTrailingEdge > 0.0,
    );
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

  @override
  Widget build(BuildContext context) {
    final isConstrained =
        ResponsiveData.from(context).isDesktop ||
        ResponsiveData.from(context).isTablet;
    final scaleEnabled = _pointerCount >= 2 || _isCtrlPressed;

    return Listener(
      onPointerDown: (_) {
        _pointerCount++;
        if (_pointerCount == 2 && mounted) setState(() {});
      },
      onPointerUp: (_) {
        _pointerCount = (_pointerCount - 1).clamp(0, 10);
        if (_pointerCount < 2 && mounted) setState(() {});
      },
      onPointerCancel: (_) {
        _pointerCount = (_pointerCount - 1).clamp(0, 10);
        if (_pointerCount < 2 && mounted) setState(() {});
      },
      child: InteractiveViewer(
        transformationController: _zoomController,
        minScale: 1.0,
        maxScale: 4.0,
        panEnabled: _isZoomed,
        scaleEnabled: scaleEnabled,
        child: ScrollablePositionedList.builder(
          physics: const BouncingScrollPhysics(),
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
