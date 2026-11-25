import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

void showSheetPhysicsSheet(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  AppBottomSheet.show(
    context: context,
    title: l10n.uiSettingsSheetPhysicsTitle,
    titleIcon: Icons.animation_rounded,
    child: Consumer(
      builder: (sheetContext, r, _) {
        final prefs = r.watch(uiPrefsProvider);
        final notifier = r.read(uiPrefsProvider.notifier);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsSegmentedTile<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(l10n.uiSettingsSheetPhysicsHammer),
                    icon: const Icon(Icons.gavel_rounded),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(l10n.uiSettingsSheetPhysicsSlideUp),
                    icon: const Icon(Icons.swipe_up_rounded),
                  ),
                ],
                selected: {prefs.sheetPhysics},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    notifier.setSheetPhysics(set.first);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ),
  );
}
