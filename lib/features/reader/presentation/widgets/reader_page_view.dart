import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';

import 'reader_image.dart';

/// Simple PageView for LTR / RTL reading modes. Pinch-to-zoom only.
class ReaderPageView extends StatefulWidget {
  final List<ChapterPage> pages;
  final PageController controller;
  final ReaderDirection direction;
  final ReaderScaleType scaleType;
  final Color textColor;
  final void Function(int) onPageChanged;

  const ReaderPageView({
    super.key,
    required this.pages,
    required this.controller,
    required this.direction,
    required this.scaleType,
    required this.textColor,
    required this.onPageChanged,
  });

  @override
  State<ReaderPageView> createState() => _ReaderPageViewState();
}

class _ReaderPageViewState extends State<ReaderPageView> {
  final TransformationController _zoomController = TransformationController();
  bool _isZoomed = false;
  int _pointerCount = 0;
  bool _isCtrlPressed = false;

  @override
  void initState() {
    super.initState();
    _zoomController.addListener(_onZoomChanged);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _zoomController.removeListener(_onZoomChanged);
    _zoomController.dispose();
    super.dispose();
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
        child: PageView.builder(
          physics: const BouncingScrollPhysics(),
          controller: widget.controller,
          reverse: widget.direction == ReaderDirection.rtl,
          allowImplicitScrolling: true,
          itemCount: widget.pages.length,
          onPageChanged: widget.onPageChanged,
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
    );
  }
}
