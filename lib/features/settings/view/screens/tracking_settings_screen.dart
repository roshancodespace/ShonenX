import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/anilist/services/anilist_service_provider.dart';
import 'package:shonenx/core/myanimelist/services/mal_service_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/features/settings/view_model/sync_settings_notifier.dart';

class TrackingSettingsScreen extends ConsumerStatefulWidget {
  const TrackingSettingsScreen({super.key});

  @override
  ConsumerState<TrackingSettingsScreen> createState() =>
      _TrackingSettingsScreenState();
}

class _TrackingSettingsScreenState
    extends ConsumerState<TrackingSettingsScreen> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final syncSettings = ref.watch(syncSettingsProvider);
    final syncNotifier = ref.read(syncSettingsProvider.notifier);
    final auth = ref.watch(authProvider);

    final isAnilistLoggedIn = auth.isAniListAuthenticated;
    final isMalLoggedIn = auth.isMalAuthenticated;

    final noSyncTargets = !syncNotifier.hasAnySyncTarget;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('Sync & Tracking'),
        forceMaterialTransparency: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsSection(
            title: 'Sync Services',
            titleColor: colorScheme.primary,
            children: [
              ToggleableSettingsItem(
                icon: Icon(Iconsax.archive_book, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'AniList',
                description: isAnilistLoggedIn
                    ? 'Sync progress with AniList'
                    : 'Log in to enable AniList sync',
                value: syncSettings.syncAnilist && isAnilistLoggedIn,
                onChanged: (val) {
                  if (!isAnilistLoggedIn) return;
                  ref
                      .read(syncSettingsProvider.notifier)
                      .updateSettings((s) => s.copyWith(syncAnilist: val));
                },
              ),
              ToggleableSettingsItem(
                icon: Icon(Iconsax.book, color: colorScheme.secondary),
                accent: colorScheme.secondary,
                title: 'MyAnimeList',
                description: isMalLoggedIn
                    ? 'Sync progress with MyAnimeList'
                    : 'Log in to enable MAL sync',
                value: syncSettings.syncMal && isMalLoggedIn,
                onChanged: (val) {
                  if (!isMalLoggedIn) return;
                  ref
                      .read(syncSettingsProvider.notifier)
                      .updateSettings((s) => s.copyWith(syncMal: val));
                },
              ),
              ToggleableSettingsItem(
                icon: Icon(Iconsax.mobile, color: colorScheme.tertiary),
                accent: colorScheme.tertiary,
                title: 'Local Sync',
                description: 'Store watchlist & progress on device',
                value: syncSettings.localSync,
                onChanged: (val) => ref
                    .read(syncSettingsProvider.notifier)
                    .updateSettings((s) => s.copyWith(localSync: val)),
              ),
            ],
          ),

          if (noSyncTargets) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No sync targets enabled. Progress will not be tracked anywhere.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          SettingsSection(
            title: 'Sync Mode',
            titleColor: colorScheme.primary,
            children: [
              SegmentedToggleSettingsItem<String>(
                icon: Icon(Iconsax.timer_1, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Sync Strategy',
                description: _syncModeDescription(syncSettings.syncMode),
                selectedValue: syncSettings.syncMode,
                children: const {
                  'realtime': Text('Real-Time'),
                  'background': Text('Background'),
                  'manual': Text('Manual'),
                },
                onValueChanged: (dynamic val) {
                  ref
                      .read(syncSettingsProvider.notifier)
                      .updateSettings((s) => s.copyWith(syncMode: val));
                },
              ),
              if (syncSettings.syncMode == 'background')
                DropdownSettingsItem(
                  icon: Icon(Iconsax.clock, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  title: 'Sync Interval',
                  description: 'How often to sync in the background',
                  value: syncSettings.backgroundIntervalMinutes.toString(),
                  items: const [
                    DropdownMenuItem(value: '15', child: Text('15 minutes')),
                    DropdownMenuItem(value: '30', child: Text('30 minutes')),
                    DropdownMenuItem(value: '60', child: Text('1 hour')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(syncSettingsProvider.notifier)
                          .updateSettings(
                            (s) => s.copyWith(
                              backgroundIntervalMinutes: int.parse(val),
                            ),
                          );
                    }
                  },
                ),
            ],
          ),

          const SizedBox(height: 20),
          SettingsSection(
            title: 'Preferences',
            titleColor: colorScheme.primary,
            children: [
              ToggleableSettingsItem(
                icon: Icon(
                  Iconsax.message_question,
                  color: colorScheme.primary,
                ),
                accent: colorScheme.primary,
                title: 'Update prompt',
                description: 'Always ask before syncing progress',
                value: syncSettings.askBeforeSync,
                onChanged: (val) => ref
                    .read(syncSettingsProvider.notifier)
                    .updateSettings((s) => s.copyWith(askBeforeSync: val)),
              ),
            ],
          ),

          const SizedBox(height: 20),
          SettingsSection(
            title: 'Actions',
            titleColor: colorScheme.primary,
            children: [
              NormalSettingsItem(
                icon: Icon(
                  _isSyncing ? Iconsax.refresh : Icons.refresh,
                  color: colorScheme.primary,
                ),
                accent: colorScheme.primary,
                title: _isSyncing ? 'Syncing...' : 'Force Sync Now',
                description: 'Manually trigger a full sync',
                onTap: _isSyncing ? null : () => _forceSyncNow(ref),
              ),
            ],
          ),

          const SizedBox(height: 20),
          SettingsSection(
            title: 'Sync Scope',
            titleColor: colorScheme.primary,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What gets synced',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildScopeRow(
                        theme,
                        Icons.list_alt,
                        'Watchlist entries',
                      ),
                      const SizedBox(height: 8),
                      _buildScopeRow(
                        theme,
                        Icons.play_arrow_rounded,
                        'Episode progress',
                      ),
                      const SizedBox(height: 8),
                      _buildScopeRow(
                        theme,
                        Icons.label_outline,
                        'Status updates',
                      ),
                      const SizedBox(height: 8),
                      _buildScopeRow(
                        theme,
                        Icons.star_border_rounded,
                        'Scores & ratings',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScopeRow(ThemeData theme, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  String _syncModeDescription(String mode) {
    switch (mode) {
      case 'realtime':
        return 'Sync immediately on every change';
      case 'background':
        return 'Sync at defined intervals';
      case 'manual':
        return 'Only sync when manually triggered';
      default:
        return '';
    }
  }

  Future<void> _forceSyncNow(WidgetRef ref) async {
    setState(() => _isSyncing = true);
    try {
      final syncNotifier = ref.read(syncSettingsProvider.notifier);
      final List<Future> tasks = [];

      if (syncNotifier.shouldSyncAnilist) {
        AppLogger.i('Force syncing with AniList...');
        tasks.add(
          ref
              .read(anilistServiceProvider)
              .getUserAnimeList(
                type: 'ANIME',
                status: 'CURRENT',
                page: 1,
                perPage: 50,
              ),
        );
      }

      if (syncNotifier.shouldSyncMal) {
        AppLogger.i('Force syncing with MAL...');
        tasks.add(
          ref
              .read(malServiceProvider)
              .getUserAnimeList(
                type: 'ANIME',
                status: 'watching',
                page: 1,
                perPage: 50,
              ),
        );
      }

      if (tasks.isNotEmpty) {
        await Future.wait(tasks);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tasks.isEmpty
                  ? 'No sync services enabled'
                  : 'Sync completed successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Force sync failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }
}
