import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_watching_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_reading_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/core/utils/responsive.dart';

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

    for (final id in toDelete) {
      if (isAnime) {
        await ref.read(watchHistoryRepositoryProvider).deleteByAnimeId(id);
      } else {
        await ref.read(readHistoryRepositoryProvider).deleteByMangaId(id);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${toDelete.length} item(s) from history'),
        ),
      );
    }
  }

  void _showMediaOptions(
    BuildContext context,
    String id,
    String title,
    String imageUrl,
    bool isAnime,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded),
                title: Text(isAnime ? 'Continue Watching' : 'Continue Reading'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/continue/${widget.type.id}/$id');
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Open Details (No Play)'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/details/${widget.type.id}',
                    extra: UnifiedMedia(
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
                  Navigator.pop(ctx);
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
                  Navigator.pop(ctx);
                  if (isAnime) {
                    await ref
                        .read(watchHistoryRepositoryProvider)
                        .deleteByAnimeId(id);
                  } else {
                    await ref
                        .read(readHistoryRepositoryProvider)
                        .deleteByMangaId(id);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Removed from history')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAnime = widget.type == MediaType.ANIME;
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));
    final theme = Theme.of(context);

    final AsyncValue<List<dynamic>> historyAsync;
    if (isAnime) {
      historyAsync = ref
          .watch(continueWatchingPerAnimeProvider(100))
          .whenData((data) => data.toList());
    } else {
      historyAsync = ref
          .watch(continueReadingPerMangaProvider(100))
          .whenData((data) => data.toList());
    }

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
                  final title =
                      (isAnime ? e.animeTitle : e.mangaTitle) as String;
                  return title.toLowerCase().contains(_searchQuery);
                }).toList();

          if (entries.isEmpty) {
            return const Center(child: Text('No history found.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) => setState(
                            () => _searchQuery = val.trim().toLowerCase(),
                          ),
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
                                _selectedIds.add(
                                  isAnime ? e.animeId : e.mangaId,
                                );
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
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching history items.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate: SliverGridDelegateWithMinCrossAxisExtent(
                          minCrossAxisExtent: style.layout.width,
                          childAspectRatio: style.layout.aspectRatio,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          final String id = isAnime
                              ? entry.animeId
                              : entry.mangaId;
                          final String title = isAnime
                              ? entry.animeTitle
                              : entry.mangaTitle;
                          final String imageUrl =
                              entry.cover ??
                              (isAnime ? entry.thumbnailUrl : null) ??
                              '';
                          final isSelected = _selectedIds.contains(id);

                          return Stack(
                            children: [
                              GestureDetector(
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    _showMediaOptions(
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
                                child: MediaCard(
                                  tag: 'ch-$id',
                                  title: title,
                                  imageUrl: imageUrl,
                                  style: style,
                                  onTap: () {
                                    if (_isSelectionMode) {
                                      _toggleSelection(id);
                                    } else {
                                      context.push(
                                        '/continue/${widget.type.id}/$id',
                                      );
                                    }
                                  },
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

class ContinueHistoryItemsScreen extends ConsumerWidget {
  final MediaType type;
  final String mediaId;

  const ContinueHistoryItemsScreen({
    super.key,
    required this.type,
    required this.mediaId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnime = type == MediaType.ANIME;

    final AsyncValue<List<dynamic>> historyAsync;
    if (isAnime) {
      historyAsync = ref
          .watch(historyEpisodesProvider(mediaId))
          .whenData((data) => data.toList());
    } else {
      historyAsync = ref
          .watch(historyChaptersProvider(mediaId))
          .whenData((data) => data.toList());
    }

    final cwStyle = ref.watch(
      uiPrefsProvider.select((s) => s.continueWatchingStyle),
    );
    final crStyle = ref.watch(
      uiPrefsProvider.select((s) => s.continueReadingStyle),
    );
    final layout = isAnime ? cwStyle.layout : crStyle.layout;

    return AppScaffold(
      title: isAnime ? 'Episodes' : 'Chapters',
      subtitle: isAnime
          ? 'Watched episodes for this anime'
          : 'Read chapters for this manga',
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No history found.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: entries.length,
            gridDelegate: SliverGridDelegateWithMinCrossAxisExtent(
              minCrossAxisExtent: layout.width,
              childAspectRatio: layout.aspectRatio,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];

              if (isAnime) {
                final progress = entry.durationInMilliseconds == 0
                    ? 0.0
                    : (entry.positionInMilliseconds /
                              entry.durationInMilliseconds)
                          .clamp(0.0, 1.0);
                return ContinueWatchingItem(
                  entry: entry,
                  progress: progress,
                  style: cwStyle,
                );
              } else {
                final progress = entry.totalPages == 0
                    ? 0.0
                    : (entry.positionPage / entry.totalPages).clamp(0.0, 1.0);
                return ContinueReadingItem(
                  entry: entry,
                  progress: progress,
                  style: crStyle,
                );
              }
            },
          );
        },
      ),
    );
  }
}
