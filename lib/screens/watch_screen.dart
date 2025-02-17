import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anilist_media;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/api/models/anime/server_model.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:shonenx/helpers/provider.dart';
import 'package:shonenx/widgets/player/controls.dart';

class WatchScreen extends ConsumerStatefulWidget {
  final String animeId;
  final anilist_media.Media animeMedia;
  final String animeName;
  final int? episode;

  const WatchScreen({
    super.key,
    required this.animeId,
    required this.animeMedia,
    required this.animeName,
    this.episode = 1,
  });

  @override
  ConsumerState<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends ConsumerState<WatchScreen>
    with SingleTickerProviderStateMixin {
  late final Player _player;
  late final VideoController _controller;
  late final AnimeProvider _animeProvider;
  StreamSubscription? _playerSubscription;

  List<EpisodeDataModel> _episodes = [];
  BaseServerModel _servers = BaseServerModel();
  String? _selectedCategory = 'sub';
  int _selectedEpIdx = 0;
  int _selectedRangeStart = 1;
  bool _isPlayerInitialized = false;
  String? _errorMessage;
  List<Map<String, String>> _qualityOptions = [];
  String? _selectedQuality;

  @override
  void initState() {
    super.initState();
    _setupSystemUI();
    _initializeProviders();
    _initializePlayer();
    _selectedEpIdx = widget.episode! - 1;
    _fetchEpisodes();
  }

  void _setupSystemUI() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  void _initializeProviders() => _animeProvider = getAnimeProvider(ref)!;

  Future<void> _initializePlayer() async {
    _player = Player();
    _controller = VideoController(_player);
    _playerSubscription = _player.stream.error
        .listen((error) => _handleError('Player error: ${error.toString()}'));
    setState(() => _isPlayerInitialized = true);
  }

  Future<void> _fetchEpisodes() async {
    if (!mounted) return;
    setState(() => _isPlayerInitialized = true);
    try {
      final baseEpisodeModel = await _animeProvider.getEpisodes(widget.animeId);
      setState(() {
        _episodes = baseEpisodeModel.episodes ?? [];
      });
      if (_episodes.isEmpty) throw Exception('No episodes found');
      await _fetchStreamData();
    } catch (e) {
      _handleError('Episode load failed: ${e.toString()}');
    }
  }

  Future<void> _fetchStreamData() async {
    if (_selectedEpIdx >= _episodes.length) {
      _handleError('No episodes available to fetch stream data.');
      return;
    }
    try {
      final episodeId = _episodes[_selectedEpIdx].id;
      _servers = await _animeProvider.getServers(episodeId!);
      final serverName = _selectedCategory == 'sub'
          ? _servers.sub.first.name
          : _servers.dub.first.name;
      final sources = await _animeProvider.getSources(
          widget.animeId, episodeId, serverName!, _selectedCategory!);
      if (sources.sources.isEmpty) throw Exception('No sources available');
      await _extractQualities(sources.sources.first.url!);
    } catch (e) {
      _handleError('Stream load failed: ${e.toString()}');
    }
  }

  Future<void> _extractQualities(String m3u8Url) async {
    try {
      debugPrint('M3U8 URL: $m3u8Url');
      final response = await http.get(Uri.parse(m3u8Url));
      if (response.statusCode != 200) throw Exception('Failed to load M3U8');

      final lines = response.body.split('\n');
      final qualities = <Map<String, String>>[];

      for (int i = 0; i < lines.length - 1; i++) {
        if (lines[i].contains('#EXT-X-STREAM-INF')) {
          final resolutionMatch =
              RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(lines[i]);
          final resolution =
              resolutionMatch != null ? resolutionMatch.group(1) : 'Unknown';
          qualities.add({
            'quality': resolution!,
            'url': m3u8Url.replaceAll('master.m3u8', lines[i + 1])
          });
        }
      }

      setState(() {
        _qualityOptions = qualities;
        _selectedQuality =
            _qualityOptions.isNotEmpty ? _qualityOptions.first['url'] : null;
      });
      debugPrint('Qualities extracted: $_qualityOptions');

      if (_selectedQuality != null) {
        await _updateVideoSource(_selectedQuality!);
      }
    } catch (e) {
      _handleError('Quality extraction failed: ${e.toString()}');
    }
  }

  void _changeQuality(String url) {
    setState(() => _selectedQuality = url);
    _updateVideoSource(url);
  }

  Future<void> _updateVideoSource(String url) async {
    debugPrint('Updating video source to: $url');
    if (!_isPlayerInitialized) return;
    try {
      await _player.open(Media(url));
      _player.play();
    } catch (e) {
      _handleError('Source update failed: ${e.toString()}');
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _playEpisode(int index) {
    if (index < 0 || index >= _episodes.length) return;
    setState(() {
      _selectedEpIdx = index;
    });
    _fetchStreamData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: MediaQuery.sizeOf(context).width > 600
            ? Row(
                children: [
                  Flexible(flex: 2, child: _buildVideoPlayer()),
                  Expanded(flex: 1, child: _buildEpisodesPanel(theme)),
                ],
              )
            : Column(
                children: [
                  _buildVideoPlayer(),
                  Expanded(child: _buildEpisodesPanel(theme)),
                ],
              ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                    onPressed: () =>
                        context.pop(), // Directly pop without confirmation
                    icon: const Icon(Iconsax.arrow_left_1, size: 35)),
                if (_episodes.isNotEmpty)
                  Flexible(
                    child: Text(
                      _episodes[_selectedEpIdx].title ?? 'Untitled',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                children: [
                  Video(
                    controller: _controller,
                    controls: (state) => CustomControls(
                      animeMedia: widget.animeMedia,
                      state: state,
                      qualityOptions: _qualityOptions,
                      changeQuality: _changeQuality,
                      episodes: _episodes,
                      currentEpisodeIndex: _selectedEpIdx,
                    ),
                    subtitleViewConfiguration: SubtitleViewConfiguration(
                      style: TextStyle(
                          backgroundColor: Colors.black.withValues(alpha: 0.2)),
                      textScaleFactor:
                          MediaQuery.sizeOf(context).width > 400 ? 1.5 : 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodesPanel(ThemeData theme) {
    return Material(
      color: theme.colorScheme.surface,
      elevation: 4,
      child: Column(
        children: [
          _buildInfoHeader(theme),
          _buildEpisodesTabs(theme),
          Expanded(child: _buildEpisodesGrid(theme)),
        ],
      ),
    );
  }

  Widget _buildInfoHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.animeName,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (_episodes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Episode ${_episodes[_selectedEpIdx].number}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ],
                ),
              ),
              _buildCategorySelector(theme),
            ],
          ),
          if (_episodes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_episodes[_selectedEpIdx].title ?? 'Untitled',
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    return PopupMenuButton<String>(
      child: Chip(
        avatar: Icon(Iconsax.language_circle, color: theme.colorScheme.primary),
        label: Text(_selectedCategory!.toUpperCase(),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.primary)),
        backgroundColor: theme.colorScheme.surface,
      ),
      itemBuilder: (context) => [
        if (_servers.sub.isNotEmpty)
          PopupMenuItem(value: 'sub', child: Text('SUB')),
        if (_servers.dub.isNotEmpty)
          PopupMenuItem(value: 'dub', child: Text('DUB')),
        if (_servers.raw.isNotEmpty)
          PopupMenuItem(value: 'raw', child: Text('RAW')),
      ],
      onSelected: (quality) {
        _player.pause();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: "Message",
            message:
                "Changed category to ${quality.toUpperCase()}, please wait for the server to respond.",
            contentType: ContentType.success,
          ),
        ));
        setState(() {
          _selectedCategory = quality;
        });
        _fetchStreamData();
      },
    );
  }

  Widget _buildEpisodesTabs(ThemeData theme) {
    final totalEpisodes = _episodes.length;
    final segments = (totalEpisodes / 50).ceil();

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: segments,
        itemBuilder: (context, index) {
          final start = index * 50 + 1;
          final end = (start + 49) > totalEpisodes ? totalEpisodes : start + 49;
          final isSelected = _selectedRangeStart == start;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text('$start-$end'),
              onSelected: (_) {
                setState(() {
                  _selectedRangeStart = start;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEpisodesGrid(ThemeData theme) {
    final visibleEpisodes = _episodes
        .where((e) =>
            e.number! >= _selectedRangeStart &&
            e.number! < _selectedRangeStart + 50)
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            _calculateCrossAxisCount(MediaQuery.of(context).size.width),
        childAspectRatio: 1.3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: visibleEpisodes.length,
      itemBuilder: (context, index) {
        final episode = visibleEpisodes[index];
        final isSelected = episode.number == _episodes[_selectedEpIdx].number;

        return Material(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                _playEpisode(_episodes.indexWhere((e) => e.id == episode.id)),
            child: Tooltip(
              message: "${episode.title}",
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${episode.number}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width > 1400) return 7;
    if (width > 1200) return 6;
    if (width > 800) return 4;
    if (width > 600) return 4;
    if (width > 300) return 5;
    return 4;
  }
}
