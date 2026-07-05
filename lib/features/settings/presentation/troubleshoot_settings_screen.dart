import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/caching/cache_manager.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/features/discovery/domain/media_preference.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class _CleanupItem {
  final String id;
  final String title;
  final String subtitle;
  final DownloadTask? task;
  final FileSystemEntity? entity;
  bool selected;

  _CleanupItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.task,
    this.entity,
    this.selected = true,
  });
}

class TroubleshootSettingsScreen extends ConsumerStatefulWidget {
  const TroubleshootSettingsScreen({super.key});

  @override
  ConsumerState<TroubleshootSettingsScreen> createState() =>
      _TroubleshootSettingsScreenState();
}

class _TroubleshootSettingsScreenState
    extends ConsumerState<TroubleshootSettingsScreen> {
  int _mappingsCount = 0;
  int _trackerLinksCount = 0;
  int _unfinishedDownloadsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);
    try {
      final isar = ref.read(databaseProvider);
      final mappings = await isar.mediaPreferences.count();
      final trackerLinks = await isar.isarTrackerLinks.count();
      final repo = ref.read(downloadRepositoryProvider);
      final unfinishedTasks = await repo.getUnfinishedTasks();
      if (mounted) {
        setState(() {
          _mappingsCount = mappings;
          _trackerLinksCount = trackerLinks;
          _unfinishedDownloadsCount = unfinishedTasks.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reviewAndClearDownloads() async {
    final repo = ref.read(downloadRepositoryProvider);
    final unfinishedTasks = await repo.getUnfinishedTasks();
    final items = <_CleanupItem>[];
    final seenPaths = <String>{};

    for (final task in unfinishedTasks) {
      String sub = 'Status: ${task.status.name}';
      final file = File(task.savePath);
      final partFile = File('${task.savePath}.part');
      final lastSlash = task.savePath.lastIndexOf('/');
      final dirPath = lastSlash != -1
          ? task.savePath.substring(0, lastSlash)
          : '';
      final tempDir = Directory('$dirPath/.temp_${task.id}');

      int size = 0;
      if (await file.exists()) {
        size += await file.length();
        seenPaths.add(file.path);
      }
      if (await partFile.exists()) {
        size += await partFile.length();
        seenPaths.add(partFile.path);
      }
      if (await tempDir.exists()) {
        seenPaths.add(tempDir.path);
      }
      if (size > 0) {
        sub +=
            ' · ${(size / (1024 * 1024)).toStringAsFixed(1)} MB partial data';
      }

      items.add(
        _CleanupItem(
          id: 'task_${task.id}',
          title: task.fileName.isEmpty
              ? 'Episode ${task.episodeNumber}'
              : task.fileName,
          subtitle: sub,
          task: task,
        ),
      );
    }

    try {
      final prefs = await ref.read(downloadPrefsProvider.future);
      final dir = Directory(prefs.downloadPath);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (seenPaths.contains(entity.path)) continue;
          final name = entity.path.split('/').last;
          if (name.endsWith('.part') || name.startsWith('.temp_')) {
            int size = 0;
            if (entity is File) {
              size = await entity.length();
            }
            items.add(
              _CleanupItem(
                id: 'file_${entity.path}',
                title: 'Orphaned: $name',
                subtitle: size > 0
                    ? '${(size / (1024 * 1024)).toStringAsFixed(1)} MB temp file'
                    : 'Incomplete temp folder',
                entity: entity,
              ),
            );
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'No unfinished downloads or orphaned temp files found.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedCount = items.where((i) => i.selected).length;
            final colors = Theme.of(context).colorScheme;

            return AppBottomSheet(
              title: 'Review Unfinished Downloads',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select unfinished queue tasks or incomplete temporary folders to permanently remove.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return CheckboxListTile(
                          value: item.selected,
                          activeColor: colors.primary,
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            item.subtitle,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          onChanged: (val) {
                            setSheetState(() => item.selected = val ?? false);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.error,
                            foregroundColor: colors.onError,
                          ),
                          onPressed: selectedCount == 0
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  for (final item in items.where(
                                    (i) => i.selected,
                                  )) {
                                    if (item.task != null) {
                                      await ref
                                          .read(
                                            downloadManagerProvider.notifier,
                                          )
                                          .cancelDownload(item.task!.id);
                                    } else if (item.entity != null) {
                                      try {
                                        await item.entity!.delete(
                                          recursive: true,
                                        );
                                      } catch (_) {}
                                    }
                                  }
                                  await _loadCounts();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          'Cleaned up $selectedCount item(s).',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Text('Clean Up ($selectedCount)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _clearMediaMappings() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear Media Mappings?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will clear $_mappingsCount saved preferred sources and manual matches.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              'Your library bookmarks, watch history, and tracking progression will not be affected.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final isar = ref.read(databaseProvider);
      await isar.writeTxn(() async {
        await isar.mediaPreferences.clear();
      });
      await _loadCounts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Media mappings cleared.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to clear mappings: $e')));
    }
  }

  Future<void> _clearTrackerLinks() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear Tracker Bridges?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Clears $_trackerLinksCount cached ID pairings between AniList and MyAnimeList.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final isar = ref.read(databaseProvider);
      await isar.writeTxn(() async {
        await isar.isarTrackerLinks.clear();
      });
      await _loadCounts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Tracker bridges cleared.'),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppScaffold(
      title: 'Troubleshoot',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Use these options if you encounter "Episodes Not Found" errors, frozen scraper lists, or mismatched tracking entries.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SettingsSection(
                  title: 'Storage & Downloads',
                  children: [
                    SettingsActionTile(
                      icon: Icons.cleaning_services_rounded,
                      title: 'Clean Incomplete Downloads',
                      subtitle:
                          'Review and purge $_unfinishedDownloadsCount unfinished tasks & orphaned temp folders',
                      onTap: _reviewAndClearDownloads,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SettingsSection(
                  title: 'Matching & Scrapers',
                  children: [
                    SettingsActionTile(
                      icon: Icons.link_off_rounded,
                      title: 'Clear All Media Mappings',
                      subtitle:
                          'Reset $_mappingsCount preferred sources and manual matches',
                      onTap: _mappingsCount > 0 ? _clearMediaMappings : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(52, 0, 16, 12),
                      child: Text(
                        'Fixes "Episodes Not Found" after extension updates. Forces automatic re-matching on your next visit.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SettingsSection(
                  title: 'Network Cache',
                  children: [
                    SettingsActionTile(
                      icon: Icons.cached_rounded,
                      title: 'Flush Scraper Cache',
                      subtitle:
                          'Clear temporary scraper responses and stream links',
                      onTap: () async {
                        await ref.read(cacheManagerProvider).clearCache();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Scraper cache flushed.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SettingsSection(
                  title: 'Sync',
                  children: [
                    SettingsActionTile(
                      icon: Icons.sync_problem_rounded,
                      title: 'Reset Tracker Bridges',
                      subtitle:
                          'Clear $_trackerLinksCount cached AniList to MAL ID pairings',
                      onTap: _trackerLinksCount > 0 ? _clearTrackerLinks : null,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}
