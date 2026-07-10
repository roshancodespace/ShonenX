import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class ReaderSettingsScreen extends StatelessWidget {
  const ReaderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(title: 'Reader', body: const ReaderSettingsContent());
  }
}

class ReaderSettingsContent extends ConsumerWidget {
  const ReaderSettingsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerPrefs = ref.watch(readerPrefsProvider);
    final prefsNotifier = ref.read(readerPrefsProvider.notifier);

    return ListView(
      shrinkWrap: true,
      children: [
        SettingsSection(
          title: 'Display',
          children: [
            SettingsSegmentedTile<ReaderBackgroundColor>(
              title: 'Background Color',
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
              title: 'Image Scale',
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
          title: 'Reading Mode',
          children: [
            SettingsDropdownTile<ReaderDirection>(
              icon: Icons.chrome_reader_mode_outlined,
              title: 'Reading Direction',
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
