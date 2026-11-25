import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/core/router/bottom_nav_bar.dart';
import 'package:shonenx/core/router/nav_bar_destinations.dart';
import 'package:shonenx/core/router/nav_download_button.dart';
import 'package:shonenx/features/settings/presentation/widgets/picker_sheet_shell.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

void showNavBarStyleSheet(
  BuildContext context,
  WidgetRef ref,
  UiPrefsNotifier notifier,
  ThemeData theme,
) {
  final cs = theme.colorScheme;
  final l10n = context.l10n;

  AppBottomSheet.show(
    context: context,
    title: l10n.uiSettingsNavBarTitle,
    child: UiSettingsSheetLayout(
      preview: Consumer(
        builder: (_, r, _) {
          final current = r.watch(uiPrefsProvider.select((s) => s.navBarStyle));
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _buildNavBarPreviewWidget(context, current),
          );
        },
      ),
      optionsTitle: l10n.navBarStylePreset,
      options: Consumer(
        builder: (_, r, _) {
          final current = r.watch(uiPrefsProvider.select((s) => s.navBarStyle));
          final options = NavBarStyle.values
              .map(
                (style) => PickerOption(
                  icon: _navBarStyleIcon(style),
                  title: style.displayName,
                  subtitle: _navBarStyleDesc(context, style),
                  selected: current == style,
                  onTap: () => notifier.updateNavBarStyle(style),
                ),
              )
              .toList();
          return PickerOptionsGrid(options: options, selectedColor: cs.primary);
        },
      ),
    ),
  );
}

Widget _buildNavBarPreviewWidget(BuildContext context, NavBarStyle style) {
  if (style == NavBarStyle.docked) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: DockedBottomNavBar(
        destinations: navBarDestinations(context),
        currentIndex: 0,
        onSelect: null,
        download: DownloadActivity.none,
        downloadLabel: context.l10n.navDownloads,
      ),
    );
  }

  return BottomNavBarView(
    navBarStyle: style,
    currentIndex: 0,
    destinations: navBarDestinations(context),
    onSelect: null,
    download: DownloadActivity.none,
    metrics: NavBarMetrics.preview,
  );
}

String _navBarStyleDesc(BuildContext context, NavBarStyle style) {
  final l10n = context.l10n;
  return switch (style) {
    NavBarStyle.classic => l10n.navBarClassicDesc,
    NavBarStyle.minimal => l10n.navBarMinimalDesc,
    NavBarStyle.frosted => l10n.navBarFrostedDesc,
    NavBarStyle.material => l10n.navBarMaterialDesc,
    NavBarStyle.docked => l10n.navBarDockedDesc,
  };
}

IconData _navBarStyleIcon(NavBarStyle style) => switch (style) {
  NavBarStyle.classic => Icons.layers_outlined,
  NavBarStyle.minimal => Icons.more_horiz_rounded,
  NavBarStyle.frosted => Icons.blur_on_rounded,
  NavBarStyle.material => Icons.android_rounded,
  NavBarStyle.docked => Icons.dock_outlined,
};
