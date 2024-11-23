import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/boxes/watchlist_box.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/screens/main/watchlist/view_all_screen.dart';
import 'package:nekoflow/widgets/anime_card.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late final WatchlistBox _watchlistBox;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  Future<void> _initializeState() async {
    _watchlistBox = WatchlistBox();
    await _watchlistBox.init();
  }

  void _navigateToFullScreen(String title, List<BaseAnimeCard> items) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ViewAllScreen(
          title: title,
          items: items,
          watchlistBox: _watchlistBox,
        ),
      ),
    );
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
      body: ValueListenableBuilder<Box<WatchlistModel>>(
        valueListenable: _watchlistBox.listenable(),
        builder: (context, box, _) {
          final watchlistModel = box.get(0);

          if (watchlistModel == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Optional: Add refresh logic if needed
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSection(
                        context,
                        title: "Recently Watched",
                        items: watchlistModel.recentlyWatched ?? [],
                        emptyMessage: "No recently watched anime",
                        tag: "recent",
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        title: "Favorites",
                        items: watchlistModel.favorites ?? [],
                        emptyMessage: "No favorite anime",
                        tag: "favorite",
                      ),
                    ]),
                  ),
                ),
              ],
            ),
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
    required String tag,
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
                          .withOpacity(0.6),
                    ),
              ),
            ),
          )
        else
          _buildAnimeList(items, tag),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, List<BaseAnimeCard> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (items.isNotEmpty)
          IconButton(
            onPressed: () => _navigateToFullScreen(title, items),
            icon: const Icon(Icons.chevron_right),
          ),
      ],
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
              tag: '$tag-$index',
            ),
          );
        },
      ),
    );
  }
}
