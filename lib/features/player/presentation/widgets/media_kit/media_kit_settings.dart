import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/domain/media_kit_prefs.dart';
import 'package:shonenx/features/player/providers/media_kit_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/raw_config_override_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';

class MediaKitAdvancedSettings extends ConsumerWidget {
  const MediaKitAdvancedSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(mediaKitPrefsProvider);
    final notifier = ref.read(mediaKitPrefsProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsSection(
          title: 'Decoder',
          children: [
            SettingsSwitchTile(
              icon: Icons.video_settings_outlined,
              title: 'Hardware acceleration',
              value: prefs.enableHardwareAcceleration,
              onChanged: (v) => notifier.updatePrefs(
                prefs.copyWith(enableHardwareAcceleration: v),
              ),
            ),
            SettingsDropdownTile<String>(
              icon: Icons.memory_outlined,
              title: 'Decoder Mode',
              value: prefs.hwdec,
              items: const [
                DropdownMenuItem(
                  value: 'auto',
                  child: Text('HW+ Decoder (Performance)'),
                ),
                DropdownMenuItem(
                  value: 'auto-copy',
                  child: Text('HW Decoder (Standard)'),
                ),
                DropdownMenuItem(
                  value: 'auto-safe',
                  child: Text('HW Decoder (Safe Mode)'),
                ),
                DropdownMenuItem(
                  value: 'no',
                  child: Text('SW Decoder (Software)'),
                ),
              ],
              onChanged: (v) {
                if (v != null) notifier.updatePrefs(prefs.copyWith(hwdec: v));
              },
            ),
            SettingsDropdownTile<String>(
              icon: Icons.tv_rounded,
              title: 'Video output',
              value: prefs.vo,
              items: const [
                DropdownMenuItem(
                  value: 'auto',
                  child: Text('Auto (Platform default)'),
                ),
                DropdownMenuItem(
                  value: 'libmpv',
                  child: Text('libmpv (Desktop)'),
                ),
                DropdownMenuItem(value: 'gpu', child: Text('GPU (Android)')),
              ],
              onChanged: (v) {
                if (v != null) notifier.updatePrefs(prefs.copyWith(vo: v));
              },
            ),
          ],
        ),
        SettingsSection(
          title: 'Buffering',
          children: [
            SettingsDropdownTile<Duration>(
              icon: Icons.speed_rounded,
              title: 'Min pre-buffer',
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
              onChanged: (v) {
                if (v != null) {
                  notifier.updatePrefs(prefs.copyWith(minBuffer: v));
                }
              },
            ),
            SettingsDropdownTile<Duration>(
              icon: Icons.all_inclusive_rounded,
              title: 'Max buffer',
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
              onChanged: (v) {
                if (v != null) {
                  notifier.updatePrefs(prefs.copyWith(maxBuffer: v));
                }
              },
            ),
            SettingsSwitchTile(
              icon: Icons.timeline,
              title: 'Low latency mode',
              value: prefs.enableLowLatency,
              onChanged: (v) =>
                  notifier.updatePrefs(prefs.copyWith(enableLowLatency: v)),
            ),
          ],
        ),
        SettingsSection(
          title: 'Audio',
          children: [
            SettingsDropdownTile<MediaKitAudioChannel>(
              icon: Icons.audiotrack,
              title: 'Audio channel',
              value: prefs.audioChannel,
              items: MediaKitAudioChannel.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  notifier.updatePrefs(prefs.copyWith(audioChannel: v));
                }
              },
            ),
            SettingsSwitchTile(
              icon: Icons.volume_up_outlined,
              title: 'Boost volume',
              value: prefs.boostVolume,
              onChanged: (v) =>
                  notifier.updatePrefs(prefs.copyWith(boostVolume: v)),
            ),
            SettingsDropdownTile<MediaKitAudioNormalizePreset>(
              icon: Icons.graphic_eq_rounded,
              title: 'Volume Stabilization',
              value: prefs.audioNormalizePreset,
              items: MediaKitAudioNormalizePreset.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  notifier.updatePrefs(prefs.copyWith(audioNormalizePreset: v));
                }
              },
            ),
          ],
        ),
        SettingsSection(
          title: 'Subtitle Engine',
          children: [
            SettingsSwitchTile(
              icon: Icons.closed_caption_outlined,
              title: 'Native libass rendering',
              value: prefs.libassEnabled,
              onChanged: (v) =>
                  notifier.updatePrefs(prefs.copyWith(libassEnabled: v)),
            ),
          ],
        ),
        SettingsSection(
          title: 'Raw',
          children: [
            SettingsActionTile(
              icon: Icons.code_rounded,
              title: 'MPV Configuration Overrides',
              subtitle: prefs.rawConfiguration.isEmpty
                  ? 'Inject raw MPV options'
                  : '${prefs.rawConfiguration.split("\n").length} overrides active',
              onTap: () {
                RawConfigOverrideSheet.show(
                  context: context,
                  title: 'MPV Raw Configuration',
                  initialValue: prefs.rawConfiguration,
                  hintText: 'e.g.\ndemuxer-max-bytes=100M\ncache=yes',
                  onSave: (val) => notifier.updatePrefs(
                    prefs.copyWith(rawConfiguration: val),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
