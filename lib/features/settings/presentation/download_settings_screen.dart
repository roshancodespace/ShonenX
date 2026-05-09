import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

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
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
