import 'package:flutter/material.dart';
import 'package:nekoflow/screens/main/browse/browse_screen.dart';
import 'package:nekoflow/screens/main/home/home_screen.dart';
import 'package:nekoflow/screens/main/watchlist/watchlist_screen.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:hugeicons/hugeicons.dart';

class AppRouter extends StatefulWidget {
  final String name;

  const AppRouter({super.key, required this.name});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  int _selectedIndex = 0;

  // Preserved state screens
  late final List<Widget> _screens = [
    HomeScreen(name: widget.name),
    const BrowseScreen(),
    const WatchlistScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CrystalNavigationBar(
        backgroundColor: colorScheme.surface.withOpacity(0.8),
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        enableFloatingNavBar: true,
        marginR: const EdgeInsets.symmetric(horizontal: 120, vertical: 16),
        splashBorderRadius: 24,
        borderRadius: 50,
        enablePaddingAnimation: true,
        items: [
          CrystalNavigationBarItem(
            icon: HugeIcons.strokeRoundedHome01,
            unselectedIcon: HugeIcons.strokeRoundedHome02,
          ),
          CrystalNavigationBarItem(
            icon: HugeIcons.strokeRoundedGlobalSearch,
            unselectedIcon: HugeIcons.strokeRoundedGlobal,
          ),
          CrystalNavigationBarItem(
            icon: HugeIcons.strokeRoundedCollectionsBookmark,
            unselectedIcon: HugeIcons.strokeRoundedAllBookmark,
          ),
        ],
      ),
    );
  }
}