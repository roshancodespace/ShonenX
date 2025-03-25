import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anilist_media;
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/api/models/anime/source_model.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/helpers/provider.dart';
import 'package:shonenx/screens/watch_screen/episodes_panel.dart';
import 'package:shonenx/screens/watch_screen/video_player_section.dart';

class WatchScreen extends ConsumerStatefulWidget {
  final String animeId;
  final anilist_media.Media animeMedia;
  final String animeName;
  final int? episode;
  final Duration startAt;

  const WatchScreen({
    super.key,
    required this.animeId,
    required this.animeMedia,
    required this.animeName,
    this.startAt = Duration.zero,
    this.episode = 1,
  });

  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen>
    with SingleTickerProviderStateMixin {
  late final Player _player;
  late final VideoController? _controller;
  late final AnimeProvider _animeProvider;
  late final AnimeWatchProgressBox? _animeWatchProgressBox;

  final List<EpisodeDataModel> _episodes = [];
  final List<SubtitleTrack> _subtitles = [];
  final List<Map<String, String>> _qualityOptions = [];

  String? _selectedCategory = 'sub';
  String? _selectedServer;
  String? _selectedQuality;

  int _selectedEpIdx = 0;
  int _selectedRangeStart = 1;
  Duration _lastPosition = Duration.zero;

  bool _isGridView = false;
  int _itemsPerPage = 100;
  int _gridColumns = 4;

  StreamSubscription? _playerSubscription;
  StreamSubscription? _positionSubscription;
  Timer? _debounceTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedEpIdx = (widget.episode ?? 1) - 1;
    _lastPosition = widget.startAt;
    _initializeComponents();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _playerSubscription?.cancel();
    _positionSubscription?.cancel();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializeComponents() async {
    try {
      _animeProvider =
          getAnimeProvider(ref) ?? (throw Exception('AnimeProvider not found'));
      _animeWatchProgressBox = AnimeWatchProgressBox();
      await _animeWatchProgressBox?.init();
      _initializePlayer();
      _selectedServer = _animeProvider.getSupportedServers().firstOrNull;
      setState(() => _isInitialized = true);
      await _fetchEpisodes();
    } catch (e) {
      _handleError('Initialization failed: $e');
    }
  }

  void _initializePlayer() {
    _player = Player(
        configuration: const PlayerConfiguration(bufferSize: 64 * 1024 * 1024));
    _controller = VideoController(_player);
    _playerSubscription = _player.stream.error.listen(_handlePlayerError);
    _positionSubscription =
        _player.stream.position.listen((position) => _lastPosition = position);
  }

  Future<void> _fetchEpisodes() async => await _handleAsyncOperation(
        operation: () async {
          final episodes =
              (await _animeProvider.getEpisodes(widget.animeId)).episodes;
          if (episodes?.isEmpty ?? true) throw Exception('No episodes found');
          setState(() {
            _episodes.clear();
            _episodes.addAll(episodes!);
          });
          _debounceFetchStreamData();
        },
        errorMessage: 'Failed to load episodes',
      );

  Future<void> _fetchStreamData() async => await _handleAsyncOperation(
        operation: () async {
          if (_selectedEpIdx >= _episodes.length) return;
          final sources = await _animeProvider.getSources(
            widget.animeId,
            _episodes[_selectedEpIdx].id!,
            _selectedServer,
            _selectedCategory!,
          );
          if (sources.sources.isEmpty)
            throw Exception('No video sources available');
          _qualityOptions.clear();
          if (sources.sources.first.url != null) {
            await _extractQualities(
                sources.sources.first.url!, sources.headers);
            _selectedQuality = _qualityOptions.first['url'];
          }
          await _configureSubtitles(sources.tracks);
          await _updateVideoSource(_selectedQuality!);
        },
        errorMessage: 'Failed to load stream data',
      );

  Future<void> _extractQualities(String m3u8Url, dynamic headers) async {
    try {
      final response = await http.get(Uri.parse(m3u8Url), headers: headers);
      if (response.statusCode == 200) {
        _qualityOptions.addAll(response.body
            .split('\n')
            .asMap()
            .entries
            .where((entry) => entry.value.contains('#EXT-X-STREAM-INF'))
            .map((entry) {
          final resolution = RegExp(r'RESOLUTION=(\d+x\d+)')
                  .firstMatch(entry.value)
                  ?.group(1) ??
              'Default';
          return {
            'quality': resolution,
            'url': Uri.parse(m3u8Url)
                .resolve(response.body.split('\n')[entry.key + 1].trim())
                .toString(),
            'isDub': 'false',
          };
        }));
        _selectedQuality = _qualityOptions.first['url'];
      }
    } catch (e) {
      log('Failed to extract qualities: $e');
    }
  }

  Future<void> _configureSubtitles(List<Subtitle> subtitles) async {
    _subtitles.clear();
    _subtitles.addAll(subtitles.map(
        (s) => SubtitleTrack.uri(s.url!, language: s.lang, title: s.lang)));
    await _player.setSubtitleTrack(_subtitles.firstWhere(
      (s) => s.language!.toLowerCase().contains('english'),
      orElse: () =>
          _subtitles.isNotEmpty ? _subtitles.first : SubtitleTrack.no(),
    ));
  }

  Future<void> _updateVideoSource(String url,
          {bool fromQualityChange = false}) async =>
      await _player.open(Media(url)).then((_) => _player.play()).then((_) =>
          _player.seek(fromQualityChange ? _lastPosition : Duration.zero));

  void _playEpisode(int index) => setState(() {
        _selectedEpIdx = index.clamp(0, _episodes.length - 1);
        _lastPosition = Duration.zero;
        _debounceFetchStreamData();
      });

  void _changeQuality(String url) =>
      _updateVideoSource(url, fromQualityChange: true)
          .then((_) => _player.seek(_lastPosition));

  void _changeServer(String server) {
    _player.pause();
    setState(() => _selectedServer = server);
    _debounceFetchStreamData();
  }

  void _changeCategory(String category) {
    _player.pause();
    setState(() => _selectedCategory = category);
    _debounceFetchStreamData();
  }

  void _toggleLayout() => setState(() => _isGridView = !_isGridView);

  void _updateItemsPerPage(int value) => setState(() => _itemsPerPage = value);

  void _updateGridColumns(int value) => setState(() => _gridColumns = value);

  void _changeRange(int start) => setState(() => _selectedRangeStart = start);

  void _debounceFetchStreamData() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _fetchStreamData);
  }

  void _handlePlayerError(String error) {
    log('Player error: $error');
    if (error.contains('Failed to open')) _initializePlayer();
  }

  Future<void> _handleAsyncOperation(
      {required Future<void> Function() operation,
      required String errorMessage}) async {
    try {
      await operation();
    } catch (e) {
      _handleError('$errorMessage: $e');
    } finally {
      if (mounted) setState(() {});
    }
  }

  void _handleError(String message) {
    log(message);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) => _isInitialized &&
          _controller != null &&
          _animeWatchProgressBox != null
      ? Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: MediaQuery.of(context).size.width > 600
                ? Row(children: [_buildVideoSection(), _buildEpisodesPanel()])
                : Column(
                    children: [_buildVideoSection(), _buildEpisodesPanel()]),
          ),
        )
      : const Scaffold(body: Center(child: CircularProgressIndicator()));

  Widget _buildVideoSection() => Expanded(
        flex: 3,
        child: VideoPlayerSection(
          animeName: widget.animeName,
          episodes: _episodes,
          selectedEpisodeIndex: _selectedEpIdx,
          controller: _controller!,
          subtitles: _subtitles,
          animeMedia: widget.animeMedia,
        ),
      );

  Widget _buildEpisodesPanel() => Expanded(
        flex: 2,
        child: EpisodesPanel(
          episodes: _episodes,
          selectedEpisodeIndex: _selectedEpIdx,
          totalEpisodes: _episodes.length,
          rangeStart: _selectedRangeStart,
          itemsPerPage: _itemsPerPage,
          gridColumns: _gridColumns,
          isGridView: _isGridView,
          animeWatchProgressBox: _animeWatchProgressBox!,
          animeMedia: widget.animeMedia,
          servers: _animeProvider.getSupportedServers(),
          selectedServer: _selectedServer,
          supportsDubSub: _animeProvider.getDubSubParamSupport(),
          selectedCategory: _selectedCategory,
          qualityOptions: _qualityOptions,
          selectedQuality: _selectedQuality,
          onEpisodeTap: _playEpisode,
          onServerChange: _changeServer,
          onCategoryChange: _changeCategory,
          onQualityChange: _changeQuality,
          onToggleLayout: _toggleLayout,
          onRangeChange: _changeRange,
          onItemsPerPageChange: _updateItemsPerPage,
          onGridColumnsChange: _updateGridColumns,
        ),
      );
}

extension ListExtension<T> on List<T> {
  T? get firstOrNull => isNotEmpty ? first : null;
}
