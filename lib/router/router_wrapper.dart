import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/browse/view/browse_screen.dart';
import 'package:shonenx/features/downloads/view/downloads_screen.dart';
import 'package:shonenx/features/home/view/home_screen.dart' as h_screen;
import 'package:shonenx/features/loading/view/loading_screen.dart';
import 'package:shonenx/features/loading/view_model/initialization_notifier.dart';
import 'package:shonenx/features/watchlist/view/watchlist_screen.dart';

class NavItem {
  final String path;
  final IconData icon;
  final Widget screen;

  const NavItem({required this.path, required this.icon, required this.screen});
}

final List<NavItem> navItems = [
  const NavItem(path: '/', icon: Iconsax.home, screen: h_screen.HomeScreen()),
  const NavItem(
    path: '/browse',
    icon: Iconsax.discover_1,
    screen: BrowseScreen(),
  ),
  const NavItem(
    path: '/downloads',
    icon: Iconsax.receive_square,
    screen: DownloadsScreen(),
  ),
  const NavItem(
    path: '/watchlist',
    icon: Iconsax.bookmark,
    screen: WatchlistScreen(),
  ),
];

class AppRouterScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppRouterScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(initializationProvider).status;
    if (status != InitializationStatus.success) return const LoadingScreen();

    final isWide = MediaQuery.sizeOf(context).width > 800;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) showExitConfirmationDialog(context, isSystemExit: true);
      },
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 90 : 0,
                isWide ? 15 : 0,
                0,
                isWide ? 15 : 0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: navigationShell,
              ),
            ),
            Positioned(
              left: isWide ? 10 : 0,
              right: isWide ? null : 0,
              top: isWide ? 20 : null,
              bottom: 10,
              child: SafeArea(
                child: isWide
                    ? _SideNav(shell: navigationShell)
                    : _BottomNav(shell: navigationShell),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _SideNav({required this.shell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 75,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: colorScheme.primary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(navItems.length, (index) {
          final isSelected = shell.currentIndex == index;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: InkWell(
                onTap: () => shell.goBranch(index),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: isSelected
                        ? colorScheme.primary.withOpacity(0.2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    navItems[index].icon,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _BottomNav({required this.shell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: colorScheme.primary.withOpacity(0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final isSelected = shell.currentIndex == index;
                return Expanded(
                  child: InkWell(
                    onTap: () => shell.goBranch(index),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.2)
                            : null,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        navItems[index].icon,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

void showExitConfirmationDialog(
  BuildContext context, {
  bool isSystemExit = false,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Exit'),
      content: const Text('Are you sure you want to exit the app?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
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
