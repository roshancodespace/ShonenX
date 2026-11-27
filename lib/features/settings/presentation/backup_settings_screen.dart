import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/shared/providers/backup_provider.dart';
import 'package:shonenx/core/services/backup_service.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/app_progress_indicator.dart';

class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() =>
      _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
  final _exportCategories = Set<BackupCategory>.from(BackupCategory.values);
  bool _exporting = false;
  bool _importing = false;
  Map<BackupCategory, int>? _existingCounts;

  @override
  void initState() {
    super.initState();
    _loadExistingCounts();
  }

  Future<void> _loadExistingCounts() async {
    try {
      final counts = await ref.read(backupServiceProvider).getExistingCounts();
      if (mounted) {
        setState(() {
          _existingCounts = counts;
        });
      }
    } catch (_) {}
  }

  int get _totalRecordsCount {
    if (_existingCounts == null) return 0;
    return _existingCounts!.values.fold(0, (sum, val) => sum + val);
  }

  String _getCategorySubtitle(BackupCategory cat) {
    final count = _existingCounts?[cat];
    if (count == null) return cat.description;
    return '${cat.description} • $count ${cat == BackupCategory.notifications
        ? "subscriptions"
        : cat == BackupCategory.appPreferences
        ? "settings"
        : "items"}';
  }

  Future<void> _export({bool share = false}) async {
    final l10n = context.l10n;
    if (_exportCategories.isEmpty) {
      _snack(l10n.backupSelectAtLeastOne);
      return;
    }

    setState(() => _exporting = true);

    try {
      final service = ref.read(backupServiceProvider);
      final manifest = await service.exportData(_exportCategories);
      final json = await manifest.toJsonAsync();

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'shonenx_backup_$timestamp.json';

      if (share) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsString(json, flush: true);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(tempFile.path)],
            text: 'ShonenX Backup ($fileName)',
          ),
        );
        return;
      }

      String? savePath;
      final bytes = Uint8List.fromList(utf8.encode(json));

      if (Platform.isAndroid || Platform.isIOS) {
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: l10n.backupSaveDialogTitle,
          fileName: fileName,
          bytes: bytes,
        );
      } else {
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: l10n.backupSaveDialogTitle,
          fileName: fileName,
        );
      }

      if (savePath != null) {
        try {
          final file = File(savePath);
          if (!await file.exists() || await file.length() == 0) {
            await file.writeAsString(json, flush: true);
          }
        } catch (_) {}

        if (mounted) {
          _snack(l10n.backupSaved);
        }
      }
    } catch (e) {
      if (mounted) _snack(l10n.backupExportFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
          withData: true,
        );
      } catch (_) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          withData: true,
        );
      }

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.single;
      String? jsonContent;

      if (pickedFile.bytes != null && pickedFile.bytes!.isNotEmpty) {
        jsonContent = utf8.decode(pickedFile.bytes!, allowMalformed: true);
      } else if (pickedFile.path != null) {
        final file = File(pickedFile.path!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          jsonContent = utf8.decode(bytes, allowMalformed: true);
        }
      }

      if (jsonContent == null || jsonContent.trim().isEmpty) {
        if (mounted) _snack(context.l10n.backupFileEmpty);
        return;
      }

      final manifest = await BackupManifest.fromJsonAsync(jsonContent);

      if (manifest.categories.isEmpty) {
        if (mounted) _snack(context.l10n.backupNoValidData);
        return;
      }

      if (mounted) {
        context.pushSettingsBackupPreview(manifest);
      }
    } catch (e) {
      if (mounted) {
        final msg = e
            .toString()
            .replaceFirst('Exception: ', '')
            .split('\n')
            .first;
        _snack(context.l10n.backupInvalidFile(msg));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;

    return AppScaffold(
      title: l10n.settingsBackup,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          // ── Restore ──
          SettingsSection(
            title: l10n.backupRestoreSection,
            subtitle: l10n.backupRestoreSectionSubtitle,
            child: SettingsActionTile(
              icon: Icons.settings_backup_restore_rounded,
              title: l10n.backupRestoreFromFile,
              subtitle: l10n.backupRestoreFromFileSubtitle,
              trailing: _importing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: AppProgressIndicator(type: AppProgressType.circular, strokeWidth: 2),
                    )
                  : Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
              onTap: _importing ? null : _import,
            ),
          ),

          // ── Export ──
          SettingsSection(
            title: l10n.backupExportSection,
            subtitle: l10n.backupExportSectionSubtitle,
            children: [
              for (final cat in BackupCategory.values)
                SettingsSwitchTile(
                  icon: cat.icon,
                  title: cat.label,
                  subtitle: _getCategorySubtitle(cat),
                  value: _exportCategories.contains(cat),
                  onChanged: (v) => setState(() {
                    v
                        ? _exportCategories.add(cat)
                        : _exportCategories.remove(cat);
                  }),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                if (_existingCounts != null)
                  Text(
                    l10n.backupLocalRecordsCount(_totalRecordsCount.toString()),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    setState(() {
                      _exportCategories.addAll(BackupCategory.values);
                    });
                  },
                  child: Text(
                    l10n.historySelectAll,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    setState(() {
                      _exportCategories.clear();
                    });
                  },
                  child: Text(
                    l10n.commonClear,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _exporting ? null : () => _export(share: false),
                    icon: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: AppProgressIndicator(type: AppProgressType.circular, strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _exporting ? l10n.backupExporting : l10n.backupSaveBackup,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _exporting ? null : () => _export(share: true),
                  icon: const Icon(Icons.share_outlined),
                  tooltip: l10n.backupShareBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
