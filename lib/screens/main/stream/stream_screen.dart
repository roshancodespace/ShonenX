import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nekoflow/data/boxes/watchlist_box.dart';
import 'package:nekoflow/data/models/episodes_model.dart';
import 'package:nekoflow/data/models/stream_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:better_player/better_player.dart';
import 'package:shimmer/shimmer.dart';

class StreamScreen extends StatefulWidget {
  final String title;
  final String id;
  final String episodeId;
  final String poster;
  final int episode;
  final String name;
  final String? type;

  const StreamScreen(
      {super.key,
      required this.title,
      required this.id,
      required this.episodeId,
      required this.poster,
      required this.episode,
      required this.name,
      this.type});

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  static const _defaultServer = "hd-1";
  static const _defaultDubSub = "sub";

  final AnimeService _animeService = AnimeService();
  final Map<String, EpisodeServersModel> _serversCache = {};
  final Map<String, EpisodeStreamingLinksModel> _linksCache = {};

  late final WatchlistBox _watchlistBox;
  late String _selectedEpisodeId;

  BetterPlayerController? _playerController;
  EpisodeServersModel? _episodeServers;
  EpisodeStreamingLinksModel? _streamingLinks;

  String _selectedServer = _defaultServer;
  String _selectedDubSub = _defaultDubSub;
  String _currentPosition = '0:00:00.000000';
  bool _isLoading = true;
  bool _isPlayerInitializing = false;

  @override
  void initState() {
    super.initState();
    _selectedEpisodeId = widget.episodeId;
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    _watchlistBox = WatchlistBox();
    await _watchlistBox.init();
    _initializeData();

    // Restore previous position if exists
    final continueWatchingItem =
        _watchlistBox.getContinueWatchingById(widget.id);
    if (continueWatchingItem != null) {
      if (continueWatchingItem.episodeId != widget.episodeId) return;
      _currentPosition = continueWatchingItem.timestamp;
    }
  }

  Future<void> _initializeData() async {
    try {
      await Future.wait([
        _fetchEpisodeServers(_selectedEpisodeId),
        _fetchStreamingLinks(_selectedEpisodeId),
      ]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchEpisodeServers(String episodeId) async {
    if (!mounted) return;
    try {
      if (_serversCache.containsKey(episodeId)) {
        _episodeServers = _serversCache[episodeId];
        setState(() {});
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
    final String finalEpisodeId =
        episodeId.isEmpty ? widget.episodeId : episodeId;
    final String cacheKey = '$finalEpisodeId-$_selectedServer-$_selectedDubSub';

    try {
      if (_linksCache.containsKey(cacheKey)) {
        _streamingLinks = _linksCache[cacheKey];
        await _initializePlayer();
        return;
      }

      final links = await _animeService.fetchEpisodeStreamingLinks(
        animeEpisodeId: finalEpisodeId,
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
    if (!mounted) return;
    if (_isPlayerInitializing ||
        _streamingLinks == null ||
        _streamingLinks!.sources.isEmpty) {
      return;
    }
    setState(() => _isPlayerInitializing = true);

    try {
      await _disposeCurrentPlayer();
      await _setupNewPlayer();
    } catch (e) {
      debugPrint("Error initializing player: $e");
    } finally {
      setState(() => _isPlayerInitializing = false);
    }
  }

  Future<void> _disposeCurrentPlayer() async {
    _playerController?.dispose();
    _playerController = null;
  }

  Future<void> _setupNewPlayer() async {
    final sourceUrl = _streamingLinks!.sources[0].url;
    final subtitleSources = _createSubtitleSources();

    _playerController = BetterPlayerController(
      _createPlayerConfiguration(),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        sourceUrl,
        subtitles: subtitleSources,
      ),
    );

    _setupSubtitles(subtitleSources);
    _setupListener();
  }

  List<BetterPlayerSubtitlesSource> _createSubtitleSources() {
    return _streamingLinks?.tracks
            ?.where((track) => track.label != null)
            .map((track) => BetterPlayerSubtitlesSource(
                  type: BetterPlayerSubtitlesSourceType.network,
                  urls: [track.file],
                  name: track.label,
                  selectedByDefault: track.isDefault ?? false,
                ))
            .toList() ??
        [];
  }

  BetterPlayerConfiguration _createPlayerConfiguration() {
    return const BetterPlayerConfiguration(
      autoPlay: true,
      autoDetectFullscreenAspectRatio: true,
      fit: BoxFit.scaleDown,
      deviceOrientationsOnFullScreen: [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight
      ],
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown
      ],
      controlsConfiguration: BetterPlayerControlsConfiguration(
        playIcon: Icons.play_arrow,
        pauseIcon: Icons.pause,
        controlBarColor: Colors.black54,
        enableProgressText: true,
        enableAudioTracks: false,
        enableSubtitles: true,
      ),
    );
  }

  void _setupSubtitles(List<BetterPlayerSubtitlesSource> subtitleSources) {
    if (subtitleSources.isNotEmpty) {
      final defaultSubtitle = subtitleSources.firstWhere(
        (subtitle) => subtitle.selectedByDefault == true,
        orElse: () => subtitleSources.first,
      );
      _playerController?.setupSubtitleSource(defaultSubtitle);
    }
  }

  void _setupListener() {
    _playerController?.addEventsListener(_onPlayerEvent);
  }

  void _onPlayerEvent(BetterPlayerEvent event) async {
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      // Set initial position if exists
      if (_currentPosition != '0:00:00.000000') {
        final parts = _currentPosition.split(':');
        if (parts.length >= 3) {
          final hours = int.parse(parts[0]);
          final minutes = int.parse(parts[1]);
          final seconds = double.parse(parts[2]);
          final duration = Duration(
            hours: hours,
            minutes: minutes,
            seconds: seconds.floor(),
            milliseconds: ((seconds - seconds.floor()) * 1000).round(),
          );
          _playerController?.seekTo(duration);
        }
      }
    }

    if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
      debugPrint("PROGRESS");

      final position = _playerController?.videoPlayerController?.value.position;
      if (position == null || position.inSeconds == 0) return;

      setState(() {
        _currentPosition = position.toString();
      });

      // Update continue watching
      final continueWatchingItem = ContinueWatchingItem(
        title: widget.title,
        id: widget.id,
        name: widget.name,
        poster: widget.poster,
        episode: widget.episode,
        episodeId: widget.episodeId,
        timestamp: _currentPosition,
        duration:
            _playerController!.videoPlayerController!.value.duration.toString(),
        type: widget.type, // Todo: Add appropriate type here
      );
      await _watchlistBox.addToContinueWatching(continueWatchingItem);

      // Add to recently watched after 5% of video progress
      final duration = _playerController?.videoPlayerController?.value.duration;
      if (duration != null && position.inSeconds > duration.inSeconds * 0.05) {
        final recentlyWatchedItem = RecentlyWatchedItem(
          id: widget.id,
          name: widget.name,
          poster: widget.poster,
          type: widget.type, // Add appropriate type here
        );
        await _watchlistBox.addToRecentlyWatched(recentlyWatchedItem);
      }
    }
  }

  @override
  void dispose() {
    _disposeCurrentPlayer();
    _animeService.dispose();
    super.dispose();
  }

  // UI Builders
  Widget _buildShimmerLoading(double height) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      highlightColor: Theme.of(context).colorScheme.secondary,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildPlayerSection() {
    return Container(
      color: Colors.black,
      height: 230,
      width: double.infinity,
      child: _isPlayerInitializing || _playerController == null
          ? Center(child: _buildShimmerLoading(230))
          : BetterPlayer(controller: _playerController!),
    );
  }

  Widget _buildDubSubSection() {
    return Row(
      children: [
        _buildChoiceButton(
          "Sub",
          Theme.of(context).colorScheme.secondary,
          _selectedDubSub == "sub",
          () => _onDubSubChanged("sub"),
        ),
        const SizedBox(width: 15),
        _buildChoiceButton(
          "Dub",
          Theme.of(context).colorScheme.secondary,
          _selectedDubSub == "dub",
          () => _onDubSubChanged("dub"),
        ),
      ],
    );
  }

  Widget _buildServersList() {
    if (_isLoading) {
      return _buildLoadingServersList();
    }

    final servers =
        _selectedDubSub != "sub" ? _episodeServers?.dub : _episodeServers?.sub;
    if (servers == null || servers.isEmpty) {
      return const Center(child: Text('No servers available'));
    }

    return SizedBox(
      height: 50,
      child: ListView.builder(
        itemCount: servers.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final serverLabel = servers[index].serverName;
          return _buildServerCard(
            serverLabel,
            serverLabel == _selectedServer,
            () => _onServerChanged(serverLabel),
          );
        },
      ),
    );
  }

  Widget _buildLoadingServersList() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: _buildShimmerLoading(80),
        ),
      ),
    );
  }

  // Event Handlers
  void _onDubSubChanged(String value) {
    setState(() {
      _selectedDubSub = value;
      _fetchStreamingLinks(_selectedEpisodeId);
    });
  }

  void _onServerChanged(String value) {
    setState(() {
      _selectedServer = value;
      _fetchStreamingLinks(_selectedEpisodeId);
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
            _buildPlayerSection(),
            const SizedBox(height: 20),
            _buildDubSubSection(),
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
            _buildServersList(),
          ],
        ),
      ),
    );
  }

  // Utility Widgets
  Widget _buildChoiceButton(
    String label,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)
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

  Widget _buildServerCard(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)
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
