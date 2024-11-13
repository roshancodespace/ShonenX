import 'package:flutter/material.dart';

class SnappingScroller extends StatefulWidget {
  final List<Widget> children;
  final double? heightFactor;
  final double widthFactor;
  final Function? onPageChanged;

  const SnappingScroller({
    super.key,
    required this.children,
    this.heightFactor,
    this.onPageChanged,
    this.widthFactor = 0.5
  });

  @override
  State<SnappingScroller> createState() => _SnappingScrollerState();
}

class _SnappingScrollerState extends State<SnappingScroller> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(viewportFraction: widget.widthFactor, initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.width * (widget.heightFactor ?? 0.6),
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.children.length,
        padEnds: false,
        physics: PageScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) => widget.children[index],
      ),
    );
  }
}
