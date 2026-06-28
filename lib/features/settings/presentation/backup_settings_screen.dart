import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  Future<void> _export() async {
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

      String? savePath;

      if (Platform.isAndroid || Platform.isIOS) {
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save backup',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: Uint8List.fromList(utf8.encode(json)),
        );
      } else {
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save backup',
          fileName: fileName,
        );
        if (savePath != null) {
          await File(savePath).writeAsString(json);
        }
      }

      if (savePath != null && mounted) {
        _snack('Backup saved');
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
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final json = await file.readAsString();
      final manifest = BackupManifest.fromJson(json);

      if (mounted) {
        context.push('/settings/backup/preview', extra: manifest);
      }
    } catch (e) {
      if (mounted) _snack('Invalid backup file');
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
                padding: const EdgeInsets.all(10.0),
                child: FilledButton.icon(
                  onPressed: _exporting ? null : _export,
                  icon: const Icon(Icons.upload_outlined),
                  label: Text(_exporting ? 'Exporting…' : 'Export Backup'),
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
