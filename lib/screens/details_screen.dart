import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/anilist/services/anilist_service.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/helpers/anime_match_popup.dart';
import 'package:shonenx/providers/anilist/anilist_medialist_provider.dart';
import 'package:shonenx/providers/anilist/anilist_user_provider.dart';

class AnimeDetailsScreen extends ConsumerStatefulWidget {
  final Media anime;
  final String tag;

  const AnimeDetailsScreen({super.key, required this.anime, required this.tag});

  @override
  ConsumerState<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends ConsumerState<AnimeDetailsScreen> {
  late final ScrollController _scrollController;
  late final Future<AnimeWatchProgressBox> _boxFuture;
  bool _isFavourite = false;
  bool _isLoading = false;
  bool _isToggeling = false;
  String? _currentStatus; // e.g., "CURRENT", "COMPLETED", etc.
  int? _currentEntryId; // The ID of the MediaList entry

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _boxFuture = _initializeBox();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _checkFavorite();
    _fetchCurrentStatus(); // Fetch status on initialization
  }

  Future<void> _fetchCurrentStatus() async {
    final user = ref.read(userProvider);
    if (user != null && user.accessToken.isNotEmpty) {
      final statusData = await AnilistService().getAnimeStatus(
        accessToken: user.accessToken,
        userId: user.id!,
        animeId: widget.anime.id!,
      );
      if (mounted && statusData != null) {
        setState(() {
          _currentStatus = statusData['status'] as String?;
          _currentEntryId = statusData['id'] as int?;
        });
        // Update local state on initial fetch
        ref.read(animeListProvider.notifier).toggleStatusStatic(
              media: widget.anime,
              newStatus: _currentStatus,
            );
      }
    }
  }

  Future<AnimeWatchProgressBox> _initializeBox() async {
    final box = AnimeWatchProgressBox();
    await box.init();
    return box;
  }

  Future<void> _checkFavorite() async {
    final mediaListState = ref.read(animeListProvider);
    if (mediaListState.favorites.any((media) => media.id == widget.anime.id)) {
      setState(() => _isFavourite = true);
      return;
    }
    final accessToken = ref.read(userProvider)?.accessToken;
    if (accessToken != null) {
      final isFavourite = await AnilistService().isAnimeFavorite(
        animeId: widget.anime.id!,
        accessToken: accessToken,
      );
      if (mounted) setState(() => _isFavourite = isFavourite);
    }
  }

  bool _isToggling = false;

  Future<void> _toggleFavorite() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    final accessToken = ref.read(userProvider)?.accessToken;
    if (accessToken != null) {
      try {
        await AnilistService().toggleFavorite(
          animeId: widget.anime.id!,
          accessToken: accessToken,
        );
        ref
            .read(animeListProvider.notifier)
            .toggleFavoritesStatic([widget.anime]);
        setState(() => _isFavourite = !_isFavourite);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle favorite: $e')),
        );
      } finally {
        setState(() => _isToggling = false);
      }
    } else {
      setState(() => _isToggling = false);
    }
  }

  Future<void> _handleWatchAction(AnimeWatchProgressBox box) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await providerAnimeMatchSearch(
      context: context,
      ref: ref,
      animeMedia: widget.anime,
      animeWatchProgressBox: box,
      afterSearchCallback: () => setState(() => _isLoading = false),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _Header(
                anime: widget.anime,
                tag: widget.tag,
                currentStatus: _currentStatus, // Pass current status
                onStatusChanged: _fetchCurrentStatus, // Callback to refresh
              ),
              SliverToBoxAdapter(
                child: _Content(
                  anime: widget.anime,
                  isFavourite: _isFavourite,
                  onToggleFavorite: _toggleFavorite,
                ),
              ),
            ],
          ),
          _WatchButton(
            anime: widget.anime,
            boxFuture: _boxFuture,
            isLoading: _isLoading,
            onTap: _handleWatchAction,
          ),
        ],
      ),
    );
  }
}

// Header Section
class _Header extends StatelessWidget {
  final Media anime;
  final String tag;
  final String? currentStatus; // Current status from AniList
  final VoidCallback onStatusChanged; // Callback to refresh status

  const _Header({
    required this.anime,
    required this.tag,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: anime.bannerImage ?? anime.coverImage?.large ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[300]),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    theme.colorScheme.surface,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
            // Align(
            //   alignment: Alignment.center,
            //   child: ClipRRect(
            //     borderRadius: BorderRadius.circular(15),
            //     child: CachedNetworkImage(
            //       imageUrl:
            //           anime.coverImage?.large ?? anime.coverImage?.medium ?? '',
            //       width: 140,
            //       height: 200,
            //       fit: BoxFit.cover,
            //       placeholder: (context, url) =>
            //           Container(color: Colors.grey[300]),
            //       errorWidget: (context, url, error) => const Icon(Icons.error),
            //     ),
            //   ),
            // ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GenreTags(
                      genres: anime.genres ?? [],
                      status: anime.status ?? 'Unknown'),
                  const SizedBox(height: 16),
                  Text(
                    anime.title?.english ?? anime.title?.romaji ?? '',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (anime.title?.native != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        anime.title!.native!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left_1, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Iconsax.more, color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          onSelected: (value) => log('Selected status: $value'),
          itemBuilder: (context) => [
            _StatusOption('Watching', Icons.visibility, Colors.blue),
            _StatusOption('Completed', Icons.check_circle, Colors.green),
            _StatusOption('Planning', Icons.calendar_today, Colors.orange),
            _StatusOption('Paused', Icons.pause_circle, Colors.amber),
            _StatusOption('Dropped', Icons.cancel, Colors.red),
          ]
              .map((option) => PopupMenuItem<String>(
                    value: option.title.toLowerCase(),
                    child: _StatusMenuItem(
                      status: option,
                      animeMedia: anime,
                      currentStatus: currentStatus,
                      onStatusChanged: onStatusChanged,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// Genre Tags
class _GenreTags extends StatelessWidget {
  final List<String> genres;
  final String status;

  const _GenreTags({required this.genres, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Tag(text: status, color: theme.colorScheme.primary, isStatus: true),
          const SizedBox(width: 8),
          ...genres.map((genre) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Tag(text: genre),
              )),
        ],
      ),
    );
  }
}

// Tag Widget
class _Tag extends StatelessWidget {
  final String text;
  final Color? color;
  final bool isStatus;

  const _Tag({required this.text, this.color, this.isStatus = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.2) ?? Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.white.withOpacity(0.9),
          fontWeight: isStatus ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

// Content Section
class _Content extends StatelessWidget {
  final Media anime;
  final bool isFavourite;
  final VoidCallback onToggleFavorite;

  const _Content(
      {required this.anime,
      required this.isFavourite,
      required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
              anime: anime,
              isFavourite: isFavourite,
              onToggleFavorite: onToggleFavorite),
          const SizedBox(height: 24),
          _Synopsis(
              description: anime.description ?? 'No description available.'),
          if (anime.rankings?.isNotEmpty ?? false) ...[
            const SizedBox(height: 24),
            _Rankings(rankings: anime.rankings!),
          ],
          const SizedBox(height: 80), // Space for floating button
        ],
      ),
    );
  }
}

// Info Card
class _InfoCard extends StatelessWidget {
  final Media anime;
  final bool isFavourite;
  final VoidCallback onToggleFavorite;

  const _InfoCard(
      {required this.anime,
      required this.isFavourite,
      required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  icon: Iconsax.star1,
                  value: '${anime.averageScore ?? "?"}/100',
                  label: 'Rating',
                ),
                _InfoItem(
                  icon: Iconsax.timer_1,
                  value: '${anime.duration ?? "?"} min',
                  label: 'Duration',
                ),
                _InfoItem(
                  icon: Iconsax.play_circle,
                  value: '${anime.episodes ?? "?"} eps',
                  label: 'Episodes',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: isFavourite ? Iconsax.heart5 : Iconsax.heart,
                    label: isFavourite ? 'Unfavourite' : 'Add to List',
                    onTap: onToggleFavorite,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Iconsax.share,
                  label: 'Share',
                  onTap: () {}, // Implement sharing logic if needed
                  isPrimary: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Info Item
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoItem(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// Action Button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isPrimary
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isPrimary
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Synopsis
class _Synopsis extends StatelessWidget {
  final String description;

  const _Synopsis({required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Synopsis',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, height: 1.5),
        ),
      ],
    );
  }
}

// Rankings
class _Rankings extends StatelessWidget {
  final List<MediaRanking> rankings;

  const _Rankings({required this.rankings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rankings',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...rankings.map((ranking) => _RankingCard(ranking: ranking)),
      ],
    );
  }
}

// Ranking Card
class _RankingCard extends StatelessWidget {
  final MediaRanking ranking;

  const _RankingCard({required this.ranking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${ranking.rank}',
                style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ranking.context.replaceFirst(
                        ranking.context[0], ranking.context[0].toUpperCase()),
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on user ratings and popularity',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Watch Button
class _WatchButton extends StatelessWidget {
  final Media anime;
  final Future<AnimeWatchProgressBox> boxFuture;
  final bool isLoading;
  final Function(AnimeWatchProgressBox) onTap;

  const _WatchButton({
    required this.anime,
    required this.boxFuture,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      bottom: 16,
      right: 16,
      child: FutureBuilder<AnimeWatchProgressBox>(
        future: boxFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox
                .shrink(); // Avoid showing button until box is ready
          }
          final box = snapshot.data!;
          final episodeProgress =
              box.getMostRecentEpisodeProgressByAnimeId(anime.id!);
          return FloatingActionButton.extended(
            onPressed: isLoading ? null : () => onTap(box),
            backgroundColor: theme.colorScheme.primary,
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      children: [
                        const Icon(Iconsax.play_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          episodeProgress != null
                              ? 'EP ${episodeProgress.episodeNumber}'
                              : 'Watch Now',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

// Status Option
class _StatusOption {
  final String title;
  final IconData icon;
  final Color color;

  const _StatusOption(this.title, this.icon, this.color);
}

// Status Menu Item
class _StatusMenuItem extends ConsumerWidget {
  final _StatusOption status;
  final Media animeMedia;
  final String? currentStatus;
  final VoidCallback onStatusChanged;

  const _StatusMenuItem({
    required this.status,
    required this.animeMedia,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  String _mapToAnilistStatus(String displayStatus) {
    switch (displayStatus.toLowerCase()) {
      case 'watching':
        return 'CURRENT';
      case 'completed':
        return 'COMPLETED';
      case 'planning':
        return 'PLANNING';
      case 'paused':
        return 'PAUSED';
      case 'dropped':
        return 'DROPPED';
      default:
        return displayStatus.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.read(userProvider);
    final anilistStatus = _mapToAnilistStatus(status.title);
    final isCurrent = currentStatus == anilistStatus;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        if (userState == null || userState.accessToken.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please log in to update status')),
          );
          return;
        }

        final anilistService = AnilistService();
        final currentData = await anilistService.getAnimeStatus(
          accessToken: userState.accessToken,
          userId: userState.id!,
          animeId: animeMedia.id!,
        );
        final entryId = currentData?['id'] as int?;

        try {
          if (isCurrent && entryId != null) {
            if (!context.mounted) return;
            final shouldRemove = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Remove from ${status.title}?'),
                content: Text(
                    'Do you want to remove "${animeMedia.title?.english ?? animeMedia.title?.romaji}" from your ${status.title} list?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Remove'),
                  ),
                ],
              ),
            );

            if (shouldRemove == true) {
              await anilistService.deleteAnimeEntry(
                entryId: entryId,
                accessToken: userState.accessToken,
              );
              ref.read(animeListProvider.notifier).toggleStatusStatic(
                    media: animeMedia,
                    newStatus: null, // Remove from list
                  );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removed from ${status.title}')),
              );
            }
          } else {
            await anilistService.updateAnimeStatus(
              mediaId: animeMedia.id!,
              accessToken: userState.accessToken,
              newStatus: anilistStatus,
            );
            ref.read(animeListProvider.notifier).toggleStatusStatic(
                  media: animeMedia,
                  newStatus: anilistStatus,
                );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added to ${status.title}')),
            );
          }
          onStatusChanged(); // Refresh current status
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: $e')),
          );
        }
        if (!context.mounted) return;
        Navigator.pop(context); // Close the popup menu
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: status.color.withOpacity(isCurrent ? 0.3 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(status.icon, color: status.color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            status.title,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color:
                  isCurrent ? status.color : theme.textTheme.bodyLarge?.color,
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            Icon(Icons.check, size: 16, color: status.color),
          ],
        ],
      ),
    );
  }
}
