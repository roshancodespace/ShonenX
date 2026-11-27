import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/core/services/one_dm_service.dart';
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/svg_icon.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/shared/widgets/app_progress_indicator.dart';

class DownloadSettingsScreen extends ConsumerWidget {
  const DownloadSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(downloadPrefsProvider);
    final prefsNotifier = ref.read(downloadPrefsProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      title: context.l10n.settingsDownloads,
      body: prefsAsync.when(
        data: (prefs) => ListView(
          padding: const EdgeInsets.only(bottom: 50),
          children: [
            SettingsSection(
              title: context.l10n.settingsStorage,
              children: [
                _DisableWhen(
                  disabled: prefs.useOneDM,
                  child: SettingsActionTile(
                    icon: Icons.folder_outlined,
                    title: context.l10n.settingsLocation,
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
                      label: Text(context.l10n.commonReset),
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
                ),
              ],
            ),
            SettingsSection(
              title: context.l10n.downloadOrganizationSection,
              children: [
                _DisableWhen(
                  disabled: prefs.useOneDM,
                  child: SettingsSwitchTile(
                    icon: Icons.create_new_folder_outlined,
                    title: context.l10n.downloadCreateSubfolders,
                    subtitle: context.l10n.downloadCreateSubfoldersSubtitle,
                    value: prefs.createSubfolders,
                    onChanged: (val) {
                      prefsNotifier.setCreateSubfolders(val);
                    },
                  ),
                ),
                _DisableWhen(
                  disabled: prefs.useOneDM,
                  child: SettingsSwitchTile(
                    icon: Icons.folder_copy_outlined,
                    title: 'Separate Anime & Manga Folders',
                    subtitle: 'Save under Anime/ and Manga/ inside root path',
                    value: prefs.separateMediaFolders,
                    onChanged: (val) {
                      prefsNotifier.setSeparateMediaFolders(val);
                    },
                  ),
                ),
                _DisableWhen(
                  disabled: prefs.useOneDM,
                  child: SettingsDropdownTile<FileNameFormat>(
                    icon: Icons.title_outlined,
                    title: context.l10n.downloadFileNameFormat,
                    subtitle: context.l10n.downloadPreviewFormat(
                      _getPreviewFormat(prefs.fileNameFormat),
                    ),
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
                ),
              ],
            ),
            SettingsSection(
              title: context.l10n.downloadNetworkSection,
              children: [
                _DisableWhen(
                  disabled: prefs.useOneDM,
                  child: SettingsSwitchTile(
                    icon: Icons.wifi_outlined,
                    title: context.l10n.downloadWifiOnly,
                    subtitle: context.l10n.downloadWifiOnlySubtitle,
                    value: prefs.wifiOnly,
                    onChanged: (val) {
                      prefsNotifier.setWifiOnly(val);
                    },
                  ),
                ),
                if (Platform.isAndroid) ...[
                  Builder(
                    builder: (context) {
                      final isInstalledAsync = ref.watch(
                        isOneDMInstalledProvider,
                      );
                      final isInstalled = isInstalledAsync.value ?? false;
                      final svgIcon = SvgIcon(
                        color: colors.primary,
                        size: 30,
                        '''<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
                          <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" d="M10.78 37.272h23.98c13.018 0 10.842-19.588-2.216-15.235c0-10.882-19.588-10.882-19.588 2.176C2.074 22.037 2.074 37.272 10.78 37.272" stroke-width="2.2" />
                          <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" d="M27.273 27.477L24 30.75l-3.273-3.273M24 30.75v-9.998m-5.758 12h11.516" stroke-width="2.2" />
                        </svg>''',
                      );

                      if (isInstalled) {
                        return SettingsSwitchTile(
                          leading: svgIcon,
                          title: context.l10n.downloadUseOneDm,
                          subtitle: context.l10n.downloadUseOneDmSubtitle,
                          value: prefs.useOneDM,
                          onChanged: (val) {
                            prefsNotifier.setUseOneDM(val);
                          },
                        );
                      } else {
                        return SettingsActionTile(
                          leading: Opacity(opacity: 0.5, child: svgIcon),
                          title: context.l10n.downloadUseOneDm,
                          subtitle: context.l10n.downloadOneDmNotInstalled,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                ),
                                tooltip: context.l10n.downloadWhatIsOneDm,
                                onPressed: () {
                                  AppDialog.show(
                                    context: context,
                                    title: context.l10n.downloadAboutOneDmTitle,
                                    child: Text(
                                      context.l10n.downloadAboutOneDmBody,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(context.l10n.commonClose),
                                      ),
                                      FilledButton.icon(
                                        icon: const Icon(
                                          Icons.get_app_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          context.l10n.downloadGetOnPlayStore,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          OneDMService.instance
                                              .launchPlayStore();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              FilledButton.tonalIcon(
                                icon: const Icon(
                                  Icons.download_rounded,
                                  size: 16,
                                ),
                                label: Text(context.l10n.addonsActionInstall),
                                onPressed: () =>
                                    OneDMService.instance.launchPlayStore(),
                              ),
                            ],
                          ),
                          onTap: () => OneDMService.instance.launchPlayStore(),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
            SettingsSection(
              title: context.l10n.downloadPerformanceSection,
              children: [
                _DisableWhen(
                  disabled: prefs.useOneDM,
                  child: SettingsSliderTile(
                    icon: Icons.layers_outlined,
                    title: context.l10n.downloadMaxQueue,
                    subtitle: context.l10n.downloadMaxQueueSubtitle,
                    value: prefs.concurrentDownloads.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: prefs.concurrentDownloads.toString(),
                    onChanged: (val) {
                      prefsNotifier.setConcurrentDownloads(val.toInt());
                    },
                  ),
                ),
                _DisableWhen(
                  disabled: prefs.useOneDM,
                  child: SettingsSliderTile(
                    icon: Icons.speed_outlined,
                    title: context.l10n.downloadMaxSegments,
                    subtitle: context.l10n.downloadMaxSegmentsSubtitle,
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
                if (Platform.isLinux ||
                    Platform.isWindows ||
                    Platform.isMacOS) ...[
                  SettingsDropdownTile<RemuxerPreference>(
                    icon: Icons.auto_fix_high_outlined,
                    title: context.l10n.downloadRemuxerPref,
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
            SettingsSection(
              title: 'Manga Downloads',
              children: [
                SettingsDropdownTile<MangaDownloadFormat>(
                  icon: Icons.menu_book_outlined,
                  title: 'Manga Storage Format',
                  subtitle: prefs.mangaFormat == MangaDownloadFormat.cbz
                      ? 'Single compressed .cbz archive per chapter'
                      : 'Folder of page images per chapter',
                  value: prefs.mangaFormat,
                  items: MangaDownloadFormat.values
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      prefsNotifier.setMangaFormat(value);
                    }
                  },
                ),
                SettingsSliderTile(
                  icon: Icons.burst_mode_outlined,
                  title: 'Concurrent Page Downloads',
                  subtitle: 'Pages downloaded simultaneously per chapter',
                  value: prefs.concurrentMangaPages.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: prefs.concurrentMangaPages.toString(),
                  onChanged: (val) {
                    prefsNotifier.setConcurrentMangaPages(val.toInt());
                  },
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: AppProgressIndicator(type: AppProgressType.circular)),
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
          SnackBar(content: Text(context.l10n.downloadLocationChanged)),
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

class _DisableWhen extends StatelessWidget {
  final bool disabled;
  final Widget child;

  const _DisableWhen({required this.disabled, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!disabled) return child;
    return IgnorePointer(
      child: Opacity(opacity: 0.5, child: child),
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
                            context.l10n.downloadReviewFilesTitle,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.downloadMovingTo(widget.targetPath),
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.downloadSelectedOfTotal(
                            selectedCount.toString(),
                            widget.files.length.toString(),
                          ),
                          style: textTheme.labelLarge,
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => setState(
                                () => _selected.updateAll((_, __) => true),
                              ),
                              child: Text(context.l10n.historySelectAll),
                            ),
                            TextButton(
                              onPressed: () => setState(
                                () => _selected.updateAll((_, __) => false),
                              ),
                              child: Text(context.l10n.commonNone),
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
                                      context.l10n.downloadMovedFiles(
                                        count.toString(),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.drive_file_move_outlined),
                      label: Text(
                        context.l10n.downloadMoveSelectedBtn(
                          selectedCount.toString(),
                        ),
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
                            SnackBar(
                              content: Text(
                                context.l10n.downloadChangedLocationOnly,
                              ),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        context.l10n.downloadChangeLocationOnlyBtn,
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
