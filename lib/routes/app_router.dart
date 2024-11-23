import 'package:flutter/material.dart';
import 'package:nekoflow/screens/main/home/home_screen.dart';
import 'package:nekoflow/screens/main/search/search_screen.dart';
import 'package:nekoflow/screens/main/settings/settings_screen.dart';
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
  int _selectedIndex = 1;

  // Preserved state screens
  late final List<Widget> _screens = [
    const SettingsScreen(),
    HomeScreen(name: widget.name),
    const Placeholder(), // Placeholder for dynamic SearchScreen
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
        children: _screens
            .asMap()
            .entries
            .map((entry) => entry.key == 2 && _selectedIndex == 2
                ? const SearchScreen() // Dynamically replace the SearchScreen
                : entry.value)
            .toList(),
      ),
      bottomNavigationBar: CrystalNavigationBar(
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: colorScheme.onSurface,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.5),
        enableFloatingNavBar: true,
        marginR: const EdgeInsets.symmetric(horizontal: 90, vertical: 20),
        splashBorderRadius: 50,
        borderRadius: 500,
        enablePaddingAnimation: true,
        items: [
          CrystalNavigationBarItem(
            icon: HugeIcons.strokeRoundedSettings01,
            unselectedIcon: HugeIcons.strokeRoundedSettings02,
          ),
          CrystalNavigationBarItem(
            icon: HugeIcons.strokeRoundedHome01,
            unselectedIcon: HugeIcons.strokeRoundedHome02,
          ),
          CrystalNavigationBarItem(
            icon: HugeIcons.strokeRoundedSearch01,
            unselectedIcon: HugeIcons.strokeRoundedSearch02,
          ),
          CrystalNavigationBarItem(
            icon: HugeIcons.strokeRoundedBookmarkAdd01,
            unselectedIcon: HugeIcons.strokeRoundedBookmark02,
          ),
        ],
      ),
    );
  }
}
