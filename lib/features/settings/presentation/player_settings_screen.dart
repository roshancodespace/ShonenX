import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/domain/aniskip_prefs.dart';
import 'package:shonenx/features/player/providers/aniskip_prefs_provider.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/gesture_settings_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/subtitle_settings_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class PlayerSettingsScreen extends ConsumerWidget {
  const PlayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerPrefs = ref.watch(playerPrefsProvider);
    final aniskipPrefs = ref.watch(aniskipPrefsProvider);
    final aniskipPrefsNotifier = ref.read(aniskipPrefsProvider.notifier);
    final prefsNotifier = ref.read(playerPrefsProvider.notifier);

    return AppScaffold(
      title: 'Player',
      body: ListView(
        children: [
          SettingsSection(
            title: 'Aniskip',
            children: SkipType.values
                .map(
                  (s) => SettingsDropdownTile(
                    icon: _icon(s),
                    title: _capitalize(s.name),
                    value: aniskipPrefs.mode(s),
                    items: SkipMode.values
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(_capitalize(m.name)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        aniskipPrefsNotifier.setMode(s, value);
                      }
                    },
                  ),
                )
                .toList(),
          ),
          if (Platform.isAndroid)
            SettingsSegmentedTile<PlayerType>(
              title: 'Player type',
              segments: [
                ButtonSegment(value: PlayerType.mediakit, label: Text('MPV')),
                ButtonSegment(
                  value: PlayerType.betterplayer,
                  label: Text('Exoplayer'),
                ),
              ],
              selected: {playerPrefs.playerType},
              onSelectionChanged: (Set<PlayerType> selection) =>
                  prefsNotifier.changePlayer(selection.first),
            ),
          SettingsSection(
            title: 'Subtitles',
            children: [
              SettingsActionTile(
                icon: Icons.subtitles_rounded,
                title: 'Subtitle Preferences',
                subtitle: 'Customize subtitle appearance and rendering engine',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const SubtitleSettingsSheet(),
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'Gestures',
            children: [
              SettingsActionTile(
                icon: Icons.gesture_rounded,
                title: 'Gesture Area',
                subtitle: 'Customize active zones for volume and brightness',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    constraints: const BoxConstraints(maxWidth: 1200),
                    isScrollControlled: true,
                    builder: (context) => const GestureSettingsSheet(),
                  );
                },
              ),
            ],
          ),
          // if (prefs.playerType == PlayerType.mediakit)
          //   SettingsSection(
          //     title: 'Mediakit Config',
          //     children: [
          //       SettingsSwitchTile(
          //         icon: Icons.memory,
          //         title: 'HW Accleration',
          //         value: prefs.mediaKitConfig.enableHardwareAcceleration,
          //         onChanged: (value) => prefsNotifier.updateMediaKitConfig(
          //           prefs.mediaKitConfig.copyWith(
          //             enableHardwareAcceleration: value,
          //           ),
          //         ),
          //       ),
          //       SettingsSwitchTile(
          //         icon: Icons.warning_amber,
          //         title: 'Boost Volume',
          //         value: prefs.mediaKitConfig.boostVolume,
          //         onChanged: (value) => prefsNotifier.updateMediaKitConfig(
          //           prefs.mediaKitConfig.copyWith(boostVolume: value),
          //         ),
          //       ),
          //       SettingsSwitchTile(
          //         icon: Icons.network_check,
          //         title: 'Low Latency',
          //         value: prefs.mediaKitConfig.enableLowLatency,
          //         onChanged: (value) => prefsNotifier.updateMediaKitConfig(
          //           prefs.mediaKitConfig.copyWith(boostVolume: value),
          //         ),
          //       ),
          //       SettingsDropdownTile<AudioChannel>(
          //         icon: Icons.audiotrack_outlined,
          //         title: 'Audio Channel',
          //         value: prefs.mediaKitConfig.audioChannel,
          //         items: AudioChannel.values
          //             .map(
          //               (s) => DropdownMenuItem<AudioChannel>(
          //                 value: s,
          //                 child: Text(s.value),
          //               ),
          //             )
          //             .toList(),
          //         onChanged: (value) => prefsNotifier.updateMediaKitConfig(
          //           prefs.mediaKitConfig.copyWith(audioChannel: value),
          //         ),
          //       ),
          //     ],
          //   ),
        ],
      ),
    );
  }

  IconData _icon(SkipType type) {
    switch (type) {
      case SkipType.opening:
        return Icons.skip_next_outlined;
      case SkipType.ending:
        return Icons.skip_next_outlined;
      case SkipType.mixedOpening:
        return Icons.skip_next_outlined;
      case SkipType.mixedEnding:
        return Icons.skip_next_outlined;
      case SkipType.recap:
        return Icons.skip_next_outlined;
    }
  }

  String _capitalize(String str) {
    return str.replaceFirst(
      str.substring(0, 1),
      str.substring(0, 1).toUpperCase(),
    );
  }
}
