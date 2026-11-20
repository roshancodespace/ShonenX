import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/core/router/nav_bar_destinations.dart';
import 'package:shonenx/core/router/nav_bar_theme.dart';
import 'package:shonenx/core/router/nav_download_button.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
import 'package:shonenx/shared/providers/navbar_action_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

const double _inactiveOpacity = 0.6;
const int _downloadsBranch = 3;

class NavBarMetrics {
  final double baseBarHeight;
  final double iconSize;
  final double fontSize;
  final double hPad;
  final double uiScale;

  const NavBarMetrics({
    required this.baseBarHeight,
    required this.iconSize,
    required this.fontSize,
    required this.hPad,
    required this.uiScale,
  });

  factory NavBarMetrics.fromResponsive(ResponsiveData r) {
    return NavBarMetrics(
      baseBarHeight: r.isPhone ? 68.0 : 80.0,
      iconSize: r.isPhone ? 25.0 : 28.0,
      fontSize: r.isPhone ? 14.0 : 15.0,
      hPad: r.isPhone ? 6.0 : 10.0,
      uiScale: GlobalUI.uiScaleFactor.clamp(0.85, 1.25).toDouble(),
    );
  }

  static const NavBarMetrics preview = NavBarMetrics(
    baseBarHeight: 68.0,
    iconSize: 25.0,
    fontSize: 14.0,
    hPad: 6.0,
    uiScale: 1.0,
  );
}

typedef NavBarSelect = void Function(int index, {bool resetOnReselect});

class BottomNavBarView extends StatelessWidget {
  final NavBarStyle navBarStyle;
  final int currentIndex;
  final List<NavBarDestination> destinations;
  final NavBarSelect? onSelect;
  final DownloadActivity download;
  final NavBarMetrics metrics;

  const BottomNavBarView({
    super.key,
    required this.navBarStyle,
    required this.currentIndex,
    required this.destinations,
    this.onSelect,
    required this.download,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scale = metrics.uiScale;
    final isMinimal = navBarStyle == NavBarStyle.minimal;
    final barHeight = (isMinimal ? 54.0 : metrics.baseBarHeight) * scale;
    final iconSize = metrics.iconSize * scale;
    final inset = metrics.hPad * scale;

    final themeData = NavBarThemeData.resolve(navBarStyle, cs, false);
    final barRadius = BorderRadius.circular(themeData.barRadius(barHeight));
    final itemRadius = themeData.itemRadius(barHeight - 2 * inset);
    final select = onSelect;

    final bar = Container(
      height: barHeight,
      padding: EdgeInsets.all(inset),
      decoration: themeData.barDecoration.copyWith(borderRadius: barRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < destinations.length; i++)
            _BottomNavItem(
              icon: destinations[i].icon,
              label: destinations[i].label,
              active: currentIndex == i,
              themeData: themeData,
              iconSize: iconSize,
              fontSize: metrics.fontSize,
              radius: itemRadius,
              scale: scale,
              cs: cs,
              onTap: select == null ? null : () => select(i),
            ),
        ],
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: barRadius,
          child: themeData.blurSigma != null
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: themeData.blurSigma!,
                    sigmaY: themeData.blurSigma!,
                  ),
                  child: bar,
                )
              : bar,
        ),
        SizedBox(width: inset + 2),
        NavDownloadButton(
          size: barHeight,
          iconSize: iconSize,
          padding: inset,
          navBarStyle: navBarStyle,
          colorScheme: cs,
          active: currentIndex == _downloadsBranch,
          activity: download,
          onTap: select == null
              ? null
              : () => select(_downloadsBranch, resetOnReselect: true),
        ),
      ],
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final NavBarThemeData themeData;
  final double iconSize;
  final double fontSize;
  final double radius;
  final double scale;
  final ColorScheme cs;
  final VoidCallback? onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.themeData,
    required this.iconSize,
    required this.fontSize,
    required this.radius,
    required this.scale,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final decoration =
        (active
                ? themeData.activeItemDecoration
                : themeData.inactiveItemDecoration)
            .copyWith(borderRadius: borderRadius);
    final iconColor = active
        ? themeData.activeIconColor
        : themeData.inactiveIconColor;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: double.maxFinite,
        decoration: decoration,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            focusColor: cs.primary.withValues(alpha: 0.2),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: (active ? 18.0 : 14.0) * scale,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: active ? themeData.activeScale : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity: active ? 1.0 : _inactiveOpacity,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(icon, color: iconColor, size: iconSize),
                        ),
                      ),
                      ClipRect(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          child: active
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      letterSpacing: 0.1,
                                      fontWeight: themeData.isMaterial3
                                          ? FontWeight.w500
                                          : FontWeight.w600,
                                      color: themeData.activeTextColor,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                  if (themeData.showDotIndicator && active) ...[
                    const SizedBox(height: 3),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DockedBottomNavBar extends StatelessWidget {
  final List<NavBarDestination> destinations;
  final int currentIndex;
  final NavBarSelect? onSelect;
  final DownloadActivity download;
  final String downloadLabel;

  const DockedBottomNavBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    this.onSelect,
    required this.download,
    required this.downloadLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final select = onSelect;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: NavigationBar(
        height: 72.0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        selectedIndex: currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: select == null
            ? null
            : (i) => select(i, resetOnReselect: true),
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.primaryContainer,
        destinations: [
          for (final d in destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
          NavigationDestination(
            icon: DockedDownloadIcon(activity: download),
            label: downloadLabel,
          ),
        ],
      ),
    );
  }
}

class BottomNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final navState = ref.watch(navBarProvider);
    final navBarStyle = ref.watch(uiPrefsProvider.select((s) => s.navBarStyle));

    if (navState.customBar != null) {
      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: navState.customBar!,
          ),
        ),
      );
    }

    final attachment = navState.topForBranch(navigationShell.currentIndex);
    final isDocked = navBarStyle == NavBarStyle.docked;
    final bottomMargin = isDocked
        ? 0.0
        : (r.height * 0.018).clamp(8.0, 20.0).toDouble();
    final activity = DownloadActivity.fromTasks(
      ref.watch(downloadTasksProvider).value ?? [],
    );

    void select(int i, {bool resetOnReselect = false}) {
      navigationShell.goBranch(
        i,
        initialLocation: resetOnReselect && i == navigationShell.currentIndex,
      );
    }

    final Widget bar = isDocked
        ? DockedBottomNavBar(
            destinations: navBarDestinations(context),
            currentIndex: navigationShell.currentIndex,
            onSelect: select,
            download: activity,
            downloadLabel: context.l10n.navDownloads,
          )
        : BottomNavBarView(
            navBarStyle: navBarStyle,
            currentIndex: navigationShell.currentIndex,
            destinations: navBarDestinations(context),
            onSelect: select,
            download: activity,
            metrics: NavBarMetrics.fromResponsive(r),
          );

    return SafeArea(
      bottom: !isDocked,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomMargin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: attachment != null
                      ? KeyedSubtree(
                          key: ValueKey(attachment.hashCode),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: attachment,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty_nav_att')),
                ),
              ),
              bar,
            ],
          ),
        ),
      ),
    );
  }
}
