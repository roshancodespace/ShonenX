import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/widgets/anime/anime_continue_card.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

class ContinueWatchingScreen extends StatelessWidget {
  final AnimeWatchProgressBox animeWatchProgressBox;

  const ContinueWatchingScreen(
      {super.key, required this.animeWatchProgressBox});

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

class _ContentState extends State<_Content>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _sortBy = 'lastWatched';
  String _filterBy = 'all'; // 'all', 'inProgress', 'completed'
  bool _groupMode = false;
  bool _multiSelectMode = false;
  final Set<String> _selectedItems = {};
  late AnimationController _animationController;
  Timer? _debounce;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController = ScrollController();
    if (!widget.box.isInitialized) {
      widget.box.init();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
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
    try {
      for (var key in _selectedItems) {
        final parts = key.split('-');
        if (parts.length != 2) continue; // Bug fix: Skip invalid keys

        final animeId = int.tryParse(parts[0]);
        final episodeNumber = int.tryParse(parts[1]);

        if (animeId == null || episodeNumber == null) {
          continue; // Bug fix: Skip invalid IDs
        }

        final entry = widget.box.getEntry(animeId);
        if (entry != null) {
          final updatedEpisodes =
              Map<int, EpisodeProgress>.from(entry.episodesProgress);
          updatedEpisodes.remove(episodeNumber);

          if (updatedEpisodes.isEmpty) {
            await widget.box.deleteEntry(animeId);
          } else {
            await widget.box
                .setEntry(entry.copyWith(episodesProgress: updatedEpisodes));
          }
        }
      }
    } catch (e) {
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting selected items: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      _exitMultiSelectMode();
    }
  }

  List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>
      _getFilteredEntries() {
    try {
      var entries = widget.box.getAllMostRecentWatchedEpisodesWithAnime();

      // Search filter
      if (_searchQuery.isNotEmpty) {
        entries = entries
            .where((entry) => entry.anime.animeTitle
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
      }

      // Filter by status
      if (_filterBy != 'all') {
        entries = entries.where((entry) {
          return _filterBy == 'completed'
              ? entry.episode.isCompleted
              : !entry.episode.isCompleted;
        }).toList();
      }

      // Sorting
      switch (_sortBy) {
        case 'title':
          entries
              .sort((a, b) => a.anime.animeTitle.compareTo(b.anime.animeTitle));
          break;
        case 'episode':
          entries.sort((a, b) =>
              a.episode.episodeNumber.compareTo(b.episode.episodeNumber));
          break;
        case 'lastWatched':
          entries.sort((a, b) => (b.episode.watchedAt ?? DateTime(1970))
              .compareTo(a.episode.watchedAt ??
                  DateTime(1970))); // Bug fix: Handle null watchedAt
          break;
      }

      return entries;
    } catch (e) {
      // Log or handle error
      debugPrint('Error getting filtered entries: $e');
      return [];
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _filterBy == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterBy = value),
        selectedColor: colorScheme.primaryContainer,
        labelStyle: GoogleFonts.montserrat(
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color:
                isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon:
                        Icon(Iconsax.arrow_left_2, color: colorScheme.primary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    'Continue Watching',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(_groupMode ? Iconsax.grid_2 : Iconsax.grid_1,
                          color: colorScheme.onSurface),
                      onPressed: () => setState(() => _groupMode = !_groupMode),
                      tooltip: 'Toggle Layout',
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Iconsax.sort, color: colorScheme.onSurface),
                      onSelected: (value) => setState(() => _sortBy = value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'title',
                          child: Text('Sort by Title',
                              style: GoogleFonts.montserrat()),
                        ),
                        PopupMenuItem(
                          value: 'episode',
                          child: Text('Sort by Episode',
                              style: GoogleFonts.montserrat()),
                        ),
                        PopupMenuItem(
                          value: 'lastWatched',
                          child: Text('Sort by Last Watched',
                              style: GoogleFonts.montserrat()),
                        ),
                      ],
                      color: colorScheme.surfaceContainer,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(110),
                    child: Column(
                      children: [
                        _SearchField(onChanged: _onSearchChanged),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              _buildFilterChip('All', 'all'),
                              _buildFilterChip('In Progress', 'inProgress'),
                              _buildFilterChip('Completed', 'completed'),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                                  // Add navigation logic here if needed
                                }
                              },
                            );
                    },
                  ),
                ),
                // Add extra padding at the bottom for FAB
                SliverToBoxAdapter(
                  child: SizedBox(height: _multiSelectMode ? 80 : 0),
                )
              ],
            ),
            if (_multiSelectMode)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _animationController,
                  child: Container(
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          icon: Iconsax.close_circle,
                          label: 'Cancel',
                          color: colorScheme.primary,
                          onTap: _exitMultiSelectMode,
                        ),
                        _ActionButton(
                          icon: Iconsax.trash,
                          label: 'Delete',
                          color: colorScheme.error,
                          onTap:
                              _selectedItems.isEmpty ? null : _deleteSelected,
                        ),
                        _ActionButton(
                          icon: Iconsax.broom,
                          label: 'Clear All',
                          color: Colors.orange,
                          onTap: () => _showClearAllDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear All Watch History?',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          'This will remove all watch progress. This action cannot be undone.',
          style: GoogleFonts.montserrat(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _clearAllEntries();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final opacity = isDisabled ? 0.5 : 1.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color.withValues(alpha: opacity),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: opacity),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search titles...',
          hintStyle:
              GoogleFonts.montserrat(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Iconsax.search_normal, color: colorScheme.primary),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: GoogleFonts.montserrat(),
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
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.video_octagon,
              size: 80,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Watch History',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Watch some anime to track your progress!',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Iconsax.play, color: colorScheme.onPrimary),
            label: const Text('Browse Anime'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntriesView extends StatelessWidget {
  final List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>
      entries;
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
      final groupedEntries = <int,
          List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>>{};
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
              maxCrossAxisExtent: 340,
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
                padding: const EdgeInsets.only(bottom: 12),
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
    return Hero(
      tag: 'anime_${anime.animeId}_ep_${episode.episodeNumber}',
      child: GestureDetector(
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
      ),
    );
  }
}

class _GroupedSection extends StatefulWidget {
  final AnimeWatchProgressEntry anime;
  final List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>
      episodes;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Function to check if all episodes in the group are selected
    bool areAllEpisodesSelected() {
      for (var episode in widget.episodes) {
        final key = '${episode.anime.animeId}-${episode.episode.episodeNumber}';
        if (!widget.selectedItems.contains(key)) {
          return false;
        }
      }
      return true;
    }

    // Function to toggle selection of all episodes in the group
    void toggleGroupSelection() {
      if (areAllEpisodesSelected()) {
        // Deselect all episodes
        for (var episode in widget.episodes) {
          final key =
              '${episode.anime.animeId}-${episode.episode.episodeNumber}';
          widget.selectedItems.remove(key);
        }
      } else {
        // Select all episodes
        for (var episode in widget.episodes) {
          final key =
              '${episode.anime.animeId}-${episode.episode.episodeNumber}';
          widget.onTap(key);
        }
      }
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: widget.multiSelectMode && areAllEpisodesSelected()
                  ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : null,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: widget.anime.animeCover.isNotEmpty
                        ? CachedNetworkImageProvider(widget.anime.animeCover)
                        : null,
                    backgroundColor: colorScheme.surfaceContainer,
                    child: widget.anime.animeCover.isEmpty
                        ? Icon(Iconsax.gallery,
                            color: colorScheme.onSurfaceVariant)
                        : null,
                  ),
                  if (widget.multiSelectMode)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 20,
                        width: 20,
                        decoration: BoxDecoration(
                          color: areAllEpisodesSelected()
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: areAllEpisodesSelected()
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
              title: Text(
                widget.anime.animeTitle,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${widget.episodes.length} episode${widget.episodes.length > 1 ? 's' : ''}',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.multiSelectMode)
                    IconButton(
                      icon: Icon(
                        areAllEpisodesSelected()
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: areAllEpisodesSelected()
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                      onPressed: toggleGroupSelection,
                    ),
                  IconButton(
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Iconsax.arrow_down_1,
                        color: colorScheme.primary,
                      ),
                    ),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
                ],
              ),
              onTap: widget.multiSelectMode
                  ? toggleGroupSelection
                  : () => setState(() => _isExpanded = !_isExpanded),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.episodes.length,
              padding: const EdgeInsets.only(bottom: 8),
              itemBuilder: (context, index) {
                final entry = widget.episodes[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _CardItem(
                    anime: entry.anime,
                    episode: entry.episode,
                    index: index,
                    isSelected: widget.selectedItems.contains(
                        '${entry.anime.animeId}-${entry.episode.episodeNumber}'),
                    onLongPress: () => widget.onLongPress(
                        '${entry.anime.animeId}-${entry.episode.episodeNumber}'),
                    onTap: () => widget.onTap(
                        '${entry.anime.animeId}-${entry.episode.episodeNumber}'),
                    multiSelectMode: widget.multiSelectMode,
                  ),
                );
              },
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromRGBO(
      red ?? r.toInt(),
      green ?? g.toInt(),
      blue ?? b.toInt(),
      alpha ?? a.toDouble(),
    );
  }
}
