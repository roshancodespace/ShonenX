import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/boxes/watchlist_box.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/widgets/anime_card.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  WatchlistScreenState createState() => WatchlistScreenState();
}

class WatchlistScreenState extends State<WatchlistScreen> {
  late Future<void> _initFuture;
  final WatchlistBox _watchlistBox = WatchlistBox();

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeWatchlistBox();
  }

  Future<void> _initializeWatchlistBox() async {
    await _watchlistBox.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Watchlist"),
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ValueListenableBuilder<Box<WatchlistModel>>(
            valueListenable: _watchlistBox.listenable(),
            builder: (context, box, _) {
              final watchlistModel = box.get(0);

              if (watchlistModel == null) {
                return const Center(child: Text("No data available"));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Optional: Add refresh logic if needed
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildSection(
                      context,
                      title: "Recently Watched",
                      items: watchlistModel.recentlyWatched ?? [],
                      emptyMessage: "No recently watched anime",
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: "Favorites",
                      items: watchlistModel.favorites ?? [],
                      emptyMessage: "No favorite anime",
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<BaseAnimeCard> items,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title, items),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                emptyMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ),
          )
        else
          _buildAnimeList(items, title),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, List<BaseAnimeCard> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Hero(
          tag: title,
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (items.isNotEmpty)
          IconButton(
            onPressed: () => _navigateToFullScreen(context, title, items),
            icon: const Icon(Icons.chevron_right),
          ),
      ],
    );
  }

  void _navigateToFullScreen(
      BuildContext context, String title, List<BaseAnimeCard> items) {
    context.push(
      '/watchlist/$title',
      extra: {'items': items, 'box': _watchlistBox},
    );
  }

  Widget _buildAnimeList(List<BaseAnimeCard> items, String tag) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final anime = items[index];
          return Padding(
            padding: EdgeInsets.only(
              right: 12.0,
              left: index == 0 ? 4.0 : 0.0,
            ),
            child: AnimeCard(
              anime: anime,
              tag: tag,
            ),
          );
        },
      ),
    );
  }
}
