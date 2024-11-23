import 'package:flutter/material.dart';
import 'package:nekoflow/data/boxes/watchlist_box.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/widgets/anime_card.dart';

class ViewAllScreen extends StatelessWidget {
  final String title;
  final List<BaseAnimeCard> items;
  final WatchlistBox watchlistBox;

  const ViewAllScreen({
    super.key,
    required this.title,
    required this.items,
    required this.watchlistBox,
  });

  void _removeItem(BuildContext context, String title, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Confirm Deletion',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: Text(
          'Are you sure you want to remove this from $title?',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onDeleteConfirmed(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _onDeleteConfirmed(String id) async {
    if (title.toLowerCase().split(' ')[0] == 'recently') {
      await watchlistBox.removeRecentlyWatched([id]);
    } else if (title.toLowerCase().split(' ')[0] == 'favorites') {
      await watchlistBox.removeFavorites([id]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        titleSpacing: 0,
        elevation: 0,
        title: Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.navigate_before,
            size: 30,
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: watchlistBox.listenable(),
        builder: (context, _, __) => Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: items.isEmpty
              ? Center(
                  child: Text("No Favorite animes"),
                )
              : GridView.builder(
                  physics: BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisExtent: 260,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 15,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => AnimatedBuilder(
                    animation: ModalRoute.of(context)!.animation!,
                    builder: (context, child) => SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: ModalRoute.of(context)!.animation!,
                        curve: Interval(
                          0.3 + (index * 0.1),
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      )),
                      child: child!,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimeCard(
                          anime: items[index],
                          tag: 'favorites',
                        ),
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  _removeItem(context, title, items[index].id),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
