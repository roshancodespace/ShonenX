import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:shonenx/widgets/player/controls.dart';

// WatchScreen remains the same as provided
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

// _WatchScreenState remains largely unchanged, only UI-related updates are applied
class _WatchScreenState extends ConsumerState<WatchScreen>
    with SingleTickerProviderStateMixin {
  late final Player _player;
  late final VideoController _controller;
  late final AnimeProvider _animeProvider;
  late final AnimeWatchProgressBox _animeWatchProgressBox;
  StreamSubscription? _playerSubscription;
  StreamSubscription? _positionSubscription;

  List<EpisodeDataModel> _episodes = [];
  List<SubtitleTrack> _subtitles = [];
  String? _selectedCategory = 'sub';
  int _selectedEpIdx = 0;
  int _selectedRangeStart = 1;
  List<Map<String, dynamic>> _qualityOptions =
      []; // Changed to Map<String, String>
  String? _selectedQuality;
  Timer? _debounceTimer;
  Duration _lastPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _selectedEpIdx = (widget.episode ?? 1) - 1;
    _lastPosition = widget.startAt;
    _initializeProviders();
    _initializeBoxes();
    _initializePlayer().then((_) => _fetchEpisodes());
  }

  void _initializeProviders() => _animeProvider = getAnimeProvider(ref)!;

  Future<void> _initializeBoxes() async {
    _animeWatchProgressBox = AnimeWatchProgressBox();
    await _animeWatchProgressBox.init();
  }

  Future<void> _initializePlayer() async {
    _player = Player(
        configuration: const PlayerConfiguration(bufferSize: 64 * 1024 * 1024));
    _controller = VideoController(_player);
    _playerSubscription = _player.stream.error.listen((error) {
      log('Player error: $error');
      if (error.contains('Failed to open')) {
        _initializePlayer();
      }
    });
    _positionSubscription = _player.stream.position.listen((position) {
      _lastPosition = position;
    });
  }

  Future<void> _fetchEpisodes() async {
    if (!mounted) return;
    try {
      final baseEpisodeModel = await _animeProvider.getEpisodes(widget.animeId);
      if ((baseEpisodeModel.episodes ?? []).isEmpty) {
        throw Exception('No episodes found for this anime.');
      }
      setState(() => _episodes = baseEpisodeModel.episodes!);
      _debounceFetchStreamData();
    } catch (e) {
      log('Failed to load episodes: $e');
    }
  }

  void _debounceFetchStreamData() {
    _debounceTimer?.cancel();
    _debounceTimer =
        Timer(const Duration(milliseconds: 500), () => _fetchStreamData());
  }

  Future<void> _fetchStreamData() async {
    if (!mounted || _selectedEpIdx >= _episodes.length) {
      log('No episodes available for streaming.');
      return;
    }
    try {
      final episodeId = _episodes[_selectedEpIdx].id!;
      final sources = await _animeProvider.getSources(
          widget.animeId, episodeId, '', _selectedCategory!);
      if (sources.sources.isEmpty) {
        throw Exception('No video sources available.');
      }
      _qualityOptions.clear();
      await _extractQualities(sources.sources.first.url!);
      for (var source in sources.sources) {
        _qualityOptions.add({
          'quality': source.quality ?? 'NO NAME',
          'url': source.url!,
          'isDub': source.isDub
        });
      }
      await _configureSubtitles(sources.tracks);
      await _updateVideoSource(sources.sources.first.url ?? '');
    } catch (e) {
      log('Failed to load stream data: $e');
    } finally {
      setState(() {});
    }
  }

  Future<void> _configureSubtitles(List<Subtitle> subtitles) async {
    _subtitles = subtitles
        .map((s) => SubtitleTrack.uri(s.url!, language: s.lang, title: s.lang))
        .toList();
    try {
      final englishSub = subtitles
          .firstWhere((s) => s.lang!.toLowerCase().contains('english'));
      await _player.setSubtitleTrack(SubtitleTrack.uri(englishSub.url!,
          language: englishSub.lang, title: englishSub.lang));
    } catch (e) {
      if (subtitles.isNotEmpty) {
        await _player.setSubtitleTrack(SubtitleTrack.uri(subtitles.first.url!,
            language: subtitles.first.lang, title: subtitles.first.lang));
      } else {
        await _player.setSubtitleTrack(SubtitleTrack.no());
      }
    }
  }

  Future<void> _extractQualities(String m3u8Url) async {
    try {
      final response = await http.get(Uri.parse(m3u8Url));
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load M3U8 playlist (HTTP ${response.statusCode}).');
      }
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
      if (qualities.isEmpty) {
        throw Exception('No quality options found in M3U8.');
      }
      setState(() {
        _qualityOptions = qualities;
        _selectedQuality =
            _qualityOptions.isNotEmpty ? _qualityOptions.first['url'] : null;
      });
    } catch (e) {
      log('Failed to extract quality options: $e');
    }
  }

  Future<void> _updateVideoSource(String url,
      {bool fromQualityChange = false}) async {
    try {
      await _player.open(Media(url));
      await _player.play();
      if (fromQualityChange) {
        await _player.seek(_lastPosition);
      } else {
        await _player.seek(Duration.zero);
      }
    } catch (e) {
      log('Failed to update video source: $e');
    }
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
      _lastPosition = Duration.zero;
    });
    _debounceFetchStreamData();
  }

  void _changeQuality(String url) {
    final currentPosition = _lastPosition;
    setState(() => _selectedQuality = url);
    _updateVideoSource(url, fromQualityChange: true).then((_) {
      _player.seek(currentPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWideScreen = MediaQuery.sizeOf(context).width > 600;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: isWideScreen
            ? Row(
                children: [
                  Flexible(flex: 3, child: _VideoPlayerSection(this)),
                  Flexible(
                    flex: 2,
                    child: _EpisodesPanel(
                      this,
                      theme,
                      withHeader: true,
                      animeWatchProgressBox: _animeWatchProgressBox,
                      animeMedia: widget.animeMedia,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _VideoPlayerSection(this),
                  Expanded(
                      child: _EpisodesPanel(
                    this,
                    theme,
                    animeWatchProgressBox: _animeWatchProgressBox,
                    animeMedia: widget.animeMedia,
                  )),
                ],
              ),
      ),
    );
  }
}

// Updated Video Player Section with Modern UI
class _VideoPlayerSection extends StatelessWidget {
  final _WatchScreenState state;

  const _VideoPlayerSection(this.state);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Anime Title and Episode Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.widget.animeName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (state._episodes.isNotEmpty)
                        Text(
                          'Episode ${state._episodes[state._selectedEpIdx].number}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Modern Video Player Container

          Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface.withValues(alpha: 0.1),
                  Colors.black,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
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
                      fontSize: 20,
                      backgroundColor: Colors.black54,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textScaleFactor:
                        MediaQuery.sizeOf(context).width > 400 ? 1.2 : 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Updated Episodes Panel with Modern UI
class _EpisodesPanel extends StatelessWidget {
  final AnimeWatchProgressBox? animeWatchProgressBox;
  final anilist_media.Media animeMedia;
  final _WatchScreenState state;
  final ThemeData theme;
  final bool withHeader;

  const _EpisodesPanel(this.state, this.theme,
      {this.withHeader = false,
      required this.animeWatchProgressBox,
      required this.animeMedia});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: state._episodes.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            )
          : Column(
              children: [
                if (withHeader) _buildHeader(context),
                Expanded(
                    child: _buildEpisodesList(
                        context, animeWatchProgressBox, animeMedia)),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                      state._episodes[state._selectedEpIdx].title ??
                          state.widget.animeName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (state._episodes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Episode ${state._episodes[state._selectedEpIdx].number}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        tooltip: "Select Language",
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
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                state._selectedCategory!.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
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
                title: "Language Changed",
                message: "Switched to ${category.toUpperCase()}...",
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

  Widget _buildEpisodesList(
      BuildContext context,
      AnimeWatchProgressBox? animeWatchProgressBox,
      anilist_media.Media animeMedia) {
    final totalEpisodes = state._episodes.length;
    final startIdx = state._selectedRangeStart - 1;
    final endIdx =
        (startIdx + 100 > totalEpisodes) ? totalEpisodes : startIdx + 100;
    final episodesInRange = state._episodes.sublist(startIdx, endIdx);
    final animeProgress =
        animeWatchProgressBox?.getAllProgressByAnimeId(animeMedia.id!) ?? [];

    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: isSelected ? 4 : 1,
                  pressElevation: 6,
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: episodesInRange.length,
            itemBuilder: (context, index) {
              final episode = episodesInRange[index];
              final globalIndex = startIdx + index;
              final isSelected = globalIndex == state._selectedEpIdx;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: GestureDetector(
                  onTap: () => state._playEpisode(globalIndex),
                  child: ValueListenableBuilder(
                    valueListenable: animeWatchProgressBox!.boxValueListenable,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: (index < animeProgress.length &&
                                animeProgress[index].isCompleted)
                            ? 0.5
                            : 1,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow
                                    .withValues(alpha: 0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${episode.number}',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: isSelected
                                          ? theme.colorScheme.onPrimary
                                          : theme
                                              .colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Episode ${episode.number}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: isSelected
                                            ? theme
                                                .colorScheme.onPrimaryContainer
                                            : theme.colorScheme.onSurface,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (episode.title != null)
                                      Text(
                                        episode.title!,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: isSelected
                                              ? theme.colorScheme
                                                  .onPrimaryContainer
                                                  .withValues(alpha: 0.8)
                                              : theme
                                                  .colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Iconsax.play5,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
