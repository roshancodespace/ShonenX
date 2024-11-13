import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';

class FavoriteButton extends StatefulWidget {
  final String animeId;
  final String title;
  final String image;
  final String type;

  const FavoriteButton({
    super.key,
    required this.animeId,
    required this.title,
    required this.image,
    required this.type
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late final Box<WatchlistModel> _watchlistBox;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _watchlistBox = Hive.box<WatchlistModel>('user_watchlist');
    _isFavorite = _checkFavourites();
  }

  bool _checkFavourites() {
    final watchlist = _watchlistBox.get('favorites') ?? WatchlistModel(
      recentlyWatched: [],
      continueWatching: [],
      favorites: [],
    );
    var favourites = watchlist.favorites ?? [];
    return favourites.any((anime) => anime.id == widget.animeId);
  }

  Future<void> _toggleFavorite() async {
    final watchlist = _watchlistBox.get('favorites') ?? WatchlistModel(
      recentlyWatched: [],
      continueWatching: [],
      favorites: [],
    );

    final newItem = AnimeItem(name: widget.title, poster: widget.image, id: widget.animeId, type: widget.type);
    var favourites = watchlist.favorites ?? [];

    if (favourites.any((item) => item.id == newItem.id)) {
      favourites.removeWhere((item) => item.id == newItem.id);
      _isFavorite = false;
    } else {
      favourites = [newItem, ...favourites.where((item) => item.id != newItem.id)].take(10).toList();
      _isFavorite = true;
    }

    watchlist.favorites = favourites;
    await _watchlistBox.put('favorites', watchlist);
    setState(() {});  // Only update the favorite button
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleFavorite,
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_outline,
      ),
    );
  }
}
