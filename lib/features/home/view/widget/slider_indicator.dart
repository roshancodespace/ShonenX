import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CustomSlideIndicator implements SlideIndicator {
  final BuildContext context;
  CustomSlideIndicator(this.context);
  @override
  Widget build(int currentPage, double pageDelta, int itemCount) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedSmoothIndicator(
        activeIndex: currentPage,
        count: itemCount,
        effect: ExpandingDotsEffect(
          dotHeight: 6,
          dotWidth: 12,
          activeDotColor: Theme.of(context).colorScheme.primary,
          dotColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}
