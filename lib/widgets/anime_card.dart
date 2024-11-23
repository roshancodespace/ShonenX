import 'package:flutter/material.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/screens/main/details/details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimeCard extends StatelessWidget {
  final BaseAnimeCard anime;
  final dynamic tag;

  const AnimeCard({
    super.key,
    required this.anime,
    required this.tag,
  });

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsScreen(
          id: anime.id,
          image: _getHighResImage(anime.poster),
          name: anime.name,
          tag: tag,
          type: anime.type,
        ),
      ),
    );
  }

  String _getHighResImage(String posterUrl) {
    return posterUrl.replaceAll(RegExp(r'(\d+)x(\d+)'), '600x800');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.4;
    final cardHeight = cardWidth * 1.5;

    return InkWell(
      onTap: () => _navigateToDetails(context),
      splashColor: Colors.pink.withOpacity(0.2),
      borderRadius: BorderRadius.circular(16),
      child: Hero(
        tag: 'poster-${anime.id}-$tag',
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            image: DecorationImage(
              image: CachedNetworkImageProvider(_getHighResImage(anime.poster)),
              fit: BoxFit.cover,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                _buildGradientOverlay(),
                _buildTitle(context),
                if (anime.type != null) _buildTypeChip(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xCC000000),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          anime.type!,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Text(
        anime.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
