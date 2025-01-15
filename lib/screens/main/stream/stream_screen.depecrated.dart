import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';
import 'package:nekoflow/data/boxes/watchlist_box.dart';
import 'package:nekoflow/data/models/episodes_model.dart';
import 'package:nekoflow/data/models/stream_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';

class StreamScreen extends StatefulWidget {
  final String title;
  final String id;
  final String episodeId;
  final String poster;
  final int episode;
  final String name;
  final String? type;

  const StreamScreen({
    super.key,
    required this.title,
    required this.id,
    required this.episodeId,
    required this.poster,
    required this.episode,
    required this.name,
    this.type,
  });

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  static const defaultServer = "hd-1";
  static const defaultDubSub = "sub";
  // static const progressThreshold = 0.05; // 5% threshold for recently watched

  final AnimeService _animeService = AnimeService();
  final _serversCache = <String, EpisodeServersModel>{};
  final _linksCache = <String, EpisodeStreamingLinksModel>{};
  late final WatchlistBox _watchlistBox;
  late ContinueWatchingItem? _continueWatchingItem;

  BetterPlayerController? _playerController;
  String _selectedServer = defaultServer;
  String _selectedDubSub = defaultDubSub;
  String _currentPosition = '0:00:00.000000';

  bool _isLoading = true;
  bool _isPlayerInitializing = false;
  EpisodeServersModel? _episodeServers;
  EpisodeStreamingLinksModel? _streamingLinks;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _watchlistBox = WatchlistBox();
    await _watchlistBox.init();

    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      _continueWatchingItem = _watchlistBox.getContinueWatchingById(widget.id);
      await Future.wait([
        _fetchEpisodeServers(widget.episodeId),
        _fetchStreamingLinks(widget.episodeId),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEpisodeServers(String episodeId) async {
    if (!mounted) return;

    try {
      if (_serversCache.containsKey(episodeId)) {
        setState(() => _episodeServers = _serversCache[episodeId]);
        return;
      }

      final servers = await _animeService.fetchEpisodeServers(
        animeEpisodeId: episodeId,
      );

      if (mounted) {
        setState(() {
          _episodeServers = servers;
          _serversCache[episodeId] = servers;
        });
      }
    } catch (e) {
      debugPrint("Error fetching episode servers: $e");
    }
  }

  Future<void> _fetchStreamingLinks(String episodeId) async {
    final cacheKey = '$episodeId-$_selectedServer-$_selectedDubSub';

    try {
      if (_linksCache.containsKey(cacheKey)) {
        _streamingLinks = _linksCache[cacheKey];
        await _initializePlayer();
        return;
      }

      final links = await _animeService.fetchEpisodeStreamingLinks(
        animeEpisodeId: episodeId,
        server: _selectedServer,
        category: _selectedDubSub,
      );

      if (mounted) {
        _streamingLinks = links;
        _linksCache[cacheKey] = links;
        await _initializePlayer();
      }
    } catch (e) {
      debugPrint("Error fetching streaming links: $e");
    }
  }

  Future<void> _initializePlayer() async {
    if (!mounted || _isPlayerInitializing || _streamingLinks == null) return;

    setState(() => _isPlayerInitializing = true);

    try {
      _playerController?.dispose();
      _playerController = null;
      final ThemeData themeData = Theme.of(context);
      final parts = _currentPosition.split(':');
      final controller = BetterPlayerController(
        BetterPlayerConfiguration(
          startAt: Duration(
            minutes: int.parse(parts[1]),
            seconds: double.parse(parts[2]).floor(),
          ),
          autoPlay: true,
          fit: BoxFit.contain,
          deviceOrientationsOnFullScreen: const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
          deviceOrientationsAfterFullScreen: const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ],
          controlsConfiguration: BetterPlayerControlsConfiguration(
            controlBarColor: Colors.black54,
            enableProgressText: true,
            enableSubtitles: true,
            loadingColor: themeData.colorScheme.primary,
          ),
        ),
      );

      final subtitles = _streamingLinks!.tracks
              ?.where((track) => track.label != null)
              .map((track) => BetterPlayerSubtitlesSource(
                    type: BetterPlayerSubtitlesSourceType.network,
                    urls: [track.file],
                    name: track.label,
                    selectedByDefault: track.isDefault ?? false,
                  ))
              .toList() ??
          [];

      await controller.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          _streamingLinks!.sources[0].url,
          subtitles: subtitles,
        ),
      );

      final existingItem = _watchlistBox.getContinueWatchingById(widget.id);
      final watchedEpisodes =
          List<String>.from(existingItem?.watchedEpisodes ?? []);
      if (!watchedEpisodes.contains(widget.episodeId)) {
        watchedEpisodes.add(widget.episodeId);
      }

      await _watchlistBox.updateContinueWatching(
        ContinueWatchingItem(
          title: widget.title,
          id: widget.id,
          name: widget.name,
          poster: widget.poster,
          episode: widget.episode,
          episodeId: widget.episodeId,
          timestamp: _currentPosition,
          duration: _currentPosition,
          type: widget.type,
          watchedEpisodes: watchedEpisodes,
        ),
      );

      await _watchlistBox.addToRecentlyWatched(
        RecentlyWatchedItem(
            name: widget.name, poster: widget.poster, id: widget.id),
      );

      controller.addEventsListener(_onPlayerEvent);

      setState(() => _playerController = controller);
    } finally {
      if (mounted) {
        if (_continueWatchingItem?.episodeId == widget.episodeId) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                'Continue Watching',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              content: Text(
                'Continue where you left off?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    _currentPosition = _continueWatchingItem!.timestamp;
                    if (_playerController != null &&
                        _currentPosition != '0:00:00.000000') {
                      final parts = _currentPosition.split(':');
                      if (parts.length >= 3) {
                        final duration = Duration(
                          hours: int.parse(parts[0]),
                          minutes: int.parse(parts[1]),
                          seconds: double.parse(parts[2]).floor(),
                          milliseconds:
                              ((double.parse(parts[2]) % 1) * 1000).round(),
                        );
                        await _playerController!.seekTo(duration);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
        }
        setState(() => _isPlayerInitializing = false);
      }
    }
  }

  Future<void> _onPlayerEvent(BetterPlayerEvent event) async {
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.progress:
        // Handle progress updates
        final position =
            _playerController?.videoPlayerController?.value.position;
        final duration =
            _playerController?.videoPlayerController?.value.duration;
        debugPrint("Progress: $position / $duration");
        await _watchlistBox.updateEpisodeProgress(
          widget.id,
          episode: widget.episode,
          episodeId: widget.episodeId,
          timestamp: position.toString(),
          duration: duration.toString(),
        );
        break;

      // case BetterPlayerEventType.finished:
      //   // Handle video finished playing
      //   debugPrint("Video playback finished");
      //   break;

      // case BetterPlayerEventType.exception:
      //   // Handle playback exceptions
      //   debugPrint("Playback exception: ${event.parameters?['exception']}");
      //   break;

      // case BetterPlayerEventType.bufferingStart:
      //   debugPrint("Buffering started");
      //   break;

      // case BetterPlayerEventType.bufferingEnd:
      //   debugPrint("Buffering ended");
      //   break;

      default:
        debugPrint("Event: ${event.betterPlayerEventType}");
    }
  }

  @override
  void dispose() {
    _playerController?.dispose();
    _animeService.dispose();
    super.dispose();
  }

  // UI Methods
  void _onDubSubChanged(String value) {
    setState(() {
      _selectedDubSub = value;
      _fetchStreamingLinks(widget.episodeId);
    });
  }

  void _onServerChanged(String value) {
    setState(() {
      _selectedServer = value;
      _fetchStreamingLinks(widget.episodeId);
    });
  }

  @override
Widget build(BuildContext context) {
  // final ThemeData themeData = Theme.of(context);

  return DismissiblePage(
    onDismissed: () => Navigator.of(context).pop(),
    direction: DismissiblePageDismissDirection.none,
    child: Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(widget.title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBannerSection(),
            const SizedBox(height: 20),
            _buildPlayer(),
            const SizedBox(height: 20),
            _buildChoiceSection(),
            const SizedBox(height: 20),
            _buildServersSection(),
          ],
        ),
      ),
    ),
  );
}

  // UI Components
  Widget _buildPlayer() {
    ThemeData themeData = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            themeData.colorScheme.primary.withOpacity(0.05),
            themeData.colorScheme.secondary.withOpacity(0.8),
            themeData.colorScheme.tertiary.withOpacity(0.05)
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      height: 230,
      width: double.infinity,
      child: _isPlayerInitializing || _playerController == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                Text(
                  "Loading video...",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            )
          : BetterPlayer(controller: _playerController!),
    );
  }

  Widget _buildBannerSection() {
  return Stack(
    children: [
      Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: NetworkImage(widget.poster),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 15,
        left: 15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                overflow: TextOverflow.ellipsis
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Episode ${widget.episode}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildChoiceSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Select Language",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          _buildChoiceButton(
              "Sub", _selectedDubSub == "sub", () => _onDubSubChanged("sub")),
          const SizedBox(width: 15),
          _buildChoiceButton(
              "Dub", _selectedDubSub == "dub", () => _onDubSubChanged("dub")),
        ],
      ),
    ],
  );
}


  Widget _buildServersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Servers",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(
            height: 50,
            child: ListView.builder(
              itemCount: _episodeServers?.sub.length ?? 0,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final serverName = _episodeServers?.sub[index].serverName ?? "";
                return _buildServerButton(
                  serverName,
                  serverName == _selectedServer,
                  () => _onServerChanged(serverName),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildChoiceButton(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary, width: 3),
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerButton(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 3),
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
