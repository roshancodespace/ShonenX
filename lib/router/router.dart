import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/browse/view/browse_screen.dart';
import 'package:shonenx/features/downloads/view/downloads_screen.dart';
import 'package:shonenx/features/loading/view/loading_screen.dart';
import 'package:shonenx/features/watchlist/view/watchlist_screen.dart';
import 'package:shonenx/features/loading/view_model/initialization_notifier.dart';
import 'package:shonenx/features/home/view/home_screen.dart' as h_screen;
import 'package:shonenx/shared/widgets/focusable_tap.dart';

// Navigation item configuration
class NavItem {
  final String path;
  final IconData icon;
  final Widget screen;

  NavItem({required this.path, required this.icon, required this.screen});
}

final List<NavItem> navItems = [
  NavItem(path: '/', icon: Iconsax.home, screen: const h_screen.HomeScreen()),
  NavItem(
      path: '/browse', icon: Iconsax.discover_1, screen: const BrowseScreen()),
  NavItem(
      path: '/downloads',
      icon: Iconsax.receive_square,
      screen: const DownloadsScreen()),
  NavItem(
      path: '/watchlist',
      icon: Iconsax.bookmark,
      screen: const WatchlistScreen()),
];

class AppRouterScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppRouterScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    final initializationState = ref.watch(initializationProvider);
    if (initializationState.status != InitializationStatus.success) {
      return const LoadingScreen();
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showExitConfirmationDialog(context, isSystemExit: true);
      },
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: isWideScreen ? 90 : 0,
                bottom: isWideScreen ? 15 : 0,
                top: isWideScreen ? 15 : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: navigationShell,
              ),
            ),
            Positioned(
              left: isWideScreen ? 10 : 0,
              right: isWideScreen ? null : 0,
              top: isWideScreen ? 20 : null,
              bottom: 10,
              child: SafeArea(
                child: isWideScreen
                    ? _buildFloatingSideNav(context)
                    : _buildCrystalBottomNav(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSideNav(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.primary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = navigationShell.currentIndex == index;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: index == 0
                    ? BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50))
                    : index == (navItems.length - 1)
                        ? BorderRadius.only(
                            bottomLeft: Radius.circular(50),
                            bottomRight: Radius.circular(50),
                          )
                        : null,
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              margin: const EdgeInsets.all(5),
              child: FocusableTap(
                onTap: () => navigationShell.goBranch(index),
                autofocus: isSelected,
                borderRadius: BorderRadius.circular(24),
                child: Center(
                  child: Icon(
                    item.icon,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCrystalBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width * 0.15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: theme.colorScheme.surface.withOpacity(0.5),
              border:
                  Border.all(color: theme.colorScheme.primary.withOpacity(0.8)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = navigationShell.currentIndex == index;
                return Expanded(
                  child: FocusableTap(
                    onTap: () => navigationShell.goBranch(index),
                    autofocus: isSelected,
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.2)
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Icon(
                          item.icon,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// Exit confirmation dialog
void showExitConfirmationDialog(BuildContext context,
    {bool isSystemExit = false}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Exit'),
      content: const Text('Are you sure you want to exit the app?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (isSystemExit) {
              SystemNavigator.pop();
            } else {
              context.pop();
            }
          },
          child: const Text('Exit'),
        ),
      ],
    ),
  );
}
