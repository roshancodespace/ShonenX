import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anilist_media;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/api/models/anime/server_model.dart';
import 'package:shonenx/api/models/anime/source_model.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
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

class _WatchScreenState extends ConsumerState<WatchScreen>
    with SingleTickerProviderStateMixin {
  late final Player _player;
  late final VideoController _controller;
  late final AnimeProvider _animeProvider;
  StreamSubscription? _playerSubscription;

  List<EpisodeDataModel> _episodes = [];
  BaseServerModel _servers = BaseServerModel();
  List<SubtitleTrack> _subtitles = [];
  String? _selectedCategory = 'dub';
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
    _player = Player(
        configuration: const PlayerConfiguration(bufferSize: 64 * 1024 * 1024));
    _controller = VideoController(_player);
    _playerSubscription = _player.stream.error
        .listen((error) => _handleError('Player error: $error'));
  }

  Future<void> _fetchEpisodes() async {
    if (!mounted) return;
    try {
      final baseEpisodeModel = await _animeProvider.getEpisodes(widget.animeId);
      if ((baseEpisodeModel.episodes ?? []).isEmpty) {
        throw Exception('No episodes found');
      }
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
      final serverName = _selectedCategory == 'sub'
          ? _servers.sub.first.name
          : _servers.dub.first.name;
      final sources = await _animeProvider.getSources(
          widget.animeId, episodeId, serverName!, _selectedCategory!);
      log("Source url: ${sources.sources.first.url}", name: "Source Url");
      if (sources.sources.isEmpty) throw Exception('No sources available');
      await _extractQualities(sources.sources.first.url!);
      await _configureSubtitles(sources.tracks);
    } catch (e) {
      _handleError('Stream load failed: $e');
    }
  }

  Future<void> _configureSubtitles(List<Subtitle> subtitles) async {
    _subtitles = subtitles
        .map((s) => SubtitleTrack.uri(s.url!, language: s.lang, title: s.lang))
        .toList();
    final englishSub =
        subtitles.firstWhere((s) => s.lang!.toLowerCase().contains('english'));
    log('English subtitle: ${englishSub.url}', name: 'English Subtitle');
    await _player.setSubtitleTrack(SubtitleTrack.uri(englishSub.url!,
        language: englishSub.lang, title: englishSub.lang));
  }

  Future<void> _extractQualities(String m3u8Url) async {
    try {
      final response = await http.get(Uri.parse(m3u8Url));
      if (response.statusCode != 200) throw Exception('Failed to load M3U8');
      final lines = response.body.split('\n');
      final qualities = <Map<String, String>>[];
      for (var i = 0; i < lines.length - 1; i++) {
        if (lines[i].contains('#EXT-X-STREAM-INF')) {
          final resolution =
              RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(lines[i])?.group(1) ??
                  'Unknown';
          qualities.add({
            'quality': resolution,
            'url': m3u8Url.replaceAll('master.m3u8', lines[i + 1])
          });
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
                  textScaleFactor:
                      MediaQuery.sizeOf(context).width > 400 ? 1.5 : 2,
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
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildEpisodesList(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.widget.animeName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (state._episodes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Episode ${state._episodes[state._selectedEpIdx].number}',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildCategoryDropdown(context),
            ],
          ),
          if (state._episodes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              state._episodes[state._selectedEpIdx].title ?? 'Untitled',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<String>(
        tooltip: "Select Category",
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.language_circle,
                color: theme.colorScheme.onPrimaryContainer,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                state._selectedCategory!.toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          if (state._servers.sub.isNotEmpty)
            PopupMenuItem(value: 'sub', child: Text('SUB')),
          if (state._servers.dub.isNotEmpty)
            PopupMenuItem(value: 'dub', child: Text('DUB')),
          if (state._servers.raw.isNotEmpty)
            PopupMenuItem(value: 'raw', child: Text('RAW')),
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
      ),
    );
  }

  Widget _buildEpisodesList(BuildContext context) {
    final totalEpisodes = state._episodes.length;
    final segments = (totalEpisodes / 100).ceil();

    return Column(
      children: [
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: segments,
            itemBuilder: (context, index) {
              final start = index * 100 + 1;
              final end = (start + 99) > totalEpisodes ? totalEpisodes : start + 99;
              final isSelected = state._selectedRangeStart == start;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text('$start-$end'),
                  onSelected: (_) => state.setState(() => state._selectedRangeStart = start),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected 
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            
            itemCount: state._episodes.length,
            itemBuilder: (context, index) {
              final episode = state._episodes[index];
              if (episode.number! < state._selectedRangeStart || 
                  episode.number! >= state._selectedRangeStart + 100) {
                return const SizedBox.shrink();
              }

              final isSelected = index == state._selectedEpIdx;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isSelected 
                    ? theme.colorScheme.primaryContainer 
                    : theme.colorScheme.surfaceContainerHighest,
                  title: Text(
                    'Episode ${episode.number}',
                    style: TextStyle(
                      color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: episode.title != null ? Text(
                    episode.title!,
                    style: TextStyle(
                      color: isSelected
                        ? theme.colorScheme.onPrimaryContainer.withOpacity(0.8)
                        : theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ) : null,
                  onTap: () => state._playEpisode(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
