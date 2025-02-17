import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/anilist/services/anilist_service.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/data/hive/boxes/continue_watching_box.dart';
import 'package:shonenx/helpers/matcher.dart';
import 'package:shonenx/helpers/provider.dart';
import 'package:shonenx/providers/anilist/anilist_medialist_provider.dart';
import 'package:shonenx/providers/anilist/anilist_user_provider.dart';

class AnimeDetailsScreen extends ConsumerStatefulWidget {
  final Media anime;
  final String tag;
  const AnimeDetailsScreen({super.key, required this.anime, required this.tag});

  @override
  ConsumerState<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends ConsumerState<AnimeDetailsScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late ContinueWatchingBox continueWatchingBox;
  bool _isBoxInitialized = false;
  bool _isLoading = false;
  bool? _isFavourite;

  @override
  void initState() {
    super.initState();
    _initializeContinueWatchingBox();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _checkFavorite();
    _scrollController = ScrollController();
  }

  Future<void> _initializeContinueWatchingBox() async {
    continueWatchingBox = ContinueWatchingBox();
    await continueWatchingBox.init();
    if (mounted) {
      setState(() {
        _isBoxInitialized = true;
      });
    }
  }

  Future<void> _checkFavorite() async {
    final mediaListState = ref.read(animeListProvider);
    if (mediaListState.favorites.isNotEmpty) {
      final isLoadedAlready =
          mediaListState.favorites.any((media) => media.id == widget.anime.id);
      if (isLoadedAlready) {
        setState(() {
          _isFavourite = true;
        });
        return;
      }
    }
    final anilistService = AnilistService();
    final accessToken = ref.read(userProvider)?.accessToken;
    if (accessToken == null) return;
    final isFavourite = await anilistService.isAnimeFavorite(
        animeId: widget.anime.id!, accessToken: accessToken);
    if (!mounted) return;
    setState(() {
      _isFavourite = isFavourite;
    });
  }

  Future<void> _toggleFavorite() async {
    final anilistService = AnilistService();
    final accessToken = ref.read(userProvider)?.accessToken;
    final mediaListState = ref.read(animeListProvider.notifier);
    anilistService.toggleFavorite(
        animeId: widget.anime.id!, accessToken: accessToken);
    mediaListState.toggleFavoritesStatic([widget.anime]);
    setState(() {
      _isFavourite = !_isFavourite!;
    });
  }

  Future<void> _handleAnilistandProviderSyncLoad() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final animeProvider = getAnimeProvider(ref);
      final title = widget.anime.title?.english ??
          widget.anime.title?.romaji ??
          widget.anime.title?.native;

      final response = await animeProvider?.getSearch(
        title!.replaceAll(' ', '+'),
        widget.anime.format,
        1,
      );

      if (!mounted || response == null) return;

      final matchedResults = response.results
          .map((result) {
            final similarity = calculateSimilarity(
              result.name?.toLowerCase(),
              title?.toLowerCase(),
            );
            return (result, similarity);
          })
          .where((pair) => pair.$2 > 0)
          .toList()
        ..sort((a, b) => b.$2.compareTo(a.$2));

      if (!mounted) return;

      if (matchedResults.isEmpty && response.results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Anime Not Found',
            message:
                'We couldn\'t locate the anime with the selected provider.',
            contentType: ContentType.failure,
          ),
        ));
        return;
      }

      // Direct navigation for high confidence matches
      if (matchedResults.isNotEmpty && matchedResults.first.$2 >= 0.8) {
        final bestMatch = matchedResults.first.$1;
        context.push('/watch/${bestMatch.id}?animeName=${bestMatch.name}',
            extra: widget.anime);
        return;
      }

      // Show selection dialog for multiple matches
      final results = matchedResults.isEmpty
          ? response.results
          : matchedResults.map((r) => r.$1).toList();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
                maxHeight: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    child: Row(
                      children: [
                        Text(
                          'Select Anime',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            if (_isBoxInitialized) {
                              _isBoxInitialized = false;
                              final continueWatchingEntry = continueWatchingBox
                                  .getEntry(widget.anime.id!);
                              if (continueWatchingEntry != null) {
                                context.push(
                                    '/watch/${result.id}?animeName=${result.name}?episode=${continueWatchingEntry.episodeNumber}&startAt=${continueWatchingEntry.progressInSeconds}',
                                    extra: widget.anime);
                              } else {
                                context.push(
                                    '/watch/${result.id}?animeName=${result.name}',
                                    extra: widget.anime);
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                // Thumbnail
                                if (result.poster != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: result.poster!,
                                      width: 50,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 50,
                                        height: 70,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        width: 50,
                                        height: 70,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: const Icon(Icons.broken_image,
                                            size: 20),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                // Title and details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        result.name ?? 'Unknown',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (result.releaseDate != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          result.releaseDate!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Error',
            message: 'Failed to load anime details. Please try again.',
            contentType: ContentType.failure,
          ),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        forceMaterialTransparency: true,
        elevation: 0,
        leading: _buildNavButton(
          icon: Iconsax.arrow_left_1,
          onTap: () => context.pop(),
        ),
        actions: [
          _buildNavButton(
            icon: Iconsax.more,
            onTap: () async {
              final List<_StatusOption> statusOptions = [
                _StatusOption(
                  title: 'Watching',
                  icon: Icons.visibility,
                  color: Colors.blue,
                ),
                _StatusOption(
                  title: 'Completed',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _StatusOption(
                  title: 'Planning',
                  icon: Icons.calendar_today,
                  color: Colors.orange,
                ),
                _StatusOption(
                  title: 'Paused',
                  icon: Icons.pause_circle,
                  color: Colors.amber,
                ),
                _StatusOption(
                  title: 'Dropped',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ];

              await showMenu<String>(
                context: context,
                position: RelativeRect.fromSize(
                    Rect.fromLTRB(55, 55, 55, 55), Size(55, 55)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                items: statusOptions.map((status) {
                  return PopupMenuItem<String>(
                    value: status.title.toLowerCase(),
                    child: _StatusMenuItem(status: status),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildHeroHeader(theme),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildMainInfo(theme),
                    _buildSynopsis(theme),
                    if (widget.anime.rankings?.isNotEmpty ?? false)
                      _buildRankings(theme),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          _buildWatchButton(theme),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 400,
      leading: const SizedBox.shrink(),
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                filterQuality: FilterQuality.high,
                imageUrl: widget.anime.bannerImage ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                ),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surface.withValues(alpha: 0.5),
                      theme.colorScheme.surface
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
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
                  _buildGenreTags(theme),
                  const SizedBox(height: 16),
                  _isBoxInitialized
                      ? ValueListenableBuilder(
                          valueListenable:
                              continueWatchingBox.boxValueListenable,
                          builder: (context, box, child) {
                            final continueWatchingEntry =
                                continueWatchingBox.getEntry(widget.anime.id!);
                            return Text(
                              '${continueWatchingEntry?.progressInSeconds ?? 0} / ${continueWatchingEntry?.durationInSeconds ?? 0}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 16,
                              ),
                            );
                          },
                        )
                      : const CircularProgressIndicator(), // Or some loading state

                  Text(
                    widget.anime.title?.english ??
                        widget.anime.title?.romaji ??
                        '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (widget.anime.title?.native != null)
                    Text(
                      widget.anime.title!.native!,
                      style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 18,
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

  Widget _buildGenreTags(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatusTag(theme),
          ...(widget.anime.genres ?? []).map((genre) => _buildGenreTag(genre)),
        ],
      ),
    );
  }

  Widget _buildStatusTag(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.anime.status ?? 'Unknown',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGenreTag(String genre) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        genre,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildMainInfo(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Iconsax.star1,
                value: '${widget.anime.averageScore ?? "?"}/100',
                label: 'Rating',
              ),
              _buildInfoItem(
                icon: Iconsax.timer_1,
                value: '${widget.anime.duration ?? "?"} min',
                label: 'Duration',
              ),
              _buildInfoItem(
                icon: Iconsax.play_circle,
                value: '${widget.anime.episodes ?? "?"} eps',
                label: 'Episodes',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        if (_isFavourite != null)
          Expanded(
            child: _buildActionButton(
              icon: _isFavourite == true ? Iconsax.heart5 : Iconsax.heart,
              label: _isFavourite == true ? 'Unfavourite' : 'Add to List',
              onTap: _toggleFavorite,
              isPrimary: true,
            ),
          ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Iconsax.share,
          label: 'Share',
          onTap: () {},
          isPrimary: false,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: isPrimary
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurface.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
                size: 20,
              ),
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

  Widget _buildSynopsis(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Synopsis',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.anime.description ?? 'No description available.',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildRankings(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rankings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.anime.rankings!
              .map((ranking) => _buildRankingCard(ranking, theme)),
        ],
      ),
    );
  }

  Widget _buildRankingCard(MediaRanking ranking, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#${ranking.rank}',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.context.replaceFirst(
                    ranking.context[0],
                    ranking.context[0].toUpperCase(),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on user ratings and popularity',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchButton(ThemeData theme) {
    return Positioned(
      bottom: 10,
      left: 20,
      right: 20,
      child: SafeArea(
        child: Material(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _isLoading ? null : _handleAnilistandProviderSyncLoad,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.play_circle,
                            color: theme.colorScheme.onPrimary,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          _isBoxInitialized &&
                                  continueWatchingBox
                                          .getEntry(widget.anime.id!) !=
                                      null
                              ? Text(
                                  '${continueWatchingBox.getEntry(widget.anime.id!)?.episodeTitle}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  'Watch Now',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _StatusOption {
  final String title;
  final IconData icon;
  final Color color;

  _StatusOption({
    required this.title,
    required this.icon,
    required this.color,
  });
}

class _StatusMenuItem extends StatelessWidget {
  final _StatusOption status;

  const _StatusMenuItem({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            status.icon,
            color: status.color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          status.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
