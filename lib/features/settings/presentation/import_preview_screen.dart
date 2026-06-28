import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/backup_provider.dart';
import 'package:shonenx/core/services/backup_service.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class ImportPreviewScreen extends ConsumerStatefulWidget {
  final BackupManifest manifest;

  const ImportPreviewScreen({super.key, required this.manifest});

  @override
  ConsumerState<ImportPreviewScreen> createState() =>
      _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  late final Set<BackupCategory> _selected;
  Map<BackupCategory, int>? _existingCounts;
  bool _loading = true;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.manifest.categories);
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final counts = await ref.read(backupServiceProvider).getExistingCounts();
    if (mounted)
      setState(() {
        _existingCounts = counts;
        _loading = false;
      });
  }

  Future<void> _confirmImport() async {
    if (_selected.isEmpty) return;
    setState(() => _importing = true);

    try {
      await ref
          .read(backupServiceProvider)
          .importData(widget.manifest, _selected);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final manifest = widget.manifest;

    return AppScaffold(
      title: 'Import Preview',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // File info
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  leading: Icon(
                    Icons.description_outlined,
                    color: colorScheme.primary,
                  ),
                  title: const Text(
                    'ShonenX Backup',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'v${manifest.appVersion} • ${_fmtDate(manifest.exportDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // Warning
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Text(
                    'Importing will replace existing data for selected categories.',
                    style: TextStyle(fontSize: 12, color: colorScheme.error),
                  ),
                ),

                SettingsSection(
                  title: 'Categories',
                  children: [
                    for (final cat in manifest.categories) ...[
                      SettingsSwitchTile(
                        icon: cat.icon,
                        title: cat.label,
                        subtitle: _subtitle(cat),
                        value: _selected.contains(cat),
                        onChanged: (v) => setState(() {
                          v ? _selected.add(cat) : _selected.remove(cat);
                        }),
                      ),
                    ],
                  ],
                ),

                // Import action
                SettingsActionTile(
                  icon: Icons.download_done_outlined,
                  title: 'Confirm Import',
                  subtitle: _importing
                      ? 'Importing…'
                      : '${_selected.length} categories selected',
                  isDestructive: true,
                  onTap: _importing || _selected.isEmpty
                      ? null
                      : _confirmImport,
                  trailing: _importing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  String _subtitle(BackupCategory cat) {
    final incoming = widget.manifest.countFor(cat);
    final existing = _existingCounts?[cat] ?? 0;
    if (existing > 0 && _selected.contains(cat)) {
      return '$incoming items → replaces $existing existing';
    }
    return '$incoming items';
  }

  String _fmtDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final p = d.hour < 12 ? 'AM' : 'PM';
    return '${m[d.month - 1]} ${d.day}, ${d.year} ${h}:${d.minute.toString().padLeft(2, '0')} $p';
  }
}
