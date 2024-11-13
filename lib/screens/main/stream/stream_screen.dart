import 'package:flutter/material.dart';
import 'package:nekoflow/data/models/episodes_model.dart';
import 'package:nekoflow/data/models/stream_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:better_player/better_player.dart';
import 'package:shimmer/shimmer.dart';

class StreamScreen extends StatefulWidget {
  final String title;
  final String id;
  final List<Episode> episodes;

  const StreamScreen({
    super.key,
    required this.title,
    required this.id,
    required this.episodes,
  });

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  late final AnimeService _animeService;
  BetterPlayerController? _playerController;

  // State management
  String _selectedServer = "hd-1";
  String _selectedDubSub = "sub";
  String _selectedEpisodeId = "";
  bool _isLoading = true;
  bool _isPlayerInitializing = false; // Initialize to false

  // Cache management
  EpisodeServersModel? _episodeServers;
  EpisodeStreamingLinksModel? _streamingLinks;
  final Map<String, EpisodeServersModel> _serversCache = {};
  final Map<String, EpisodeStreamingLinksModel> _linksCache = {};

  @override
  void initState() {
    super.initState();
    _animeService = AnimeService();
    _selectedEpisodeId = widget.id;
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _fetchEpisodeServers(_selectedEpisodeId);
      await _fetchStreamingLinks(_selectedEpisodeId);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchEpisodeServers(String episodeId) async {
    try {
      if (_serversCache.containsKey(episodeId)) {
        _episodeServers = _serversCache[episodeId];
        setState(() {});
        return;
      }

      _episodeServers = await _animeService.fetchEpisodeServers(
        animeEpisodeId: episodeId,
      );
      _serversCache[episodeId] = _episodeServers!;
      setState(() {});
    } catch (e) {
      debugPrint("Error fetching episode servers: $e");
    }
  }

  Future<void> _fetchStreamingLinks(String episodeId) async {
    if (episodeId.isEmpty) episodeId = widget.id;

    final cacheKey = '$episodeId-$_selectedServer-$_selectedDubSub';
    try {
      if (_linksCache.containsKey(cacheKey)) {
        _streamingLinks = _linksCache[cacheKey];
        await initializePlayer();
        return;
      }

      _streamingLinks = await _animeService.fetchEpisodeStreamingLinks(
        animeEpisodeId: episodeId,
        server: _selectedServer,
        category: _selectedDubSub,
      );
      _linksCache[cacheKey] = _streamingLinks!;
      await initializePlayer();
    } catch (e) {
      debugPrint("Error fetching streaming links: $e");
    }
  }

  Future<void> initializePlayer() async {
    if (_isPlayerInitializing || _streamingLinks == null || _streamingLinks!.sources.isEmpty) {
      // Avoid re-initializing if already in progress or if no streaming links
      return;
    }

    setState(() => _isPlayerInitializing = true);

    try {
      // Dispose of existing controller if it exists
      _playerController?.dispose();

      final sourceUrl = _streamingLinks!.sources[0].url;
      final subtitleSources = _streamingLinks?.tracks
              ?.where((track) => track.label != null)
              .map(
                (track) => BetterPlayerSubtitlesSource(
                  type: BetterPlayerSubtitlesSourceType.network,
                  urls: [track.file],
                  name: track.label,
                  selectedByDefault: track.isDefault ?? false
                ),
              )
              .toList() ??
          [];

      // Initialize new controller with updated configuration
      _playerController = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          autoDetectFullscreenAspectRatio: true,
          fit: BoxFit.contain,
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            playIcon: Icons.play_arrow,
            pauseIcon: Icons.pause,
            controlBarColor: Colors.black54,
            enableProgressText: true,
            enableAudioTracks: false,
            enableSubtitles: true,
          ),
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          sourceUrl,
          subtitles: subtitleSources,
        ),
      );

      // Set the first subtitle as the default if available
      if (subtitleSources.isNotEmpty) {
        _playerController?.setupSubtitleSource(subtitleSources.firstWhere((subtitle) => subtitle.selectedByDefault == true));
      }

    } catch (e) {
      debugPrint("Error initializing player: $e");
    } finally {
      if (mounted) {
        setState(() => _isPlayerInitializing = false);
      }
    }
  }

  @override
  void dispose() {
    _playerController?.dispose();
    _animeService.dispose();
    super.dispose();
  }

  Widget _buildShimmerLoading(double height) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
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
          ? Center(
              child: _buildShimmerLoading(230),
            )
          : BetterPlayer(controller: _playerController!),
    );
  }

  Widget _buildDubSubSection() {
    return Row(
      children: [
        _buildChoiceButton("Sub", Colors.grey[700]!, _selectedDubSub == "sub",
            () => _onDubSubChanged("sub")),
        const SizedBox(width: 15),
        _buildChoiceButton("Dub", Colors.grey[700]!, _selectedDubSub == "dub",
            () => _onDubSubChanged("dub")),
      ],
    );
  }

  Widget _buildServersList() {
    if (_isLoading) {
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

    final servers = _selectedDubSub != "sub"
        ? _episodeServers?.dub ?? []
        : _episodeServers?.sub ?? [];

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

  Widget _buildEpisodesList() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildShimmerLoading(60),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.episodes.length,
      itemBuilder: (context, index) {
        final episode = widget.episodes[index];
        return _buildEpisodeCard(
          episode.title,
          episode.number,
          widget.id,
        );
      },
    );
  }

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

  void _onEpisodeSelected(String episodeId) {
    setState(() {
      _selectedEpisodeId = episodeId;
      _fetchEpisodeServers(episodeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.grey[900],
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
            // const SizedBox(height: 20),
            // Expanded(child: _buildEpisodesList()),
          ],
        ),
      ),
    );
  }

  // Helper widgets remain the same as in your original code
  Widget _buildChoiceButton(
      String label, Color color, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).secondaryHeaderColor
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
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).secondaryHeaderColor
            : Colors.grey[600],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
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

  Widget _buildEpisodeCard(
      String episodeTitle, int episodeNumber, String episodeId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
        onTap: () => _onEpisodeSelected(episodeId),
        child: Row(
          children: [
            const Icon(Icons.play_arrow, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                episodeTitle,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              "#$episodeNumber",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}