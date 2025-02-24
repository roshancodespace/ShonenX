import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/widgets/anime/anime_continue_card.dart';
import 'dart:async';

class ContinueAllScreen extends StatelessWidget {
  final AnimeWatchProgressBox animeWatchProgressBox;

  const ContinueAllScreen({super.key, required this.animeWatchProgressBox});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _Content(box: animeWatchProgressBox),
    );
  }
}

class _Content extends StatefulWidget {
  final AnimeWatchProgressBox box;

  const _Content({required this.box});

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _sortBy = 'lastWatched';
  String _filterBy = 'all'; // 'all', 'inProgress', 'completed'
  bool _groupMode = false;
  bool _multiSelectMode = false;
  final Set<String> _selectedItems = {};
  late AnimationController _animationController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (!widget.box.isInitialized) {
      widget.box.init();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value);
    });
  }

  void _enterMultiSelectMode() {
    setState(() {
      _multiSelectMode = true;
      _animationController.forward();
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _multiSelectMode = false;
      _selectedItems.clear();
      _animationController.reverse();
    });
  }

  void _clearAllEntries() async {
    await widget.box.clearAll();
    _exitMultiSelectMode();
  }

  void _deleteSelected() async {
    for (var key in _selectedItems) {
      final parts = key.split('-');
      final animeId = int.parse(parts[0]);
      final episodeNumber = int.parse(parts[1]);
      final entry = widget.box.getEntry(animeId);
      if (entry != null) {
        final updatedEpisodes = Map<int, EpisodeProgress>.from(entry.episodesProgress);
        updatedEpisodes.remove(episodeNumber);
        if (updatedEpisodes.isEmpty) {
          await widget.box.deleteEntry(animeId);
        } else {
          await widget.box.setEntry(entry.copyWith(episodesProgress: updatedEpisodes));
        }
      }
    }
    _exitMultiSelectMode();
  }

  List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})> _getFilteredEntries() {
    var entries = widget.box.getAllMostRecentWatchedEpisodesWithAnime();

    // Search filter
    if (_searchQuery.isNotEmpty) {
      entries = entries
          .where((entry) => entry.anime.animeTitle.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by status
    if (_filterBy != 'all') {
      entries = entries.where((entry) {
        return _filterBy == 'completed' ? entry.episode.isCompleted : !entry.episode.isCompleted;
      }).toList();
    }

    // Sorting
    switch (_sortBy) {
      case 'title':
        entries.sort((a, b) => a.anime.animeTitle.compareTo(b.anime.animeTitle));
        break;
      case 'episode':
        entries.sort((a, b) => a.episode.episodeNumber.compareTo(b.episode.episodeNumber));
        break;
      case 'lastWatched':
        entries.sort((a, b) => b.episode.watchedAt!.compareTo(a.episode.watchedAt!));
        break;
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: theme.colorScheme.surface,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left_2),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'Continue Watching',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: Icon(_groupMode ? Iconsax.grid_2 : Iconsax.grid_1),
                  onPressed: () => setState(() => _groupMode = !_groupMode),
                  tooltip: 'Toggle Layout',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Iconsax.sort),
                  onSelected: (value) => setState(() => _sortBy = value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'title', child: Text('Sort by Title')),
                    const PopupMenuItem(value: 'episode', child: Text('Sort by Episode')),
                    const PopupMenuItem(value: 'lastWatched', child: Text('Sort by Last Watched')),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Iconsax.filter),
                  onSelected: (value) => setState(() => _filterBy = value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'all', child: Text('All')),
                    const PopupMenuItem(value: 'inProgress', child: Text('In Progress')),
                    const PopupMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: _SearchField(onChanged: _onSearchChanged),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: ValueListenableBuilder<Box>(
                valueListenable: widget.box.boxValueListenable,
                builder: (context, box, child) {
                  final entries = _getFilteredEntries();
                  return entries.isEmpty
                      ? const SliverFillRemaining(child: _EmptyState())
                      : _EntriesView(
                          entries: entries,
                          groupMode: _groupMode,
                          multiSelectMode: _multiSelectMode,
                          selectedItems: _selectedItems,
                          onLongPress: (key) {
                            if (!_multiSelectMode) _enterMultiSelectMode();
                            setState(() => _selectedItems.contains(key)
                                ? _selectedItems.remove(key)
                                : _selectedItems.add(key));
                          },
                          onTap: (key) {
                            if (_multiSelectMode) {
                              setState(() => _selectedItems.contains(key)
                                  ? _selectedItems.remove(key)
                                  : _selectedItems.add(key));
                            } else {
                              // Add navigation or action for single tap
                            }
                          },
                        );
                },
              ),
            ),
          ],
        ),
        if (_multiSelectMode)
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: _exitMultiSelectMode,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Iconsax.close_circle, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: _deleteSelected,
                  backgroundColor: Colors.red,
                  child: const Icon(Iconsax.trash, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: () => _showClearAllDialog(context),
                  backgroundColor: Colors.orange,
                  child: const Icon(Iconsax.broom, color: Colors.white),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will remove all watch progress. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _clearAllEntries();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search titles...',
          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          prefixIcon: const Icon(Iconsax.search_normal),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.video_octagon, size: 100, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Nothing Here Yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Watch some anime to track your progress!',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EntriesView extends StatelessWidget {
  final List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})> entries;
  final bool groupMode;
  final bool multiSelectMode;
  final Set<String> selectedItems;
  final Function(String) onLongPress;
  final Function(String) onTap;

  const _EntriesView({
    required this.entries,
    required this.groupMode,
    required this.multiSelectMode,
    required this.selectedItems,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    if (groupMode) {
      final groupedEntries = <int, List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>>{};
      for (var entry in entries) {
        groupedEntries.putIfAbsent(entry.anime.animeId, () => []).add(entry);
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final animeId = groupedEntries.keys.elementAt(index);
            final group = groupedEntries[animeId]!;
            return _GroupedSection(
              anime: group.first.anime,
              episodes: group,
              multiSelectMode: multiSelectMode,
              selectedItems: selectedItems,
              onLongPress: onLongPress,
              onTap: onTap,
            );
          },
          childCount: groupedEntries.length,
        ),
      );
    }

    return isWideScreen
        ? SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 16 / 10,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildCard(context, index),
              childCount: entries.length,
            ),
          )
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCard(context, index),
              ),
              childCount: entries.length,
            ),
          );
  }

  Widget _buildCard(BuildContext context, int index) {
    final entry = entries[index];
    final key = '${entry.anime.animeId}-${entry.episode.episodeNumber}';
    return AnimatedScale(
      scale: selectedItems.contains(key) ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: _CardItem(
        anime: entry.anime,
        episode: entry.episode,
        index: index,
        isSelected: selectedItems.contains(key),
        onLongPress: () => onLongPress(key),
        onTap: () => onTap(key),
        multiSelectMode: multiSelectMode,
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  final AnimeWatchProgressEntry anime;
  final EpisodeProgress episode;
  final int index;
  final bool isSelected;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final bool multiSelectMode;

  const _CardItem({
    required this.anime,
    required this.episode,
    required this.index,
    required this.isSelected,
    required this.onLongPress,
    required this.onTap,
    required this.multiSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: ContinueWatchingCard(
        anime: anime,
        episode: episode,
        index: index,
        isSelected: isSelected,
        onTap: onTap,
        multiSelectMode: multiSelectMode,
      ),
    );
  }
}

class _GroupedSection extends StatefulWidget {
  final AnimeWatchProgressEntry anime;
  final List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})> episodes;
  final bool multiSelectMode;
  final Set<String> selectedItems;
  final Function(String) onLongPress;
  final Function(String) onTap;

  const _GroupedSection({
    required this.anime,
    required this.episodes,
    required this.multiSelectMode,
    required this.selectedItems,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  State<_GroupedSection> createState() => _GroupedSectionState();
}

class _GroupedSectionState extends State<_GroupedSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundImage: widget.anime.animeCover.isNotEmpty ? NetworkImage(widget.anime.animeCover) : null,
              child: widget.anime.animeCover.isEmpty ? const Icon(Iconsax.image) : null,
            ),
            title: Text(
              widget.anime.animeTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Iconsax.arrow_down_1 : Iconsax.arrow_right_2),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            ...widget.episodes.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _CardItem(
                    anime: entry.anime,
                    episode: entry.episode,
                    index: widget.episodes.indexOf(entry),
                    isSelected: widget.selectedItems.contains('${entry.anime.animeId}-${entry.episode.episodeNumber}'),
                    onLongPress: () => widget.onLongPress('${entry.anime.animeId}-${entry.episode.episodeNumber}'),
                    onTap: () => widget.onTap('${entry.anime.animeId}-${entry.episode.episodeNumber}'),
                    multiSelectMode: widget.multiSelectMode,
                  ),
                )),
        ],
      ),
    );
  }
}