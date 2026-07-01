import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:fvp/fvp.dart';
import 'package:shonenx/features/player/providers/mdk_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/raw_config_override_sheet.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class MdkVideoPlayerSettings extends ConsumerWidget {
  final VideoPlayerController? controller;

  const MdkVideoPlayerSettings({super.key, this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mdkPrefs = ref.watch(mdkPrefsProvider);
    final notifier = ref.read(mdkPrefsProvider.notifier);

    return AppBottomSheet(
      title: 'MDK performance & buffer',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsDropdownTile<int>(
              icon: Icons.speed_rounded,
              title: 'Buffer capacity',
              value: mdkPrefs.bufferCapacityMs,
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
                DropdownMenuItem(
                  value: 60000,
                  child: Text('Max cache (60s buffer)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  notifier.updatePrefs(mdkPrefs.copyWith(bufferCapacityMs: value));
                  controller?.setBufferRange(
                    min: 1000,
                    max: value,
                    drop: mdkPrefs.dropFrames,
                  );
                }
              },
            ),
            SettingsDropdownTile<String>(
              icon: Icons.memory_outlined,
              title: 'Hardware decoder priority',
              value: mdkPrefs.decoderPriority,
              items: ['Auto', 'D3D11', 'NVDEC', 'FFmpeg']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  notifier.updatePrefs(mdkPrefs.copyWith(decoderPriority: value));
                  if (value == 'Auto') {
                    controller?.setVideoDecoders([]);
                  } else {
                    controller?.setVideoDecoders([value]);
                  }
                }
              },
            ),
            SettingsSwitchTile(
              icon: Icons.fast_forward_rounded,
              title: 'Fast hardware keyframe seek',
              value: mdkPrefs.enableFastSeek,
              onChanged: (value) {
                notifier.updatePrefs(mdkPrefs.copyWith(enableFastSeek: value));
              },
            ),
            SettingsSwitchTile(
              icon: Icons.sync_problem_rounded,
              title: 'Drop late frames on high load',
              value: mdkPrefs.dropFrames,
              onChanged: (value) {
                notifier.updatePrefs(mdkPrefs.copyWith(dropFrames: value));
                controller?.setBufferRange(
                  min: 1000,
                  max: mdkPrefs.bufferCapacityMs,
                  drop: value,
                );
              },
            ),
            SettingsActionTile(
              icon: Icons.code_rounded,
              title: 'Raw Configuration Overrides',
              subtitle: mdkPrefs.rawConfiguration.isEmpty
                  ? 'Caution: Inject raw MDK properties'
                  : 'Configured (${mdkPrefs.rawConfiguration.split("\n").length} overrides)',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => RawConfigOverrideSheet(
                    title: 'MDK Raw Configuration',
                    initialValue: mdkPrefs.rawConfiguration,
                    hintText: 'e.g.\navio.reconnect=1\navformat.fpsprobesize=0',
                    onSave: (val) => notifier.updatePrefs(
                      mdkPrefs.copyWith(rawConfiguration: val),
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
