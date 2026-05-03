import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class UiSettingsScreen extends ConsumerWidget {
  const UiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiPrefs = ref.watch(uiPrefsProvider);
    final uiPrefsNotifier = ref.read(uiPrefsProvider.notifier);

    return AppScaffold(
      title: 'UI',
      body: ListView(
        children: [
          SettingsDropdownTile<MediaCardStyle>(
            icon: Icons.view_compact,
            title: 'Card Style',
            value: uiPrefs.cardStyle,
            items: MediaCardStyle.values
                .map(
                  (s) => DropdownMenuItem<MediaCardStyle>(
                    value: s,
                    child: Text(s.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) => uiPrefsNotifier.updateCardStyle(value!),
          ),
          SettingsDropdownTile<ContinueWatchingStyle>(
            icon: Icons.view_compact,
            title: 'Continue Card Style',
            value: uiPrefs.continueWatchingStyle,
            items: ContinueWatchingStyle.values
                .map(
                  (s) => DropdownMenuItem<ContinueWatchingStyle>(
                    value: s,
                    child: Text(s.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                uiPrefsNotifier.updateContinueWatchingStyle(value!),
          ),
        ],
      ),
    );
  }
}
