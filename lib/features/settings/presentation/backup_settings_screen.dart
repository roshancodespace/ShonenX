import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/shared/providers/backup_provider.dart';
import 'package:shonenx/core/services/backup_service.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() =>
      _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
  final _exportCategories = Set<BackupCategory>.from(BackupCategory.values);
  bool _exporting = false;

  Future<void> _export({bool share = false}) async {
    if (_exportCategories.isEmpty) {
      _snack('Select at least one category');
      return;
    }

    setState(() => _exporting = true);

    try {
      final service = ref.read(backupServiceProvider);
      final manifest = await service.exportData(_exportCategories);
      final json = manifest.toJson();

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
          dialogTitle: 'Save backup',
          fileName: fileName,
          bytes: bytes,
        );
      } else {
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save backup',
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
          _snack('Backup saved');
        }
      }
    } catch (e) {
      if (mounted) _snack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _import() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowedExtensions: ['json'],
        withData: true,
      );

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
        if (mounted) _snack('Backup file is empty');
        return;
      }

      final manifest = BackupManifest.fromJson(jsonContent);

      if (manifest.categories.isEmpty) {
        if (mounted) _snack('No valid backup data found in file');
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
        _snack('Invalid backup file: $msg');
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Backup & Restore',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          SettingsSection(
            title: 'Export',
            subtitle: 'Choose what to include in your backup',
            children: [
              for (final cat in BackupCategory.values)
                SettingsSwitchTile(
                  icon: cat.icon,
                  title: cat.label,
                  subtitle: cat.description,
                  value: _exportCategories.contains(cat),
                  onChanged: (v) => setState(() {
                    v
                        ? _exportCategories.add(cat)
                        : _exportCategories.remove(cat);
                  }),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _exporting
                            ? null
                            : () => _export(share: false),
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_exporting ? 'Exporting…' : 'Save Backup'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _exporting ? null : () => _export(share: true),
                      icon: const Icon(Icons.share_outlined),
                      tooltip: 'Share Backup',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SettingsSection(
            title: 'Import',
            children: [
              SettingsActionTile(
                icon: Icons.download_outlined,
                title: 'Restore from file',
                subtitle: 'Select a .json backup',
                onTap: _import,
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
