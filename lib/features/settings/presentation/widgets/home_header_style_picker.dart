import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/features/discovery/presentation/widgets/header/home_header.dart';
import 'package:shonenx/features/settings/presentation/widgets/picker_sheet_shell.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

void showHomeHeaderStyleSheet(
  BuildContext context,
  WidgetRef ref,
  UiPrefsNotifier notifier,
  ThemeData theme,
) {
  final cs = theme.colorScheme;
  final l10n = context.l10n;

  AppBottomSheet.show(
    context: context,
    title: l10n.headerStyleTitle,
    child: UiSettingsSheetLayout(
      preview: Consumer(
        builder: (_, r, _) {
          final current = r.watch(
            uiPrefsProvider.select((s) => s.homeHeaderStyle),
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: HomeHeader(styleOverride: current, isPreview: true),
            ),
          );
        },
      ),
      optionsTitle: l10n.headerStylePreset,
      options: Consumer(
        builder: (_, r, _) {
          final current = r.watch(
            uiPrefsProvider.select((s) => s.homeHeaderStyle),
          );
          final options = HomeHeaderStyle.values
              .map(
                (style) => PickerOption(
                  icon: _homeHeaderStyleIcon(style),
                  title: style.displayName,
                  subtitle: _homeHeaderStyleDesc(context, style),
                  selected: current == style,
                  onTap: () => notifier.updateHomeHeaderStyle(style),
                ),
              )
              .toList();
          return PickerOptionsGrid(options: options, selectedColor: cs.primary);
        },
      ),
    ),
  );
}

String _homeHeaderStyleDesc(BuildContext context, HomeHeaderStyle style) {
  final l10n = context.l10n;
  return switch (style) {
    HomeHeaderStyle.classic => l10n.headerStyleClassicDesc,
    HomeHeaderStyle.minimal => l10n.headerStyleMinimalDesc,
    HomeHeaderStyle.material => l10n.headerStyleMaterialDesc,
    HomeHeaderStyle.prominent => l10n.headerStyleProminentDesc,
    HomeHeaderStyle.docked => l10n.headerStyleDockedDesc,
  };
}

IconData _homeHeaderStyleIcon(HomeHeaderStyle style) => switch (style) {
  HomeHeaderStyle.classic => Icons.view_headline_rounded,
  HomeHeaderStyle.minimal => Icons.density_small_rounded,
  HomeHeaderStyle.material => Icons.branding_watermark_outlined,
  HomeHeaderStyle.prominent => Icons.featured_play_list_rounded,
  HomeHeaderStyle.docked => Icons.tv_rounded,
};
