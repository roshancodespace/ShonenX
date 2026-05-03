import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth > 800;

          if (isLarge) {
            return Row(
              children: [
                _SideNavBar(
                  navigationShell: navigationShell,
                  colorScheme: colorScheme,
                ),
                Expanded(child: navigationShell),
              ],
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              navigationShell,
              _BottomNavBar(
                navigationShell: navigationShell,
                colorScheme: colorScheme,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ColorScheme colorScheme;

  const _BottomNavBar({
    required this.navigationShell,
    required this.colorScheme,
  });

  Widget _buildGlassPill({required Widget child, double? width}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: SizedBox(
          height: 60,
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: colorScheme.surface.withValues(alpha: 0.5),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Padding(padding: const EdgeInsets.all(8), child: child),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGlassPill(
                width: size.width * 0.65,
                child: Row(
                  children: [
                    _NavItem(
                      index: 0,
                      currentIndex: navigationShell.currentIndex,
                      icon: Icons.home,
                      onTap: () => navigationShell.goBranch(0),
                    ),
                    const SizedBox(width: 8),
                    _NavItem(
                      index: 1,
                      currentIndex: navigationShell.currentIndex,
                      icon: Icons.search,
                      onTap: () => navigationShell.goBranch(1),
                    ),
                    const SizedBox(width: 8),
                    _NavItem(
                      index: 2,
                      currentIndex: navigationShell.currentIndex,
                      icon: Icons.library_books,
                      onTap: () => navigationShell.goBranch(2),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              // const SizedBox(width: 12),
              // _buildGlassPill(
              //   width: 60,
              //   child: Center(
              //     child: IconButton(
              //       padding: EdgeInsets.zero,
              //       icon: Icon(Icons.download, color: colorScheme.onSurface),
              //       onPressed: () {
              //         context.push('/downloads');
              //       },
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ColorScheme colorScheme;

  const _SideNavBar({required this.navigationShell, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: 80,
        margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: colorScheme.surface.withValues(alpha: 0.5),
          border: Border.all(color: colorScheme.outline),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _NavItem(
              index: 0,
              radius: 50,
              currentIndex: navigationShell.currentIndex,
              icon: Icons.home,
              onTap: () => navigationShell.goBranch(0),
              forSideBar: true,
            ),
            _NavItem(
              index: 1,
              radius: 50,
              currentIndex: navigationShell.currentIndex,
              icon: Icons.search,
              onTap: () => navigationShell.goBranch(1),
              forSideBar: true,
            ),
            _NavItem(
              index: 2,
              radius: 50,
              currentIndex: navigationShell.currentIndex,
              icon: Icons.library_books,
              onTap: () => navigationShell.goBranch(2),
              forSideBar: true,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final bool isLast;
  final double radius;
  final VoidCallback onTap;
  final IconData icon;
  final bool forSideBar;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.icon,
    this.radius = 30.0,
    this.isLast = false,
    this.forSideBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = currentIndex == index;
    final isFirst = index == 0;

    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? radius : 0),
      topRight: Radius.circular(
        (isLast && !forSideBar) || (forSideBar && isFirst) ? radius : 0,
      ),
      bottomLeft: Radius.circular(
        (isFirst && !forSideBar) || (forSideBar && isLast) ? radius : 0,
      ),
      bottomRight: Radius.circular(isLast ? radius : 0),
    );

    return Expanded(
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: isActive
                ? colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: isActive ? colorScheme.primary : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
