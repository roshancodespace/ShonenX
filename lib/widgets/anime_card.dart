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
    final detailsScreen = DetailsScreen(
      id: anime.id,
      image: getHighResImage(anime.poster),
      name: anime.name,
      tag: tag,
      type: anime.type,
    );

    if (isListLayout) {
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => detailsScreen),
      );
    } else {
      context.pushTransparentRoute(detailsScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return isListLayout ? _buildListLayout(context) : _buildGridLayout(context);
  }

  Widget _buildGridLayout(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: _buildCardContent(context),
    );
  }

  Widget _buildListLayout(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildCardContent(context),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      onLongPress: onLongPress,
      child: isListLayout 
        ? _buildListCardContent(context)
        : _buildGridCardContent(context),
    );
  }

  Widget _buildGridCardContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPosterImage(theme),
          _buildGradientOverlay(),
          _buildTitle(context),
          Positioned(
            top: 10,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (anime.episodeCount != null) _buildEpisodeChip(context),
                const SizedBox(width: 8), // Spacing between chips
                if (anime.type != null) _buildTypeChip(context),
                const SizedBox(width: 8), // Spacing between chips
                if (anime.score != null) _buildScoreIndicator(context),
                const SizedBox(width: 8), // Spacing between chips
                if (anime.status != null) _buildStatusBadge(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterImage(ThemeData theme) {
    return Hero(
      tag: 'poster-${anime.id}-$tag',
      child: CachedNetworkImage(
        imageUrl: getHighResImage(anime.poster),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Container(
          color: theme.colorScheme.surface,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => Container(
          color: theme.colorScheme.error,
          child: const Icon(Icons.error, color: Colors.white),
        ),
      ),
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
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
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
                  _buildListTitle(theme),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (anime.type != null) _buildListTypeChip(theme),
                      if (anime.episodeCount != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${anime.episodeCount} Episodes',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  if (anime.score != null) ...[
                    const SizedBox(height: 8),
                    _buildListScore(theme),
                  ],
                  const Spacer(),
                  _buildListBottomRow(theme, context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTitle(ThemeData theme) {
    return Hero(
      tag: 'title-${anime.id}-$tag',
      child: Text(
        anime.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildListTypeChip(ThemeData theme) {
    return Chip(
      label: Text(
        anime.type!,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
    );
  }

  Widget _buildListScore(ThemeData theme) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 18),
        const SizedBox(width: 4),
        Text(
          anime.score!.toString(),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildListBottomRow(ThemeData theme, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (anime.status != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(context, anime.status!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              anime.status!,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        const Spacer(),
        IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedInformationSquare,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => _navigateToDetails(context),
        ),
      ],
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
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
      child: _buildChip(
        text: anime.type!,
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
      ),
    );
  }

  Widget _buildEpisodeChip(BuildContext context) {
    return Positioned(
      top: 48,
      right: 12,
      child: _buildChip(
        text: '${anime.episodeCount} eps',
        color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
        icon: const Icon(Icons.video_library, size: 16, color: Colors.white),
      ),
    );
  }
  
  Widget _buildScoreIndicator(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: _buildChip(
        text: anime.score.toString(),
        color: Colors.amber.withOpacity(0.9),
        icon: const Icon(Icons.star, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Positioned(
      bottom: 40,
      right: 12,
      child: _buildChip(
        text: anime.status!,
        color: _getStatusColor(context, anime.status!),
      ),
    );
  }

  Widget _buildChip({
    required String text,
    required Color color,
    Widget? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
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
                color: Colors.black45,
              ),
            ],
          ),
          maxLines: 2,
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
        return Theme.of(context).colorScheme.secondary;
    }
  }
}
