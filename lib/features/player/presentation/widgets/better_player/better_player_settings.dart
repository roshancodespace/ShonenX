import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/providers/better_player_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';

class BetterPlayerSettings extends ConsumerWidget {
  const BetterPlayerSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(betterPlayerPrefsProvider);
    final prefsNotifier = ref.read(betterPlayerPrefsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Better Player Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsSwitchTile(
            icon: Icons.subtitles,
            title: 'Use ASMS Subtitles',
            subtitle: 'Automatically parse HLS/DASH subtitles',
            value: prefs.useAsmsSubtitles,
            onChanged: (val) => prefsNotifier.updatePrefs(
              prefs.copyWith(useAsmsSubtitles: val),
            ),
          ),
          SettingsSwitchTile(
            icon: Icons.audiotrack,
            title: 'Use ASMS Audio Tracks',
            subtitle: 'Automatically parse HLS/DASH audio tracks',
            value: prefs.useAsmsAudioTracks,
            onChanged: (val) => prefsNotifier.updatePrefs(
              prefs.copyWith(useAsmsAudioTracks: val),
            ),
          ),
          SettingsSwitchTile(
            icon: Icons.sd_storage,
            title: 'Enable Video Cache',
            subtitle: 'Cache video chunks to storage to save bandwidth',
            value: prefs.enableCache,
            onChanged: (val) =>
                prefsNotifier.updatePrefs(prefs.copyWith(enableCache: val)),
          ),
          if (prefs.enableCache)
            SettingsDropdownTile<int>(
              icon: Icons.memory,
              title: 'Max Cache Size',
              value: prefs.maxCacheSizeMb,
              items: const [
                DropdownMenuItem(value: 50, child: Text('50 MB')),
                DropdownMenuItem(value: 100, child: Text('100 MB')),
                DropdownMenuItem(value: 200, child: Text('200 MB')),
                DropdownMenuItem(value: 500, child: Text('500 MB')),
                DropdownMenuItem(value: 1024, child: Text('1 GB')),
              ],
              onChanged: (val) {
                if (val != null) {
                  prefsNotifier.updatePrefs(
                    prefs.copyWith(maxCacheSizeMb: val),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
