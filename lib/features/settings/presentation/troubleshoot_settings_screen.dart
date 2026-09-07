import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/core/caching/cache_manager.dart';
import 'package:shonenx/core/caching/domain/cache_entry.dart';
import 'package:shonenx/core/commentum/commentum_auth_service.dart';
import 'package:shonenx/core/network/secure_storage.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/discord/providers/discord_provider.dart';
import 'package:shonenx/features/discovery/domain/media_preference.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
import 'package:shonenx/features/extensions/providers/extension_service_provider.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/library/domain/models/library_entry.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/utils/source_invalidation.dart';

class _CleanupItem {
  final String id;
  final String title;
  final String subtitle;
  final DownloadTask? task;
  final FileSystemEntity? entity;
  bool selected = true;

  _CleanupItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.task,
    this.entity,
  });
}

class _SelectiveDataCategory {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final int count;
  final bool isDestructive;
  bool isSelected;

  _SelectiveDataCategory({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.count = 0,
    this.isDestructive = false,
    this.isSelected = true,
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
  int _watchHistoryCount = 0;
  int _readHistoryCount = 0;
  int _libraryCount = 0;
  int _cacheCount = 0;
  int _authTokensCount = 0;
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
      final watchHistory = await isar.watchHistoryEntrys.count();
      final readHistory = await isar.readHistoryEntrys.count();
      final library = await isar.libraryEntrys.count();
      final cache = await isar.cacheEntrys.count();

      final repo = ref.read(downloadRepositoryProvider);
      final unfinishedTasks = await repo.getUnfinishedTasks();

      final storage = ref.read(secureStorageProvider);
      final allKeys = await storage.readAll();
      final authTokens = allKeys.keys
          .where((k) => k.startsWith('auth_token_') || k.startsWith('discord_'))
          .length;

      if (mounted) {
        setState(() {
          _mappingsCount = mappings;
          _trackerLinksCount = trackerLinks;
          _unfinishedDownloadsCount = unfinishedTasks.length;
          _watchHistoryCount = watchHistory;
          _readHistoryCount = readHistory;
          _libraryCount = library;
          _cacheCount = cache;
          _authTokensCount = authTokens;
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

  Future<void> _clearAllExtensionRepos() async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Clear All Repositories?',
      icon: Icon(
        Icons.folder_delete_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      child: Text(
        'This will remove all added extension repository URLs across Aniyomi, Mangayomi, CloudStream, Kotatsu, and Sora.\n\nInstalled extensions will remain until uninstalled.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Clear All'),
        ),
      ],
    );

    if (confirmed == true) {
      final adapter = ref.read(extensionAdapterProvider);
      await adapter.clearAllRepos();
      ref.invalidate(activeExtReposProvider);
      ref.invalidateAllSources();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('All extension repositories cleared.'),
          ),
        );
      }
    }
  }

  Future<void> _uninstallAllExtensions() async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Uninstall All Extensions?',
      icon: Icon(
        Icons.extension_off_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      child: Text(
        'This will remove all installed extension plugins across all engines.\n\nFixes crashes or broken sources caused by outdated/corrupted extension installs.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Uninstall All'),
        ),
      ],
    );

    if (confirmed == true) {
      final adapter = ref.read(extensionAdapterProvider);
      await adapter.uninstallAllExtensions();
      ref.invalidateAllSources();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('All installed extensions uninstalled.'),
          ),
        );
      }
    }
  }

  Future<void> _resetExtensionCacheAndPreferences() async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Reset Extension Cache & Preferences?',
      icon: Icon(
        Icons.restart_alt_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Text(
        'This will reset extension-specific settings, source preferences, and cached metadata, then reload active extension managers.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Reset'),
        ),
      ],
    );

    if (confirmed == true) {
      final adapter = ref.read(extensionAdapterProvider);
      await adapter.resetExtensionPreferencesAndCache();
      ref.invalidate(activeExtReposProvider);
      ref.invalidateAllSources();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Extension cache and preferences reset.'),
          ),
        );
      }
    }
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

  Future<void> _clearImageCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final file in tempDir.list()) {
          try {
            await file.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Image & poster cache purged from memory and disk.'),
      ),
    );
  }

  Future<void> _resetAuthenticationData() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reset Authentication Data?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will sign out of all linked accounts and erase saved tokens:',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              '• Tracker accounts (AniList, MyAnimeList, Kitsu, SIMKL)\n'
              '• Discord Rich Presence integration\n'
              '• Commentum discussions session',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your local bookmarks, watch history, and downloads will NOT be affected.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.primary,
              ),
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
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset Auth'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final storage = ref.read(secureStorageProvider);
      final allKeys = await storage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith('auth_token_') || key.startsWith('discord_')) {
          await storage.delete(key: key);
        }
      }

      final profileNotifier = ref.read(trackerProfileProvider.notifier);
      for (final type in TrackerType.values) {
        profileNotifier.removeProfile(type);
      }
      ref.invalidate(authTokensProvider);

      await ref.read(discordProvider.notifier).logout();
      await ref.read(commentumAuthServiceProvider).signOutAll();

      await _loadCounts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'All authentication tokens cleared and accounts signed out.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reset auth data: $e')));
    }
  }

  Future<void> _resetAppSettings() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reset App Settings?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will revert all player, UI theme, extension, and content settings back to factory defaults.\n\nYour library bookmarks, history, and downloads will remain intact.',
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
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
            child: const Text('Reset Settings'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('App settings restored to defaults.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reset settings: $e')));
    }
  }

  Future<void> _showSelectiveClearDataSheet() async {
    final categories = [
      _SelectiveDataCategory(
        key: 'history',
        title: 'Watch & Read History',
        subtitle:
            '$_watchHistoryCount anime entries • $_readHistoryCount manga entries',
        icon: Icons.history_rounded,
        count: _watchHistoryCount + _readHistoryCount,
        isSelected: true,
      ),
      _SelectiveDataCategory(
        key: 'library',
        title: 'Library & Bookmarks',
        subtitle: '$_libraryCount saved titles in your library',
        icon: Icons.collections_bookmark_rounded,
        count: _libraryCount,
        isSelected: false,
      ),
      _SelectiveDataCategory(
        key: 'cache',
        title: 'Scraper & Network Cache',
        subtitle: '$_cacheCount cached API responses and stream links',
        icon: Icons.cached_rounded,
        count: _cacheCount,
        isSelected: true,
      ),
      _SelectiveDataCategory(
        key: 'mappings',
        title: 'Media & Source Mappings',
        subtitle: '$_mappingsCount preferred sources and manual matches',
        icon: Icons.link_off_rounded,
        count: _mappingsCount,
        isSelected: true,
      ),
      _SelectiveDataCategory(
        key: 'bridges',
        title: 'Tracker Bridges',
        subtitle: '$_trackerLinksCount AniList to MAL ID mapping links',
        icon: Icons.sync_problem_rounded,
        count: _trackerLinksCount,
        isSelected: true,
      ),
      _SelectiveDataCategory(
        key: 'downloads',
        title: 'Incomplete Downloads & Temp Files',
        subtitle:
            '$_unfinishedDownloadsCount pending download tasks and temp files',
        icon: Icons.download_for_offline_rounded,
        count: _unfinishedDownloadsCount,
        isSelected: true,
      ),
      _SelectiveDataCategory(
        key: 'auth',
        title: 'Authentication & Accounts',
        subtitle:
            '$_authTokensCount saved tokens (AniList, MAL, Kitsu, Discord)',
        icon: Icons.lock_reset_rounded,
        count: _authTokensCount,
        isDestructive: true,
        isSelected: false,
      ),
      _SelectiveDataCategory(
        key: 'settings',
        title: 'App Preferences & Settings',
        subtitle: 'Reset all player, UI, and extension settings to defaults',
        icon: Icons.tune_rounded,
        isDestructive: true,
        isSelected: false,
      ),
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cs = Theme.of(context).colorScheme;
            final selectedCount = categories.where((c) => c.isSelected).length;

            return AppBottomSheet(
              title: 'Clear Data (Selective)',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select data categories to purge:',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final allSelected = categories.every(
                            (c) => c.isSelected,
                          );
                          setSheetState(() {
                            for (final c in categories) {
                              c.isSelected = !allSelected;
                            }
                          });
                        },
                        child: Text(
                          categories.every((c) => c.isSelected)
                              ? 'Deselect All'
                              : 'Select All',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.50,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return CheckboxListTile(
                          value: cat.isSelected,
                          activeColor: cat.isDestructive
                              ? cs.error
                              : cs.primary,
                          secondary: Icon(
                            cat.icon,
                            color: cat.isDestructive
                                ? cs.error
                                : cs.onSurfaceVariant,
                            size: 22,
                          ),
                          title: Text(
                            cat.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cat.isDestructive ? cs.error : null,
                            ),
                          ),
                          subtitle: Text(
                            cat.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          onChanged: (val) {
                            setSheetState(() => cat.isSelected = val ?? false);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.error,
                            foregroundColor: cs.onError,
                          ),
                          onPressed: selectedCount == 0
                              ? null
                              : () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: cs.surfaceContainerHigh,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text(
                                        'Confirm Data Wipe?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      content: Text(
                                        'This will permanently delete the $selectedCount selected categories. This action cannot be undone.',
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: cs.error,
                                            foregroundColor: cs.onError,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Wipe Selected'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed != true) return;
                                  if (!context.mounted) return;
                                  Navigator.pop(context);

                                  final isar = ref.read(databaseProvider);
                                  final selectedKeys = categories
                                      .where((c) => c.isSelected)
                                      .map((c) => c.key)
                                      .toSet();

                                  await isar.writeTxn(() async {
                                    if (selectedKeys.contains('history')) {
                                      await isar.watchHistoryEntrys.clear();
                                      await isar.readHistoryEntrys.clear();
                                    }
                                    if (selectedKeys.contains('library')) {
                                      await isar.libraryEntrys.clear();
                                    }
                                    if (selectedKeys.contains('cache')) {
                                      await isar.cacheEntrys.clear();
                                    }
                                    if (selectedKeys.contains('mappings')) {
                                      await isar.mediaPreferences.clear();
                                    }
                                    if (selectedKeys.contains('bridges')) {
                                      await isar.isarTrackerLinks.clear();
                                    }
                                  });

                                  if (selectedKeys.contains('cache')) {
                                    await ref
                                        .read(cacheManagerProvider)
                                        .clearCache();
                                    PaintingBinding.instance.imageCache.clear();
                                    PaintingBinding.instance.imageCache
                                        .clearLiveImages();
                                  }

                                  if (selectedKeys.contains('downloads')) {
                                    final repo = ref.read(
                                      downloadRepositoryProvider,
                                    );
                                    final tasks = await repo
                                        .getUnfinishedTasks();
                                    for (final t in tasks) {
                                      try {
                                        await ref
                                            .read(
                                              downloadManagerProvider.notifier,
                                            )
                                            .cancelDownload(t.id);
                                      } catch (_) {}
                                    }
                                  }

                                  if (selectedKeys.contains('auth')) {
                                    final storage = ref.read(
                                      secureStorageProvider,
                                    );
                                    final allKeys = await storage.readAll();
                                    for (final key in allKeys.keys) {
                                      if (key.startsWith('auth_token_') ||
                                          key.startsWith('discord_')) {
                                        await storage.delete(key: key);
                                      }
                                    }
                                    final profileNotifier = ref.read(
                                      trackerProfileProvider.notifier,
                                    );
                                    for (final type in TrackerType.values) {
                                      profileNotifier.removeProfile(type);
                                    }
                                    ref.invalidate(authTokensProvider);
                                    await ref
                                        .read(discordProvider.notifier)
                                        .logout();
                                    await ref
                                        .read(commentumAuthServiceProvider)
                                        .signOutAll();
                                  }

                                  if (selectedKeys.contains('settings')) {
                                    final prefs = ref.read(
                                      sharedPreferencesProvider,
                                    );
                                    await prefs.clear();
                                  }

                                  await _loadCounts();

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      content: Text(
                                        'Purged $selectedCount selected data categories.',
                                      ),
                                    ),
                                  );
                                },
                          child: Text('Wipe Selected ($selectedCount)'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppScaffold(
      title: 'Troubleshoot & Repair',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 50),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Use these options if you encounter broken playback, frozen scrapers, desynced tracking, or corrupted settings.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Storage & Cache
                SettingsSection(
                  title: 'Storage & Cache',
                  children: [
                    SettingsActionTile(
                      icon: Icons.cleaning_services_rounded,
                      title: 'Clean Incomplete Downloads',
                      subtitle:
                          'Review and purge $_unfinishedDownloadsCount unfinished tasks & orphaned temp files',
                      onTap: _reviewAndClearDownloads,
                    ),
                    SettingsActionTile(
                      icon: Icons.photo_library_outlined,
                      title: 'Clear Image & Poster Cache',
                      subtitle:
                          'Purge loaded cover art thumbnails and temp files from memory & disk',
                      onTap: _clearImageCache,
                    ),
                    SettingsActionTile(
                      icon: Icons.cached_rounded,
                      title: 'Flush Scraper Cache',
                      subtitle:
                          'Clear $_cacheCount temporary scraper responses and stream links',
                      onTap: () async {
                        await ref.read(cacheManagerProvider).clearCache();
                        final isar = ref.read(databaseProvider);
                        await isar.writeTxn(() async {
                          await isar.cacheEntrys.clear();
                        });
                        await _loadCounts();
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

                // Matching & Scrapers
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

                // Extensions & Repositories
                SettingsSection(
                  title: 'Extensions & Repositories',
                  children: [
                    SettingsActionTile(
                      icon: Icons.folder_delete_rounded,
                      isDestructive: true,
                      title: 'Clear All Extension Repositories',
                      subtitle:
                          'Wipe all repository URLs across Aniyomi, Mangayomi, CloudStream, Kotatsu, and Sora',
                      onTap: _clearAllExtensionRepos,
                    ),
                    SettingsActionTile(
                      icon: Icons.extension_off_rounded,
                      isDestructive: true,
                      title: 'Uninstall All Extensions',
                      subtitle:
                          'Uninstall all extension plugins across all engines to fix corrupted builds',
                      onTap: _uninstallAllExtensions,
                    ),
                    SettingsActionTile(
                      icon: Icons.restart_alt_rounded,
                      title: 'Reset Extension Cache & Preferences',
                      subtitle:
                          'Clear custom source preferences, cached metadata, and refresh engines',
                      onTap: _resetExtensionCacheAndPreferences,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sync & Tracking
                SettingsSection(
                  title: 'Sync & Tracking',
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
                const SizedBox(height: 8),

                // Authentication & Accounts
                SettingsSection(
                  title: 'Authentication & Accounts',
                  children: [
                    SettingsActionTile(
                      icon: Icons.lock_reset_rounded,
                      isDestructive: true,
                      title: 'Reset Authentication Data',
                      subtitle:
                          'Log out and erase all saved credentials (AniList, MAL, Kitsu, SIMKL, Discord, Commentum)',
                      onTap: _resetAuthenticationData,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Reset & Data Management (Danger Zone)
                SettingsSection(
                  title: 'Data Management & Reset',
                  children: [
                    SettingsActionTile(
                      icon: Icons.delete_sweep_rounded,
                      isDestructive: true,
                      title: 'Clear App Data (Selective)',
                      subtitle:
                          'Selectively wipe history, bookmarks, caches, mappings, or perform a full wipe',
                      onTap: _showSelectiveClearDataSheet,
                    ),
                    SettingsActionTile(
                      icon: Icons.settings_backup_restore_rounded,
                      title: 'Reset App Settings to Default',
                      subtitle:
                          'Restore all player, UI, and extension preferences without affecting saved data',
                      onTap: _resetAppSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}
