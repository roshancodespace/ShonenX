import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class ReaderSettingsScreen extends StatelessWidget {
  const ReaderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.settingsReader,
      body: const ReaderSettingsContent(),
    );
  }
}

class ReaderSettingsContent extends ConsumerWidget {
  const ReaderSettingsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerPrefs = ref.watch(readerPrefsProvider);
    final prefsNotifier = ref.read(readerPrefsProvider.notifier);
    final l10n = context.l10n;

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 50),
      children: [
        SettingsSection(
          title: l10n.settingsDisplay,
          children: [
            SettingsSegmentedTile<ReaderBackgroundColor>(
              title: l10n.readerBackgroundColor,
              segments: const [
                ButtonSegment(
                  value: ReaderBackgroundColor.black,
                  label: Text('Black'),
                ),
                ButtonSegment(
                  value: ReaderBackgroundColor.darkGrey,
                  label: Text('Dark Grey'),
                ),
                ButtonSegment(
                  value: ReaderBackgroundColor.white,
                  label: Text('White'),
                ),
              ],
              selected: {readerPrefs.backgroundColor},
              onSelectionChanged: (Set<ReaderBackgroundColor> selection) =>
                  prefsNotifier.updateBackgroundColor(selection.first),
            ),
            SettingsDropdownTile<ReaderScaleType>(
              icon: Icons.aspect_ratio_outlined,
              title: l10n.readerZoom,
              value: readerPrefs.scaleType,
              items: ReaderScaleType.values
                  .map(
                    (s) =>
                        DropdownMenuItem(value: s, child: Text(s.displayName)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  prefsNotifier.updateScaleType(value);
                }
              },
            ),
          ],
        ),
        SettingsSection(
          title: l10n.readerMode,
          children: [
            SettingsDropdownTile<ReaderDirection>(
              icon: Icons.chrome_reader_mode_outlined,
              title: l10n.readerReadingDirection,
              value: readerPrefs.direction,
              items: ReaderDirection.values
                  .map(
                    (s) =>
                        DropdownMenuItem(value: s, child: Text(s.displayName)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  prefsNotifier.updateDirection(value);
                }
              },
            ),
            if (readerPrefs.direction != ReaderDirection.webtoon)
              SettingsDropdownTile<ReaderTransition>(
                icon: Icons.animation_outlined,
                title: 'Page Transition',
                value: readerPrefs.transition,
                items: ReaderTransition.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    prefsNotifier.updateTransition(value);
                  }
                },
              ),
          ],
        ),
        SettingsSection(
          title: 'Controls & Behavior',
          children: [
            SettingsSwitchTile(
              icon: Icons.info_outline_rounded,
              title: 'Mini Status Pill',
              subtitle: 'Show page number & progress when controls are hidden',
              value: readerPrefs.showMiniStatus,
              onChanged: (val) => prefsNotifier.updateShowMiniStatus(val),
            ),
            SettingsSwitchTile(
              icon: Icons.touch_app_outlined,
              title: 'Tap to Turn Pages',
              subtitle:
                  'Tap screen edges to turn pages, center to show controls',
              value: readerPrefs.tapToTurnPage,
              onChanged: (val) => prefsNotifier.updateTapToTurnPage(val),
            ),
            SettingsSwitchTile(
              icon: Icons.screen_lock_portrait_outlined,
              title: 'Keep Screen Awake',
              subtitle: 'Prevent display from sleeping while reading',
              value: readerPrefs.keepScreenOn,
              onChanged: (val) => prefsNotifier.updateKeepScreenOn(val),
            ),
          ],
        ),
      ],
    );
  }
}
