import 'dart:developer';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
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
import 'package:google_fonts/google_fonts.dart';

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
  String? _currentStatus;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _boxFuture = _initializeBox();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _checkFavorite();
    _fetchCurrentStatus();
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
        });
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
        _showSnackBar(context, 'Toggling failed',
            'Failed to toggle favorite: $e', ContentType.warning);
      } finally {
        setState(() => _isToggling = false);
      }
    } else {
      _showSnackBar(context, 'Login required',
          'You need to login to use this feature', ContentType.warning);
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
      afterSearchCallback: () {
        if (!mounted) return;
        setState(() => _isLoading = false);
      },
    );
  }

  void _showSnackBar(
      BuildContext context, String title, String message, ContentType type) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 5),
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: type,
        titleTextStyle:
            GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700),
        messageTextStyle: GoogleFonts.montserrat(fontSize: 14),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _Header(
                anime: widget.anime,
                tag: widget.tag,
                currentStatus: _currentStatus,
                onStatusChanged: _fetchCurrentStatus,
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

class _Header extends StatelessWidget {
  final Media anime;
  final String tag;
  final String? currentStatus;
  final VoidCallback onStatusChanged;

  const _Header({
    required this.anime,
    required this.tag,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 420,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: anime.bannerImage ?? anime.coverImage?.large ?? '',
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: colorScheme.surfaceContainer),
              errorWidget: (_, __, ___) =>
                  Icon(Icons.error, color: colorScheme.error),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: tag,
                        child: ClipRRect(
                          borderRadius:
                              (theme.cardTheme.shape as RoundedRectangleBorder?)
                                      ?.borderRadius ??
                                  BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: anime.coverImage?.large ??
                                anime.coverImage?.medium ??
                                '',
                            width: 105,
                            height: 160,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: colorScheme.surfaceContainer),
                            errorWidget: (_, __, ___) =>
                                Icon(Icons.error, color: colorScheme.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anime.title?.english ?? anime.title?.romaji ?? '',
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (anime.title?.native != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  anime.title!.native!,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            _GenreTags(
                                genres: anime.genres ?? [],
                                status: anime.status ?? 'Unknown'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: Icon(Iconsax.arrow_left_1, color: Colors.white, size: 28),
        onPressed: () => context.pop(),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Iconsax.more, color: Colors.white, size: 28),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          color: colorScheme.surfaceContainer,
          onSelected: (value) => log('Selected status: $value'),
          itemBuilder: (context) => [
            _StatusOption('Watching', Iconsax.eye, Colors.blue),
            _StatusOption('Completed', Iconsax.tick_circle, Colors.green),
            _StatusOption('Planning', Iconsax.calendar_1, Colors.orange),
            _StatusOption('Paused', Iconsax.pause_circle, Colors.amber),
            _StatusOption('Dropped', Iconsax.close_circle, Colors.red),
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

class _Tag extends StatelessWidget {
  final String text;
  final Color? color;
  final bool isStatus;

  const _Tag({required this.text, this.color, this.isStatus = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.2) ??
            Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color?.withValues(alpha: 0.1) ?? Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: color ?? Colors.white.withValues(alpha: 0.9),
          fontWeight: isStatus ? FontWeight.w600 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final Media anime;
  final bool isFavourite;
  final VoidCallback onToggleFavorite;

  const _Content({
    required this.anime,
    required this.isFavourite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            anime: anime,
            isFavourite: isFavourite,
            onToggleFavorite: onToggleFavorite,
          ),
          const SizedBox(height: 24),
          _Synopsis(
              description: anime.description ?? 'No description available.'),
          if (anime.rankings?.isNotEmpty ?? false) ...[
            const SizedBox(height: 24),
            _Rankings(rankings: anime.rankings!),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Media anime;
  final bool isFavourite;
  final VoidCallback onToggleFavorite;

  const _InfoCard({
    required this.anime,
    required this.isFavourite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  icon: Iconsax.star_1,
                  value: '${anime.averageScore ?? "?"}/100',
                  label: 'Rating',
                ),
                _InfoItem(
                  icon: Iconsax.timer_1,
                  value: '${anime.duration ?? "?"} min',
                  label: 'Duration',
                ),
                _InfoItem(
                  icon: Iconsax.video_play,
                  value: '${anime.episodes ?? "?"} eps',
                  label: 'Episodes',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: isFavourite ? Iconsax.heart5 : Iconsax.heart,
                    label: isFavourite ? 'Unfavourite' : 'Favourite',
                    onTap: onToggleFavorite,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Iconsax.share,
                  label: 'Share',
                  onTap: () {}, // Add sharing logic if needed
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

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoItem(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

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
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isPrimary
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? colorScheme.primary.withValues(alpha: 0.3)
                : Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color:
                      isPrimary ? colorScheme.onPrimary : colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color:
                        isPrimary ? colorScheme.onPrimary : colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Synopsis extends StatelessWidget {
  final String description;

  const _Synopsis({required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Synopsis',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Rankings extends StatelessWidget {
  final List<MediaRanking> rankings;

  const _Rankings({required this.rankings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rankings',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...rankings.map((ranking) => _RankingCard(ranking: ranking)),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  final MediaRanking ranking;

  const _RankingCard({required this.ranking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '#${ranking.rank}',
                style: GoogleFonts.montserrat(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on user ratings and popularity',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
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
    final colorScheme = theme.colorScheme;

    return Positioned(
      bottom: 16,
      right: 16,
      child: FutureBuilder<AnimeWatchProgressBox>(
        future: boxFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final box = snapshot.data!;
          final episodeProgress =
              box.getMostRecentEpisodeProgressByAnimeId(anime.id!);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: isLoading ? null : () => onTap(box),
              backgroundColor: colorScheme.primary,
              elevation: 0,
              label: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Row(
                        key:
                            ValueKey(episodeProgress?.episodeNumber ?? 'watch'),
                        children: [
                          Icon(Iconsax.play_circle,
                              color: colorScheme.onPrimary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            episodeProgress != null
                                ? 'EP ${episodeProgress.episodeNumber}'
                                : 'Watch Now',
                            style: GoogleFonts.montserrat(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusOption {
  final String title;
  final IconData icon;
  final Color color;

  const _StatusOption(this.title, this.icon, this.color);
}

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
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () async {
        if (userState == null || userState.accessToken.isEmpty) {
          _showSnackBar(context, 'Login required',
              'Please log in to update status', ContentType.warning);
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text('Remove from ${status.title}?',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                content: Text(
                  'Do you want to remove "${animeMedia.title?.english ?? animeMedia.title?.romaji}" from your ${status.title} list?',
                  style: GoogleFonts.montserrat(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel', style: GoogleFonts.montserrat()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Remove',
                        style: GoogleFonts.montserrat(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (shouldRemove == true) {
              await anilistService.deleteAnimeEntry(
                entryId: entryId,
                accessToken: userState.accessToken,
              );
              ref
                  .read(animeListProvider.notifier)
                  .toggleStatusStatic(media: animeMedia, newStatus: null);
              if (!context.mounted) return;
              _showSnackBar(context, 'Removed', 'Removed from ${status.title}',
                  ContentType.success);
            }
          } else {
            await anilistService.updateAnimeStatus(
              mediaId: animeMedia.id!,
              accessToken: userState.accessToken,
              newStatus: anilistStatus,
            );
            ref.read(animeListProvider.notifier).toggleStatusStatic(
                media: animeMedia, newStatus: anilistStatus);
            if (!context.mounted) return;
            _showSnackBar(context, '${status.title} updated',
                'Added to ${status.title}', ContentType.success);
          }
          onStatusChanged();
        } catch (e) {
          if (!context.mounted) return;
          _showSnackBar(context, 'Update failed', 'Failed to update status: $e',
              ContentType.failure);
        }
        if (!context.mounted) return;
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: isCurrent ? 0.3 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(status.icon, color: status.color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              status.title,
              style: GoogleFonts.montserrat(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? status.color : colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Icon(Icons.check, size: 18, color: status.color),
            ],
          ],
        ),
      ),
    );
  }

  void _showSnackBar(
      BuildContext context, String title, String message, ContentType type) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 5),
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: type,
        titleTextStyle:
            GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700),
        messageTextStyle: GoogleFonts.montserrat(fontSize: 14),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
