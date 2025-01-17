import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/screens/main/details/details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:nekoflow/utils/converter.dart';

class AnimeCard extends StatelessWidget {
  final BaseAnimeCard anime;
  final dynamic tag;
  final VoidCallback? onLongPress;
  final bool isListLayout;

  const AnimeCard({
    super.key,
    required this.anime,
    required this.tag,
    this.onLongPress,
    this.isListLayout = false,
  });

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => DetailsScreen(
          id: anime.id,
          image: getHighResImage(anime.poster),
          name: anime.name,
          tag: tag,
          type: anime.type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isListLayout ? _buildListLayout(context) : _buildGridLayout(context);
  }

  Widget _buildGridLayout(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: _buildCardContent(context, isGrid: true),
    );
  }

  Widget _buildListLayout(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildCardContent(context, isGrid: false),
    );
  }

  Widget _buildCardContent(BuildContext context, {required bool isGrid}) {
    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      onLongPress: onLongPress,
      child: isGrid
          ? _buildGridCardContent(context)
          : _buildListCardContent(context),
    );
  }

  Widget _buildGridCardContent(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'poster-${anime.id}-$tag',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: getHighResImage(anime.poster),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.surface,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: theme.colorScheme.error,
                child: const Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
        ),
        _buildGradientOverlay(),
        _buildTitle(context),
        Positioned(
          top: 5,
          right: 5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (anime.episodeCount != null && anime.episodeCount != 0)
                _buildEpisodeCount(context),
              SizedBox(
                width: 5,
              ),
              if (anime.type != null) _buildTypeChip(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListCardContent(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'poster-${anime.id}-$tag',
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: getHighResImage(anime.poster),
                width: 120,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'title-${anime.id}-$tag',
                    child: Text(
                      anime.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (anime.type != null)
                    Chip(
                      label: Text(
                        anime.type!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor:
                          theme.colorScheme.primaryContainer.withOpacity(0.2),
                    ),
                  if (anime.score != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          anime.score!.toString(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                  if (anime.episodeCount != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${anime.episodeCount} Episodes',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (anime.status != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(context, anime.status!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            anime.status!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedInformationSquare,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: () => _navigateToDetails(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
            stops: const [0.0, 0.4, 0.75, 1.0],
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
          color:
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          anime.type!,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            shadows: [
              Shadow(
                color: Theme.of(context).shadowColor.withOpacity(0.3),
                offset: Offset(1.0, 1.0),
                blurRadius: 2.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeCount(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${anime.episodeCount} Episodes',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            shadows: [
              Shadow(
                color: Theme.of(context).shadowColor.withOpacity(0.3),
                offset: Offset(1.0, 1.0),
                blurRadius: 2.0,
              ),
            ],
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
      child: Hero(
        tag: 'title-${anime.id}-$tag',
        child: Text(
          anime.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'ongoing':
        return Colors.blue;
      case 'upcoming':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.secondaryContainer;
    }
  }
}
