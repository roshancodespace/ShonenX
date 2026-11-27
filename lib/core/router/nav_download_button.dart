import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:shonenx/core/router/nav_bar_theme.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/widgets/app_progress_indicator.dart';

class DownloadActivity {
  final int count;
  final double? progress;

  const DownloadActivity({required this.count, this.progress});

  static const DownloadActivity none = DownloadActivity(count: 0);

  factory DownloadActivity.fromTasks(Iterable<DownloadTask> tasks) {
    final activeTasks = tasks
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.pending,
        )
        .toList();
    final count = activeTasks.length;
    if (count == 0) return const DownloadActivity(count: 0);

    double? progress;
    final valid = activeTasks.where((t) => t.progress >= 0);
    if (valid.isNotEmpty) {
      progress =
          valid.map((t) => t.progress).reduce((a, b) => a + b) / valid.length;
    }
    return DownloadActivity(count: count, progress: progress);
  }
}

class NavDownloadButton extends StatelessWidget {
  final NavBarStyle navBarStyle;
  final ColorScheme colorScheme;
  final double size;
  final double iconSize;
  final double padding;
  final bool active;
  final DownloadActivity activity;
  final VoidCallback? onTap;

  const NavDownloadButton({
    super.key,
    required this.navBarStyle,
    required this.colorScheme,
    required this.size,
    required this.iconSize,
    required this.padding,
    required this.active,
    required this.activity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    final count = activity.count;
    final hasActive = count > 0;
    final progress = activity.progress;

    final themeData = NavBarThemeData.resolve(navBarStyle, cs, active);
    final barRadius = themeData.barRadius(size);
    final activeItemRadius = themeData.itemRadius(size - 2 * padding);

    Widget item = InkWell(
      onTap: onTap,
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
                          child: AppProgressIndicator(type: AppProgressType.circular, value: progress, strokeWidth: 2.5, color:
                                active &&
                                    themeData.isMaterial3 == false &&
                                    !themeData.showDotIndicator &&
                                    navBarStyle != NavBarStyle.frosted
                                ? cs.onPrimary
                                : cs.primary),
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

/// The download icon used by the docked NavigationBar and the desktop rail.
/// The caller supplies the activity instead of reading the provider directly.
class DockedDownloadIcon extends StatelessWidget {
  final DownloadActivity activity;

  const DockedDownloadIcon({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final count = activity.count;
    final hasActive = count > 0;
    final progress = activity.progress;

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
              child: AppProgressIndicator(type: AppProgressType.circular, value: progress, strokeWidth: 2, color: cs.primary),
            ),
          const Icon(Icons.download_outlined),
        ],
      ),
    );
  }
}
