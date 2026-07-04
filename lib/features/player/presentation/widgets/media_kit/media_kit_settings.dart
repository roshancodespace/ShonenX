import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/domain/media_kit_prefs.dart';
import 'package:shonenx/features/player/providers/media_kit_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/raw_config_override_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class MediaKitSettings extends ConsumerWidget {
  const MediaKitSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(mediaKitPrefsProvider);
    final prefsNotifier = ref.read(mediaKitPrefsProvider.notifier);

    return AppBottomSheet(
      title: 'MediaKit preferences',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsSwitchTile(
              icon: Icons.video_settings_outlined,
              title: 'Enable hardware acceleration',
              value: prefs.enableHardwareAcceleration,
              onChanged: (value) => prefsNotifier.updatePrefs(
                prefs.copyWith(enableHardwareAcceleration: value),
              ),
            ),
            SettingsDropdownTile<String>(
              icon: Icons.memory_outlined,
              title: 'Hardware Decoder',
              value: prefs.hwdec,
              items: const [
                DropdownMenuItem(
                  value: 'auto-copy',
                  child: Text('Auto Copy (Recommended)'),
                ),
                DropdownMenuItem(value: 'auto-safe', child: Text('Auto Safe')),
                DropdownMenuItem(
                  value: 'auto',
                  child: Text('Auto (Best Performance)'),
                ),
                DropdownMenuItem(
                  value: 'd3d11va-copy',
                  child: Text('DirectX 11 Copy'),
                ),
                DropdownMenuItem(
                  value: 'dxva2-copy',
                  child: Text('DirectX Legacy Copy'),
                ),
                DropdownMenuItem(value: 'no', child: Text('Software Decoding')),
              ],
              onChanged: (value) {
                if (value != null) {
                  prefsNotifier.updatePrefs(prefs.copyWith(hwdec: value));
                }
              },
            ),
            SettingsDropdownTile<String>(
              icon: Icons.tv_rounded,
              title: 'Video output driver (vo)',
              value: prefs.vo,
              items: const [
                DropdownMenuItem(
                  value: 'auto',
                  child: Text('auto (Platform default)'),
                ),
                DropdownMenuItem(
                  value: 'libmpv',
                  child: Text('libmpv (Desktop default)'),
                ),
                DropdownMenuItem(
                  value: 'gpu',
                  child: Text('gpu (Android default)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  prefsNotifier.updatePrefs(prefs.copyWith(vo: value));
                }
              },
            ),
            SettingsSwitchTile(
              icon: Icons.timeline,
              title: 'Enable low latency',
              value: prefs.enableLowLatency,
              onChanged: (value) => prefsNotifier.updatePrefs(
                prefs.copyWith(enableLowLatency: value),
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
            SettingsDropdownTile<MediaKitAudioChannel>(
              icon: Icons.audiotrack,
              title: 'Audio channel',
              value: prefs.audioChannel,
              items: MediaKitAudioChannel.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.value)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  prefsNotifier.updatePrefs(
                    prefs.copyWith(audioChannel: value),
                  );
                }
              },
            ),
            SettingsSwitchTile(
              icon: Icons.volume_up_outlined,
              title: 'Boost volume',
              value: prefs.boostVolume,
              onChanged: (value) =>
                  prefsNotifier.updatePrefs(prefs.copyWith(boostVolume: value)),
            ),
            SettingsActionTile(
              icon: Icons.code_rounded,
              title: 'Raw Configuration Overrides',
              subtitle: prefs.rawConfiguration.isEmpty
                  ? 'Caution: Inject raw MPV options'
                  : 'Configured (${prefs.rawConfiguration.split("\n").length} overrides)',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => RawConfigOverrideSheet(
                    title: 'MPV Raw Configuration',
                    initialValue: prefs.rawConfiguration,
                    hintText: 'e.g.\ndemuxer-max-bytes=100M\ncache=yes',
                    onSave: (val) => prefsNotifier.updatePrefs(
                      prefs.copyWith(rawConfiguration: val),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
