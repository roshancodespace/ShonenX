import 'dart:ui';

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/router/nav_bar_theme.dart';

import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/remote_config/providers/remote_config_provider.dart';
import 'package:shonenx/core/remote_config/ui/remote_config_ui.dart';
import 'package:shonenx/features/updates/services/update_service.dart';
import 'package:shonenx/features/updates/ui/update_ui.dart';
import 'package:shonenx/core/router/app_router.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/providers/navbar_action_provider.dart';
import 'package:shonenx/app_init.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/features/extensions/presentation/widgets/runtime_setup_sheet.dart';
import 'package:shonenx/features/extensions/providers/runtime_update_provider.dart';
import 'package:shonenx/features/tv_mode/presentation/tv_shell.dart';

final _navBreakpoints = ResponsiveBreakpoints.defaults.copyWith(
  heightNormal: 750,
  heightCompact: 600,
  heightTight: 500,
);

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRemoteAnnouncements();
      _checkPendingDeepLink();
    });
  }

  @override
  void didUpdateWidget(covariant ScaffoldWithNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkPendingDeepLink();
  }

  void _checkPendingDeepLink() {
    final pendingLink = AppInit.pendingDeepLink;
    if (pendingLink != null) {
      AppInit.pendingDeepLink = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushSettings();
          context.pushPendingLink(pendingLink);
        }
      });
    }
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    if (host == 'anilist.co' ||
        host == 'myanimelist.net' ||
        host == 'kitsu.io' ||
        host == 'kitsu.app') {
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final mediaTypeStr = pathSegments[0].toLowerCase();
        final id = pathSegments[1];
        MediaType? mediaType;
        if (mediaTypeStr == 'anime') mediaType = MediaType.ANIME;
        if (mediaTypeStr == 'manga') mediaType = MediaType.MANGA;

        if (mediaType != null) {
          String providerId = 'anilist';
          if (host == 'myanimelist.net') providerId = 'myanimelist';
          if (host == 'kitsu.io' || host == 'kitsu.app') providerId = 'kitsu';

          final media = UnifiedMedia(
            id: id,
            title: MediaTitle(english: 'Loading...'),
            type: mediaType,
            providerId: providerId,
          );

          context.pushDetails(mediaType: mediaType, media: media);
          return;
        }
      }
    }

    if ((scheme == 'aniyomi' ||
            scheme == 'tachiyomi' ||
            scheme == 'mangayomi' ||
            scheme.contains('cloudstream') ||
            scheme == 'kotatsu' ||
            scheme == 'sora' ||
            scheme == 'shonenx') &&
        (host == 'add-repo' ||
            host == 'add-repository' ||
            scheme == 'cloudstreamrepo' ||
            uri.queryParameters.containsKey('url'))) {
      String? url = uri.queryParameters['url'];
      String? managerId;
      String? type;

      if (scheme == 'aniyomi') {
        managerId = 'aniyomi';
        type = 'anime';
      } else if (scheme == 'tachiyomi') {
        managerId = 'aniyomi';
        type = 'manga';
      } else if (scheme == 'mangayomi') {
        managerId = 'mangayomi';
      } else if (scheme.contains('cloudstream')) {
        managerId = 'cloudstream';
        if (url == null &&
            host.isNotEmpty &&
            host != 'add-repo' &&
            host != 'add-repository') {
          url = uri.toString().replaceFirst(
            RegExp(
              r'^cloudstreamrepo://|^cloudstream://',
              caseSensitive: false,
            ),
            '',
          );
          if (!url.startsWith('http://') && !url.startsWith('https://')) {
            url = 'https://$url';
          }
        }
      } else if (scheme == 'kotatsu') {
        managerId = 'kotatsu';
        type = 'manga';
      } else if (scheme == 'sora') {
        managerId = 'sora';
        type = 'novel';
      } else if (scheme == 'shonenx' && host == 'add-repo') {
        managerId = uri.queryParameters['manager'] ?? 'aniyomi';
        type = uri.queryParameters['type'];
      }

      final targetUri = Uri(
        path: '/settings/extensions',
        queryParameters: {
          if (url != null && url.isNotEmpty && url != '()') 'autoAddUrl': url,
          if (managerId != null) 'autoAddManager': managerId,
          if (type != null) 'autoAddType': type,
        },
      );
      final target = targetUri.toString();

      try {
        final currentUri = GoRouterState.of(context).uri;
        if (currentUri.path == '/settings/extensions' &&
            currentUri.queryParameters['autoAddUrl'] == url) {
          return;
        }
      } catch (_) {}

      context.pushSettings();
      context.pushPendingLink(target);
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkRemoteAnnouncements() async {
    final config = await ref.read(remoteConfigStateProvider.future);
    if (config != null && !config.applicationEnabled) return;
    if (!mounted) return;

    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;

    // 1. Check GitHub Release Updates
    try {
      final updatePrefs = ref.read(updatePrefsProvider);
      if (updatePrefs.autoCheckOnStartup) {
        final updateService = ref.read(updateServiceProvider);
        final release = await updateService.checkForUpdate();
        if (release != null && navContext.mounted) {
          await UpdateUI.showReleaseUpdateSheet(
            navContext,
            release: release,
            onDismiss: () => ref
                .read(updatePrefsProvider.notifier)
                .setLastDismissedReleaseId(release.id),
            onDownload: () => ref
                .read(updatePrefsProvider.notifier)
                .setLastSeenReleaseId(release.id),
          );
        }
      }
    } catch (_) {}

    if (!mounted || !navContext.mounted) return;

    // 1.5 Check Runtime Update
    try {
      final updateVersion = await ref.read(runtimeUpdateProvider.future);
      if (updateVersion != null && navContext.mounted) {
        await showRuntimeSetupSheet(navContext, ref);
      }
    } catch (_) {}

    if (!mounted || !navContext.mounted) return;

    // 2. Check Announcements
    final service = ref.read(remoteConfigServiceProvider);
    final announcement = service.getActiveAppAnnouncement();
    if (announcement != null) {
      await RemoteConfigUI.showAnnouncementSheet(
        navContext,
        announcement: announcement,
      );
      await service.markAnnouncementAsSeen(announcement.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useNewUi = ref.watch(uiPrefsProvider.select((p) => p.useNewUi));
    if (useNewUi) {
      return TvShell(navigationShell: widget.navigationShell);
    }

    final navBarStyle = ref.watch(uiPrefsProvider.select((p) => p.navBarStyle));
    final isDocked = navBarStyle == NavBarStyle.docked;

    return ResponsiveHandler(
      breakpoints: _navBreakpoints,
      builder: (context, r) {
        return AppScaffold(
          extendBody: !isDocked,
          body: r.isDesktop || r.isTabletLandscape
              ? Row(
                  children: [
                    _SideNavBar(navigationShell: widget.navigationShell),
                    Expanded(
                      child: Stack(
                        children: [
                          widget.navigationShell,
                          _SideNavAttachment(
                            navigationShell: widget.navigationShell,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : isDocked
              ? Column(
                  children: [
                    Expanded(child: widget.navigationShell),
                    _BottomNavBar(navigationShell: widget.navigationShell),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.navigationShell,
                    _BottomNavBar(navigationShell: widget.navigationShell),
                  ],
                ),
        );
      },
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

class _BottomNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _BottomNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final cs = Theme.of(context).colorScheme;
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

    Widget navBarWidget;

    if (isDocked) {
      navBarWidget = NavigationBar(
        height: 72.0,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.primaryContainer,
        destinations: [
          ..._destinations.map(
            (d) => NavigationDestination(icon: Icon(d.icon), label: d.label),
          ),
          const NavigationDestination(
            icon: _DockedDownloadIcon(),
            label: 'Downloads',
          ),
        ],
      );
    } else {
      final uiScale = GlobalUI.uiScaleFactor.clamp(0.85, 1.25);
      final double barHeight =
          (navBarStyle == NavBarStyle.minimal
              ? 54.0
              : (r.isPhone ? 68.0 : 80.0)) *
          uiScale;
      final iconSize = (r.isPhone ? 25.0 : 28.0) * uiScale;
      final fontSize = r.isPhone ? 14.5 : 16.0;
      final hPad = (r.isPhone ? 6.0 : 10.5) * uiScale;

      final vPad = hPad;

      final themeData = NavBarThemeData.resolve(navBarStyle, cs, false, false);
      final barRadius = themeData.barRadius(barHeight);
      final activeItemRadius = themeData.itemRadius(barHeight - 2 * vPad);

      final contentWidget = Container(
        height: barHeight,
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: themeData.barDecoration.copyWith(
          borderRadius: BorderRadius.circular(barRadius),
        ),
        child: _buildItemsRow(
          context,
          cs,
          iconSize,
          fontSize,
          activeItemRadius,
          navBarStyle,
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

      navBarWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(barRadius),
            child: innerContent,
          ),
          SizedBox(width: hPad + 4),
          _DownloadButton(
            colorScheme: cs,
            size: barHeight,
            iconSize: iconSize,
            padding: hPad,
            navBarStyle: navBarStyle,
            navigationShell: navigationShell,
          ),
        ],
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

  Widget _buildItemsRow(
    BuildContext context,
    ColorScheme cs,
    double iconSize,
    double fontSize,
    double itemRadius,
    NavBarStyle navBarStyle,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(_destinations.length, (i) {
        final active = navigationShell.currentIndex == i;
        final themeData = NavBarThemeData.resolve(
          navBarStyle,
          cs,
          active,
          false,
        );

        Widget item = InkWell(
          onTap: () => navigationShell.goBranch(i),
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
                          _destinations[i].icon,
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
                                  _destinations[i].label,
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

class _DownloadButton extends ConsumerWidget {
  final ColorScheme colorScheme;
  final double size;
  final double iconSize;
  final double padding;
  final NavBarStyle navBarStyle;
  final StatefulNavigationShell navigationShell;

  const _DownloadButton({
    required this.colorScheme,
    required this.size,
    required this.iconSize,
    required this.padding,
    required this.navBarStyle,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = colorScheme;
    final active = navigationShell.currentIndex == 3;
    final tasks = ref.watch(downloadTasksProvider).value ?? [];
    final activeTasks = tasks
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.pending,
        )
        .toList();
    final count = activeTasks.length;
    final hasActive = count > 0;

    double? progress;
    if (hasActive) {
      final valid = activeTasks.where((t) => t.progress >= 0);
      if (valid.isNotEmpty) {
        progress =
            valid.map((t) => t.progress).reduce((a, b) => a + b) / valid.length;
      }
    }

    final themeData = NavBarThemeData.resolve(navBarStyle, cs, false, active);
    final barRadius = themeData.barRadius(size);
    final activeItemRadius = themeData.itemRadius(size - 2 * padding);

    Widget item = InkWell(
      onTap: () => navigationShell.goBranch(
        3,
        initialLocation: 3 == navigationShell.currentIndex,
      ),
      borderRadius: BorderRadius.circular(activeItemRadius),
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
                .copyWith(
                  borderRadius: BorderRadius.circular(activeItemRadius),
                ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(
                  isLabelVisible: hasActive,
                  backgroundColor: cs.primary,
                  textColor: cs.onPrimary,
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text('$count', key: ValueKey(count)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        opacity: hasActive ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: SizedBox(
                          width: iconSize + 8,
                          height: iconSize + 8,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2.5,
                            color:
                                active &&
                                    themeData.isMaterial3 == false &&
                                    !themeData.showDotIndicator &&
                                    navBarStyle != NavBarStyle.frosted
                                ? cs.onPrimary
                                : cs.primary,
                          ),
                        ),
                      ),
                      AnimatedScale(
                        scale: active ? themeData.activeScale : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity: active ? 1.0 : 0.55,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.download_outlined,
                            color: active
                                ? themeData.activeIconColor
                                : themeData.inactiveIconColor,
                            size: iconSize,
                          ),
                        ),
                      ),
                    ],
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

    final contentWidget = Container(
      height: size,
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
      decoration: themeData.barDecoration.copyWith(
        borderRadius: BorderRadius.circular(barRadius),
      ),
      child: item,
    );

    if (themeData.blurSigma != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(barRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: themeData.blurSigma!,
            sigmaY: themeData.blurSigma!,
          ),
          child: contentWidget,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(barRadius),
      child: contentWidget,
    );
  }
}

class _SideNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _SideNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final cs = Theme.of(context).colorScheme;
    final h = r.heightTier;
    final uiPrefs = ref.watch(uiPrefsProvider);
    final navBarStyle = uiPrefs.navBarStyle;

    final isDocked = navBarStyle == NavBarStyle.docked;

    if (isDocked) {
      return SafeArea(
        child: Container(
          width: 80, // Material standard side rail width
          color: cs.surfaceContainer,
          child: Column(
            children: [
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
                  groupAlignment: 0.0, // Center alignment
                  destinations: [
                    ..._destinations.map(
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
                child: InkWell(
                  onTap: () => navigationShell.goBranch(
                    3,
                    initialLocation: 3 == navigationShell.currentIndex,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: navigationShell.currentIndex == 3
                                ? cs.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const _DockedDownloadIcon(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Downloads',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: navigationShell.currentIndex == 3
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final barWidth = h.pick(
      spacious: 90.0,
      normal: 82.0,
      compact: 72.0,
      tight: 64.0,
      cramped: 56.0,
    );
    final hPad = isDocked
        ? 0.0
        : h.pick(
            spacious: 12.0,
            normal: 10.0,
            compact: 8.0,
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
    final itemsCol = Column(
      children: List.generate(_destinations.length, (i) {
        final active = navigationShell.currentIndex == i;
        final themeData = NavBarThemeData.resolve(
          navBarStyle,
          cs,
          active,
          false,
        );
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
                icon: _destinations[i].icon,
                label: _destinations[i].label,
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
    final themeData = NavBarThemeData.resolve(navBarStyle, cs, false, false);
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
                    child: RotatedBox(
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
    final tasks = ref.watch(downloadTasksProvider).value ?? [];
    final count = tasks
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.pending,
        )
        .length;

    final themeData = NavBarThemeData.resolve(navBarStyle, cs, false, active);
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
              label: 'DOWNLOAD',
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

class _SideNavAttachment extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _SideNavAttachment({required this.navigationShell});

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

class _DockedDownloadIcon extends ConsumerWidget {
  const _DockedDownloadIcon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tasks = ref.watch(downloadTasksProvider).value ?? [];
    final activeTasks = tasks
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.pending,
        )
        .toList();
    final count = activeTasks.length;
    final hasActive = count > 0;

    double? progress;
    if (hasActive) {
      final valid = activeTasks.where((t) => t.progress >= 0);
      if (valid.isNotEmpty) {
        progress =
            valid.map((t) => t.progress).reduce((a, b) => a + b) / valid.length;
      }
    }

    return Badge(
      isLabelVisible: hasActive,
      backgroundColor: cs.primary,
      textColor: cs.onPrimary,
      label: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text('$count', key: ValueKey(count)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasActive)
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
          const Icon(Icons.download_outlined),
        ],
      ),
    );
  }
}
