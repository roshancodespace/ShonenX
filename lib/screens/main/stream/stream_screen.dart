import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/boxes/watchlist_box.dart';
import 'package:nekoflow/data/models/episodes_model.dart';
import 'package:nekoflow/data/models/stream_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:nekoflow/widgets/player/video_player.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class StreamScreen extends StatefulWidget {
  final List<Episode> episodes;
  final Episode? episode;
  final AnimeItem? anime;
  final ContinueWatchingItem? continueWatchingItem;
  const StreamScreen({
    super.key,
    required this.episodes,
    this.anime,
    this.episode,
    this.continueWatchingItem,
  });

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  String _selectedServer = "hd-1";
  String _selectedDuborSuborRaw = "sub";
  int _selectedRangeIndex = 0;

  Duration? _position;
  Duration? _duration;
  List<Map<String, List<Episode>>> _groupedEpisodes = [];

  EpisodeServersModel? _episodeServersModel;
  EpisodeStreamingLinksModel? _episodeStreamingLinksModel;

  bool _isPlayerInitializing = true;

  late Episode _currentEpisode;
  late AutoScrollController _autoScrollController;
  late AnimeService _animeService;
  late WatchlistBox _watchlistBox;

  // Change to nullable and initialize as null
  BetterPlayerController? _playerController;

  @override
  void initState() {
    super.initState();
    _animeService = AnimeService();
    _initializeBox();
    _autoScrollController = AutoScrollController();
    _initializeEpisode();
    _initializePlayer();
    _scrollToCurrentEpisode();
  }

  @override
  void dispose() {
    _autoScrollController.dispose();
    _animeService.dispose();
    _playerController?.dispose();
    super.dispose();
  }

  Future<void> _initializeEpisode() async {
    _groupedEpisodes = _getGroupedEpisodes(widget.episodes);
    _currentEpisode = widget.episode ?? widget.episodes.first;
    _fetchEpisodeServers(_currentEpisode.episodeId);
    _fetchStreamingLinks(_currentEpisode.episodeId);
    if (widget.continueWatchingItem != null) {
      final item = widget.continueWatchingItem;
      List<String> timestampParts = item?.timestamp.split(":") ?? [];
      _position = Duration(
        minutes: int.parse(timestampParts[1]),
        seconds: int.parse(timestampParts[2].split('.')[0]),
      );
    }
  }

  Future<void> _initializeBox() async {
    _watchlistBox = WatchlistBox();
    await _watchlistBox.init();
  }

  Future<void> _initializePlayer() async {
    // Dispose of existing controller if it exists
    _playerController?.dispose();

    setState(() {
      _isPlayerInitializing = true;
    });

    try {
      // Create a new controller each time
      _playerController = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          autoDispose: true,
          fit: BoxFit.contain,
          startAt: _position,
          // Add error handling configuration
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                'Error loading video: $errorMessage',
                style: TextStyle(color: Colors.red),
              ),
            );
          },
        ),
      );

      await _playerController?.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          _episodeStreamingLinksModel!.sources[0].url,
          subtitles: _episodeStreamingLinksModel!.tracks
              ?.map(
                (track) => BetterPlayerSubtitlesSource(
                  type: BetterPlayerSubtitlesSourceType.network,
                  name: track.label,
                  urls: [track.file],
                  selectedByDefault: track.isDefault,
                ),
              )
              .toList(),
        ),
      );

      _playerController?.addEventsListener(_onPlayerEvent);
      setState(() {
        _isPlayerInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isPlayerInitializing = false;
      });
      debugPrint("Player initialization failed: $e");
    } finally {
      // await _watchlistBox.updateContinueWatching(
      //   ContinueWatchingItem(
      //     id: widget.anime!.id,
      //     name: widget.anime!.name,
      //     poster: widget.anime!.poster,
      //     episode: widget.episode!.number,
      //     episodeId: widget.episode!.episodeId,
      //     title: widget.episode!.title,
      //   ),
      // );
      await _watchlistBox.addToRecentlyWatched(
        RecentlyWatchedItem(
          name: widget.anime!.name,
          poster: widget.anime!.poster,
          id: widget.anime!.id,
        ),
      );
    }
  }

  Future<void> _onPlayerEvent(BetterPlayerEvent event) async {
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.progress:
        _position = _playerController?.videoPlayerController?.value.position;
        _duration = _playerController?.videoPlayerController?.value.duration;
        if (_position != null && _duration != null) {
          await _watchlistBox.updateEpisodeProgress(
            widget.anime!.id,
            episode: _currentEpisode.number,
            episodeId: _currentEpisode.episodeId,
            timestamp: _position.toString(),
            duration: _duration.toString(),
            markAsWatched: true,
            item: ContinueWatchingItem(
              id: widget.anime!.id,
              name: widget.anime!.name,
              poster: widget.anime!.poster,
              episode: _currentEpisode.number,
              episodeId: _currentEpisode.episodeId,
              title: _currentEpisode.title,
            ),
          );
        }
        break;
      default:
    }
  }

  Future<void> _fetchEpisodeServers(String episodeId) async {
    try {
      _episodeServersModel =
          await _animeService.fetchEpisodeServers(animeEpisodeId: episodeId);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  Future<void> _fetchStreamingLinks(String episodeId) async {
    try {
      _episodeStreamingLinksModel =
          await _animeService.fetchEpisodeStreamingLinks(
        animeEpisodeId: episodeId,
        server: _selectedServer,
        category: _selectedDuborSuborRaw,
      );
      // Call _initializePlayer after fetching streaming links
      await _initializePlayer();
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  List<String> _getAvailableServers(String type) {
    // Map of types to their respective server lists
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

    // Return the list for the requested type, or an empty list if not found
    return serverMap[type] ?? [];
  }

  List<Map<String, List<Episode>>> _getGroupedEpisodes(List<Episode> episodes,
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
                : (index + 1) * rangeSize,
          )
        };
      },
    );
  }

  void _changeRange(int rangeIndex) {
    setState(() {
      _selectedRangeIndex = rangeIndex;
    });
  }

  void _playEpisode(Episode episode) {
    _currentEpisode = episode;
    _fetchStreamingLinks(_currentEpisode.episodeId);
    _scrollToCurrentEpisode();
    setState(() {});
  }

  void _scrollToCurrentEpisode() {
    final int currentIndex = widget.episodes.indexWhere(
      (episode) => episode.number == _currentEpisode.number,
    );
    if (currentIndex >= 50) {
      _selectedRangeIndex = _groupedEpisodes.indexWhere(
        (item) =>
            int.parse(item.keys.first.split('-')[0].trim()) - 1 <
                currentIndex &&
            int.parse(item.keys.first.split('-')[1].trim()) >= currentIndex,
      );
      setState(() {});
    }
    final int currentIndexInGrouped =
        _groupedEpisodes[_selectedRangeIndex].values.first.indexWhere(
              (episode) => episode.number == _currentEpisode.number,
            );
    if (currentIndex != -1) {
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
        actions: [
          // _buildDropAction(
          //   currentValue: _selectedServer,
          //   items: _getAvailableServers(_selectedDuborSuborRaw),
          //   onChanged: (value) {
          //     setState(() {
          //       _selectedServer = value!;
          //       _fetchStreamingLinks(_currentEpisode.episodeId);
          //     });
          //   },
          // ),
          // _buildDropAction(
          //   currentValue: _selectedDuborSuborRaw,
          //   items: ['sub', 'dub', 'raw'],
          //   onChanged: (value) {
          //     setState(() {
          //       _selectedDuborSuborRaw = value!;
          //       _fetchStreamingLinks(_currentEpisode.episodeId);
          //     });
          //   },
          // ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
        
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: _buildVideoPlayer(),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              _currentEpisode.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // _buildDropAction(
                //   currentValue: _groupedEpisodes[_selectedRangeIndex].keys.first,
                //   items: extractKeysFromList(_groupedEpisodes),
                //   onChanged: (index) {
                //     // Ensure index is properly parsed to int
                //     _changeRange(int.parse(index ?? '0'));
                //   },
                // ),
                Expanded(
                  child: _buildDropAction(
                    currentValue: _selectedDuborSuborRaw,
                    items: ['sub', 'dub', 'raw'],
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _selectedDuborSuborRaw = value!;
                        _fetchStreamingLinks(_currentEpisode.episodeId);
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                _buildDropAction(
                  currentValue: _selectedServer,
                  items: _getAvailableServers(_selectedDuborSuborRaw),
                  onChanged: (value) {
                    setState(() {
                      _selectedServer = value!;
                      _fetchStreamingLinks(_currentEpisode.episodeId);
                    });
                  },
                ),
                SizedBox(
                  width: 10,
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(15)),
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownButton<int>(
                    value: _selectedRangeIndex,
                    onChanged: (index) {
                      _changeRange(index ?? _selectedRangeIndex);
                    },
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowDown01,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    iconSize: 24,
                    items: _groupedEpisodes.asMap().entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(
                          entry.value.keys.first,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
                controller: _autoScrollController,
                padding: EdgeInsets.all(0),
                itemCount:
                    _groupedEpisodes[_selectedRangeIndex].values.first.length,
                itemBuilder: (context, index) {
                  final Episode episode =
                      _groupedEpisodes[_selectedRangeIndex].values.first[index];
                  return _buildEpisodeTile(episode, index);
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildDropAction(
      {required String currentValue,
      required List<String>? items,
      required ValueChanged<String?> onChanged,
      bool isExpanded = false}) {
    if (items == null || items.isEmpty) return SizedBox.shrink();

    // Ensure currentValue is valid
    final validCurrentValue = items.contains(currentValue)
        ? currentValue
        : items.first; // Fallback to the first item if currentValue is invalid

    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(15)),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButton<String>(
        underline: SizedBox(),
        value: validCurrentValue,
        isExpanded: isExpanded,
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowDown01,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        iconSize: 24,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
        selectedItemBuilder: (context) => items.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(
              option.toUpperCase(),
            ),
          );
        }).toList(),
        items: items.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(
              option.toUpperCase(),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Widget _buildActionButton(
  //   IconData iconData, {
  //   VoidCallback? action,
  //   double? top,
  //   double? right,
  //   double? bottom,
  //   double? left,
  // }) {
  //   return Positioned(
  //     left: left,
  //     right: right,
  //     top: top,
  //     bottom: bottom,
  //     child: InkWell(
  //       onTap: action,
  //       child: Container(
  //         height: 50,
  //         width: 50,
  //         decoration: BoxDecoration(
  //           color: Theme.of(context).colorScheme.primary,
  //           borderRadius: BorderRadius.circular(50),
  //         ),
  //         child: HugeIcon(
  //           icon: iconData,
  //           color: Theme.of(context).colorScheme.onTertiary,
  //           size: 30,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildVideoPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 1.8,
        child: _isPlayerInitializing || _playerController == null
            ? Container(
                color: Theme.of(context).colorScheme.primary,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              )
            : VideoPlayer(playerController: _playerController!),
      ),
    );
  }

  Widget _buildEpisodeTile(Episode episode, int index) {
    final bool isCurrentEpisode = episode.number == _currentEpisode.number;

    return AutoScrollTag(
      key: ValueKey(index),
      controller: _autoScrollController,
      index: index,
      child: Card(
        color: isCurrentEpisode
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        elevation: isCurrentEpisode ? 6 : 2,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            episode.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight:
                      isCurrentEpisode ? FontWeight.bold : FontWeight.w600,
                  color: isCurrentEpisode
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Episode ${episode.number}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isCurrentEpisode
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: HugeIcon(
              icon: isCurrentEpisode
                  ? HugeIcons.strokeRoundedPause
                  : HugeIcons.strokeRoundedPlay,
              color: isCurrentEpisode
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
              size: 36,
            ),
            onPressed: () => _playEpisode(episode),
          ),
        ),
      ),
    );
  }
}
