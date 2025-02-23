import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart' as anilist_media;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/api/models/anime/server_model.dart';
import 'package:shonenx/api/models/anime/source_model.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:shonenx/api/sources/anime/aniwatch/kaido.dart';
import 'package:shonenx/helpers/provider.dart';
import 'package:shonenx/widgets/player/controls.dart';

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

class _WatchScreenState extends ConsumerState<WatchScreen> with SingleTickerProviderStateMixin {
  late final Player _player;
  late final VideoController _controller;
  late final AnimeProvider _animeProvider;
  StreamSubscription? _playerSubscription;

  List<EpisodeDataModel> _episodes = [];
  BaseServerModel _servers = BaseServerModel();
  List<SubtitleTrack> _subtitles = [];
  String? _selectedCategory = 'sub';
  int _selectedEpIdx = 0;
  int _selectedRangeStart = 1;
  String? _errorMessage;
  List<Map<String, String>> _qualityOptions = [];
  String? _selectedQuality;

  @override
  void initState() {
    super.initState();
    _selectedEpIdx = (widget.episode ?? 1) - 1;
    _initializeProviders();
    _initializePlayer().then((_) => _fetchEpisodes());
  }

  void _initializeProviders() => _animeProvider = getAnimeProvider(ref)!;

  Future<void> _initializePlayer() async {
    _player = Player(configuration: const PlayerConfiguration(bufferSize: 64 * 1024 * 1024));
    _controller = VideoController(_player);
    _playerSubscription = _player.stream.error.listen((error) => _handleError('Player error: $error'));
  }

  Future<void> _fetchEpisodes() async {
    if (!mounted) return;
    try {
      final baseEpisodeModel = await _animeProvider.getEpisodes(widget.animeId);
      if ((baseEpisodeModel.episodes ?? []).isEmpty) throw Exception('No episodes found');
      setState(() {
        _episodes = baseEpisodeModel.episodes!;
      });
      await _fetchStreamData();
    } catch (e) {
      _handleError('Episode load failed: $e');
    }
  }

  Future<void> _fetchStreamData() async {
    if (!mounted || _selectedEpIdx >= _episodes.length) {
      _handleError('No episodes available.');
      return;
    }
    try {
      final episodeId = _episodes[_selectedEpIdx].id!;
      _servers = await _animeProvider.getServers(episodeId);
      final serverName = _selectedCategory == 'sub' ? _servers.sub.first.name : _servers.dub.first.name;
      final sources = await _animeProvider.getSources(widget.animeId, episodeId, serverName!, _selectedCategory!);
      if (sources.sources.isEmpty) throw Exception('No sources available');
      await _extractQualities(sources.sources.first.url!);
      await _configureSubtitles(sources.tracks);
    } catch (e) {
      _handleError('Stream load failed: $e');
    }
  }

  Future<void> _configureSubtitles(List<Subtitle> subtitles) async {
    _subtitles = subtitles.map((s) => SubtitleTrack.uri(s.url!, language: s.lang, title: s.lang)).toList();
    final englishSub = subtitles.firstWhere((s) => s.lang!.toLowerCase().contains('english'));
    log('English subtitle: ${englishSub.url}', name: 'English Subtitle');
    await _player.setSubtitleTrack(SubtitleTrack.uri(englishSub.url!, language: englishSub.lang, title: englishSub.lang));
  }

  Future<void> _extractQualities(String m3u8Url) async {
    try {
      final response = await http.get(Uri.parse(m3u8Url));
      if (response.statusCode != 200) throw Exception('Failed to load M3U8');
      final lines = response.body.split('\n');
      final qualities = <Map<String, String>>[];
      for (var i = 0; i < lines.length - 1; i++) {
        if (lines[i].contains('#EXT-X-STREAM-INF')) {
          final resolution = RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(lines[i])?.group(1) ?? 'Unknown';
          qualities.add({'quality': resolution, 'url': m3u8Url.replaceAll('master.m3u8', lines[i + 1])});
        }
      }
      setState(() {
        _qualityOptions = qualities;
        _selectedQuality = qualities.isNotEmpty ? qualities.first['url'] : null;
      });
      if (_selectedQuality != null) await _updateVideoSource(_selectedQuality!);
    } catch (e) {
      _handleError('Quality extraction failed: $e');
    }
  }

  Future<void> _updateVideoSource(String url) async {
    try {
      await _player.open(Media(url));
      await _player.play();
      await _player.seek(widget.startAt);
    } catch (e) {
      _handleError('Source update failed: $e');
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    log(message, level: 1000); // Error level logging
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
    setState(() => _selectedEpIdx = index);
    _fetchStreamData();
  }

  void _changeQuality(String url) {
    setState(() => _selectedQuality = url);
    _updateVideoSource(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWideScreen = MediaQuery.sizeOf(context).width > 600;
    return Scaffold(
      body: SafeArea(
        child: isWideScreen
            ? Row(
                children: [
                  Flexible(flex: 2, child: _VideoPlayerSection(this)),
                  Expanded(flex: 1, child: _EpisodesPanel(this, theme)),
                ],
              )
            : Column(
                children: [
                  _VideoPlayerSection(this),
                  Expanded(child: _EpisodesPanel(this, theme)),
                ],
              ),
      ),
    );
  }
}

// Video Player Section
class _VideoPlayerSection extends StatelessWidget {
  final _WatchScreenState state;

  const _VideoPlayerSection(this.state);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Video(
                controller: state._controller,
                controls: (videoState) => CustomControls(
                  animeMedia: state.widget.animeMedia,
                  state: videoState,
                  subtitles: state._subtitles,
                  qualityOptions: state._qualityOptions,
                  changeQuality: state._changeQuality,
                  episodes: state._episodes,
                  currentEpisodeIndex: state._selectedEpIdx,
                ),
                subtitleViewConfiguration: SubtitleViewConfiguration(
                  style: TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black.withValues(alpha: 0.2),
                  ),
                  textScaleFactor: MediaQuery.sizeOf(context).width > 400 ? 1.5 : 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Episodes Panel
class _EpisodesPanel extends StatelessWidget {
  final _WatchScreenState state;
  final ThemeData theme;

  const _EpisodesPanel(this.state, this.theme);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surface,
      elevation: 4,
      child: Column(
        children: [
          _InfoHeader(state, theme),
          _EpisodesTabs(state, theme),
          Expanded(child: _EpisodesGrid(state, theme)),
        ],
      ),
    );
  }
}

// Info Header
class _InfoHeader extends StatelessWidget {
  final _WatchScreenState state;
  final ThemeData theme;

  const _InfoHeader(this.state, this.theme);

  @override
  Widget build(BuildContext context) {
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
                    Text(state.widget.animeName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    if (state._episodes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Episode ${state._episodes[state._selectedEpIdx].number}',
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ],
                ),
              ),
              _CategorySelector(state, theme),
            ],
          ),
          if (state._episodes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(state._episodes[state._selectedEpIdx].title ?? 'Untitled',
                style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

// Category Selector
class _CategorySelector extends StatelessWidget {
  final _WatchScreenState state;
  final ThemeData theme;

  const _CategorySelector(this.state, this.theme);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: "Select Category",
      child: Chip(
        avatar: Icon(Iconsax.language_circle, color: theme.colorScheme.primary),
        label: Text(state._selectedCategory!.toUpperCase(), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
        backgroundColor: theme.colorScheme.surface,
      ),
      itemBuilder: (context) => [
        if (state._servers.sub.isNotEmpty) PopupMenuItem(value: 'sub', child: Text('SUB')),
        if (state._servers.dub.isNotEmpty) PopupMenuItem(value: 'dub', child: Text('DUB')),
        if (state._servers.raw.isNotEmpty) PopupMenuItem(value: 'raw', child: Text('RAW')),
      ],
      onSelected: (category) {
        state._player.pause();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: "Message",
              message: "Changed category to ${category.toUpperCase()}, please wait for the server to respond.",
              contentType: ContentType.success,
            ),
          ),
        );
        state.setState(() => state._selectedCategory = category);
        state._fetchStreamData();
      },
    );
  }
}

// Episodes Tabs
class _EpisodesTabs extends StatelessWidget {
  final _WatchScreenState state;
  final ThemeData theme;

  const _EpisodesTabs(this.state, this.theme);

  @override
  Widget build(BuildContext context) {
    final totalEpisodes = state._episodes.length;
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
          final isSelected = state._selectedRangeStart == start;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text('$start-$end'),
              onSelected: (_) => state.setState(() => state._selectedRangeStart = start),
            ),
          );
        },
      ),
    );
  }
}

// Episodes Grid
class _EpisodesGrid extends StatelessWidget {
  final _WatchScreenState state;
  final ThemeData theme;

  const _EpisodesGrid(this.state, this.theme);

  @override
  Widget build(BuildContext context) {
    final visibleEpisodes = state._episodes
        .where((e) => e.number! >= state._selectedRangeStart && e.number! < state._selectedRangeStart + 50)
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _calculateCrossAxisCount(MediaQuery.of(context).size.width),
        childAspectRatio: 1.3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: visibleEpisodes.length,
      itemBuilder: (context, index) {
        final episode = visibleEpisodes[index];
        final isSelected = episode.number == state._episodes[state._selectedEpIdx].number;

        return Material(
          color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => state._playEpisode(state._episodes.indexWhere((e) => e.id == episode.id)),
            child: Tooltip(
              message: episode.title ?? '',
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    '${episode.number}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
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