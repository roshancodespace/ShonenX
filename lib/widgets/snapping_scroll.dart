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
  final double indicatorSpacing;
  final double indicatorHeight;
  final double activeIndicatorWidth;
  final double inactiveIndicatorWidth;
  final BorderRadius? indicatorBorderRadius;
  final bool enableGradientIndicators;

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
    this.indicatorSpacing = 4.0,
    this.indicatorHeight = 8.0,
    this.activeIndicatorWidth = 24.0,
    this.inactiveIndicatorWidth = 8.0,
    this.indicatorBorderRadius,
    this.enableGradientIndicators = false,
  });

  @override
  State<SnappingScroller> createState() => _SnappingScrollerState();
}

class _SnappingScrollerState extends State<SnappingScroller> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  bool _isScrolling = false;
  late AnimationController _indicatorAnimationController;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    _initPageController();
    _initAnimationController();
    if (widget.autoScroll) {
      _startAutoScroll();
    }
  }

  void _initAnimationController() {
    _indicatorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _indicatorAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _indicatorAnimationController,
        curve: Curves.easeInOut,
      ),
    );
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
    _indicatorAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final containerHeight = widget.scrollDirection == Axis.horizontal
        ? screenSize.width * (widget.heightFactor ?? 0.65)
        : screenSize.height * (widget.heightFactor ?? 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanDown: (_) => _autoScrollTimer?.cancel(),
          onPanCancel: () {
            if (widget.autoScroll) _startAutoScroll();
          },
          child: SizedBox(
            height: containerHeight,
            child: PageView.builder(
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
                _indicatorAnimationController.forward(from: 0);
              },
              itemBuilder: (context, index) {
                final actualIndex = index % widget.children.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: widget.children[actualIndex],
                );
              },
              itemCount: widget.loop ? null : widget.children.length,
            ),
          ),
        ),
        if (widget.showIndicators)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AnimatedBuilder(
              animation: _indicatorAnimationController, // Changed from _indicatorAnimation to _indicatorAnimationController
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.children.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: widget.indicatorPadding ??
                          EdgeInsets.symmetric(horizontal: widget.indicatorSpacing),
                      height: widget.indicatorHeight,
                      width: isActive ? widget.activeIndicatorWidth : widget.inactiveIndicatorWidth,
                      decoration: BoxDecoration(
                        gradient: widget.enableGradientIndicators && isActive
                            ? LinearGradient(
                                colors: [
                                  widget.activeIndicatorColor ?? Theme.of(context).colorScheme.primaryContainer,
                                  widget.activeIndicatorColor?.withOpacity(0.7) ??
                                      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                                ],
                              )
                            : null,
                        color: !widget.enableGradientIndicators
                            ? isActive
                                ? widget.activeIndicatorColor ?? Theme.of(context).colorScheme.primaryContainer
                                : widget.inactiveIndicatorColor?.withOpacity(0.5) ??
                                    Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                            : null,
                        borderRadius: widget.indicatorBorderRadius ?? BorderRadius.circular(4),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: (widget.activeIndicatorColor ?? Theme.of(context).colorScheme.secondaryContainer)
                                      .withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
      ],
    );
  }
}
