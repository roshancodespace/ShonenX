import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/core/caching/cache_manager.dart';
import 'package:shonenx/core/caching/domain/cache_entry.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/features/comments/api/commentum_auth_service.dart';
import 'package:shonenx/core/network/secure_storage.dart';
import 'package:shonenx/features/tracking/providers/tracker_auth_provider.dart';
import 'package:shonenx/features/discord/providers/discord_provider.dart';
import 'package:shonenx/features/discovery/domain/media_preference.dart';
import 'package:shonenx/features/downloads/domain/models/download_task.dart';
import 'package:shonenx/features/downloads/providers/download_prefs_provider.dart';
import 'package:shonenx/features/downloads/providers/download_provider.dart';
import 'package:shonenx/features/extensions/providers/extension_service_provider.dart';
import 'package:shonenx/features/history/domain/models/history_entry.dart';
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
import 'package:shonenx/shared/widgets/app_progress_indicator.dart';

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
  int _historyCount = 0;
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
      final historyCount = await isar.historyEntrys.count();
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
          _historyCount = historyCount;
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.l10n.troubleshootNoUnfinishedDownloads),
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
            final l10n = context.l10n;

            return AppBottomSheet(
              title: l10n.troubleshootReviewUnfinishedTitle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.troubleshootReviewUnfinishedDesc,
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
                          child: Text(l10n.commonCancel),
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
                                          l10n.troubleshootCleanedUpSnack(
                                            selectedCount.toString(),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Text(
                            l10n.troubleshootCleanUpBtn(
                              selectedCount.toString(),
                            ),
                          ),
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
    final l10n = context.l10n;
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: l10n.troubleshootClearAllReposDialogTitle,
      icon: Icon(
        Icons.folder_delete_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      child: Text(
        l10n.troubleshootClearAllReposDialogBody,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.troubleshootClearAllBtn),
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
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(l10n.troubleshootAllReposCleared),
          ),
        );
      }
    }
  }

  Future<void> _uninstallAllExtensions() async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: l10n.troubleshootUninstallAllExtDialogTitle,
      icon: Icon(
        Icons.extension_off_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      child: Text(
        l10n.troubleshootUninstallAllExtDialogBody,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.troubleshootUninstallAllBtn),
        ),
      ],
    );

    if (confirmed == true) {
      final adapter = ref.read(extensionAdapterProvider);
      await adapter.uninstallAllExtensions();
      ref.invalidateAllSources();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(l10n.troubleshootAllExtUninstalled),
          ),
        );
      }
    }
  }

  Future<void> _resetExtensionCacheAndPreferences() async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: l10n.troubleshootResetExtCacheDialogTitle,
      icon: Icon(
        Icons.restart_alt_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Text(
        l10n.troubleshootResetExtCacheDialogBody,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.commonReset),
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
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(l10n.troubleshootExtCacheResetSnack),
          ),
        );
      }
    }
  }

  Future<void> _clearMediaMappings() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.troubleshootClearMediaMappingsDialogTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.troubleshootClearMediaMappingsDialogBody(
                _mappingsCount.toString(),
              ),
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.troubleshootLibraryNotAffected,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.commonCancel,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonClear),
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.troubleshootMappingsCleared),
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
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.troubleshootClearTrackerBridgesDialogTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          l10n.troubleshootResetTrackerBridgesSubtitle(
            _trackerLinksCount.toString(),
          ),
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.commonCancel,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonClear),
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.troubleshootTrackerBridgesCleared),
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
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.l10n.troubleshootImageCachePurged),
      ),
    );
  }

  Future<void> _resetAuthenticationData() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.troubleshootResetAuthDialogTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.troubleshootResetAuthDialogLead,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.troubleshootResetAuthDialogList,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.troubleshootLocalDataSafeNote,
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
            child: Text(
              l10n.commonCancel,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.troubleshootResetAuthBtn),
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.troubleshootAuthClearedSnack),
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
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.troubleshootResetAppSettingsDialogTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          l10n.troubleshootResetAppSettingsDialogBody,
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.commonCancel,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.troubleshootResetSettingsBtn),
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.troubleshootSettingsRestoredSnack),
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
    final l10n = context.l10n;
    final categories = [
      _SelectiveDataCategory(
        key: 'history',
        title: l10n.troubleshootCatHistory,
        subtitle: l10n.troubleshootCatHistorySub(_historyCount.toString()),
        icon: Icons.history_rounded,
        count: _historyCount,
        isSelected: true,
      ),
      _SelectiveDataCategory(
        key: 'library',
        title: l10n.troubleshootCatLibrary,
        subtitle: l10n.troubleshootCatLibrarySub(_libraryCount.toString()),
        icon: Icons.collections_bookmark_rounded,
        count: _libraryCount,
        isSelected: false,
      ),
      _SelectiveDataCategory(
        key: 'cache',
        title: l10n.troubleshootCatCache,
        subtitle: l10n.troubleshootCatCacheSub(_cacheCount.toString()),
        icon: Icons.cached_rounded,
        count: _cacheCount,
        isSelected: true,
      ),
      _SelectiveDataCategory(
        key: 'mappings',
        title: l10n.troubleshootCatMappings,
        subtitle: l10n.troubleshootCatMappingsSub(_mappingsCount.toString()),
        icon: Icons.link_off_rounded,
        count: _mappingsCount,
        isSelected: true,
      ),
      _SelectiveDataCategory(
        key: 'bridges',
        title: l10n.troubleshootCatBridges,
        subtitle: l10n.troubleshootCatBridgesSub(_trackerLinksCount.toString()),
        icon: Icons.sync_problem_rounded,
        count: _trackerLinksCount,
        isSelected: true,
      ),
      _SelectiveDataCategory(
        key: 'downloads',
        title: l10n.troubleshootCatDownloads,
        subtitle: l10n.troubleshootCatDownloadsSub(
          _unfinishedDownloadsCount.toString(),
        ),
        icon: Icons.download_for_offline_rounded,
        count: _unfinishedDownloadsCount,
        isSelected: true,
      ),
      _SelectiveDataCategory(
        key: 'auth',
        title: l10n.troubleshootAuthAccountsSection,
        subtitle: l10n.troubleshootCatAuthSub(_authTokensCount.toString()),
        icon: Icons.lock_reset_rounded,
        count: _authTokensCount,
        isDestructive: true,
        isSelected: false,
      ),
      _SelectiveDataCategory(
        key: 'settings',
        title: l10n.troubleshootCatSettings,
        subtitle: l10n.troubleshootCatSettingsSub,
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
              title: l10n.troubleshootClearDataSelectiveTitle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.troubleshootSelectCategoriesToPurge,
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
                              ? l10n.historyDeselectAll
                              : l10n.historySelectAll,
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
                          child: Text(l10n.commonCancel),
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
                                      title: Text(
                                        l10n.troubleshootConfirmDataWipeTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      content: Text(
                                        l10n.troubleshootConfirmDataWipeBody(
                                          selectedCount.toString(),
                                        ),
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text(
                                            l10n.commonCancel,
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
                                          child: Text(
                                            l10n.troubleshootWipeSelectedBtn,
                                          ),
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
                                      await isar.historyEntrys.clear();
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
                                        l10n.troubleshootPurgedCategoriesSnack(
                                          selectedCount.toString(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                          child: Text(
                            l10n.troubleshootWipeSelectedCountBtn(
                              selectedCount.toString(),
                            ),
                          ),
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
    final l10n = context.l10n;

    return AppScaffold(
      title: l10n.settingsTroubleshoot,
      body: _isLoading
          ? const Center(child: AppProgressIndicator(type: AppProgressType.circular))
          : ListView(
              padding: const EdgeInsets.only(bottom: 50),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.troubleshootIntro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Storage & Cache
                SettingsSection(
                  title: l10n.troubleshootStorageCacheSection,
                  children: [
                    SettingsActionTile(
                      icon: Icons.cleaning_services_rounded,
                      title: l10n.troubleshootCleanIncompleteDownloads,
                      subtitle: l10n.troubleshootCleanIncompleteDownloadsSubtitle(
                        _unfinishedDownloadsCount.toString(),
                      ),
                      onTap: _reviewAndClearDownloads,
                    ),
                    SettingsActionTile(
                      icon: Icons.photo_library_outlined,
                      title: l10n.troubleshootClearImageCache,
                      subtitle: l10n.troubleshootClearImageCacheSubtitle,
                      onTap: _clearImageCache,
                    ),
                    SettingsActionTile(
                      icon: Icons.cached_rounded,
                      title: l10n.troubleshootFlushScraperCache,
                      subtitle: l10n.troubleshootFlushScraperCacheSubtitle(
                        _cacheCount.toString(),
                      ),
                      onTap: () async {
                        await ref.read(cacheManagerProvider).clearCache();
                        final isar = ref.read(databaseProvider);
                        await isar.writeTxn(() async {
                          await isar.cacheEntrys.clear();
                        });
                        await _loadCounts();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(l10n.troubleshootScraperCacheFlushed),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Matching & Scrapers
                SettingsSection(
                  title: l10n.troubleshootMatchingScrapersSection,
                  children: [
                    SettingsActionTile(
                      icon: Icons.link_off_rounded,
                      title: l10n.troubleshootClearMediaMappings,
                      subtitle: l10n.troubleshootClearMediaMappingsSubtitle(
                        _mappingsCount.toString(),
                      ),
                      onTap: _mappingsCount > 0 ? _clearMediaMappings : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(52, 0, 16, 12),
                      child: Text(
                        l10n.troubleshootClearMediaMappingsNote,
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
                  title: l10n.troubleshootExtensionsReposSection,
                  children: [
                    SettingsActionTile(
                      icon: Icons.folder_delete_rounded,
                      isDestructive: true,
                      title: l10n.troubleshootClearAllReposTitle,
                      subtitle: l10n.troubleshootClearAllReposSubtitle,
                      onTap: _clearAllExtensionRepos,
                    ),
                    SettingsActionTile(
                      icon: Icons.extension_off_rounded,
                      isDestructive: true,
                      title: l10n.troubleshootUninstallAllExtTitle,
                      subtitle: l10n.troubleshootUninstallAllExtSubtitle,
                      onTap: _uninstallAllExtensions,
                    ),
                    SettingsActionTile(
                      icon: Icons.restart_alt_rounded,
                      title: l10n.troubleshootResetExtCacheTitle,
                      subtitle: l10n.troubleshootResetExtCacheSubtitle,
                      onTap: _resetExtensionCacheAndPreferences,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sync & Tracking
                SettingsSection(
                  title: l10n.troubleshootSyncTrackingSection,
                  child: SettingsActionTile(
                    icon: Icons.sync_problem_rounded,
                    title: l10n.troubleshootResetTrackerBridges,
                    subtitle: l10n.troubleshootResetTrackerBridgesSubtitle(
                      _trackerLinksCount.toString(),
                    ),
                    onTap: _trackerLinksCount > 0 ? _clearTrackerLinks : null,
                  ),
                ),
                const SizedBox(height: 8),

                // Authentication & Accounts
                SettingsSection(
                  title: l10n.troubleshootAuthAccountsSection,
                  child: SettingsActionTile(
                    icon: Icons.lock_reset_rounded,
                    isDestructive: true,
                    title: l10n.troubleshootResetAuthTitle,
                    subtitle: l10n.troubleshootResetAuthSubtitle,
                    onTap: _resetAuthenticationData,
                  ),
                ),
                const SizedBox(height: 8),

                // Reset & Data Management (Danger Zone)
                SettingsSection(
                  title: l10n.troubleshootDataMgmtSection,
                  children: [
                    SettingsActionTile(
                      icon: Icons.delete_sweep_rounded,
                      isDestructive: true,
                      title: l10n.troubleshootClearDataSelectiveTitle,
                      subtitle: l10n.troubleshootClearDataSelectiveSubtitle,
                      onTap: _showSelectiveClearDataSheet,
                    ),
                    SettingsActionTile(
                      icon: Icons.settings_backup_restore_rounded,
                      title: l10n.troubleshootResetAppSettingsTitle,
                      subtitle: l10n.troubleshootResetAppSettingsSubtitle,
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
