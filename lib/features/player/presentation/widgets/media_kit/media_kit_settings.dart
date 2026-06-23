import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/domain/media_kit_prefs.dart';
import 'package:shonenx/features/player/providers/media_kit_prefs_provider.dart';
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
              icon: Icons.volume_up_outlined,
              title: 'Boost volume',
              value: prefs.boostVolume,
              onChanged: (value) =>
                  prefsNotifier.updatePrefs(prefs.copyWith(boostVolume: value)),
            ),
            SettingsDropdownTile<MediaKitAudioChannel>(
              icon: Icons.audiotrack,
              title: 'Audio channel',
              value: prefs.audioChannel,
              items: MediaKitAudioChannel.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => prefsNotifier.updatePrefs(
                prefs.copyWith(audioChannel: value!),
              ),
            ),
            SettingsSwitchTile(
              icon: Icons.video_settings_outlined,
              title: 'Enable hardware acceleration',
              value: prefs.enableHardwareAcceleration,
              onChanged: (value) => prefsNotifier.updatePrefs(
                prefs.copyWith(enableHardwareAcceleration: value),
              ),
            ),
            SettingsSwitchTile(
              icon: Icons.timeline,
              title: 'Enable low latency',
              value: prefs.enableLowLatency,
              onChanged: (value) => prefsNotifier.updatePrefs(
                prefs.copyWith(enableLowLatency: value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
