import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/models/episodes_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:nekoflow/screens/main/stream/stream_screen.dart';
import 'package:shimmer/shimmer.dart';

class EpisodesList extends StatefulWidget {
  final String id;
  final String title;
  final String poster;
  final int rangeSize;
  final String type;

  const EpisodesList({
    super.key,
    required this.id,
    required this.poster,
    required this.title,
    required this.type,
    this.rangeSize = 50,
  });

  @override
  State<EpisodesList> createState() => _EpisodesListState();
}

class _EpisodesListState extends State<EpisodesList> {
  final ValueNotifier<List<Episode>> _episodes =
      ValueNotifier<List<Episode>>([]);
  final ValueNotifier<List<Map<String, List<Episode>>>> _groupedEpisodes =
      ValueNotifier<List<Map<String, List<Episode>>>>([]);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(true);
  final ValueNotifier<int> _selectedRangeIndex = ValueNotifier<int>(0);

  late final Box<WatchlistModel> _watchlistBox;
  late final AnimeService _animeService;

  @override
  void initState() {
    super.initState();
    _watchlistBox = Hive.box<WatchlistModel>('user_watchlist');
    _animeService = AnimeService();
    _fetchData();
  }

  Future<void> _addToRecentlyWatched(String episodeId, int episodeNumber) async {
    final watchlist = _watchlistBox.get('recentlyWatched') ??
        WatchlistModel(
          recentlyWatched: [],
          continueWatching: [],
          favorites: [],
        );

    final newItem = RecentlyWatchedItem(name: widget.title, poster: widget.poster, type: widget.type, id: widget.id);

    var recentlyWatched = watchlist.recentlyWatched ?? [];
    recentlyWatched = [
      newItem,
      ...recentlyWatched.where((item) =>
          item.name != newItem.name || item.id != newItem.id)
    ].take(10).toList();

    watchlist.recentlyWatched = recentlyWatched;
    _watchlistBox.put('recentlyWatched', watchlist);
  }

  Future<void> _fetchData() async {
    try {
      final result = await _animeService.fetchEpisodes(id: widget.id);
      if (!mounted) return;
      _episodes.value = result;
      _groupedEpisodes.value = _groupEpisodesByRange(result, widget.rangeSize);
    } catch (e) {
      null;
    } finally {
      if (mounted) {
        _isLoading.value = false;
      }
    }
  }

  List<Map<String, List<Episode>>> _groupEpisodesByRange(
      List<Episode> episodes, int rangeSize) {
    return List.generate(
      (episodes.length / rangeSize).ceil(),
      (index) {
        final start = index * rangeSize + 1;
        final end = (start + rangeSize - 1).clamp(1, episodes.length);
        return {
          '$start - $end': episodes.sublist(
            index * rangeSize,
            (index + 1) * rangeSize > episodes.length
                ? episodes.length
                : (index + 1) * rangeSize,
          )
        };
      },
    );
  }

  void _navigateToStreamScreen(Episode episode) {
    _addToRecentlyWatched(episode.episodeId, episode.number);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamScreen(
          id: episode.episodeId,
          title: episode.title,
          episodes: _episodes.value,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        ValueListenableBuilder<bool>(
          valueListenable: _isLoading,
          builder: (context, isLoading, _) {
            return isLoading ? _buildShimmerList() : _buildEpisodeList();
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Episodes",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        ValueListenableBuilder<List<Map<String, List<Episode>>>>(
          valueListenable: _groupedEpisodes,
          builder: (context, groupedEpisodes, _) {
            if (groupedEpisodes.isEmpty) return const SizedBox.shrink();

            return ValueListenableBuilder<int>(
              valueListenable: _selectedRangeIndex,
              builder: (context, selectedIndex, _) {
                return DropdownButton<int>(
                  value: selectedIndex,
                  icon: Icon(Icons.view_list, color: Theme.of(context).iconTheme.color,),
                  onChanged: (newIndex) {
                    if (newIndex != null) {
                      _selectedRangeIndex.value = newIndex;
                    }
                  },
                  items: groupedEpisodes.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value.keys.first, style: Theme.of(context).textTheme.labelMedium,),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Container(
            height: 70.0,
            decoration: BoxDecoration(
              color: Colors.grey[800]!,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeList() {
    return ValueListenableBuilder<List<Map<String, List<Episode>>>>(
      valueListenable: _groupedEpisodes,
      builder: (context, groupedEpisodes, _) {
        if (groupedEpisodes.isEmpty) {
          return const Center(child: Text('No episodes available'));
        }

        return ValueListenableBuilder<int>(
          valueListenable: _selectedRangeIndex,
          builder: (context, selectedIndex, _) {
            final episodes = groupedEpisodes[selectedIndex].values.first;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: episodes.length,
              itemBuilder: (context, index) =>
                  _buildEpisodeTile(episodes[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildEpisodeTile(Episode episode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15.0),
      decoration: BoxDecoration(
        color: episode.isFiller
            ? Theme.of(context).splashColor
            : Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          "EP : ${episode.number}${episode.isFiller ? " : FILLER" : ""}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          episode.title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.play_circle_fill,
            color: Colors.white,
          ),
          onPressed: () => _navigateToStreamScreen(episode),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _episodes.dispose();
    _groupedEpisodes.dispose();
    _isLoading.dispose();
    _selectedRangeIndex.dispose();
    _animeService.dispose();
    super.dispose();
  }
}
