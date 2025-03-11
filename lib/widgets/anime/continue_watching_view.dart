import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive/hive.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/widgets/anime/anime_continue_card.dart';

class ContinueWatchingView extends ConsumerWidget {
  final AnimeWatchProgressBox animeWatchProgressBox;

  const ContinueWatchingView({super.key, required this.animeWatchProgressBox});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 250,
      child: ValueListenableBuilder<Box>(
        valueListenable: animeWatchProgressBox.boxValueListenable,
        builder: (context, box, child) {
          final entries =
              animeWatchProgressBox.getAllMostRecentWatchedEpisodesWithAnime();
          return entries.isEmpty
              ? const _EmptyWatchingState()
              : _WatchingContent(entries: entries);
        },
      ),
    );
  }
}

// Empty State
class _EmptyWatchingState extends StatelessWidget {
  const _EmptyWatchingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.video_circle,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No shows in progress',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/browse'),
            icon: Icon(Iconsax.discover, color: theme.colorScheme.onPrimary),
            label: const Text('Discover Shows'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

final loadingProvider = StateProvider.family<bool, int>((ref, index) => false);

// Watching Content
class _WatchingContent extends ConsumerWidget {
  final List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>
      entries;

  const _WatchingContent({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final theme = Theme.of(context);
    return SizedBox(
      height: 220, // Reduced height for compactness
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ContinueWatchingCard(
                    onTap: () async {
                      // final anime = entries[index].anime;
                      // final animeMedia = Media(
                      //   id: anime.animeId,
                      // );
                      // await providerAnimeMatchSearch(context: context, ref: ref, animeMedia: , animeWatchProgressBox: animeWatchProgressBox)
                    },
                    anime: entries[index].anime,
                    episode: entries[index].episode,
                    index: index,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Header with Floating Action
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Continue Watching',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          FloatingActionButton.small(
            heroTag: 'continue-all-button',
            onPressed: () => context.push('/continue-all'),
            backgroundColor: theme.colorScheme.primary,
            tooltip: 'View All',
            child: const Icon(Iconsax.arrow_right_3, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
