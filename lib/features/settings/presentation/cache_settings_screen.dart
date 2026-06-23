import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/caching/cache_config.dart';
import 'package:shonenx/core/caching/cache_manager.dart';
import 'package:shonenx/core/caching/domain/cache_entry.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class CacheSettingsScreen extends ConsumerStatefulWidget {
  const CacheSettingsScreen({super.key});

  @override
  ConsumerState<CacheSettingsScreen> createState() =>
      _CacheSettingsScreenState();
}

class _CacheSettingsScreenState extends ConsumerState<CacheSettingsScreen> {
  int _totalCacheSize = 0;
  List<CacheEntry> _cacheEntries = [];
  bool _isLoadingBreakdown = true;

  @override
  void initState() {
    super.initState();
    _loadCacheData();
  }

  Future<void> _loadCacheData() async {
    setState(() => _isLoadingBreakdown = true);
    final cacheManager = ref.read(cacheManagerProvider);
    final size = await cacheManager.getCacheSize();
    final entries = await cacheManager.getAllEntries();
    if (mounted) {
      setState(() {
        _totalCacheSize = size;
        _cacheEntries = entries;
        _isLoadingBreakdown = false;
      });
    }
  }

  Map<String, List<CacheEntry>> _groupEntries() {
    final cacheManager = ref.read(cacheManagerProvider);
    final groups = <String, List<CacheEntry>>{
      'Search Queries': [],
      'Episode Metadata': [],
      'Server Lists': [],
      'Stream Sources': [],
      'General / Others': [],
    };

    for (final entry in _cacheEntries) {
      final category = cacheManager.getCategoryName(entry.key);
      groups.putIfAbsent(category, () => []).add(entry);
    }
    return groups;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Search Queries':
        return Icons.search_rounded;
      case 'Episode Metadata':
        return Icons.format_list_bulleted_rounded;
      case 'Server Lists':
        return Icons.dns_rounded;
      case 'Stream Sources':
        return Icons.play_circle_outline_rounded;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      final gb = bytes / (1024 * 1024 * 1024);
      return gb % 1 == 0 ? '${gb.toInt()} GB' : '${gb.toStringAsFixed(1)} GB';
    } else {
      final mb = bytes / (1024 * 1024);
      return mb % 1 == 0 ? '${mb.toInt()} MB' : '${mb.toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cacheConfig = ref.watch(cacheConfigProvider);
    final notifier = ref.read(cacheConfigProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final maxCacheSize = cacheConfig.maxCacheSize;
    final usedFraction = maxCacheSize > 0
        ? (_totalCacheSize / maxCacheSize).clamp(0.0, 1.0)
        : 0.0;

    final double pct = usedFraction * 100;
    final String pctLabel;
    if (_totalCacheSize == 0) {
      pctLabel = '0%';
    } else if (pct < 0.1) {
      pctLabel = '<0.1%';
    } else if (pct < 1.0) {
      pctLabel = '${pct.toStringAsFixed(1)}%';
    } else {
      pctLabel = '${pct.toStringAsFixed(0)}%';
    }

    final visualFraction = _totalCacheSize > 0
        ? usedFraction.clamp(0.02, 1.0)
        : 0.0;

    final grouped = _groupEntries();

    return AppScaffold(
      title: 'Cache Manager',
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 8.0,
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: visualFraction),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return SizedBox(
                            height: 70,
                            width: 70,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 6,
                              backgroundColor: cs.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                value > 0.85 ? cs.error : cs.primary,
                              ),
                            ),
                          );
                        },
                      ),
                      Text(
                        pctLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: pctLabel.length > 4 ? 10 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage Usage',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_totalCacheSize / 1024 / 1024).toStringAsFixed(2)} MB used out of ${_formatBytes(maxCacheSize)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Isar Database cache contains ${_cacheEntries.length} items',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          SettingsSection(
            title: 'Caching Settings',
            children: [
              SettingsSwitchTile(
                icon: Icons.cached_outlined,
                title: 'Enable HTTP Caching',
                subtitle:
                    'Cache network responses to load pages faster and save data.',
                value: cacheConfig.enableCaching,
                onChanged: (val) {
                  notifier.setEnableCaching(val);
                },
              ),
              SettingsSwitchTile(
                icon: Icons.refresh_rounded,
                title: 'Bypass Cache (Force Refresh)',
                subtitle:
                    'Forces network fetching, bypassing cached results on reads.',
                value: cacheConfig.bypassCache,
                onChanged: (val) {
                  notifier.setBypassCache(val);
                },
              ),
              SettingsDropdownTile<int>(
                icon: Icons.storage_outlined,
                title: 'Maximum Cache Size',
                value: cacheConfig.maxCacheSize,
                items: const [
                  DropdownMenuItem(
                    value: 100 * 1024 * 1024,
                    child: Text('100 MB'),
                  ),
                  DropdownMenuItem(
                    value: 250 * 1024 * 1024,
                    child: Text('250 MB'),
                  ),
                  DropdownMenuItem(
                    value: 500 * 1024 * 1024,
                    child: Text('500 MB'),
                  ),
                  DropdownMenuItem(
                    value: 1024 * 1024 * 1024,
                    child: Text('1 GB'),
                  ),
                ],
                onChanged: cacheConfig.enableCaching
                    ? (val) {
                        if (val != null) {
                          notifier.setMaxCacheSize(val);
                        }
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingsSection(
            title: 'Cache Breakdown',
            children: [
              if (_isLoadingBreakdown)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                ...grouped.entries.map((group) {
                  final categoryName = group.key;
                  final entries = group.value;
                  final count = entries.length;
                  final size = entries.fold<int>(
                    0,
                    (prev, element) => prev + element.bodyBytes.length,
                  );

                  if (count == 0) return const SizedBox.shrink();

                  return AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: SettingsActionTile(
                      icon: _getCategoryIcon(categoryName),
                      title: categoryName,
                      subtitle:
                          '$count items (${(size / 1024).toStringAsFixed(1)} KB)',
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          await ref
                              .read(cacheManagerProvider)
                              .deleteEntriesByCategory(categoryName);
                          await _loadCacheData();
                        },
                      ),
                    ),
                  );
                }),
                if (_cacheEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24.0,
                      horizontal: 16.0,
                    ),
                    child: Center(
                      child: Text(
                        'No cached data available.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          SettingsSection(
            title: 'Global Actions',
            children: [
              SettingsActionTile(
                icon: Icons.delete_forever_outlined,
                title: 'Clear Entire Cache',
                subtitle: 'Delete all cached files and network logs.',
                isDestructive: true,
                onTap: () async {
                  await ref.read(cacheManagerProvider).clearCache();
                  await _loadCacheData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
