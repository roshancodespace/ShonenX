import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                _SideNavBar(navigationShell: navigationShell),
                Expanded(child: navigationShell),
              ],
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              navigationShell,
              _BottomNavV2(navigationShell: navigationShell),
            ],
          );
        },
      ),
    );
  }
}

class _NavDest {
  final IconData icon;
  final String label;
  const _NavDest(this.icon, this.label);
}

const _destinations = [
  _NavDest(Icons.home_outlined, 'Home'),
  _NavDest(Icons.search_rounded, 'Search'),
  _NavDest(Icons.library_books_outlined, 'Library'),
];

class _BottomNavV2 extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _BottomNavV2({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final barHeight = screenWidth < 400 ? 60.0 : 68.0;
    final iconSize = screenWidth < 400 ? 22.0 : 25.0;
    final fontSize = screenWidth < 400 ? 13.0 : 14.5;
    final hPad = screenWidth < 400 ? 6.0 : 8.0;
    final itemRadius = barHeight / 2 - 2;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.018),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(barHeight / 2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    height: barHeight,
                    padding: EdgeInsets.all(hPad),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(barHeight / 2),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_destinations.length, (i) {
                        final active = navigationShell.currentIndex == i;
                        return GestureDetector(
                          onTap: () => navigationShell.goBranch(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.symmetric(
                              horizontal: active ? 18 : 14,
                              vertical: hPad + 5,
                            ),
                            decoration: BoxDecoration(
                              color: active ? cs.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(itemRadius),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _destinations[i].icon,
                                  color: active
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant.withValues(
                                          alpha: 0.6,
                                        ),
                                  size: iconSize,
                                ),
                                ClipRect(
                                  child: AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    child: active
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            child: Text(
                                              _destinations[i].label,
                                              style: TextStyle(
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.w600,
                                                color: cs.onPrimary,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              SizedBox(width: hPad + 4),
              _DownloadButton(
                colorScheme: cs,
                size: barHeight,
                iconSize: iconSize,
                padding: hPad,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadButton extends ConsumerWidget {
  final ColorScheme colorScheme;
  final double size;
  final double iconSize;
  final double padding;
  const _DownloadButton({
    required this.colorScheme,
    required this.size,
    required this.iconSize,
    required this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadTasksProvider).value ?? [];
    final activeTasks = tasks
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.pending,
        )
        .toList();
    final count = activeTasks.length;

    double? progress;
    if (count > 0) {
      final valid = activeTasks.where((t) => t.progress >= 0);
      if (valid.isNotEmpty) {
        progress =
            valid.map((t) => t.progress).reduce((a, b) => a + b) / valid.length;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.75),
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (count > 0)
                    SizedBox(
                      width: iconSize + 8,
                      height: iconSize + 8,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2.5,
                        color: colorScheme.primary,
                      ),
                    ),
                  Icon(
                    Icons.download_outlined,
                    color: colorScheme.onSurface,
                    size: iconSize,
                  ),
                ],
              ),
            ),
            onPressed: () => context.push('/downloads'),
          ),
        ),
      ),
    );
  }
}

class _SideNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _SideNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const barWidth = 72.0;
    const hPad = 8.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: _GlassPillContainer(
                width: barWidth,
                padding: hPad,
                child: Column(
                  children: List.generate(_destinations.length, (i) {
                    final active = navigationShell.currentIndex == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => navigationShell.goBranch(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: active ? cs.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(barWidth / 2),
                          ),
                          child: _PillContent(
                            icon: _destinations[i].icon,
                            label: _destinations[i].label,
                            active: active,
                            cs: cs,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 1,
              child: _GlassPillContainer(
                width: barWidth,
                padding: hPad,
                child: _TallDownloadPillContent(cs: cs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPillContainer extends StatelessWidget {
  final double width;
  final double padding;
  final Widget child;

  const _GlassPillContainer({
    required this.width,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(width / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: width,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(width / 2),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PillContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final ColorScheme cs;
  final bool isDownload;

  const _PillContent({
    required this.icon,
    required this.label,
    required this.active,
    required this.cs,
    this.isDownload = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: active || isDownload
              ? (isDownload ? cs.onSurface : cs.onPrimary)
              : cs.onSurfaceVariant.withValues(alpha: 0.6),
          size: 25,
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: (active || isDownload)
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: isDownload ? cs.onSurface : cs.onPrimary,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _TallDownloadPillContent extends ConsumerWidget {
  final ColorScheme cs;

  const _TallDownloadPillContent({required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadTasksProvider).value ?? [];
    final count = tasks
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.pending,
        )
        .length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => context.push('/downloads'),
        child: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          backgroundColor: cs.primary,
          textColor: cs.onPrimary,
          child: _PillContent(
            icon: Icons.download_outlined,
            label: 'DOWNLOAD',
            active: false,
            isDownload: true,
            cs: cs,
          ),
        ),
      ),
    );
  }
}
