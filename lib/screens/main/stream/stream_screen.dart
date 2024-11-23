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

    final continueWatching = _watchlistBox.getContinueWatchingById(widget.id);
    if (continueWatching?.episodeId == widget.episodeId) {
      if (!mounted) return;
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
              onPressed: () {
                Navigator.of(context).pop();
                _currentPosition = continueWatching!.timestamp;
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

    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
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

      final controller = BetterPlayerController(
        BetterPlayerConfiguration(
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
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            controlBarColor: Colors.black54,
            enableProgressText: true,
            enableSubtitles: true,
            loadingColor: Colors.white,
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

      controller.addEventsListener(_onPlayerEvent);

      if (_currentPosition != '0:00:00.000000') {
        final parts = _currentPosition.split(':');
        if (parts.length >= 3) {
          final duration = Duration(
            hours: int.parse(parts[0]),
            minutes: int.parse(parts[1]),
            seconds: double.parse(parts[2]).floor(),
            milliseconds: ((double.parse(parts[2]) % 1) * 1000).round(),
          );
          await controller.seekTo(duration);
        }
      }

      setState(() => _playerController = controller);
    } finally {
      _playerController?.pause();
      if (mounted) setState(() => _isPlayerInitializing = false);
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
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(widget.title),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlayer(),
            const SizedBox(height: 20),
            _buildDubSubButtons(),
            const SizedBox(height: 20),
            const Text(
              "Servers",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            _buildServersSection(),
          ],
        ),
      ),
    );
  }

  // UI Components
  Widget _buildPlayer() {
    return Container(
      color: Colors.black,
      height: 230,
      width: double.infinity,
      child: _isPlayerInitializing || _playerController == null
          ? const Center(child: CircularProgressIndicator())
          : BetterPlayer(controller: _playerController!),
    );
  }

  Widget _buildDubSubButtons() {
    return Row(
      children: [
        _buildChoiceButton(
            "Sub", _selectedDubSub == "sub", () => _onDubSubChanged("sub")),
        const SizedBox(width: 15),
        _buildChoiceButton(
            "Dub", _selectedDubSub == "dub", () => _onDubSubChanged("dub")),
      ],
    );
  }

  Widget _buildServersSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final servers =
        _selectedDubSub == "sub" ? _episodeServers?.sub : _episodeServers?.dub;

    if (servers == null || servers.isEmpty) {
      return const Center(child: Text('No servers available'));
    }

    return SizedBox(
      height: 50,
      child: ListView.builder(
        itemCount: servers.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final serverName = servers[index].serverName;
          return _buildServerButton(
            serverName,
            serverName == _selectedServer,
            () => _onServerChanged(serverName),
          );
        },
      ),
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
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary.withOpacity(0.7),
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
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary,
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
