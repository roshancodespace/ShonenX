import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavBarState {
  final Widget? customBar;
  final Widget? globalTop;
  final Map<int, Widget> branchTops;

  const NavBarState({
    this.customBar,
    this.globalTop,
    this.branchTops = const {},
  });

  Widget? topForBranch(int currentIndex) =>
      globalTop ?? branchTops[currentIndex];
}

class NavBarNotifier extends Notifier<NavBarState> {
  @override
  NavBarState build() => const NavBarState();

  void replace(Widget customBar) => state = NavBarState(
        customBar: customBar,
        globalTop: state.globalTop,
        branchTops: state.branchTops,
      );

  void hide() => replace(const SizedBox.shrink());

  void restore() => state = const NavBarState();

  void attachTop(Widget widget, {int? branchIndex}) {
    if (branchIndex != null) {
      state = NavBarState(
        customBar: state.customBar,
        globalTop: state.globalTop,
        branchTops: {...state.branchTops, branchIndex: widget},
      );
    } else {
      state = NavBarState(
        customBar: state.customBar,
        globalTop: widget,
        branchTops: state.branchTops,
      );
    }
  }

  void clearTop({int? branchIndex}) {
    if (branchIndex != null) {
      final next = Map<int, Widget>.from(state.branchTops)
        ..remove(branchIndex);
      state = NavBarState(
        customBar: state.customBar,
        globalTop: state.globalTop,
        branchTops: next,
      );
    } else {
      state = NavBarState(
        customBar: state.customBar,
        globalTop: null,
        branchTops: state.branchTops,
      );
    }
  }
}

final navBarProvider =
    NotifierProvider<NavBarNotifier, NavBarState>(NavBarNotifier.new);
