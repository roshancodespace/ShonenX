import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/router/bottom_nav_bar.dart';
import 'package:shonenx/core/router/nav_deep_links.dart';
import 'package:shonenx/core/router/nav_startup_tasks.dart';
import 'package:shonenx/core/router/side_nav_bar.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
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

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar>
    with NavDeepLinkHandling<ScaffoldWithNavBar> {
  @override
  void initState() {
    super.initState();
    initNavDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runNavStartupTasks(ref, isMounted: () => mounted);
      checkPendingDeepLink();
    });
  }

  @override
  void didUpdateWidget(covariant ScaffoldWithNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    checkPendingDeepLink();
  }

  @override
  void dispose() {
    disposeNavDeepLinks();
    super.dispose();
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
                    SideNavBar(navigationShell: widget.navigationShell),
                    Expanded(
                      child: Stack(
                        children: [
                          widget.navigationShell,
                          SideNavAttachment(
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
                    BottomNavBar(navigationShell: widget.navigationShell),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.navigationShell,
                    BottomNavBar(navigationShell: widget.navigationShell),
                  ],
                ),
        );
      },
    );
  }
}

