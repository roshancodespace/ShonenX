import 'dart:async';
import 'package:flutter/material.dart';

class SnappingScroller extends StatefulWidget {
  final List<Widget> children;
  final double? heightFactor;
  final double widthFactor;
  final Function(int)? onPageChanged;
  final bool showIndicators;
  final bool loop;
  final bool disableBouncing;
  final Curve scrollCurve;
  final bool autoScroll;
  final Duration animationDuration;
  final Duration scrollInterval;
  final Axis scrollDirection;
  final Color? activeIndicatorColor;
  final Color? inactiveIndicatorColor;
  final bool reverseScrollDirection;
  final EdgeInsets? indicatorPadding;

  const SnappingScroller({
    super.key,
    required this.children,
    this.heightFactor,
    this.onPageChanged,
    this.widthFactor = 0.85,
    this.showIndicators = true,
    this.loop = true,
    this.disableBouncing = false,
    this.scrollCurve = Curves.easeInOutQuart,
    this.autoScroll = false,
    this.animationDuration = const Duration(milliseconds: 500),
    this.scrollInterval = const Duration(seconds: 3),
    this.scrollDirection = Axis.horizontal,
    this.activeIndicatorColor,
    this.inactiveIndicatorColor,
    this.reverseScrollDirection = false,
    this.indicatorPadding,
  });

  @override
  State<SnappingScroller> createState() => _SnappingScrollerState();
}

class _SnappingScrollerState extends State<SnappingScroller> {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _initPageController();
    if (widget.autoScroll) {
      _startAutoScroll();
    }
  }

  void _initPageController() {
    _pageController = PageController(
      viewportFraction: widget.widthFactor,
      initialPage: widget.loop ? widget.children.length * 100 : 0,
    );
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(widget.scrollInterval, (_) {
      if (!_isScrolling && _pageController.hasClients) {
        _scrollToNextPage();
      }
    });
  }

  void _scrollToNextPage() {
    _isScrolling = true;
    final nextPage = _calculateNextPage();

    _pageController
        .animateToPage(
      nextPage,
      duration: widget.animationDuration,
      curve: widget.scrollCurve,
    )
        .then((_) {
      _isScrolling = false;
    });
  }

  int _calculateNextPage() {
    final currentIndex = _pageController.page?.round() ?? 0;
    return widget.reverseScrollDirection ? currentIndex - 1 : currentIndex + 1;
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final containerHeight = widget.scrollDirection == Axis.horizontal
        ? screenSize.width * (widget.heightFactor ?? 0.65)
        : screenSize.height * (widget.heightFactor ?? 0.6);

    return GestureDetector(
      onPanDown: (_) => _autoScrollTimer?.cancel(),
      onPanCancel: () {
        if (widget.autoScroll) _startAutoScroll();
      },
      child: SizedBox(
        height: containerHeight,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              padEnds: false,
              physics: widget.disableBouncing
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              scrollDirection: widget.scrollDirection,
              onPageChanged: (index) {
                final actualIndex = index % widget.children.length;
                setState(() {
                  _currentPage = actualIndex;
                });
                widget.onPageChanged?.call(actualIndex);
              },
              itemBuilder: (context, index) {
                final actualIndex = index % widget.children.length;
                return Padding(padding: EdgeInsets.only(right: 5),child: widget.children[actualIndex]);
              },
              itemCount: widget.loop ? null : widget.children.length,
            ),

            // Improved Page Indicators
            if (widget.showIndicators)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.children.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: widget.indicatorPadding ??
                          const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: isActive ? 24 : 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? widget.activeIndicatorColor ??
                                Theme.of(context).colorScheme.primary
                            : widget.inactiveIndicatorColor?.withOpacity(0.5) ??
                                Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
