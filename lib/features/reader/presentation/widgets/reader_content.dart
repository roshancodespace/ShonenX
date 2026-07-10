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
  final ScrollOffsetController? scrollOffsetController;
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
    this.scrollOffsetController,
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
            ? _buildWebtoonView(context, state.pages)
            : _buildPageView(state.pages);

        return _ZoomableContent(child: content);
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

  Widget _buildWebtoonView(BuildContext context, List<ChapterPage> pages) {
    final isConstrained =
        ResponsiveData.from(context).isDesktop ||
        ResponsiveData.from(context).isTablet;

    return ScrollablePositionedList.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: pages.length,
      initialScrollIndex: initialPage.clamp(
        0,
        pages.isEmpty ? 0 : pages.length - 1,
      ),
      itemScrollController: itemScrollController,
      scrollOffsetController: scrollOffsetController,
      itemPositionsListener: itemPositionsListener,
      itemBuilder: (context, index) {
        final page = pages[index];
        Widget pageWidget = ReaderImage(
          url: page.url,
          headers: page.headers ?? const {},
          index: index,
          scaleType: prefs.scaleType,
          textColor: textColor,
        );

        if (isConstrained) {
          pageWidget = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: pageWidget,
            ),
          );
        }

        return KeyedSubtree(key: ValueKey(page.url), child: pageWidget);
      },
    );
  }

  Widget _buildPageView(List<ChapterPage> pages) {
    return PageView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: pageController,
      reverse: prefs.direction == ReaderDirection.rtl,
      itemCount: pages.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        final page = pages[index];
        return ReaderImage(
          key: ValueKey(page.url),
          url: page.url,
          headers: page.headers ?? const {},
          index: index,
          scaleType: prefs.scaleType,
          textColor: textColor,
        );
      },
    );
  }
}

class _ZoomableContent extends StatefulWidget {
  final Widget child;

  const _ZoomableContent({required this.child});

  @override
  State<_ZoomableContent> createState() => _ZoomableContentState();
}

class _ZoomableContentState extends State<_ZoomableContent> {
  final TransformationController _controller = TransformationController();
  bool _isZoomed = false;
  int _pointersCount = 0;
  bool _isCtrlPressed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScaleChanged);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
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

  void _onScaleChanged() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed && mounted) {
      setState(() => _isZoomed = zoomed);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _controller.removeListener(_onScaleChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_isZoomed) {
      _controller.value = Matrix4.identity();
    } else {
      final position = details.localPosition;
      _controller.value = Matrix4.identity()
        ..translateByDouble(-position.dx, -position.dy, 0.0, 1.0)
        ..scaleByDouble(2.0, 2.0, 1.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleEnabled = _pointersCount >= 2 || _isCtrlPressed;

    return Listener(
      onPointerDown: (event) {
        _pointersCount++;
        if (_pointersCount == 2 && mounted) {
          setState(() {});
        }
      },
      onPointerUp: (event) {
        _pointersCount = (_pointersCount - 1).clamp(0, 10);
        if (_pointersCount < 2 && mounted) {
          setState(() {});
        }
      },
      onPointerCancel: (event) {
        _pointersCount = (_pointersCount - 1).clamp(0, 10);
        if (_pointersCount < 2 && mounted) {
          setState(() {});
        }
      },
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final isCtrl =
              HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;
          if (_isCtrlPressed != isCtrl && mounted) {
            setState(() => _isCtrlPressed = isCtrl);
          }
        }
      },
      child: GestureDetector(
        onDoubleTapDown: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 1.0,
          maxScale: 4.0,
          panEnabled: _isZoomed,
          scaleEnabled: scaleEnabled,
          child: widget.child,
        ),
      ),
    );
  }
}
