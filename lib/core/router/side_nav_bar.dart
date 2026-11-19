import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/core/router/nav_bar_destinations.dart';
import 'package:shonenx/core/router/nav_bar_theme.dart';
import 'package:shonenx/core/router/nav_download_button.dart';
import 'package:shonenx/shared/providers/navbar_action_provider.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/shared/widgets/svg_icon.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';

class SideNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const SideNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final cs = Theme.of(context).colorScheme;
    final h = r.heightTier;
    final uiPrefs = ref.watch(uiPrefsProvider);
    final navBarStyle = uiPrefs.navBarStyle;

    final isDocked = navBarStyle == NavBarStyle.docked;

    if (isDocked) {
      final dockedDownloadActivity = DownloadActivity.fromTasks(
        ref.watch(downloadTasksProvider).value ?? [],
      );
      return SafeArea(
        child: Container(
          width: 80,
          color: cs.surfaceContainer,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18.0, bottom: 18.0),
                child: SvgIcon(
                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 344 621" width="344" height="621"><g stroke-width="2" fill="none" stroke-linecap="butt"/><path d="M 159.2 515.84Q 166.12 520.83 167.49 521.49C 172.06 523.67 180.09 528.8 184.78 531.41Q 219.92 550.94 256.51 573.47A 1.26 1.25 -65 0 1 257.04 574.94C 255.87 578.46 254.22 582.5 252.75 585.21Q 244.45 600.59 237.19 614.43A 1.33 1.33 31.71 0 1 235.24 614.89C 227.06 608.94 218.45 604.55 210.01 599.29C 193.4 588.93 176.06 579.32 155.06 567.44Q 147.18 562.98 109.83 540.2C 97.04 532.4 86.29 526.57 73.9 519.4C 67.14 515.48 59.22 509.59 54.8 506.16Q 54.63 506.03 53.92 505.17A 0.91 0.91 67.15 0 1 54.52 503.69C 60.1 503.08 64.95 502.84 71.02 501.17Q 72.33 500.81 89.35 496.55Q 101.66 493.46 119.05 486.77Q 137.28 479.76 159.61 468.85Q 169.97 463.78 194.14 448.57Q 198.69 445.7 203.85 441.87C 219.98 429.89 235.19 416.97 246.26 404Q 250.1 399.5 260.39 386.16Q 280.24 360.41 289.24 329.69C 290.71 324.68 291.56 318.79 293.35 313.14A 0.5 0.49 88.01 0 0 292.7 312.53Q 290.93 313.24 289.53 314.32Q 275.18 325.41 259.57 331.8Q 253.98 334.09 246.22 336.73Q 239.58 339 232.5 340.59Q 212.63 345.05 192.01 345.14C 163.09 345.26 137.23 342.19 111.5 345.5Q 101.69 346.76 85.79 351.67C 80.44 353.33 73.16 356.98 69.08 359.11Q 63.45 362.04 54.21 367.96C 38.89 377.77 24.21 389.7 11.41 401.64A 0.81 0.8 -24.97 0 1 10.06 401.15Q 9.21 394.22 7.25 384.01C 5.72 376.06 5.82 365.35 5.83 356.96C 5.86 341.18 8.01 324.22 11.39 308.04Q 14.69 292.21 19.24 279.7C 22.19 271.57 25.72 262.08 29.61 254.31Q 32.87 247.81 35.45 242.42Q 39.76 233.38 50.97 216.26C 53.81 211.94 56.73 208.45 61.34 202.34Q 76.35 182.46 86.83 172.09Q 96.85 162.16 116.13 146.15Q 131.98 132.99 154.15 121.9Q 162.54 117.71 167.51 115.15Q 175.65 110.95 184.9 107.93A 0.32 0.32 54.25 0 0 184.99 107.37Q 182.33 105.39 178.73 103.35C 172.05 99.55 165.01 94.17 157.69 90.11Q 146.18 83.73 135.21 77.62Q 111.34 64.32 87.3 50.43Q 84.4 48.75 81.78 46.31A 0.63 0.62 -53.26 0 1 81.67 45.54Q 85.61 38.72 86.2 37.41Q 87.74 33.95 99.41 6.47A 1.75 1.74 27.99 0 1 101.97 5.69C 114.9 14.13 130.42 22.13 141.64 29.15C 151.11 35.08 168.97 44.59 182.1 52.6Q 190.98 58.01 199.78 62.68C 210.79 68.52 220.93 75.29 231.78 81.46Q 252.65 93.31 277 108.02Q 284.11 112.32 290.07 118.21A 0.91 0.91 47.25 0 1 290.02 119.55C 287.31 121.87 284.93 122.89 280.88 123.51Q 247.19 128.65 215.87 140.86Q 212.75 142.08 201.12 147.24C 181.62 155.89 163.5 166.89 146.05 179.81C 138.72 185.24 130.26 192.64 122.61 200.38C 114.38 208.71 105.26 217.66 97.8 227.79Q 83.36 247.43 73.61 265.09Q 64.38 281.83 59.62 297.32Q 54.45 314.15 54.24 315.49Q 53.81 318.24 53.72 319.52A 0.38 0.38 77.97 0 0 54.27 319.88Q 63.41 315.06 73.47 310.47Q 81.63 306.75 89.01 305.29Q 97.8 303.54 98.69 303.33Q 104.48 301.98 108.42 301.7C 113.46 301.34 123.39 299.54 130.57 299.45Q 149.37 299.21 168.51 300.3Q 184.06 301.19 199.89 300.28Q 217.38 299.27 230.8 295.3Q 255.83 287.87 275.41 273.42Q 297.99 256.74 317.97 233.19C 320.97 229.66 323.49 227 326.37 223.13Q 327.87 221.12 331.33 217.94A 0.78 0.78 40.63 0 1 332.29 217.87Q 333.59 218.76 334.03 220.38Q 337.96 234.72 338.76 240.26C 339.88 248.14 341.36 254.57 341.61 261.32Q 342.17 276.24 341.73 293.34Q 341.55 300.31 340.36 307.22Q 340.27 307.75 338.3 321.06Q 337.3 327.8 333.27 342.67Q 330.48 353.01 326 363.61Q 316.75 385.56 308.39 399.67Q 304.94 405.5 298.25 415.44Q 293.4 422.66 286.92 430.38Q 266.06 455.23 239.53 474.52Q 238.21 475.47 228.14 482.31C 214.59 491.51 200.62 498.95 184.69 505.92Q 176.14 509.67 169.38 511.59C 165.34 512.74 162.76 514.23 159.29 515.31A 0.3 0.3 -35.58 0 0 159.2 515.84Z" fill="#ff0000"/></svg>',
                  size: 32,
                  color: cs.primary,
                ),
              ),
              Expanded(
                child: NavigationRail(
                  selectedIndex: navigationShell.currentIndex == 3
                      ? null
                      : navigationShell.currentIndex,
                  onDestinationSelected: (i) => navigationShell.goBranch(
                    i,
                    initialLocation: i == navigationShell.currentIndex,
                  ),
                  backgroundColor: Colors.transparent,
                  indicatorColor: cs.primaryContainer,
                  groupAlignment: 0.0,
                  destinations: [
                    ...navBarDestinations(context).map(
                      (d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ),
                    ),
                  ],
                  labelType: NavigationRailLabelType.all,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DockedActionItem(
                      icon: DockedDownloadIcon(activity: dockedDownloadActivity),
                      label: context.l10n.navDownloads,
                      isActive: navigationShell.currentIndex == 3,
                      onTap: () => navigationShell.goBranch(
                        3,
                        initialLocation: 3 == navigationShell.currentIndex,
                      ),
                      cs: cs,
                    ),

                    const SizedBox(height: 8),
                    _DockedActionItem(
                      icon: const Icon(Icons.settings_outlined),
                      label: 'Settings',
                      isActive: false,
                      onTap: () => context.push('/settings'),
                      cs: cs,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final barWidth = h.pick(
      spacious: 80.0,
      normal: 72.0,
      compact: 64.0,
      tight: 54.0,
      cramped: 56.0,
    );
    final hPad = isDocked
        ? 0.0
        : h.pick(
            spacious: 10.0,
            normal: 8.0,
            compact: 6.0,
            tight: 6.0,
            cramped: 4.0,
          );
    final vOuterPad = isDocked
        ? 0.0
        : h.pick(
            spacious: 24.0,
            normal: 20.0,
            compact: 16.0,
            tight: 10.0,
            cramped: 6.0,
          );
    final hOuterPad = isDocked
        ? 0.0
        : h.pick(
            spacious: 16.0,
            normal: 16.0,
            compact: 14.0,
            tight: 8.0,
            cramped: 6.0,
          );
    final gapBetween = h.pick(
      spacious: 14.0,
      normal: 12.0,
      compact: 10.0,
      tight: 8.0,
      cramped: 4.0,
    );

    final hideDownloadLabel = h.isBelowCompact;
    final hideNavLabels = h == HeightTier.cramped;
    final destinations = navBarDestinations(context);
    final itemsCol = Column(
      children: List.generate(destinations.length, (i) {
        final active = navigationShell.currentIndex == i;
        final themeData = NavBarThemeData.resolve(navBarStyle, cs, false);
        final activeItemRadius = themeData.itemRadius(barWidth);

        return Expanded(
          child: InkWell(
            onTap: () => navigationShell.goBranch(i),
            borderRadius: BorderRadius.circular(activeItemRadius),
            focusColor: cs.primary.withValues(alpha: 0.2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              decoration:
                  (active
                          ? themeData.activeItemDecoration
                          : themeData.inactiveItemDecoration)
                      .copyWith(
                        borderRadius: BorderRadius.circular(activeItemRadius),
                      ),
              child: _PillContent(
                icon: destinations[i].icon,
                label: destinations[i].label,
                active: active,
                themeData: themeData,
                heightTier: h,
                forceHideLabel: hideNavLabels,
              ),
            ),
          ),
        );
      }),
    );

    final downloadPill = _TallDownloadPillContent(
      cs: cs,
      heightTier: h,
      hideLabel: hideDownloadLabel,
      navBarStyle: navBarStyle,
      navigationShell: navigationShell,
      barWidth: barWidth,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: vOuterPad,
          horizontal: hOuterPad,
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: _SideBarContainer(
                width: barWidth,
                padding: hPad,
                navBarStyle: navBarStyle,
                cs: cs,
                child: itemsCol,
              ),
            ),
            SizedBox(height: gapBetween),
            Expanded(
              flex: 1,
              child: _SideBarContainer(
                width: barWidth,
                padding: hPad,
                navBarStyle: navBarStyle,
                cs: cs,
                child: downloadPill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SideNavAttachment extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const SideNavAttachment({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navBarProvider);
    if (navState.customBar != null) {
      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: navState.customBar!,
          ),
        ),
      );
    }

    final activeWidget = navState.topForBranch(navigationShell.currentIndex);

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: activeWidget ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _SideBarContainer extends StatelessWidget {
  final double width;
  final double padding;
  final Widget child;
  final NavBarStyle navBarStyle;
  final ColorScheme cs;

  const _SideBarContainer({
    required this.width,
    required this.padding,
    required this.child,
    required this.navBarStyle,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = NavBarThemeData.resolve(navBarStyle, cs, false);
    final barRadius = themeData.barRadius(width);

    final content = Container(
      width: width,
      padding: EdgeInsets.all(padding),
      decoration: themeData.barDecoration.copyWith(
        borderRadius: BorderRadius.circular(barRadius),
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(barRadius),
      child: themeData.blurSigma != null
          ? BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: themeData.blurSigma!,
                sigmaY: themeData.blurSigma!,
              ),
              child: content,
            )
          : content,
    );
  }
}

class _PillContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final NavBarThemeData themeData;
  final bool isDownload;
  final HeightTier heightTier;
  final bool forceHideLabel;

  const _PillContent({
    required this.icon,
    required this.label,
    required this.active,
    required this.themeData,
    required this.heightTier,
    this.isDownload = false,
    this.forceHideLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = heightTier.pick(
      spacious: 26.0,
      normal: 25.0,
      compact: 23.0,
      tight: 21.0,
      cramped: 20.0,
    );
    final labelSize = heightTier.pick(
      spacious: 14.0,
      normal: 14.0,
      compact: 13.0,
      tight: 12.0,
      cramped: 11.0,
    );
    final labelSpacing = heightTier.pick(
      spacious: 2.0,
      normal: 2.0,
      compact: 1.8,
      tight: 1.6,
      cramped: 1.4,
    );
    final labelTopPad = heightTier.pick(
      spacious: 14.0,
      normal: 12.0,
      compact: 10.0,
      tight: 7.0,
      cramped: 5.0,
    );

    final showLabel = !forceHideLabel && (active || isDownload);
    final locale = Localizations.localeOf(context);
    final isNonLatinOrRtl = Directionality.of(context) == TextDirection.rtl ||
        const {'ar', 'bn', 'yue', 'ja', 'hi'}.contains(locale.languageCode);

    final resolvedColor = active
        ? themeData.activeIconColor
        : (isDownload
              ? themeData.downloadIconColor
              : themeData.inactiveIconColor);
    final resolvedTextColor = active
        ? themeData.activeTextColor
        : themeData.inactiveIconColor;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: active ? themeData.activeScale : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: active || isDownload ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 250),
            child: Icon(icon, color: resolvedColor, size: iconSize),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: showLabel
                ? Padding(
                    padding: EdgeInsets.only(top: labelTopPad),
                    child: isNonLatinOrRtl
                        ? Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: labelSize * 0.85,
                              fontWeight: themeData.isMaterial3
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: resolvedTextColor,
                            ),
                          )
                        : RotatedBox(
                            quarterTurns: -1,
                            child: Text(
                              label.toUpperCase(),
                              style: TextStyle(
                                fontSize: labelSize,
                                letterSpacing: labelSpacing,
                                fontWeight: themeData.isMaterial3
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                color: resolvedTextColor,
                              ),
                            ),
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        if (themeData.showDotIndicator && active) ...[
          const SizedBox(height: 5),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: resolvedColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

class _TallDownloadPillContent extends ConsumerWidget {
  final ColorScheme cs;
  final HeightTier heightTier;
  final bool hideLabel;
  final NavBarStyle navBarStyle;
  final StatefulNavigationShell navigationShell;
  final double barWidth;

  const _TallDownloadPillContent({
    required this.cs,
    required this.heightTier,
    required this.hideLabel,
    required this.navBarStyle,
    required this.navigationShell,
    required this.barWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = navigationShell.currentIndex == 3;
    final count = DownloadActivity.fromTasks(
      ref.watch(downloadTasksProvider).value ?? [],
    ).count;

    final themeData = NavBarThemeData.resolve(navBarStyle, cs, active);
    final activeItemRadius = themeData.itemRadius(barWidth);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(activeItemRadius),
        focusColor: cs.primary.withValues(alpha: 0.2),
        onTap: () => navigationShell.goBranch(
          3,
          initialLocation: 3 == navigationShell.currentIndex,
        ),
        child: Badge(
          isLabelVisible: count > 0,
          backgroundColor: cs.primary,
          textColor: cs.onPrimary,
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text('$count', key: ValueKey(count)),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            decoration:
                (active
                        ? themeData.activeItemDecoration
                        : themeData.inactiveItemDecoration)
                    .copyWith(
                      borderRadius: BorderRadius.circular(
                        themeData.itemRadius(72.0),
                      ),
                    ),
            child: _PillContent(
              icon: Icons.download_outlined,
              label: context.l10n.navDownloads,
              active: active,
              isDownload: true,
              themeData: themeData,
              heightTier: heightTier,
              forceHideLabel: hideLabel,
            ),
          ),
        ),
      ),
    );
  }
}

class _DockedActionItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _DockedActionItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? cs.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
                child: icon,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
