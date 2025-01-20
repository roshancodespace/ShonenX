import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/boxes/watchlist_box.dart';
import 'package:nekoflow/data/models/episodes_model.dart';
import 'package:nekoflow/data/models/info_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:nekoflow/utils/converter.dart';
import 'package:nekoflow/widgets/bottom_player_bar.dart';
import 'package:nekoflow/widgets/episodes_list.dart';
import 'package:nekoflow/widgets/favorite_button.dart';
import 'package:shimmer/shimmer.dart';

class DetailsScreen extends StatefulWidget {
  final String name;
  final String id;
  final String image;
  final dynamic tag;
  final String? type;

  const DetailsScreen({
    super.key,
    required this.name,
    required this.id,
    required this.image,
    required this.tag,
    this.type,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final ValueNotifier<bool> _isDescriptionExpanded = ValueNotifier(false);
  final ValueNotifier<List<Episode>> _episodes =
      ValueNotifier<List<Episode>>([]);
  final ValueNotifier<bool> _isLoadingEpisodes = ValueNotifier(true);
  final ValueNotifier<AnimeData?> _info = ValueNotifier(null);
  final ValueNotifier<String?> _error = ValueNotifier(null);
  final ValueNotifier<ContinueWatchingItem?> _continueWatchingItem =
      ValueNotifier(null);

  late final AnimeService _animeService;
  late final ScrollController _scrollController;
  WatchlistBox? _watchlistBox;
  bool _isDisposed = false;


  @override
  void initState() {
    super.initState();
    _animeService = AnimeService();
    _scrollController = ScrollController();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _initWatchlistBox();
      await Future.wait([
        _fetchInfo(),
        _fetchEpisodes(),
      ]);
    } catch (e) {
      if (!_isDisposed) {
        _error.value = 'Failed to initialize: ${e.toString()}';
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    _isDescriptionExpanded.dispose();
    _episodes.dispose();
    _isLoadingEpisodes.dispose();
    _info.dispose();
    _error.dispose();
    _continueWatchingItem.dispose();
    _animeService.dispose();
    super.dispose();
  }

  Future<void> _fetchInfo() async {
    if (_isDisposed) return;

    try {
      final data = await _animeService.fetchAnimeInfoById(id: widget.id);
      if (!_isDisposed) {
        _info.value = data?.data;
      }
    } catch (e) {
      if (!_isDisposed) {
        _error.value = 'Failed to fetch anime info: ${e.toString()}';
      }
    }
  }

  Future<void> _fetchEpisodes() async {
    if (_isDisposed) return;

    try {
      final episodes = await _animeService.fetchEpisodes(id: widget.id);
      debugPrint("Fetching episodes");
      if (!_isDisposed && episodes.isNotEmpty) {
        _episodes.value = episodes;
      }
    } catch (e) {
      if (!_isDisposed) {
        _error.value = 'Failed to fetch episodes: ${e.toString()}';
      }
    } finally {
      if (!_isDisposed) {
        _isLoadingEpisodes.value = false;
      }
    }
  }

  Future<void> _initWatchlistBox() async {
    try {
      _watchlistBox = WatchlistBox();
      await _watchlistBox!.init();
      _loadContinueWatching();
    } catch (e) {
      if (!_isDisposed) {
        _error.value = 'Failed to initialize watchlist: ${e.toString()}';
      }
    }
  }

  void _loadContinueWatching() {
    if (_isDisposed || _watchlistBox == null) return;
    _continueWatchingItem.value =
        _watchlistBox!.getContinueWatchingById(widget.id);
  }

  Widget _buildShimmer(BoxConstraints constraints) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.primaryContainer,
      highlightColor: Theme.of(context).colorScheme.secondaryContainer,
      child: Container(
        height: constraints.maxWidth,
        color: Colors.grey[300],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 400,
      color: Colors.grey[300],
      child: Icon(Icons.error, size: 50, color: Colors.grey[600]),
    );
  }

  Widget _buildHeaderSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<AnimeData?>(
          valueListenable: _info,
          builder: (context, info, _) {
            return Padding(
              padding: const EdgeInsets.only(top: 85.0),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: 70,
                    child: _buildHeaderImage(info, constraints),
                  ),
                  _buildHeaderTitle(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderImage(AnimeData? info, BoxConstraints constraints) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.center,
        colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context)
              .colorScheme
              .secondaryContainer
              .withValues(alpha: 0.15),
        ],
      ).createShader(rect),
      blendMode: BlendMode.srcATop,
      child: Hero(
        tag: 'poster-${widget.id}-${widget.tag}',
        child: SizedBox(
          height: constraints.maxWidth,
          width: 300,
          child: Card(
            child: CachedNetworkImage(
              imageUrl: info != null && widget.tag == 'spotlight'
                  ? getHighResImage(info.anime!.info!.poster)
                  : getHighResImage(widget.image),
              fit: BoxFit.cover,
              memCacheHeight: (constraints.maxWidth *
                      MediaQuery.of(context).devicePixelRatio)
                  .round(),
              placeholder: (context, url) => _buildShimmer(constraints),
              errorWidget: (_, __, ___) => _buildErrorWidget(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Hero(
          tag: 'title-${widget.id}-${widget.tag}',
          child: Text(
            widget.name,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfoItem(IconData icon, String label, String? value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(icon,
                size: 24, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          value == null
              ? Shimmer.fromColors(
                  baseColor: Colors.grey[400]!,
                  highlightColor: Colors.grey[300]!,
                  child: Container(
                    width: 50,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                )
              : Text(
                  value.isEmpty ? 'N/A' : value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
        ],
      ),
    );
  }

  Widget _buildSeasonsSection() {
    return ValueListenableBuilder<AnimeData?>(
      valueListenable: _info,
      builder: (context, info, _) {
        if (info?.seasons == null || info!.seasons!.isEmpty) {
          return const SizedBox.shrink();
        }

        final filteredSeasons =
            info.seasons!.where((season) => !season.isCurrent).toList();

        if (filteredSeasons.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('Seasons', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filteredSeasons.length,
                itemBuilder: (context, index) =>
                    _buildSeasonItem(filteredSeasons[index], index),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeasonItem(AnimeBasic season, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          context.replace(
            '/details?id=${season.id}&tag=season-$index&image=${season.poster}&name=${season.title}',
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'season-poster-$index',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: season.poster,
                      height: 150,
                      width: 100,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        height: 150,
                        width: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      season.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return ValueListenableBuilder<AnimeData?>(
      valueListenable: _info,
      builder: (context, info, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildQuickInfoItem(
                  Icons.timelapse,
                  "Duration",
                  info?.anime?.moreInfo?.duration,
                ),
                _buildQuickInfoItem(
                  Icons.translate,
                  "Japanese",
                  info?.anime?.moreInfo?.japanese,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Details', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            _buildDescription(info),
            const SizedBox(height: 10),
            _buildSeasonsSection(),
            const SizedBox(height: 10),
            _buildEpisodesList(),
          ],
        );
      },
    );
  }

  Widget _buildDescription(AnimeData? info) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDescriptionExpanded,
      builder: (_, isExpanded, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              firstChild: Text(
                info?.anime?.info?.description ?? 'Description not available',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                info?.anime?.info?.description ?? 'Description not available',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  _isDescriptionExpanded.value = !_isDescriptionExpanded.value,
              child: Row(
                children: [
                  Text(
                    isExpanded ? 'Show Less' : 'Show More',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 25,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEpisodesList() {
    return ValueListenableBuilder<Box<WatchlistModel>>(
      valueListenable: _watchlistBox!.listenable(),
      builder: (context, box, _) {
        return ValueListenableBuilder<List<Episode>>(
          valueListenable: _episodes,
          builder: (context, episodes, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _isLoadingEpisodes,
              builder: (context, isLoading, _) {
                return ValueListenableBuilder<AnimeData?>(
                  valueListenable: _info,
                  builder: (context, info, _) {
                    _loadContinueWatching();
                    return EpisodesList(
                      anime: AnimeItem(
                        name: widget.name,
                        poster: info?.anime?.info?.poster ?? widget.image,
                        id: widget.id,
                        type: info?.anime?.info?.stats?.type,
                      ),
                      watchedEpisodes:
                          _continueWatchingItem.value?.watchedEpisodes,
                      episodes: episodes,
                      isLoading: isLoading,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMainContent() {
    final ThemeData themeData = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeData.colorScheme.primaryContainer,
            themeData.colorScheme.secondaryContainer,
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: MediaQuery.of(context).size.height * 0.6,
            leading: IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCancel02,
                size: 30,
                color: themeData.colorScheme.onPrimaryContainer,
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderSection(),
            ),
            actions: [
              FavoriteButton(
                animeId: widget.id,
                title: widget.name,
                image: widget.image,
                type: widget.type,
              ),
              const SizedBox(width: 10),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 10,
              ),
              decoration: BoxDecoration(
                color: themeData.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: _buildDetailsSection(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: ValueListenableBuilder<String?>(
        valueListenable: _error,
        builder: (context, error, child) {
          if (error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(error),
                  ElevatedButton(
                    onPressed: _initializeData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return child!;
        },
        child: _buildMainContent(),
      ),
      bottomNavigationBar: ValueListenableBuilder<Box<WatchlistModel>>(
        valueListenable: _watchlistBox!.listenable(),
        builder: (context, box, _) {
          return ValueListenableBuilder<List<Episode>>(
            valueListenable: _episodes,
            builder: (context, episodes, _) {
              final continueWatchingItem =
                  _watchlistBox?.getContinueWatchingById(widget.id);

              if (continueWatchingItem == null || episodes.length < 2) {
                return const SizedBox.shrink();
              }

              return BottomPlayerBar(
                animeId: widget.id,
                episodes: episodes,
                continueWatchingItem: continueWatchingItem,
                type: widget.type,
              );
            },
          );
        },
      ),
    );
  }
}
