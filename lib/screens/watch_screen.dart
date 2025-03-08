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
  StreamSubscription? _positionSubscription;

  List<EpisodeDataModel> _episodes = [];
  List<SubtitleTrack> _subtitles = [];
  final Map<String, List<SubtitleTrack>> _subtitleCache = {};
  final Map<String, List<Map<String, String>>> _qualityCache = {};
  String? _selectedCategory = 'sub';
  int _selectedEpIdx = 0;
  int _selectedRangeStart = 1;
  String? _errorMessage;
  List<Map<String, String>> _qualityOptions = [];
  String? _selectedQuality;
  Timer? _debounceTimer;
  Duration _lastPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _selectedEpIdx = (widget.episode ?? 1) - 1;
    _lastPosition = widget.startAt;
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
    _positionSubscription = _player.stream.position.listen((position) {
      _lastPosition = position; // Continuously update last position
    });
  }

  Future<void> _fetchEpisodes() async {
    if (!mounted) return;
    try {
      final baseEpisodeModel = await _animeProvider.getEpisodes(widget.animeId);
      if ((baseEpisodeModel.episodes ?? []).isEmpty)
        throw Exception('No episodes found for this anime.');
      setState(() => _episodes = baseEpisodeModel.episodes!);
      _debounceFetchStreamData();
    } catch (e) {
      _handleError('Failed to load episodes: $e', onRetry: _fetchEpisodes);
    }
  }

  void _debounceFetchStreamData() {
    _debounceTimer?.cancel();
    _debounceTimer =
        Timer(const Duration(milliseconds: 500), () => _fetchStreamData());
  }

  Future<void> _fetchStreamData() async {
    if (!mounted || _selectedEpIdx >= _episodes.length) {
      _handleError('No episodes available for streaming.');
      return;
    }
    try {
      final episodeId = _episodes[_selectedEpIdx].id!;
      final sources = await _animeProvider.getSources(
          widget.animeId, episodeId, '', _selectedCategory!);
      if (sources.sources.isEmpty)
        throw Exception('No video sources available.');
      await _extractQualities(sources.sources.first.url!);
      await _configureSubtitles(sources.tracks);
      await _updateVideoSource(sources.sources.first.url ?? '');
    } catch (e) {
      _handleError('Failed to load stream data: $e', onRetry: _fetchStreamData);
    }
  }

  Future<void> _configureSubtitles(List<Subtitle> subtitles) async {
    final episodeId = _episodes[_selectedEpIdx].id!;
    if (_subtitleCache[episodeId] == null ||
        _subtitleCache[episodeId]!.length != subtitles.length) {
      _subtitles = subtitles
          .map(
              (s) => SubtitleTrack.uri(s.url!, language: s.lang, title: s.lang))
          .toList();
      _subtitleCache[episodeId] = _subtitles;
      try {
        final englishSub = subtitles
            .firstWhere((s) => s.lang!.toLowerCase().contains('english'));
        await _player.setSubtitleTrack(SubtitleTrack.uri(englishSub.url!,
            language: englishSub.lang, title: englishSub.lang));
      } catch (e) {
        if (subtitles.isNotEmpty) {
          await _player.setSubtitleTrack(SubtitleTrack.uri(subtitles.first.url!,
              language: subtitles.first.lang, title: subtitles.first.lang));
          log('Falling back to first available subtitle: ${subtitles.first.url}',
              name: 'Subtitle Fallback');
        } else {
          await _player.setSubtitleTrack(SubtitleTrack.no());
          log('No subtitles available, disabling subtitles.',
              name: 'Subtitle Fallback');
        }
      }
    }
  }

  Future<void> _extractQualities(String m3u8Url) async {
    final episodeId = _episodes[_selectedEpIdx].id!;
    if (_qualityCache[episodeId] == null) {
      try {
        final response = await http.get(Uri.parse(m3u8Url));
        if (response.statusCode != 200)
          throw Exception(
              'Failed to load M3U8 playlist (HTTP ${response.statusCode}).');
        final lines = response.body.split('\n');
        final qualities = <Map<String, String>>[];
        for (var i = 0; i < lines.length - 1; i++) {
          if (lines[i].contains('#EXT-X-STREAM-INF')) {
            final resolution = RegExp(r'RESOLUTION=(\d+x\d+)')
                    .firstMatch(lines[i])
                    ?.group(1) ??
                'Unknown';
            qualities.add({
              'quality': resolution,
              'url': m3u8Url.replaceAll('master.m3u8', lines[i + 1])
            });
          }
        }
        if (qualities.isEmpty)
          throw Exception('No quality options found in M3U8.');
        _qualityCache[episodeId] = qualities;
      } catch (e) {
        _handleError('Failed to extract quality options: $e',
            onRetry: () => _extractQualities(m3u8Url));
        return;
      }
    }
    setState(() {
      _qualityOptions = _qualityCache[episodeId]!;
      _selectedQuality =
          _qualityOptions.isNotEmpty ? _qualityOptions.first['url'] : null;
    });
  }

  Future<void> _updateVideoSource(String url,
      {bool fromQualityChange = false}) async {
    try {
      await _player.open(Media(url));
      await _player.play();
      if (fromQualityChange) {
        await _player.seek(_lastPosition);
      } else {
        await _player.seek(Duration.zero); // For new episodes
      }
    } catch (e) {
      _handleError('Failed to update video source: $e');
    }
  }

  void _handleError(String message, {VoidCallback? onRetry}) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: onRetry != null
            ? SnackBarAction(label: 'Retry', onPressed: onRetry)
            : null,
      ),
    );
    log(message, level: 1000);
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

  void _playEpisode(int index) {
    if (index < 0 || index >= _episodes.length) return;
    setState(() {
      _selectedEpIdx = index;
      _lastPosition = Duration.zero; // Reset for new episode
    });
    _debounceFetchStreamData();
  }

  void _changeQuality(String url) {
    final currentPosition = _lastPosition;
    setState(() => _selectedQuality = url);
    _updateVideoSource(url, fromQualityChange: true).then((_) {
      _player.seek(currentPosition); // Ensure position is restored
    });
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
              child: state._errorMessage != null
                  ? Center(child: Text(state._errorMessage!))
                  : state._selectedQuality == null
                      ? const Center(child: CircularProgressIndicator())
                      : Video(
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
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.2),
                            ),
                            textScaleFactor:
                                MediaQuery.sizeOf(context).width > 400
                                    ? 1.5
                                    : 2,
                          ),
                        ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EpisodesPanel extends StatelessWidget {
  final _WatchScreenState state;
  final ThemeData theme;

  const _EpisodesPanel(this.state, this.theme);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surface,
      child: state._episodes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
            PopupMenuItem(value: 'sub', child: const Text('SUB')),
            PopupMenuItem(value: 'dub', child: const Text('DUB')),
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
                message:
                    "Changed category to ${category.toUpperCase()}, please wait for the server to respond.",
                contentType: ContentType.success,
              ),
            ),
          );
          state.setState(() => state._selectedCategory = category);
          state._debounceFetchStreamData();
        },
      ),
    );
  }

  Widget _buildEpisodesList(BuildContext context) {
    final totalEpisodes = state._episodes.length;
    final startIdx = state._selectedRangeStart - 1;
    final endIdx =
        (startIdx + 100 > totalEpisodes) ? totalEpisodes : startIdx + 100;
    final episodesInRange = state._episodes.sublist(startIdx, endIdx);

    return Column(
      children: [
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: (totalEpisodes / 100).ceil(),
            itemBuilder: (context, index) {
              final start = index * 100 + 1;
              final end =
                  (start + 99) > totalEpisodes ? totalEpisodes : start + 99;
              final isSelected = state._selectedRangeStart == start;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text('$start-$end'),
                  onSelected: (_) =>
                      state.setState(() => state._selectedRangeStart = start),
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
            itemCount: episodesInRange.length,
            itemBuilder: (context, index) {
              final episode = episodesInRange[index];
              final globalIndex = startIdx + index;
              final isSelected = globalIndex == state._selectedEpIdx;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  tileColor: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  title: Text(
                    'Episode ${episode.number}',
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: episode.title != null
                      ? Text(
                          episode.title!,
                          style: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.8)
                                : theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () => state._playEpisode(globalIndex),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
