import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/boxes/watchlist_box.dart';
import 'package:nekoflow/data/models/episodes_model.dart';
import 'package:nekoflow/data/models/stream_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:nekoflow/widgets/player/custom_controls.dart';
import 'package:nekoflow/widgets/player/video_player.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class StreamScreen extends StatefulWidget {
  final List<Episode> episodes;
  final Episode? episode;
  final AnimeItem? anime;

  const StreamScreen({
    super.key,
    required this.episodes,
    this.anime,
    this.episode,
  });

  @override
  StreamScreenState createState() => StreamScreenState();
}

class StreamScreenState extends State<StreamScreen> {
  late AnimeService _animeService;
  late WatchlistBox _watchlistBox;
  late AutoScrollController _autoScrollController;

  BetterPlayerController? _playerController;
  Episode? _currentEpisode;
  String _selectedServer = "hd-1";
  String _selectedDubOrSubOrRaw = "sub";
  int _selectedRangeIndex = 0;
  Duration? _position;
  Duration? _duration;
  bool _isPlayerInitializing = true;

  List<Map<String, List<Episode>>> _groupedEpisodes = [];
  EpisodeServersModel? _episodeServersModel;
  EpisodeStreamingLinksModel? _episodeStreamingLinksModel;

  @override
  void initState() {
    super.initState();
    // Enable wakelock when entering this screen
    WakelockPlus.enable();

    _animeService = AnimeService();
    _watchlistBox = WatchlistBox();
    _autoScrollController = AutoScrollController();

    // First priority: Set up episode list and scroll position
    _currentEpisode = widget.episode ?? widget.episodes.first;
    _groupedEpisodes = _groupEpisodes(widget.episodes);

    // Set initial range index based on current episode
    final currentIndex = widget.episodes
        .indexWhere((episode) => episode.number == _currentEpisode!.number);
    if (currentIndex >= 50) {
      _selectedRangeIndex = _groupedEpisodes.indexWhere((item) {
        final range = item.keys.first.split('-').map(int.parse).toList();
        return range[0] <= currentIndex + 1 && range[1] >= currentIndex + 1;
      });
    }

    // Schedule scroll after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentEpisode();
    });

    // Initialize the rest in the background
    _initialize();
  }

  Future<void> _initialize() async {
    await _watchlistBox.init();
    await _loadEpisodeData(_currentEpisode!.episodeId);
    await _askContinueWatching();
  }

  Future<void> _askContinueWatching() async {
    final continueWatchingItem =
        _watchlistBox.getContinueWatchingById(widget.anime!.id);
    if (continueWatchingItem != null &&
        continueWatchingItem.episodeId == _currentEpisode!.episodeId) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Continue Watching?'),
            content: Text('Would you like to resume from where you left off?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Resume'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Start Over'),
              ),
            ],
          );
        },
      );

      if (shouldContinue == true) {
        final parts = continueWatchingItem.timestamp.split(":");
        _position = Duration(
          minutes: int.parse(parts[1]),
          seconds: int.parse(parts[2].split('.')[0]),
        );
      } else {
        _position = Duration.zero; // Reset position if user opts to start over
      }
    } else {
      _position =
          Duration.zero; // Reset position if no continue watching item exists
    }
    await _fetchStreamingLinks(_currentEpisode!
        .episodeId); // Fetch streaming links after setting position
  }

  Future<void> _loadEpisodeData(String episodeId) async {
    await _fetchEpisodeServers(episodeId);
  }

  Future<void> _fetchEpisodeServers(String episodeId) async {
    try {
      _episodeServersModel =
          await _animeService.fetchEpisodeServers(animeEpisodeId: episodeId);
    } catch (e) {
      debugPrint("Error fetching episode servers: $e");
    }
  }

  Future<void> _fetchStreamingLinks(String episodeId) async {
    try {
      _episodeStreamingLinksModel =
          await _animeService.fetchEpisodeStreamingLinks(
        animeEpisodeId: episodeId,
        server: _selectedServer,
        category: _selectedDubOrSubOrRaw,
      );
      await _initializePlayer();
    } catch (e) {
      debugPrint("Error fetching streaming links: $e");
    }
  }

  Future<void> _initializePlayer() async {
    _playerController?.dispose();
    setState(() => _isPlayerInitializing = true);

    try {
      final startPosition =
          _position ?? Duration.zero; // Capture the current position
      _playerController = BetterPlayerController(
        BetterPlayerConfiguration(
            autoPlay: true,
            autoDispose: true,
            fit: BoxFit.contain,
            startAt: startPosition, // Use the captured position
            errorBuilder: (context, errorMessage) => Center(
                  child: Text('Error loading video: $errorMessage',
                      style: TextStyle(color: Colors.red)),
                ),
            controlsConfiguration: BetterPlayerControlsConfiguration(
              playerTheme: BetterPlayerTheme.custom,
              customControlsBuilder:
                  (controller, onControlsVisibilityChanged) =>
                      CustomControlsWidget(
                controller: controller,
                onControlsVisibilityChanged: onControlsVisibilityChanged,
              ),
            ),
            subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(
              fontColor: Colors.white,
                backgroundColor: Colors.black.withValues(alpha:0.0),
                fontSize: 22,
                fontFamily: 'Montserrat',
            )),
      );

      await _playerController?.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          _episodeStreamingLinksModel!.sources[0].url,
          subtitles: _episodeStreamingLinksModel!.tracks
              ?.map((track) => BetterPlayerSubtitlesSource(
                    type: BetterPlayerSubtitlesSourceType.network,
                    name: track.label,
                    urls: [track.file],
                    selectedByDefault: track.isDefault,
                  ),)
              .toList(),
        ),
      );

      _playerController?.addEventsListener(_onPlayerEvent);
    } catch (e) {
      debugPrint("Player initialization failed: $e");
    } finally {
      setState(() => _isPlayerInitializing = false);
      await _watchlistBox.addToRecentlyWatched(RecentlyWatchedItem(
        name: widget.anime!.name,
        poster: widget.anime!.poster,
        id: widget.anime!.id,
      ));
    }
  }

  Future<void> _onPlayerEvent(BetterPlayerEvent event) async {
    if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
      final videoController = _playerController?.videoPlayerController;
      _position = videoController?.value.position;
      _duration = videoController?.value.duration;

      if (_position != null && _duration != null) {
        final episodeProgress = ContinueWatchingItem(
          id: widget.anime!.id,
          name: widget.anime!.name,
          poster: widget.anime!.poster,
          episode: _currentEpisode!.number,
          episodeId: _currentEpisode!.episodeId,
          title: _currentEpisode!.title,
        );

        await _watchlistBox.updateEpisodeProgress(
          widget.anime!.id,
          episode: _currentEpisode!.number,
          episodeId: _currentEpisode!.episodeId,
          timestamp: _position.toString(),
          duration: _duration.toString(),
          markAsWatched: true,
          item: episodeProgress,
        );
      }
    }
  }

  List<Map<String, List<Episode>>> _groupEpisodes(List<Episode> episodes,
      {int rangeSize = 50}) {
    if (episodes.isEmpty) return [];
    return List.generate(
      (episodes.length / rangeSize).ceil(),
      (index) {
        final start = index * rangeSize + 1;
        final end = (start + rangeSize - 1).clamp(1, episodes.length);
        return {
          '$start - $end': episodes.sublist(
              index * rangeSize,
              (index + 1) * rangeSize > episodes.length
                  ? episodes.length
                  : (index + 1) * rangeSize),
        };
      },
    );
  }

  void _playEpisode(Episode episode) async {
    setState(() {
      _currentEpisode = episode;
      _position = Duration.zero; // Reset position for new episode
    });
    await _fetchStreamingLinks(_currentEpisode!.episodeId); // Wait for this
    _playerController?.videoPlayerController?.seekTo(Duration.zero);
    _scrollToCurrentEpisode();
  }

  void _scrollToCurrentEpisode() {
    final currentIndexInGrouped = _groupedEpisodes[_selectedRangeIndex]
        .values
        .first
        .indexWhere((episode) => episode.number == _currentEpisode!.number);

    if (currentIndexInGrouped != -1) {
      _autoScrollController.scrollToIndex(
        currentIndexInGrouped,
        preferPosition: AutoScrollPosition.middle,
        duration: Duration(milliseconds: 500),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(widget.anime?.name ?? 'Stream'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildVideoPlayer(),
          _buildEpisodeTitle(),
          _buildControls(),
          _buildEpisodeList(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _isPlayerInitializing || _playerController == null
            ? Center(child: CircularProgressIndicator())
            : VideoPlayer(playerController: _playerController!),
      ),
    );
  }

  Widget _buildEpisodeTitle() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Text(
        _currentEpisode?.title ?? '',
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDropdown(
            value: _selectedDubOrSubOrRaw,
            items: ['sub', 'dub', 'raw'],
            onChanged: (value) {
              setState(() {
                _selectedDubOrSubOrRaw = value!;
                _fetchStreamingLinks(_currentEpisode!.episodeId);
              });
            },
          ),
          SizedBox(
            width: 10,
          ),
          _buildDropdown(
            value: _selectedServer,
            items: _getAvailableServers(_selectedDubOrSubOrRaw),
            onChanged: (value) {
              setState(() {
                _selectedServer = value!;
                _fetchStreamingLinks(_currentEpisode!.episodeId);
              });
            },
          ),
          SizedBox(
            width: 10,
          ),
          _buildRangeDropdown(),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    if (items.isEmpty) {
      return SizedBox.shrink();
    }
    return Expanded(
      child: GestureDetector(
        onTap: () => _showDropdownMenu(value, items, onChanged),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.primary),
            borderRadius:
                (Theme.of(context).cardTheme.shape as RoundedRectangleBorder)
                    .borderRadius,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }

  void _showDropdownMenu(
      String value, List<String> items, ValueChanged<String?> onChanged) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: items.map((item) {
              return ListTile(
                title: Text(
                  item.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  onChanged(item);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildRangeDropdown() {
    if (_groupedEpisodes.isEmpty) {
      return SizedBox.shrink();
    }
    return Expanded(
      child: GestureDetector(
        onTap: () => _showRangeSelectionModal(),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.primary),
            borderRadius:
                (Theme.of(context).cardTheme.shape as RoundedRectangleBorder)
                    .borderRadius,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _groupedEpisodes[_selectedRangeIndex].keys.first,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }

  void _showRangeSelectionModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _groupedEpisodes.length,
            itemBuilder: (context, index) {
              final isSelected = index ==
                  _selectedRangeIndex; // Check if this index is selected
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRangeIndex = index;
                  });
                  Navigator.of(context).pop();
                },
                child: Card(
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .secondaryContainer // Highlight selected range
                      : Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.8),
                  child: Center(
                    child: Text(
                      _groupedEpisodes[index].keys.first,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEpisodeList() {
    if (_groupedEpisodes.isEmpty) {
      return Center(child: Text('No episodes available.'));
    }

    return Expanded(
      child: ListView.builder(
        controller: _autoScrollController,
        itemCount: _groupedEpisodes[_selectedRangeIndex].values.first.length,
        itemBuilder: (context, index) {
          final episode =
              _groupedEpisodes[_selectedRangeIndex].values.first[index];
          return AutoScrollTag(
            key: ValueKey(episode.number),
            controller: _autoScrollController,
            index: index,
            child: _buildEpisodeTile(episode),
          );
        },
      ),
    );
  }

  Widget _buildEpisodeTile(Episode episode) {
    final isCurrentEpisode = episode.number == _currentEpisode?.number;

    return Card(
      color: isCurrentEpisode
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      elevation: isCurrentEpisode ? 6 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(
          episode.title,
          style: TextStyle(
              fontWeight:
                  isCurrentEpisode ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: Text('Episode ${episode.number}'),
        trailing: IconButton(
          icon: HugeIcon(
            icon: isCurrentEpisode
                ? HugeIcons.strokeRoundedPause
                : HugeIcons.strokeRoundedPlay,
            size: 36,
            color: isCurrentEpisode
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => _playEpisode(episode),
        ),
      ),
    );
  }

  List<String> _getAvailableServers(String type) {
    final serverMap = {
      'sub': _episodeServersModel?.sub
              .map((server) => server.serverName)
              .toList() ??
          [],
      'dub': _episodeServersModel?.dub
              .map((server) => server.serverName)
              .toList() ??
          [],
      'raw': _episodeServersModel?.raw
              .map((server) => server.serverName)
              .toList() ??
          [],
    };
    return serverMap[type] ?? [];
  }

  @override
  void dispose() {
    // Disable wakelock when leaving this screen
    WakelockPlus.disable();
    _autoScrollController.dispose();
    _animeService.dispose();
    _playerController?.dispose();
    super.dispose();
  }
}
