import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/tv_mode/presentation/screens/tv_home_screen.dart';
import 'package:shonenx/features/tv_mode/presentation/screens/tv_library_screen.dart';
import 'package:shonenx/features/tv_mode/presentation/screens/tv_search_screen.dart';
import 'package:shonenx/features/tv_mode/presentation/tv_scale.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_nav_bar.dart';

class TvShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell? navigationShell;

  const TvShell({super.key, this.navigationShell});

  @override
  ConsumerState<TvShell> createState() => _TvShellState();
}

class _TvShellState extends ConsumerState<TvShell> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.navigationShell != null) {
      _currentTabIndex = widget.navigationShell!.currentIndex;
    }
  }

  void _onTabSelected(int index) {
    setState(() => _currentTabIndex = index);
    if (widget.navigationShell != null) {
      widget.navigationShell!.goBranch(
        index,
        initialLocation: index == widget.navigationShell!.currentIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scale = context.tvScale;
    final navBarHeight = (66.0 * scale).clamp(64.0, 96.0);

    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(scale)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              top: navBarHeight,
              child: IndexedStack(
                index: _currentTabIndex,
                children: const [
                  TvHomeScreen(),
                  TvSearchScreen(),
                  TvLibraryScreen(),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TvNavBar(
                selectedIndex: _currentTabIndex,
                onTabSelected: _onTabSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
