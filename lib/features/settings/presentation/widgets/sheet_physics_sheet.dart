import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

void showSheetPhysicsSheet(BuildContext context, WidgetRef ref) {
  AppBottomSheet.show(
    context: context,
    title: 'Sheet Physics',
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
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Hammer'),
                    icon: Icon(Icons.gavel_rounded),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Slide Up'),
                    icon: Icon(Icons.swipe_up_rounded),
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
