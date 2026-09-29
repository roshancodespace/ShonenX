import 'package:shonenx/shared/widgets/smart_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_media_mixin.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/history/providers/history_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_watching_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_reading_card.dart';

class ContinueHistoryScreen extends ConsumerStatefulWidget {
  final MediaType type;

  const ContinueHistoryScreen({super.key, required this.type});

  @override
  ConsumerState<ContinueHistoryScreen> createState() =>
      _ContinueHistoryScreenState();
}

class _ContinueHistoryScreenState extends ConsumerState<ContinueHistoryScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  Future<void> _deleteSelected(bool isAnime) async {
    final toDelete = _selectedIds.toList();
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });

    await ref.read(historyRepositoryProvider).deleteByMediaIds(toDelete);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${toDelete.length} item(s) from history'),
        ),
      );
    }
  }

  void _showMediaOptionsBottomSheet(
    BuildContext context,
    String id,
    String title,
    String imageUrl,
    bool isAnime,
  ) {
    AppBottomSheet.show(
      context: context,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow_rounded),
            title: Text(isAnime ? 'Continue Watching' : 'Continue Reading'),
            onTap: () {
              Navigator.pop(context);
              context.pushContinueHistoryItem(widget.type, id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Open Details (No Play)'),
            onTap: () {
              Navigator.pop(context);
              context.pushDetails(
                mediaType: widget.type,
                media: UnifiedMedia(
                  id: id,
                  title: MediaTitle(english: title),
                  type: widget.type,
                  cover: imageUrl,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('Select Media'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _isSelectionMode = true;
                _selectedIds.add(id);
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Remove from History',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(this.context);
              Navigator.pop(context);
              await ref.read(historyRepositoryProvider).deleteByMediaId(id);
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Removed from history')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSelectionHeader(List<dynamic> filtered, bool isAnime) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search history...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
          ),
          if (_isSelectionMode) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == filtered.length) {
                    _selectedIds.clear();
                  } else {
                    for (final e in filtered) {
                      _selectedIds.add(e.mediaId);
                    }
                  }
                });
              },
              child: Text(
                _selectedIds.length == filtered.length
                    ? 'Deselect All'
                    : 'Select All',
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAnime = widget.type == MediaType.ANIME;
    final uiState = ref.watch(uiPrefsProvider);
    final style = uiState.cardStyle;
    final isWideMode = uiState.isMediaCardWide(style.name);
    final scale = ref.watch(themePrefsProvider).uiScaleFactor;
    final layout = style.getScaledLayout(scale, isWideMode: isWideMode);
    final theme = Theme.of(context);

    final historyAsync = ref
        .watch(historyPerMediaProvider((mediaType: widget.type.id, limit: 100)))
        .whenData((data) => data.toList());

    return AppScaffold(
      title: _isSelectionMode
          ? '${_selectedIds.length} Selected'
          : (isAnime ? 'Continue Watching' : 'Continue Reading'),
      subtitle: _isSelectionMode
          ? 'Select items to delete'
          : 'Pick up where you left off',
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Selected',
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _deleteSelected(isAnime),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel Selection',
            onPressed: () => setState(() {
              _isSelectionMode = false;
              _selectedIds.clear();
            }),
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Select Items',
            onPressed: () => setState(() => _isSelectionMode = true),
          ),
        ],
      ],
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (entries) {
          final filtered = _searchQuery.isEmpty
              ? entries
              : entries.where((e) {
                  final title = e.mediaTitle;
                  return title.toLowerCase().contains(_searchQuery);
                }).toList();

          if (entries.isEmpty) {
            return const Center(child: Text('No history found.'));
          }

          return Column(
            children: [
              _buildSearchAndSelectionHeader(filtered, isAnime),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching history items.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate: SliverGridDelegateWithMinCrossAxisExtent(
                          minCrossAxisExtent: layout.width,
                          childAspectRatio: layout.aspectRatio,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          final String id = entry.mediaId;
                          final String title = entry.mediaTitle;
                          final String imageUrl =
                              entry.cover ??
                              (isAnime ? entry.thumbnailUrl : null) ??
                              '';
                          final isSelected = _selectedIds.contains(id);

                          return Stack(
                            children: [
                              AnimatedScale(
                                scale: _isSelectionMode && !isSelected
                                    ? 0.95
                                    : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: AnimatedOpacity(
                                  opacity: _isSelectionMode && !isSelected
                                      ? 0.6
                                      : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: MediaCard(
                                    media: UnifiedMedia(
                                      id: id,
                                      type: isAnime
                                          ? MediaType.ANIME
                                          : MediaType.MANGA,
                                      title: MediaTitle(english: title),
                                      cover: imageUrl,
                                    ),
                                    tag: 'ch-$id',
                                    style: style,
                                    onSecondaryTap: () {
                                      if (!_isSelectionMode) {
                                        _showMediaOptionsBottomSheet(
                                          context,
                                          id,
                                          title,
                                          imageUrl,
                                          isAnime,
                                        );
                                      }
                                    },
                                    onLongPress: () {
                                      if (!_isSelectionMode) {
                                        _showMediaOptionsBottomSheet(
                                          context,
                                          id,
                                          title,
                                          imageUrl,
                                          isAnime,
                                        );
                                      } else {
                                        _toggleSelection(id);
                                      }
                                    },
                                    onTap: () {
                                      if (_isSelectionMode) {
                                        _toggleSelection(id);
                                      } else {
                                        context.pushContinueHistoryItem(
                                          widget.type,
                                          id,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              if (_isSelectionMode)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.black54,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Icon(
                                        isSelected
                                            ? Icons.check
                                            : Icons.circle_outlined,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ContinueHistoryItemsScreen extends ConsumerStatefulWidget {
  final MediaType type;
  final String mediaId;

  const ContinueHistoryItemsScreen({
    super.key,
    required this.type,
    required this.mediaId,
  });

  @override
  ConsumerState<ContinueHistoryItemsScreen> createState() =>
      _ContinueHistoryItemsScreenState();
}

class _ContinueHistoryItemsScreenState
    extends ConsumerState<ContinueHistoryItemsScreen>
    with ContinueMediaMixin<ContinueHistoryItemsScreen> {
  @override
  Widget build(BuildContext context) {
    final isAnime = widget.type == MediaType.ANIME;

    final historyAsync = ref
        .watch(historyForMediaProvider(widget.mediaId))
        .whenData((data) => data.toList());

    return AppScaffold(
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No history found.'));
          }

          final prefsAsync = ref.watch(uiPrefsProvider);
          final style = isAnime
              ? prefsAsync.continueWatchingStyle
              : prefsAsync.continueReadingStyle;

          final isWideMode = isAnime
              ? prefsAsync.isContinueWatchingWide(style.name)
              : prefsAsync.isContinueReadingWide(style.name);

          final layout = style.getLayout(
            isContinueWatching: isAnime,
            isContinueReading: !isAnime,
            isWideMode: isWideMode,
          );

          final firstEntry = entries.first;
          final title = firstEntry.mediaTitle;
          final bannerUrl =
              firstEntry.banner ?? firstEntry.cover ?? firstEntry.thumbnailUrl;
          final coverUrl = firstEntry.cover ?? bannerUrl;
          final imageUrl = bannerUrl ?? coverUrl ?? '';

          int totalWatched = entries.length;
          String totalTimeStr = '';
          if (isAnime) {
            final totalMillis = entries.fold<int>(
              0,
              (sum, e) => sum + (e.total.toInt()),
            );
            final duration = Duration(milliseconds: totalMillis);
            final hours = duration.inHours;
            final mins = (duration.inMinutes % 60);
            totalTimeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
          } else {
            final totalPages = entries.fold<int>(
              0,
              (sum, e) => sum + (e.total.toInt()),
            );
            totalTimeStr = '$totalPages Pages';
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.isNotEmpty)
                        ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black,
                                Colors.black,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.dstIn,
                          child: SmartImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildStatBadge(
                                  context,
                                  Icons.play_circle_outline,
                                  isAnime
                                      ? '$totalWatched Episodes'
                                      : '$totalWatched Chapters',
                                ),
                                const SizedBox(width: 8),
                                _buildStatBadge(
                                  context,
                                  Icons.timer_outlined,
                                  totalTimeStr,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(10),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isWideMode
                        ? layout.width * 1.5
                        : layout.width * 1.2,
                    childAspectRatio: layout.width / layout.height,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = entries[index];

                    if (isAnime) {
                      final duration = entry.total;
                      final pos = entry.progress;
                      final progress = (duration > 0) ? (pos / duration) : 0.0;

                      return ContinueWatchingItem(
                        entry: entry,
                        progress: progress,
                        style: style,
                      );
                    } else {
                      final total = entry.total;
                      final current = entry.progress;
                      final progress = (total > 0) ? (current / total) : 0.0;

                      return ContinueReadingItem(
                        entry: entry,
                        progress: progress,
                        style: style,
                      );
                    }
                  }, childCount: entries.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatBadge(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
