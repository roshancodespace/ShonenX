import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/features/settings/view_model/download_settings_notifier.dart';

class DownloadSettingsScreen extends ConsumerWidget {
  const DownloadSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(downloadSettingsProvider);
    final notifier = ref.read(downloadSettingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('Download Settings'),
        forceMaterialTransparency: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          SettingsSection(
            title: 'Storage',
            titleColor: colorScheme.primary,
            onTap: () {},
            children: [
              Consumer(
                builder: (context, ref, child) {
                  return ToggleableSettingsItem(
                    icon: Icon(Iconsax.folder_open, color: colorScheme.primary),
                    accent: colorScheme.primary,
                    title: 'Custom Download Path',
                    description: 'Use a custom directory for downloads',
                    value: settings.useCustomPath,
                    onChanged: (val) => notifier.toggleUseCustomPath(val),
                  );
                },
              ),
              if (settings.useCustomPath)
                NormalSettingsItem(
                  icon: Icon(Iconsax.folder, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  title: 'Select Path',
                  description:
                      settings.customDownloadPath ?? 'Tap to select...',
                  onTap: () async {
                    String? selectedDirectory = await FilePicker.platform
                        .getDirectoryPath();
                    if (selectedDirectory != null) {
                      notifier.setCustomPath(selectedDirectory);
                    }
                  },
                ),
              DropdownSettingsItem(
                icon: Icon(Iconsax.sort),
                accent: colorScheme.primary,
                title: 'Folder Structure',
                description: 'Organize downloaded files',
                value: settings.folderStructure,
                items: ['Anime/Episode', 'Anime', 'Flat']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) notifier.setFolderStructure(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          SettingsSection(
            title: 'Performance',
            titleColor: colorScheme.primary,
            onTap: () {},
            children: [
              SliderSettingsItem(
                accent: colorScheme.primary,
                title: 'Parallel Downloads (M3U8)',
                description:
                    'Concurrent segments: ${settings.parallelDownloads}',
                value: settings.parallelDownloads.toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                onChanged: (val) => notifier.setParallelDownloads(val.toInt()),
                icon: Icon(Iconsax.flash_1, color: colorScheme.primary),
              ),
              SliderSettingsItem(
                accent: colorScheme.primary,
                title: 'Speed Limit',
                description: settings.speedLimitKBps == 0
                    ? 'Unlimited'
                    : '${settings.speedLimitKBps} KB/s',
                value: settings.speedLimitKBps.toDouble(),
                min: 0,
                max: 10000,
                divisions: 100,
                onChanged: (val) => notifier.setSpeedLimit(val.toInt()),
                icon: Icon(Iconsax.timer_1, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SettingsSection(
            title: 'Network',
            titleColor: colorScheme.primary,
            onTap: () {},
            children: [
              ToggleableSettingsItem(
                icon: Icon(Iconsax.wifi, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Wi-Fi Only',
                description: 'Only download when connected to Wi-Fi',
                value: settings.wifiOnly,
                onChanged: (val) => notifier.toggleWifiOnly(val),
              ),
            ],
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
