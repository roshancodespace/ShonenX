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
      fontSize: r.isPhone ? 14.5 : 16.0,
      hPad: r.isPhone ? 6.0 : 10.5,
      uiScale: GlobalUI.uiScaleFactor.clamp(0.85, 1.25).toDouble(),
    );
  }

  static const NavBarMetrics preview = NavBarMetrics(
    baseBarHeight: 68.0,
    iconSize: 25.0,
    fontSize: 14.5,
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
    final barHeight =
        (navBarStyle == NavBarStyle.minimal ? 54.0 : metrics.baseBarHeight) *
        scale;
    final iconSize = metrics.iconSize * scale;
    final fontSize = metrics.fontSize;
    final hPad = metrics.hPad * scale;
    final vPad = hPad;

    final themeData = NavBarThemeData.resolve(navBarStyle, cs, false);
    final barRadius = themeData.barRadius(barHeight);
    final itemRadius = themeData.itemRadius(barHeight - 2 * vPad);
    final select = onSelect;

    final contentWidget = Container(
      height: barHeight,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: themeData.barDecoration.copyWith(
        borderRadius: BorderRadius.circular(barRadius),
      ),
      child: _buildItemsRow(
        destinations: destinations,
        currentIndex: currentIndex,
        cs: cs,
        iconSize: iconSize,
        fontSize: fontSize,
        itemRadius: itemRadius,
        navBarStyle: navBarStyle,
        onSelect: onSelect,
      ),
    );

    final innerContent = themeData.blurSigma != null
        ? BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: themeData.blurSigma!,
              sigmaY: themeData.blurSigma!,
            ),
            child: contentWidget,
          )
        : contentWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(barRadius),
          child: innerContent,
        ),
        SizedBox(width: hPad + 4),
        NavDownloadButton(
          size: barHeight,
          iconSize: iconSize,
          padding: hPad,
          navBarStyle: navBarStyle,
          colorScheme: cs,
          active: currentIndex == 3,
          activity: download,
          onTap: select == null
              ? null
              : () => select(3, resetOnReselect: true),
        ),
      ],
    );
  }

  Widget _buildItemsRow({
    required List<NavBarDestination> destinations,
    required int currentIndex,
    required ColorScheme cs,
    required double iconSize,
    required double fontSize,
    required double itemRadius,
    required NavBarStyle navBarStyle,
    NavBarSelect? onSelect,
  }) {
    final select = onSelect;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(destinations.length, (i) {
        final active = currentIndex == i;
        final themeData = NavBarThemeData.resolve(navBarStyle, cs, false);

        Widget item = InkWell(
          onTap: select == null ? null : () => select(i),
          borderRadius: BorderRadius.circular(itemRadius),
          focusColor: cs.primary.withValues(alpha: 0.2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: double.maxFinite,
            padding: EdgeInsets.symmetric(horizontal: active ? 18 : 14),
            decoration:
                (active
                        ? themeData.activeItemDecoration
                        : themeData.inactiveItemDecoration)
                    .copyWith(borderRadius: BorderRadius.circular(itemRadius)),
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
                        opacity: active ? 1.0 : 0.55,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          destinations[i].icon,
                          color: active
                              ? themeData.activeIconColor
                              : themeData.inactiveIconColor,
                          size: iconSize,
                        ),
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
                                  destinations[i].label,
                                  style: TextStyle(
                                    fontSize: fontSize,
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
                      color: themeData.activeIconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        return item;
      }),
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
    return NavigationBar(
      height: 72.0,
      selectedIndex: currentIndex,
      onDestinationSelected: select == null
          ? null
          : (i) => select(i, resetOnReselect: true),
      backgroundColor: cs.surfaceContainer,
      indicatorColor: cs.primaryContainer,
      destinations: [
        ...destinations.map(
          (d) => NavigationDestination(icon: Icon(d.icon), label: d.label),
        ),
        NavigationDestination(
          icon: DockedDownloadIcon(activity: download),
          label: downloadLabel,
        ),
      ],
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
    final uiPrefs = ref.watch(uiPrefsProvider);
    final navBarStyle = uiPrefs.navBarStyle;

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

    final activeAttachmentWidget = navState.topForBranch(
      navigationShell.currentIndex,
    );

    final isDocked = navBarStyle == NavBarStyle.docked;
    final bottomMargin = isDocked ? 0.0 : r.height * 0.018;

    void adapter(int i, {bool resetOnReselect = false}) {
      navigationShell.goBranch(
        i,
        initialLocation: resetOnReselect && i == navigationShell.currentIndex,
      );
    }

    final Widget navBarWidget;
    if (isDocked) {
      navBarWidget = DockedBottomNavBar(
        destinations: navBarDestinations(context),
        currentIndex: navigationShell.currentIndex,
        onSelect: adapter,
        download: DownloadActivity.fromTasks(
          ref.watch(downloadTasksProvider).value ?? [],
        ),
        downloadLabel: context.l10n.navDownloads,
      );
    } else {
      navBarWidget = BottomNavBarView(
        navBarStyle: navBarStyle,
        currentIndex: navigationShell.currentIndex,
        destinations: navBarDestinations(context),
        onSelect: adapter,
        download: DownloadActivity.fromTasks(
          ref.watch(downloadTasksProvider).value ?? [],
        ),
        metrics: NavBarMetrics.fromResponsive(r),
      );
    }

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
                  child: activeAttachmentWidget != null
                      ? KeyedSubtree(
                          key: ValueKey(activeAttachmentWidget.hashCode),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: activeAttachmentWidget,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty_nav_att')),
                ),
              ),
              navBarWidget,
            ],
          ),
        ),
      ),
    );
  }
}
