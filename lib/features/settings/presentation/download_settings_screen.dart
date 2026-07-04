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
                    if (directoryPath != null &&
                        directoryPath != prefs.downloadPath) {
                      if (context.mounted) {
                        _handleLocationChangeRequest(
                          context,
                          prefsNotifier,
                          prefs.downloadPath,
                          directoryPath,
                        );
                      }
                    }
                  },
                  trailing: FilledButton.icon(
                    icon: const Icon(Icons.restore_outlined, size: 18),
                    label: const Text('Reset'),
                    onPressed: () async {
                      final targetPath = await prefsNotifier
                          .getDefaultDownloadPath();
                      if (context.mounted) {
                        _handleLocationChangeRequest(
                          context,
                          prefsNotifier,
                          prefs.downloadPath,
                          targetPath,
                        );
                      }
                    },
                  ),
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
                SettingsActionTile(
                  icon: Icons.speed_outlined,
                  title: 'Concurrent Segments per Download',
                  subtitle:
                      'Parallel threads for stream segments: ${prefs.concurrentSegments}',
                  onTap: () {},
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 56,
                    right: 16,
                    bottom: 8,
                  ),
                  child: Slider(
                    value: prefs.concurrentSegments.toDouble(),
                    min: 1,
                    max: 16,
                    divisions: 15,
                    label: prefs.concurrentSegments.toString(),
                    onChanged: (val) {
                      prefsNotifier.setConcurrentSegments(val.toInt());
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
                if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) ...[
                  SettingsDropdownTile<RemuxerPreference>(
                    icon: Icons.auto_fix_high_outlined,
                    title: 'HLS Remuxer Preference',
                    value: prefs.remuxerPreference,
                    items: RemuxerPreference.values
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        prefsNotifier.setRemuxerPreference(value);
                      }
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

  Future<void> _handleLocationChangeRequest(
    BuildContext context,
    DownloadPrefsNotifier notifier,
    String currentPath,
    String targetPath,
  ) async {
    if (targetPath == currentPath) return;

    final files = await notifier.getMigratableFiles();
    if (!context.mounted) return;

    if (files.isEmpty) {
      await notifier.migrateStorageToPath(targetPath, moveFiles: false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download location changed successfully.'),
          ),
        );
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FileReviewSheet(
        files: files,
        oldPath: currentPath,
        targetPath: targetPath,
        notifier: notifier,
      ),
    );
  }
}

class _FileReviewSheet extends StatefulWidget {
  final List<File> files;
  final String oldPath;
  final String targetPath;
  final DownloadPrefsNotifier notifier;

  const _FileReviewSheet({
    required this.files,
    required this.oldPath,
    required this.targetPath,
    required this.notifier,
  });

  @override
  State<_FileReviewSheet> createState() => _FileReviewSheetState();
}

class _FileReviewSheetState extends State<_FileReviewSheet> {
  late Map<File, bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {};
    for (final file in widget.files) {
      final name = file.path.split('/').last;
      final isAnimeLikely = RegExp(
        r'(Episode|Ep\s*\d+|- \d+\.mp4|- \d+\.mkv)',
        caseSensitive: false,
      ).hasMatch(name);
      _selected[file] = isAnimeLikely;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selectedCount = _selected.values.where((v) => v).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.rule_folder_outlined,
                          color: cs.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Review Files to Move',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Moving to:\n${widget.targetPath}',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$selectedCount of ${widget.files.length} selected',
                          style: textTheme.labelLarge,
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => setState(
                                () => _selected.updateAll((_, __) => true),
                              ),
                              child: const Text('Select All'),
                            ),
                            TextButton(
                              onPressed: () => setState(
                                () => _selected.updateAll((_, __) => false),
                              ),
                              child: const Text('None'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.files.length,
                  itemBuilder: (context, index) {
                    final file = widget.files[index];
                    String displayPath = file.path;
                    if (widget.oldPath.isNotEmpty &&
                        file.path.startsWith(widget.oldPath)) {
                      displayPath = file.path.substring(widget.oldPath.length);
                      if (displayPath.startsWith('/')) {
                        displayPath = displayPath.substring(1);
                      }
                    } else {
                      displayPath = file.path.split('/').last;
                    }

                    return CheckboxListTile(
                      value: _selected[file] ?? false,
                      onChanged: (val) =>
                          setState(() => _selected[file] = val ?? false),
                      title: Text(
                        displayPath.split('/').last,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: displayPath.contains('/')
                          ? Text(
                              displayPath,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: selectedCount == 0
                          ? null
                          : () async {
                              Navigator.pop(context);
                              final toMove = _selected.entries
                                  .where((e) => e.value)
                                  .map((e) => e.key)
                                  .toList();
                              final count = await widget.notifier
                                  .migrateSelectedFiles(
                                    widget.targetPath,
                                    toMove,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Moved $count files and updated location.',
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.drive_file_move_outlined),
                      label: Text(
                        'Move Selected ($selectedCount) & Change Location',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await widget.notifier.migrateStorageToPath(
                          widget.targetPath,
                          moveFiles: false,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Changed location without moving files.',
                              ),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Change Location Only (Don\'t Move Any)',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
