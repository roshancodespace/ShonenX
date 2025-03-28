import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
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
  late AnimationController _panelController;
  bool _isPanelVisible = false;

  final List<Source> _sources = [];
  final List<EpisodeDataModel> _episodes = [];
  final List<SubtitleTrack> _subtitles = [];
  final List<Map<String, String>> _qualityOptions = [];

  late final ValueNotifier<Source?> _selectedSource;
  late final ValueNotifier<String?> _selectedCategory;
  late final ValueNotifier<String?> _selectedServer;
  late final ValueNotifier<String?> _selectedQuality;

  int _selectedEpIdx = 0;
  int _selectedRangeStart = 1;
  Duration _lastPosition = Duration.zero;

  bool _isGridView = false;
  int _itemsPerPage = 50;
  int _gridColumns = 5;

  StreamSubscription? _playerSubscription;
  StreamSubscription? _positionSubscription;
  Timer? _debounceTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _selectedEpIdx = (widget.episode ?? 1) - 1;
    _lastPosition = widget.startAt;

    // Initialize ValueNotifiers
    _selectedSource = ValueNotifier(null);
    _selectedCategory = ValueNotifier('sub');
    _selectedServer = ValueNotifier(null);
    _selectedQuality = ValueNotifier(null);

    _initializeComponents();
    _togglePanel();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _playerSubscription?.cancel();
    _positionSubscription?.cancel();
    _player.dispose();
    _selectedSource.dispose();
    _selectedCategory.dispose();
    _selectedServer.dispose();
    _selectedQuality.dispose();
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
      _selectedServer.value = _animeProvider.getSupportedServers().firstOrNull;
      setState(() => _isInitialized = true);
      await _fetchEpisodes();
    } catch (e) {
      _handleError('Initialization failed: $e');
    }
  }

  void _initializePlayer() {
    _player = Player(
      configuration: const PlayerConfiguration(bufferSize: 64 * 1024 * 1024),
    );
    _controller =
        VideoController(_player, configuration: VideoControllerConfiguration());
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
            _selectedServer.value,
            _selectedCategory.value!,
          );
          if (sources.sources.isEmpty) {
            throw Exception('No video sources available');
          }
          setState(() {
            _sources.clear();
            _sources.addAll(sources.sources);
            _selectedSource.value = _sources.first;
          });
          _qualityOptions.clear();
          if (_selectedSource.value != null) {
            await _extractQualities(
                _selectedSource.value!.url!, sources.headers);
            _selectedQuality.value = _qualityOptions.first['url'];
          }
          await _configureSubtitles(sources.tracks);
          await _updateVideoSource(_selectedQuality.value!);
        },
        errorMessage: 'Failed to load stream data',
      );

  Future<void> _extractQualities(String m3u8Url, dynamic headers) async {
    try {
      final response = await http.get(Uri.parse(m3u8Url), headers: headers);
      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        final List<Map<String, String>> extractedQualities = [];

        for (int i = 0; i < lines.length; i++) {
          if (lines[i].contains('#EXT-X-STREAM-INF')) {
            final resolution = RegExp(r'RESOLUTION=(\d+x\d+)')
                    .firstMatch(lines[i])
                    ?.group(1) ??
                'Default';
            if (i + 1 < lines.length) {
              extractedQualities.add({
                'quality': resolution,
                'url':
                    Uri.parse(m3u8Url).resolve(lines[i + 1].trim()).toString(),
              });
            }
          }
        }

        if (extractedQualities.isNotEmpty) {
          setState(() {
            _qualityOptions.clear();
            _qualityOptions.addAll(extractedQualities);
            _selectedQuality.value = _qualityOptions.first['url'];
          });
        } else {
          setState(() {
            _qualityOptions.clear();
            _qualityOptions.add({'quality': 'Default', 'url': m3u8Url});
            _selectedQuality.value = m3u8Url;
          });
        }
      }
    } catch (e) {
      log('Failed to extract qualities: $e');
      setState(() {
        _qualityOptions.clear();
        _qualityOptions.add({'quality': 'Default', 'url': m3u8Url});
        _selectedQuality.value = m3u8Url;
      });
    }
  }

  Future<void> _configureSubtitles(List<Subtitle> subtitles) async {
    _subtitles.clear();
    _subtitles.addAll(subtitles.map(
      (s) => SubtitleTrack.uri(
        s.url!,
        language: s.lang ?? 'Unknown',
        title: s.lang ?? 'Unknown',
      ),
    ));

    SubtitleTrack initialTrack = _subtitles.firstWhere(
      (s) => s.language!.toLowerCase().contains('english'),
      orElse: () =>
          _subtitles.isNotEmpty ? _subtitles.first : SubtitleTrack.no(),
    );
    await _player.setSubtitleTrack(initialTrack);
  }

  Future<void> _updateVideoSource(String url,
      {bool fromQualityChange = false}) async {
    _togglePanel(value: false);
    await _player.open(Media(url)).then((_) => _player.play()).then(
        (_) => _player.seek(fromQualityChange ? _lastPosition : Duration.zero));
  }

  void _playEpisode(int index) => setState(() {
        _selectedEpIdx = index.clamp(0, _episodes.length - 1);
        _lastPosition = Duration.zero;
        _debounceFetchStreamData();
      });

  void _changeSource(Source source) {
    _selectedSource.value = source;
    _updateVideoSource(source.url!);
  }

  void _changeQuality(String url) {
    _updateVideoSource(url, fromQualityChange: true).then((_) {
      _player.seek(_lastPosition);
      _selectedQuality.value = url;
    });
  }

  void _changeServer(String server) {
    _player.pause();
    _selectedServer.value = server;
    _debounceFetchStreamData();
  }

  void _changeCategory(String category) {
    _player.pause();
    _selectedCategory.value = category;
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

  Future<void> _handleAsyncOperation({
    required Future<void> Function() operation,
    required String errorMessage,
  }) async {
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

  void _togglePanel({bool? value}) {
    setState(() {
      if (value != null) {
        _isPanelVisible = value;
      } else {
        _isPanelVisible = !_isPanelVisible;
      }
      _isPanelVisible ? _panelController.forward() : _panelController.reverse();
    });
  }

  void _hidePanel() {
    if (_isPanelVisible) {
      setState(() {
        _isPanelVisible = false;
        _panelController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_isInitialized ||
            _controller == null ||
            _animeWatchProgressBox == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final isWideScreen = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _hidePanel,
                  child: Column(
                    children: [
                      _buildControlBar(context, isWideScreen),
                      _buildVideoSection(flex: 1),
                      if (!isWideScreen) _buildEpisodesPanel(flex: 2),
                    ],
                  ),
                ),
                if (isWideScreen) _buildSlidingPanel(constraints),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlBar(BuildContext context, bool isWideScreen) {
    final theme = Theme.of(context);
    final episode = _episodes.isNotEmpty && _selectedEpIdx < _episodes.length
        ? _episodes[_selectedEpIdx]
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceContainer,
            theme.colorScheme.surfaceContainer.withValues(alpha: 0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Iconsax.arrow_left_2, size: 24),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.animeName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (episode != null)
                  Text(
                    'Ep ${episode.number}${episode.title != null ? ': ${episode.title}' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (isWideScreen)
            IconButton(
              icon: Icon(
                _isPanelVisible ? Iconsax.arrow_right_3 : Iconsax.element_plus,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: _togglePanel,
              tooltip: _isPanelVisible ? 'Hide Episodes' : 'Show Episodes',
            ),
        ],
      ),
    );
  }

  Widget _buildSlidingPanel(BoxConstraints constraints) {
    final panelWidth = constraints.maxWidth * 0.3;
    return AnimatedBuilder(
      animation: _panelController,
      builder: (context, child) {
        return Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Transform.translate(
            offset: Offset((1 - _panelController.value) * panelWidth, 0),
            child: SizedBox(
              width: panelWidth,
              child: _buildEpisodesPanel(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoSection({int flex = 1}) => Expanded(
        flex: flex,
        child: IntrinsicHeight(
          child: VideoPlayerSection(
            animeName: widget.animeName,
            episodes: _episodes,
            selectedEpisodeIndex: _selectedEpIdx,
            controller: _controller!,
            subtitles: _subtitles,
            animeMedia: widget.animeMedia,
            sources: _sources,
            selectedSource: _selectedSource,
            servers: _animeProvider.getSupportedServers(),
            selectedServer: _selectedServer,
            supportsDubSub: _animeProvider.getDubSubParamSupport(),
            selectedCategory: _selectedCategory,
            qualityOptions: _qualityOptions,
            selectedQuality: _selectedQuality,
            onSourceChange: _changeSource,
            onServerChange: _changeServer,
            onCategoryChange: _changeCategory,
            onQualityChange: _changeQuality,
          ),
        ),
      );

  Widget _buildEpisodesPanel({int flex = 1}) => Expanded(
        flex: flex,
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
          onToggleLayout: _toggleLayout,
          onRangeChange: _changeRange,
          onItemsPerPageChange: _updateItemsPerPage,
          onGridColumnsChange: _updateGridColumns,
          onEpisodeTap: _playEpisode,
        ),
      );
}

extension ListExtension<T> on List<T> {
  T? get firstOrNull => isNotEmpty ? first : null;
}
