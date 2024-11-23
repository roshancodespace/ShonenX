import 'package:flutter/material.dart';
import 'package:nekoflow/data/boxes/watchlist_box.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';

class FavoriteButton extends StatefulWidget {
  final String animeId;
  final String title;
  final String image;
  final String? type;

  const FavoriteButton({
    super.key,
    required this.animeId,
    required this.title,
    required this.image,
    this.type,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late final WatchlistBox _watchlistBox;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  Future<void> _initializeState() async {
    _watchlistBox = WatchlistBox();
    await _watchlistBox.init();
    _isFavorite = _watchlistBox.isFavorite(widget.animeId);
  }

  Future<void> _toggleFavorite() async {
    final animeItem = AnimeItem(
      id: widget.animeId,
      name: widget.title,
      poster: widget.image,
      type: widget.type,
    );

    // Toggle favorite status
    await _watchlistBox.toggleFavorite(animeItem);
    setState(() {
      _isFavorite = !_isFavorite;
    });
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
