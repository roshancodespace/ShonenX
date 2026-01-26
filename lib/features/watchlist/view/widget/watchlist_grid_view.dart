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

  const WatchlistGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onRefresh,
    this.isLoading = false,
    this.notificationPredicate,
    this.onScrollNotification,
    this.padding,
  });

  int _columns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1400) return 6;
    if (w >= 1100) return 5;
    if (w >= 800) return 4;
    if (w >= 450) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: onScrollNotification,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ShonenXGridView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding ?? const EdgeInsets.fromLTRB(10, 10, 10, 120),
          crossAxisCount: _columns(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.7,
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }
}
