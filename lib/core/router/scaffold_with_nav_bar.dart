import 'dart:ui';

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/remote_config/providers/remote_config_provider.dart';
import 'package:shonenx/core/remote_config/ui/remote_config_ui.dart';
import 'package:shonenx/core/updates/services/update_service.dart';
import 'package:shonenx/core/updates/ui/update_ui.dart';
import 'package:shonenx/core/router/app_router.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/providers/navbar_action_provider.dart';
import 'package:shonenx/app_init.dart';

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
          context.push('/settings');
          context.push(pendingLink);
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

      context.push('/settings');
      context.push(target);
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
          return;
        }
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
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        switch (event.logicalKey) {
          case LogicalKeyboardKey.digit1:
            widget.navigationShell.goBranch(0);
          case LogicalKeyboardKey.digit2:
            widget.navigationShell.goBranch(1);
          case LogicalKeyboardKey.digit3:
            widget.navigationShell.goBranch(2);
          case LogicalKeyboardKey.digit4:
            context.push('/downloads');
        }
      },
      child: ResponsiveHandler(
        breakpoints: _navBreakpoints,
        builder: (context, r) {
          return AppScaffold(
            extendBody: true,
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
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.navigationShell,
                      _BottomNavBar(navigationShell: widget.navigationShell),
                    ],
                  ),
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

class _BottomNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _BottomNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final cs = Theme.of(context).colorScheme;
    final navState = ref.watch(navBarProvider);

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

    final uiScale = GlobalUI.uiScaleFactor.clamp(0.85, 1.25);
    final barHeight = (r.isPhone ? 68.0 : 80.0) * uiScale;
    final iconSize = (r.isPhone ? 25.0 : 28.0) * uiScale;
    final fontSize = r.isPhone ? 14.5 : 16.0;
    final hPad = (r.isPhone ? 6.0 : 10.5) * uiScale;
    final itemRadius = GlobalUI.uiRoundness;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: r.height * 0.018),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        height: barHeight,
                        padding: EdgeInsets.all(hPad),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(
                            GlobalUI.uiRoundness,
                          ),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_destinations.length, (i) {
                            final active = navigationShell.currentIndex == i;
                            return InkWell(
                              onTap: () => navigationShell.goBranch(i),
                              borderRadius: BorderRadius.circular(itemRadius),
                              focusColor: cs.primary.withValues(alpha: 0.2),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                height: double.maxFinite,
                                padding: EdgeInsets.symmetric(
                                  horizontal: active ? 18 : 14,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? cs.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    itemRadius,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedScale(
                                      scale: active ? 1.15 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOutBack,
                                      child: AnimatedOpacity(
                                        opacity: active ? 1.0 : 0.55,
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        child: Icon(
                                          _destinations[i].icon,
                                          color: active
                                              ? cs.onPrimary
                                              : cs.onSurfaceVariant,
                                          size: iconSize,
                                        ),
                                      ),
                                    ),
                                    ClipRect(
                                      child: AnimatedSize(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
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
    final hasActive = count > 0;

    double? progress;
    if (hasActive) {
      final valid = activeTasks.where((t) => t.progress >= 0);
      if (valid.isNotEmpty) {
        progress =
            valid.map((t) => t.progress).reduce((a, b) => a + b) / valid.length;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Badge(
              isLabelVisible: hasActive,
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
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  AnimatedScale(
                    scale: hasActive ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.download_outlined,
                      color: colorScheme.onSurface,
                      size: iconSize,
                    ),
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
    final r = context.responsive;
    final cs = Theme.of(context).colorScheme;
    final h = r.heightTier;

    final barWidth = h.pick(
      spacious: 72.0,
      normal: 72.0,
      compact: 70.0,
      tight: 68.0,
      cramped: 66.0,
    );
    final hPad = h.pick(
      spacious: 8.0,
      normal: 8.0,
      compact: 6.0,
      tight: 5.0,
      cramped: 4.0,
    );
    final vOuterPad = h.pick(
      spacious: 16.0,
      normal: 16.0,
      compact: 14.0,
      tight: 8.0,
      cramped: 6.0,
    );
    final hOuterPad = h.pick(
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
              child: _GlassPillContainer(
                width: barWidth,
                padding: hPad,
                child: Column(
                  children: List.generate(_destinations.length, (i) {
                    final active = navigationShell.currentIndex == i;
                    return Expanded(
                      child: InkWell(
                        onTap: () => navigationShell.goBranch(i),
                        borderRadius: BorderRadius.circular(
                          GlobalUI.uiRoundness,
                        ),
                        focusColor: cs.primary.withValues(alpha: 0.2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: active ? cs.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              GlobalUI.uiRoundness,
                            ),
                          ),
                          child: _PillContent(
                            icon: _destinations[i].icon,
                            label: _destinations[i].label,
                            active: active,
                            cs: cs,
                            heightTier: h,
                            forceHideLabel: hideNavLabels,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SizedBox(height: gapBetween),
            Expanded(
              flex: 1,
              child: _GlassPillContainer(
                width: barWidth,
                padding: hPad,
                child: _TallDownloadPillContent(
                  cs: cs,
                  heightTier: h,
                  hideLabel: hideDownloadLabel,
                ),
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
      borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: width,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
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
  final HeightTier heightTier;
  final bool forceHideLabel;

  const _PillContent({
    required this.icon,
    required this.label,
    required this.active,
    required this.cs,
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: active ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: active || isDownload ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              icon,
              color: active || isDownload
                  ? (isDownload ? cs.onSurface : cs.onPrimary)
                  : cs.onSurfaceVariant,
              size: iconSize,
            ),
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
  final HeightTier heightTier;
  final bool hideLabel;

  const _TallDownloadPillContent({
    required this.cs,
    required this.heightTier,
    required this.hideLabel,
  });

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
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        onTap: () => context.push('/downloads'),
        child: Badge(
          isLabelVisible: count > 0,
          backgroundColor: cs.primary,
          textColor: cs.onPrimary,
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text('$count', key: ValueKey(count)),
          ),
          child: _PillContent(
            icon: Icons.download_outlined,
            label: 'DOWNLOAD',
            active: false,
            isDownload: true,
            cs: cs,
            heightTier: heightTier,
            forceHideLabel: hideLabel,
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
