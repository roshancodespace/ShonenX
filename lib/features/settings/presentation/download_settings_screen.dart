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
              ],
            ),
            SettingsSection(
              title: 'Formatting',
              children: [
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
              ],
            ),
            if (Platform.isAndroid) ...[
              SettingsSection(
                title: 'Add-ons',
                children: [
                  SettingsSwitchTile(
                    leading: SvgIcon(
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                      '''<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
                        <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" d="M10.78 37.272h23.98c13.018 0 10.842-19.588-2.216-15.235c0-10.882-19.588-10.882-19.588 2.176C2.074 22.037 2.074 37.272 10.78 37.272" stroke-width="2.2" />
                        <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" d="M27.273 27.477L24 30.75l-3.273-3.273M24 30.75v-9.998m-5.758 12h11.516" stroke-width="2.2" />
                      </svg>''',
                    ),
                    title: 'Use 1DM for Downloads',
                    subtitle: 'Hand off downloads to the 1DM app if installed',
                    value: prefs.useOneDM,
                    onChanged: (val) {
                      prefsNotifier.setUseOneDM(val);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
