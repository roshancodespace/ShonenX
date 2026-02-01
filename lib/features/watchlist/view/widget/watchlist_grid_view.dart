import 'package:flutter/material.dart';
import 'package:shonenx/features/watchlist/view/widget/shonenx_gridview.dart';

class WatchlistGridView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Future<void> Function() onRefresh;
  final bool isLoading;
  final ScrollNotificationPredicate? notificationPredicate;
  final bool Function(ScrollNotification)? onScrollNotification;
  final EdgeInsets? padding;
  final double? crossAxisExtent;

  const WatchlistGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onRefresh,
    this.isLoading = false,
    this.notificationPredicate,
    this.onScrollNotification,
    this.padding,
    this.crossAxisExtent,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: onScrollNotification,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ShonenXGridView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding ?? const EdgeInsets.fromLTRB(10, 10, 10, 120),
          crossAxisExtent: crossAxisExtent,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.7,
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }
}
