import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fvp/fvp.dart';
import 'package:video_player/video_player.dart';
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
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;

    return AppBottomSheet(
      title: 'Video Player & Backend Settings',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDesktop)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withAlpha(128),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(128),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.desktop_windows_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'On Desktop (Windows, Linux, macOS), FVP Engine (MDK High-Performance) is automatically used as the Video Player backend for optimal codec support and hardware acceleration.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SettingsDropdownTile<String>(
                icon: Icons.layers_rounded,
                title: 'Playback Backend',
                value: mdkPrefs.backend,
                items: const [
                  DropdownMenuItem(
                    value: 'default',
                    child: Text('Default OS Engine (ExoPlayer/AVPlayer/MF)'),
                  ),
                  DropdownMenuItem(
                    value: 'fvp',
                    child: Text('FVP Engine (MDK High-Performance)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    notifier.updatePrefs(mdkPrefs.copyWith(backend: value));
                  }
                },
              ),
            if (!isDesktop && mdkPrefs.backend == 'default')
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withAlpha(128),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withAlpha(128),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Using the native OS video rendering engine. Switch to FVP Engine above to unlock custom buffer capacities, hardware decoder selection, and fast keyframe seeking.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isDesktop || mdkPrefs.backend == 'fvp') ...[
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
                    notifier.updatePrefs(
                      mdkPrefs.copyWith(bufferCapacityMs: value),
                    );
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
                    notifier.updatePrefs(
                      mdkPrefs.copyWith(decoderPriority: value),
                    );
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
                  notifier.updatePrefs(
                    mdkPrefs.copyWith(enableFastSeek: value),
                  );
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
                      hintText:
                          'e.g.\navio.reconnect=1\navformat.fpsprobesize=0',
                      onSave: (val) => notifier.updatePrefs(
                        mdkPrefs.copyWith(rawConfiguration: val),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
