import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/widgets/anime/anime_continue_card.dart';

class ContinueAllScreen extends StatefulWidget {
  final AnimeWatchProgressBox animeWatchProgressBox;

  const ContinueAllScreen({super.key, required this.animeWatchProgressBox});

  @override
  State<ContinueAllScreen> createState() => _ContinueAllScreenState();
}

class _ContinueAllScreenState extends State<ContinueAllScreen> {
  String _searchQuery = '';
  String _sortBy = 'lastWatched'; // Options: 'title', 'episode', 'lastWatched'
  bool _groupMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2, size: 24),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Continue Watching',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(_groupMode ? Iconsax.grid_2 : Iconsax.grid_1, size: 24),
            onPressed: () => setState(() => _groupMode = !_groupMode),
            tooltip: 'Toggle Group Mode',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Iconsax.sort, size: 24),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'title', child: Text('Sort by Title')),
              const PopupMenuItem(
                  value: 'episode', child: Text('Sort by Episode')),
              const PopupMenuItem(
                  value: 'lastWatched', child: Text('Sort by Last Watched')),
            ],
            tooltip: 'Sort Options',
          ),
          IconButton(
            icon: const Icon(Iconsax.trash, size: 24),
            onPressed: () async {
              await widget.animeWatchProgressBox.clearAll();
              if (context.mounted) Navigator.of(context).pop();
            },
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by anime title...',
                hintStyle: GoogleFonts.montserrat(
                    color: Theme.of(context).colorScheme.outlineVariant),
                prefixIcon:
                    const Icon(Iconsax.search_normal, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainer,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<Box>(
              valueListenable: widget.animeWatchProgressBox.boxValueListenable,
              builder: (context, box, child) {
                var entries = widget.animeWatchProgressBox
                    .getAllMostRecentWatchedEpisodesWithAnime();

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  entries = entries
                      .where((entry) => (entry.anime.animeTitle)
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                // Apply sorting
                switch (_sortBy) {
                  case 'title':
                    entries.sort((a, b) => (a.anime.animeTitle )
                        .compareTo(b.anime.animeTitle ));
                    break;
                  case 'episode':
                    entries.sort(
                        (a, b) => a.episode.episodeNumber.compareTo(b.episode.episodeNumber));
                    break;
                  case 'lastWatched':
                    entries.sort((a, b) =>
                        b.episode.watchedAt!.compareTo(a.episode.watchedAt!));
                    break;
                }

                return entries.isEmpty
                    ? const _EmptyContinueAllState()
                    : _ContinueAllContent(
                        entries: entries,
                        groupMode: _groupMode,
                        onDelete: (animeId, episodeNumber) async {
                          final entry = widget.animeWatchProgressBox.getEntry(animeId);
                          if (entry != null) {
                            final updatedEpisodes =
                                Map<int, EpisodeProgress>.from(entry.episodesProgress);
                            updatedEpisodes.remove(episodeNumber);
                            if (updatedEpisodes.isEmpty) {
                              await widget.animeWatchProgressBox.deleteEntry(animeId);
                            } else {
                              await widget.animeWatchProgressBox.setEntry(
                                  entry.copyWith(episodesProgress: updatedEpisodes));
                            }
                          }
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyContinueAllState extends StatelessWidget {
  const _EmptyContinueAllState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.video_circle,
              size: 80, color: colorScheme.outline.withValues(alpha: 0.7)),
          const SizedBox(height: 24),
          Text(
            'No Shows in Progress',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              color: colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start watching something to see it here!',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: colorScheme.outlineVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ContinueAllContent extends ConsumerWidget {
  final List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>
      entries;
  final bool groupMode;
  final Future<void> Function(int animeId, int episodeNumber) onDelete;

  const _ContinueAllContent({
    required this.entries,
    required this.groupMode,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    if (groupMode) {
      // Group by anime ID
      final groupedEntries = <int, List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>>{};
      for (var entry in entries) {
        groupedEntries
            .putIfAbsent(entry.anime.animeId, () => [])
            .add(entry);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedEntries.length,
        itemBuilder: (context, index) {
          final animeId = groupedEntries.keys.elementAt(index);
          final group = groupedEntries[animeId]!;
          return _GroupedAnimeSection(
            anime: group.first.anime,
            episodes: group,
            onDelete: onDelete,
          );
        },
      );
    }

    return isWideScreen
        ? GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: (screenWidth / 300).floor().clamp(2, 4),
              childAspectRatio: 1.8,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Dismissible(
                key: Key('${entry.anime.animeId}-${entry.episode.episodeNumber}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Iconsax.trash, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await onDelete(entry.anime.animeId, entry.episode.episodeNumber);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Removed ${entry.anime.animeTitle} - EP ${entry.episode.episodeNumber}'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            // Logic to undo deletion could be added here
                          },
                        ),
                      ),
                    );
                  }
                },
                child: ContinueWatchingCard(
                  anime: entry.anime,
                  episode: entry.episode,
                  index: index,
                ),
              );
            },
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: Key('${entry.anime.animeId}-${entry.episode.episodeNumber}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Iconsax.trash, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    await onDelete(entry.anime.animeId, entry.episode.episodeNumber);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Removed ${entry.anime.animeTitle} - EP ${entry.episode.episodeNumber}'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              // Logic to undo deletion could be added here
                            },
                          ),
                        ),
                      );
                    }
                  },
                  child: ContinueWatchingCard(
                    anime: entry.anime,
                    episode: entry.episode,
                    index: index,
                  ),
                ),
              );
            },
          );
  }
}

class _GroupedAnimeSection extends StatefulWidget {
  final AnimeWatchProgressEntry anime;
  final List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>
      episodes;
  final Future<void> Function(int animeId, int episodeNumber) onDelete;

  const _GroupedAnimeSection({
    required this.anime,
    required this.episodes,
    required this.onDelete,
  });

  @override
  State<_GroupedAnimeSection> createState() => _GroupedAnimeSectionState();
}

class _GroupedAnimeSectionState extends State<_GroupedAnimeSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    // final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.anime.animeCover.isNotEmpty
                  ? NetworkImage(widget.anime.animeCover)
                  : null,
              child: widget.anime.animeCover.isEmpty
                  ? const Icon(Iconsax.image)
                  : null,
            ),
            title: Text(
              widget.anime.animeTitle,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                  _isExpanded ? Iconsax.arrow_down_1 : Iconsax.arrow_right_2),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            ...widget.episodes.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Dismissible(
                    key: Key('${entry.anime.animeId}-${entry.episode.episodeNumber}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Iconsax.trash, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      await widget.onDelete(
                          entry.anime.animeId, entry.episode.episodeNumber);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Removed ${entry.anime.animeTitle} - EP ${entry.episode.episodeNumber}'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                // Logic to undo could be added here
                              },
                            ),
                          ),
                        );
                      }
                    },
                    child: ContinueWatchingCard(
                      anime: entry.anime,
                      episode: entry.episode,
                      index: widget.episodes.indexOf(entry),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}