import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/svg_icon.dart';

class DownloadSettingsScreen extends ConsumerWidget {
  const DownloadSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(downloadPrefsProvider);
    final prefsNotifier = ref.read(downloadPrefsProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Downloads',
      body: prefsAsync.when(
        data: (prefs) => ListView(
          children: [
            SettingsSection(
              title: 'Storage',
              children: [
                SettingsActionTile(
                  icon: Icons.folder_outlined,
                  title: 'Download Location',
                  subtitle: prefs.downloadPath,
                  onTap: () async {
                    final String? directoryPath = await FilePicker.platform
                        .getDirectoryPath();
                    if (directoryPath != null) {
                      prefsNotifier.setDownloadPath(directoryPath);
                    }
                  },
                ),
                SettingsSwitchTile(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Auto-Delete Watched Episodes',
                  subtitle:
                      'Frees up space automatically when an episode is marked as completed',
                  value: prefs.autoDeleteWatched,
                  onChanged: (val) {
                    prefsNotifier.setAutoDeleteWatched(val);
                  },
                ),
              ],
            ),
            SettingsSection(
              title: 'Organization',
              children: [
                SettingsSwitchTile(
                  icon: Icons.create_new_folder_outlined,
                  title: 'Create Anime Folders',
                  subtitle:
                      'Groups episodes inside a folder named after the anime title',
                  value: prefs.createSubfolders,
                  onChanged: (val) {
                    prefsNotifier.setCreateSubfolders(val);
                  },
                ),
                SettingsDropdownTile<FileNameFormat>(
                  icon: Icons.title_outlined,
                  title: 'File Name Format',
                  value: prefs.fileNameFormat,
                  items: FileNameFormat.values
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      prefsNotifier.setFileNameFormat(value);
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 72,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Text(
                    '↳ Preview: ${_getPreviewFormat(prefs.fileNameFormat)}',
                    style: TextStyle(
                      color: colors.primary,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
                SettingsDropdownTile<DuplicateAction>(
                  icon: Icons.file_copy_outlined,
                  title: 'If File Already Exists',
                  value: prefs.duplicateAction,
                  items: DuplicateAction.values
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      prefsNotifier.setDuplicateAction(value);
                    }
                  },
                ),
              ],
            ),
            SettingsSection(
              title: 'Network & Behavior',
              children: [
                SettingsSwitchTile(
                  icon: Icons.wifi_outlined,
                  title: 'Download over Wi-Fi Only',
                  subtitle: 'Pause downloads when connected to mobile data',
                  value: prefs.wifiOnly,
                  onChanged: (val) {
                    prefsNotifier.setWifiOnly(val);
                  },
                ),
                SettingsActionTile(
                  icon: Icons.layers_outlined,
                  title: 'Concurrent Downloads',
                  subtitle:
                      'Maximum active downloads: ${prefs.concurrentDownloads}',
                  onTap: () {},
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 56,
                    right: 16,
                    bottom: 8,
                  ),
                  child: Slider(
                    value: prefs.concurrentDownloads.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    label: prefs.concurrentDownloads.toString(),
                    onChanged: (val) {
                      prefsNotifier.setConcurrentDownloads(val.toInt());
                    },
                  ),
                ),
                if (Platform.isAndroid) ...[
                  SettingsSwitchTile(
                    leading: SvgIcon(
                      color: colors.primary,
                      size: 30,
                      '''<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
                        <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" d="M10.78 37.272h23.98c13.018 0 10.842-19.588-2.216-15.235c0-10.882-19.588-10.882-19.588 2.176C2.074 22.037 2.074 37.272 10.78 37.272" stroke-width="2.2" />
                        <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" d="M27.273 27.477L24 30.75l-3.273-3.273M24 30.75v-9.998m-5.758 12h11.516" stroke-width="2.2" />
                      </svg>''',
                    ),
                    title: 'Use External Downloader (1DM)',
                    subtitle:
                        'Send links to external apps instead of the built-in engine',
                    value: prefs.useOneDM,
                    onChanged: (val) {
                      prefsNotifier.setUseOneDM(val);
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  String _getPreviewFormat(FileNameFormat format) {
    switch (format) {
      case FileNameFormat.titleAndEpisode:
        return 'Jujutsu Kaisen - Ep 12.mp4';
      case FileNameFormat.episodeOnly:
        return 'Ep 12.mp4';
    }
  }
}
