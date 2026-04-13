import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/tracker/tracker_type.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/features/details/view/widgets/comments_bottom_sheet.dart';
import 'package:shonenx/features/details/view/widgets/tracker/track_bottom_sheet.dart';
import 'package:shonenx/features/watchlist/view_model/watchlist_notifier.dart';
import 'package:shonenx/shared/auth/providers/auth_notifier.dart';
import 'package:shonenx/shared/providers/tracker/media_tracker_notifier.dart';


class DetailsHeader extends ConsumerStatefulWidget {
  final UniversalMedia anime;
  final String tag;

  const DetailsHeader({super.key, required this.anime, required this.tag});

  @override
  ConsumerState<DetailsHeader> createState() => _DetailsHeaderState();
}

class _DetailsHeaderState extends ConsumerState<DetailsHeader> {
  bool isFavorite = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  void _checkFavorite() {
    final auth = ref.read(authProvider);
    Future.microtask(() async {
      if (auth.isAniListAuthenticated) {
        final watchlist = ref.read(watchlistProvider.notifier);
        isFavorite = await watchlist.ensureFavorite(widget.anime.id);
      } else {
        isFavorite = await ref
            .read(mediaTrackerProvider(widget.anime.id).notifier)
            .isFavorite(widget.anime.id);
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> toggleFavorite() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final auth = ref.read(authProvider);
      if (auth.isAniListAuthenticated) {
        await ref.read(watchlistProvider.notifier).toggleFavorite(widget.anime);
        setState(() => isFavorite = !isFavorite);
      } else {
        final newStatus = await ref
            .read(mediaTrackerProvider(widget.anime.id).notifier)
            .toggleFavorite(widget.anime);
        setState(() => isFavorite = newStatus);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 420,
      pinned: false,
      floating: true,
      elevation: 0,
      backgroundColor: colorScheme.surfaceContainerLowest,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl:
                  widget.anime.bannerImage != null &&
                      widget.anime.bannerImage!.isNotEmpty
                  ? widget.anime.bannerImage!
                  : widget.anime.coverImage.large ??
                        widget.anime.coverImage.medium ??
                        '',
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  Container(color: colorScheme.surfaceContainer),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    colorScheme.surfaceContainerLowest,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Hero(
                    tag: widget.tag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl:
                            widget.anime.coverImage.large ??
                            widget.anime.coverImage.medium ??
                            '',
                        width: 105,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          widget.anime.title.english ??
                              widget.anime.title.romaji ??
                              '',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.anime.title.native != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.anime.title.native!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Metadata Row
                        Row(
                          children: [
                            if (widget.anime.averageScore != null) ...[
                              Icon(
                                Iconsax.star1,
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (widget.anime.averageScore! / 10)
                                    .toStringAsFixed(1),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              [
                                widget.anime.seasonYear?.toString(),
                                widget.anime.format,
                                widget.anime.episodes != null
                                    ? '${widget.anime.episodes} eps'
                                    : null,
                                widget.anime.status,
                              ].whereType<String>().join(' • '),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GenreTags(genres: widget.anime.genres),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left_1, color: Colors.white, size: 30),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.comment_outlined,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () => CommentsBottomSheet.show(context, widget.anime),
        ),
        const SizedBox(width: 4),
        const SizedBox(width: 4),
        TrackerStatusWidget(anime: widget.anime),
        const SizedBox(width: 4),
        isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : IconButton(
                icon: Icon(
                  isFavorite ? Iconsax.heart5 : Iconsax.heart,
                  color: Colors.white,
                  size: 30,
                ),
                tooltip: isFavorite
                    ? 'Remove from favourites'
                    : 'Add to favourites',
                onPressed: toggleFavorite,
              ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Widget for displaying genre tags and status
class GenreTags extends StatelessWidget {
  final List<String> genres;

  const GenreTags({super.key, required this.genres});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: genres
            .map(
              (genre) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GenreTag(text: genre),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Individual tag widget for genres and status
class GenreTag extends StatelessWidget {
  final String text;
  final Color? color;
  final bool isStatus;

  const GenreTag({
    super.key,
    required this.text,
    this.color,
    this.isStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            color?.withValues(alpha: 0.2) ??
            Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color ?? Colors.white.withValues(alpha: 0.9),
          fontWeight: isStatus ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class TrackerStatusWidget extends ConsumerWidget {
  final UniversalMedia anime;

  const TrackerStatusWidget({super.key, required this.anime});

  String _formatStatus(String status) {
    final clean = status.replaceAll('_', ' ').toLowerCase();
    return clean[0].toUpperCase() + clean.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackerState = ref.watch(mediaTrackerProvider(anime.id));
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    final activePlatform = authState.activePlatform;
    final trackerType = activePlatform == AuthPlatform.anilist
        ? TrackerType.anilist
        : TrackerType.mal;

    final entry = trackerState.entries[trackerType];

    Widget content;
    bool isActive = false;

    if (trackerState.isLoading && !trackerState.remoteLoaded) {
      content = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else if (entry != null) {
      isActive = true;
      final statusText = _formatStatus(entry.status);
      final progressText = entry.progress > 0 ? ' ${entry.progress}' : '';
      final totalEps = anime.episodes != null ? '/${anime.episodes}' : '';
      final displayProgress = entry.progress > 0
          ? '$progressText$totalEps'
          : '';

      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.bookmark_25, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            '$statusText$displayProgress',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.add, size: 16, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            'Track',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () => TrackBottomSheet.show(context, anime),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}


/// Floating watch button widget
class WatchButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const WatchButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final navHeight = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 16 + navHeight,
      left: 16,
      right: 16,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        label: Text(
          'Watch Now',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : const Icon(Iconsax.play_circle),
      ),
    );
  }
}

