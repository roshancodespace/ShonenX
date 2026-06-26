import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/caching/cache_manager.dart';
import 'package:shonenx/core/database/database_provider.dart';
import 'package:shonenx/features/discovery/domain/media_preference.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

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
      if (mounted) {
        setState(() {
          _mappingsCount = mappings;
          _trackerLinksCount = trackerLinks;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
