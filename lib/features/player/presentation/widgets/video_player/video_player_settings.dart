import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/providers/video_player_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class VideoPlayerSettings extends ConsumerWidget {
  const VideoPlayerSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(videoPlayerPrefsProvider);
    final prefsNotifier = ref.read(videoPlayerPrefsProvider.notifier);

    return AppBottomSheet(
      title: 'ExoPlayer preferences',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsSwitchTile(
              icon: Icons.video_settings_outlined,
              title: 'Enable hardware acceleration',
              subtitle:
                  'Use GPU decoding. Disable if experiencing green screen, artifacting, or freezes',
              value: prefs.enableHardwareAcceleration,
              onChanged: (value) => prefsNotifier.updatePrefs(
                prefs.copyWith(enableHardwareAcceleration: value),
              ),
            ),
            SettingsDropdownTile<Duration>(
              icon: Icons.speed_rounded,
              title: 'Minimum pre-buffer',
              value: prefs.minBuffer,
              items: const [
                DropdownMenuItem(
                  value: Duration(seconds: 3),
                  child: Text('3 seconds'),
                ),
                DropdownMenuItem(
                  value: Duration(seconds: 5),
                  child: Text('5 seconds'),
                ),
                DropdownMenuItem(
                  value: Duration(seconds: 10),
                  child: Text('10 seconds'),
                ),
                DropdownMenuItem(
                  value: Duration(seconds: 15),
                  child: Text('15 seconds'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  prefsNotifier.updatePrefs(prefs.copyWith(minBuffer: value));
                }
              },
            ),
            SettingsDropdownTile<Duration>(
              icon: Icons.all_inclusive_rounded,
              title: 'Maximum buffer capacity',
              value: prefs.maxBuffer,
              items: const [
                DropdownMenuItem(
                  value: Duration(seconds: 15),
                  child: Text('15 seconds'),
                ),
                DropdownMenuItem(
                  value: Duration(seconds: 30),
                  child: Text('30 seconds'),
                ),
                DropdownMenuItem(
                  value: Duration(seconds: 60),
                  child: Text('60 seconds'),
                ),
                DropdownMenuItem(
                  value: Duration(seconds: 120),
                  child: Text('120 seconds'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  prefsNotifier.updatePrefs(prefs.copyWith(maxBuffer: value));
                }
              },
            ),
            SettingsSwitchTile(
              icon: Icons.timeline,
              title: 'Enable low latency',
              subtitle:
                  'Optimize HLS/DASH stream fetching. Turn off if buffering occurs frequently',
              value: prefs.enableLowLatency,
              onChanged: (value) => prefsNotifier.updatePrefs(
                prefs.copyWith(enableLowLatency: value),
              ),
            ),
            SettingsDropdownTile<String>(
              icon: Icons.security_rounded,
              title: 'Network User-Agent Override',
              value: prefs.userAgent,
              items: const [
                DropdownMenuItem(
                  value: 'Default',
                  child: Text('Default (Stream provided)'),
                ),
                DropdownMenuItem(
                  value: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                  child: Text('Desktop Chrome (Windows)'),
                ),
                DropdownMenuItem(
                  value: 'Mozilla/5.0 (Linux; Android 14)',
                  child: Text('Mobile Android'),
                ),
                DropdownMenuItem(
                  value: 'ExoPlayer/ShonenX',
                  child: Text('ExoPlayer ShonenX'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  prefsNotifier.updatePrefs(prefs.copyWith(userAgent: value));
                }
              },
            ),
            SettingsSwitchTile(
              icon: Icons.play_circle_outline,
              title: 'Allow background playback',
              subtitle:
                  'Continue playing audio when app is minimized or screen is off',
              value: prefs.allowBackgroundPlayback,
              onChanged: (value) => prefsNotifier.updatePrefs(
                prefs.copyWith(allowBackgroundPlayback: value),
              ),
            ),
            SettingsSwitchTile(
              icon: Icons.headset_rounded,
              title: 'Mix audio with others',
              subtitle:
                  'Play video audio concurrently with other music players or apps',
              value: prefs.mixWithOthers,
              onChanged: (value) => prefsNotifier.updatePrefs(
                prefs.copyWith(mixWithOthers: value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
