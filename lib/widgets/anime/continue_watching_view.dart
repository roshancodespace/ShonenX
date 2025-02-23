import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive/hive.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/models/anime_watch_progress_model.dart';
import 'package:shonenx/widgets/anime/anime_continue_card.dart';

class ContinueWatchingView extends StatelessWidget {
  final AnimeWatchProgressBox animeWatchProgressBox;

  const ContinueWatchingView({super.key, required this.animeWatchProgressBox});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: animeWatchProgressBox.boxValueListenable,
      builder: (context, box, child) {
        final entries =
            animeWatchProgressBox.getAllMostRecentWatchedEpisodesWithAnime();
        return entries.isEmpty
            ? const _EmptyWatchingState()
            : _WatchingContent(entries: entries);
      },
    );
  }
}

class _EmptyWatchingState extends StatelessWidget {
  const _EmptyWatchingState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.video_circle, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No shows in progress',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/browse'),
            icon: Icon(Iconsax.discover, color: colorScheme.onPrimary),
            label: const Text('Discover Shows'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
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

class _WatchingContent extends StatelessWidget {
  final List<({AnimeWatchProgressEntry anime, EpisodeProgress episode})>
      entries;

  const _WatchingContent({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Expanded(
                  child: ContinueWatchingCard(
                    anime: entries[index].anime,
                    episode: entries[index].episode,
                    index: index,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Iconsax.play_circle,
                  size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Continue Watching',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            onPressed: () => context.push('/continue-all'),
            icon: const Icon(Iconsax.arrow_right_3, size: 24),
            tooltip: 'View all',
          ),
        ],
      ),
    );
  }
}
