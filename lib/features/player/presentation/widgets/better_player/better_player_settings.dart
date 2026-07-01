import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/providers/exo_player_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class BetterPlayerSettings extends ConsumerWidget {
  final BetterPlayerController? controller;

  const BetterPlayerSettings({super.key, this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exoPrefs = ref.watch(exoPlayerPrefsProvider);
    final notifier = ref.read(exoPlayerPrefsProvider.notifier);

    return AppBottomSheet(
      title: 'ExoPlayer performance & buffer',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsSwitchTile(
              icon: Icons.cached_rounded,
              title: 'Enable stream caching',
              value: exoPrefs.useCache,
              onChanged: (value) {
                notifier.updatePrefs(exoPrefs.copyWith(useCache: value));
              },
            ),
            SettingsDropdownTile<int>(
              icon: Icons.speed_rounded,
              title: 'Buffer capacity',
              value: exoPrefs.bufferCapacityMs,
              items: const [
                DropdownMenuItem(
                  value: 5000,
                  child: Text('Fast start (5s buffer)'),
                ),
                DropdownMenuItem(
                  value: 15000,
                  child: Text('Balanced (15s buffer)'),
                ),
                DropdownMenuItem(
                  value: 30000,
                  child: Text('Deep buffer (30s anti-stutter)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  notifier.updatePrefs(exoPrefs.copyWith(bufferCapacityMs: value));
                }
              },
            ),
            SettingsSwitchTile(
              icon: Icons.memory_rounded,
              title: 'Hardware accelerated decoding',
              value: exoPrefs.hwAcceleration,
              onChanged: (value) {
                notifier.updatePrefs(exoPrefs.copyWith(hwAcceleration: value));
              },
            ),
          ],
        ),
      ),
    );
  }
}
