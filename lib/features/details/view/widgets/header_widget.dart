import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/details/view/widgets/comments_bottom_sheet.dart';
import 'package:shonenx/features/watchlist/view_model/watchlist_notifier.dart';
import 'package:shonenx/shared/auth/providers/auth_notifier.dart';
import 'package:shonenx/features/details/view_model/local_tracker_notifier.dart';

class DetailsHeader extends ConsumerStatefulWidget {
  final UniversalMedia anime;
  final String tag;
  final VoidCallback onEditPressed;

  const DetailsHeader({
    super.key,
    required this.anime,
    required this.tag,
    required this.onEditPressed,
  });

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
        final localTracker = ref.read(localTrackerProvider.notifier);
        isFavorite = await localTracker.isFavorite(widget.anime.id);
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
        final localTracker = ref.read(localTrackerProvider.notifier);
        final newStatus = await localTracker.toggleFavorite(widget.anime);
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
              placeholder: (_, __) =>
                  Container(color: colorScheme.surfaceContainer),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
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
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.8,
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
        const SizedBox(width: 8),
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
        IconButton(
          icon: const Icon(Iconsax.add_circle, color: Colors.white, size: 30),
          tooltip: 'Add or Edit in your list',
          onPressed: widget.onEditPressed,
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
        color: color?.withOpacity(0.2) ?? Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color ?? Colors.white.withOpacity(0.9),
          fontWeight: isStatus ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
