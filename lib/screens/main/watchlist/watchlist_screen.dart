import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/models/anime_interface.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/widgets/anime_card.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late Box<WatchlistModel> _watchlistBox;
  List<RecentlyWatchedItem> _recentlyWatched = [];
  List<AnimeItem> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _watchlistBox = Hive.box<WatchlistModel>("user_watchlist");
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final recentWatchlist = _watchlistBox.get('recentlyWatched');
      final favouriteWatchlist = _watchlistBox.get('favorites');
      setState(() {
        _recentlyWatched = recentWatchlist?.recentlyWatched ?? [];
        _favorites = favouriteWatchlist?.favorites ?? [];
      });
    } catch (e) {
      debugPrint('Error loading watchlist: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(
          "Watchlist",
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadWatchlist,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildSectionTitle("Recently Watched"),
              const SizedBox(height: 8),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _recentlyWatched.isEmpty
                      ? const Center(
                          child: Text('No recently watched anime'),
                        )
                      : _buildAnimeList(_recentlyWatched, "recentlyWatched"),
              const SizedBox(height: 24),
              // _buildSectionTitle("Continue Watching"),
              // const SizedBox(height: 8),
              // _buildHorizontalList([]),
              // const SizedBox(height: 24),
              _buildSectionTitle("Favorites"),
              const SizedBox(height: 8),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _favorites.isEmpty
                      ? const Center(
                          child: Text('No recently watched anime'),
                        )
                      : _buildAnimeList(_favorites, "favorites"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.navigate_next,
              size: 35,
            ))
      ],
    );
  }

  Widget _buildAnimeList(List<BaseAnimeCard> items, String tag) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final anime = items[index];
          return AnimeCard(
              anime: Anime(
                id: anime.id,
                name: anime.name,
                poster: anime.poster,
                type: anime.type,
              ),
              tag: tag);
        },
      ),
    );
  }

  Widget _buildHorizontalList(List<String> items) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.movie,
                  size: 50,
                  color: Colors.grey[700],
                ),
                const SizedBox(height: 8),
                Text(
                  items[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
