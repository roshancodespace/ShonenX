import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/widgets/anime/anime_continue_card.dart';

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
  String _filterBy = 'all';
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
      duration: const Duration(milliseconds: 200),
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
    try {
      await widget.box.clearAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing history: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
    _exitMultiSelectMode();
  }

  void _deleteSelected() async {
    try {
      for (var key in _selectedItems.toList()) {
        final parts = key.split('-');
        if (parts.length != 2) continue;

        final animeId = int.tryParse(parts[0]);
        final episodeNumber = int.tryParse(parts[1]);

        if (animeId == null || episodeNumber == null) continue;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting items: $e'),
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

      if (_searchQuery.isNotEmpty) {
        entries = entries
            .where((entry) => entry.anime.animeTitle
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
      }

      if (_filterBy != 'all') {
        entries = entries.where((entry) {
          return _filterBy == 'completed'
              ? entry.episode.isCompleted
              : !entry.episode.isCompleted;
        }).toList();
      }

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
              .compareTo(a.episode.watchedAt ?? DateTime(1970)));
          break;
      }

      return entries;
    } catch (e) {
      debugPrint('Error getting filtered entries: $e');
      return [];
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final theme = Theme.of(context);
    final isSelected = _filterBy == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterBy = value),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        selectedColor:
            theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        checkmarkColor: theme.colorScheme.primary,
        labelStyle: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        backgroundColor: theme.colorScheme.surfaceContainerLow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
                  backgroundColor: theme.colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon: Icon(Iconsax.arrow_left_25,
                        size: 20, color: theme.colorScheme.primary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    'Continue Watching',
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _groupMode ? Iconsax.grid_25 : Iconsax.grid_15,
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: () => setState(() => _groupMode = !_groupMode),
                      tooltip: 'Toggle Layout',
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Iconsax.sort5,
                          size: 20, color: theme.colorScheme.onSurface),
                      onSelected: (value) => setState(() => _sortBy = value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'title',
                          child: Text('Sort by Title',
                              style: GoogleFonts.roboto(fontSize: 14)),
                        ),
                        PopupMenuItem(
                          value: 'episode',
                          child: Text('Sort by Episode',
                              style: GoogleFonts.roboto(fontSize: 14)),
                        ),
                        PopupMenuItem(
                          value: 'lastWatched',
                          child: Text('Sort by Last Watched',
                              style: GoogleFonts.roboto(fontSize: 14)),
                        ),
                      ],
                      color: theme.colorScheme.surfaceContainer,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(100),
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
                                setState(() {
                                  if (_selectedItems.contains(key)) {
                                    _selectedItems.remove(key);
                                    if (_selectedItems.isEmpty) {
                                      _exitMultiSelectMode();
                                    }
                                  } else {
                                    _selectedItems.add(key);
                                  }
                                });
                              },
                              onTap: (key) {
                                if (_multiSelectMode) {
                                  setState(() {
                                    if (_selectedItems.contains(key)) {
                                      _selectedItems.remove(key);
                                      if (_selectedItems.isEmpty) {
                                        _exitMultiSelectMode();
                                      }
                                    } else {
                                      _selectedItems.add(key);
                                    }
                                  });
                                }
                              },
                            );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                    child: SizedBox(height: _multiSelectMode ? 80 : 0)),
              ],
            ),
            if (_multiSelectMode)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: FadeTransition(
                  opacity: _animationController,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.shadow.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          icon: Iconsax.close_circle5,
                          label: 'Cancel',
                          color: theme.colorScheme.primary,
                          onTap: _exitMultiSelectMode,
                        ),
                        _ActionButton(
                          icon: Iconsax.trash5,
                          label: 'Delete',
                          color: theme.colorScheme.error,
                          onTap:
                              _selectedItems.isEmpty ? null : _deleteSelected,
                        ),
                        _ActionButton(
                          icon: Iconsax.broom5,
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: theme.colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Clear All History?',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will remove all watch progress and cannot be undone.',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      _clearAllEntries();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      backgroundColor: theme.colorScheme.errorContainer
                          .withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.roboto(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onTap == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered && !isDisabled
                ? widget.color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.color.withValues(alpha: isDisabled ? 0.5 : 1.0),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: isDisabled ? 0.5 : 1.0),
                ),
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search titles...',
          hintStyle: GoogleFonts.roboto(
            fontSize: 14,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(Iconsax.search_normal_15,
              size: 20, color: theme.colorScheme.primary),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        style: GoogleFonts.roboto(
            fontSize: 14, color: theme.colorScheme.onSurface),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.video_octagon5,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Watch History',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Watch some anime to track your progress!',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon:
                Icon(Iconsax.play5, size: 20, color: theme.colorScheme.primary),
            label: Text(
              'Browse Anime',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2)),
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
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
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

class _CardItem extends StatefulWidget {
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
  State<_CardItem> createState() => _CardItemState();
}

class _CardItemState extends State<_CardItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Hero(
        tag: 'anime_${widget.anime.animeId}_ep_${widget.episode.episodeNumber}',
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onLongPress: widget.onLongPress,
            onTap: widget.onTap,
            child: ContinueWatchingCard(
              anime: widget.anime,
              episode: widget.episode,
              index: widget.index,
              isSelected: widget.isSelected,
              onTap: widget.onTap,
              multiSelectMode: widget.multiSelectMode,
            ),
          ),
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
    bool areAllEpisodesSelected() {
      for (var episode in widget.episodes) {
        final key = '${episode.anime.animeId}-${episode.episode.episodeNumber}';
        if (!widget.selectedItems.contains(key)) return false;
      }
      return true;
    }

    void toggleGroupSelection() {
      setState(() {
        if (areAllEpisodesSelected()) {
          for (var episode in widget.episodes) {
            final key =
                '${episode.anime.animeId}-${episode.episode.episodeNumber}';
            widget.selectedItems.remove(key);
          }
          if (widget.selectedItems.isEmpty) {
            // Trigger exit multi-select mode
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && widget.multiSelectMode) {
                (context.findAncestorStateOfType<_ContentState>())
                    ?._exitMultiSelectMode();
              }
            });
          }
        } else {
          for (var episode in widget.episodes) {
            final key =
                '${episode.anime.animeId}-${episode.episode.episodeNumber}';
            if (!widget.selectedItems.contains(key)) {
              widget.onTap(key);
            }
          }
        }
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Material(
            color: widget.multiSelectMode && areAllEpisodesSelected()
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: InkWell(
              onTap: widget.multiSelectMode
                  ? toggleGroupSelection
                  : () => setState(() => _isExpanded = !_isExpanded),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: widget.anime.animeCover.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.anime.animeCover,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color:
                                          theme.colorScheme.surfaceContainerLow,
                                    ),
                                    errorWidget: (_, __, ___) => Icon(
                                      Iconsax.gallery_slash5,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : Icon(
                                    Iconsax.gallery5,
                                    size: 24,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                          ),
                        ),
                        if (widget.multiSelectMode)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: areAllEpisodesSelected()
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 1.5),
                              ),
                              child: areAllEpisodesSelected()
                                  ? const Icon(Iconsax.tick_circle5,
                                      size: 10, color: Colors.white)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.anime.animeTitle,
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.episodes.length} episode${widget.episodes.length > 1 ? 's' : ''}',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.multiSelectMode)
                          IconButton(
                            icon: Icon(
                              areAllEpisodesSelected()
                                  ? Iconsax.tick_circle5
                                  : Iconsax.add_circle,
                              size: 20,
                              color: areAllEpisodesSelected()
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: toggleGroupSelection,
                          ),
                        IconButton(
                          icon: AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Iconsax.arrow_down_15,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          onPressed: () =>
                              setState(() => _isExpanded = !_isExpanded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.episodes.length,
              padding: const EdgeInsets.only(bottom: 8),
              itemBuilder: (context, index) {
                final entry = widget.episodes[index];
                final key =
                    '${entry.anime.animeId}-${entry.episode.episodeNumber}';
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: _CardItem(
                    anime: entry.anime,
                    episode: entry.episode,
                    index: index,
                    isSelected: widget.selectedItems.contains(key),
                    onLongPress: () => widget.onLongPress(key),
                    onTap: () => widget.onTap(key),
                    multiSelectMode: widget.multiSelectMode,
                  ),
                );
              },
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromRGBO(
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
      alpha ?? opacity,
    );
  }
}
