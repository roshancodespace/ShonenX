import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nekoflow/utils/converter.dart';
import 'package:shimmer/shimmer.dart';

class AnimeCard extends StatelessWidget {
  final BaseAnimeCard anime;
  final dynamic tag;
  final bool disableInteraction;
  final bool isListLayout;

  const AnimeCard({
    super.key,
    required this.anime,
    required this.tag,
    this.isListLayout = false,
    this.disableInteraction = false,
  });

  void _navigateToDetails(BuildContext context) {
    if (!disableInteraction) {
      context.push(
          '/details?id=${anime.id}&type=${anime.type}&name=${anime.name}&image=${getHighResImage(anime.poster)}&tag=$tag');
    }
  }

  @override
  Widget build(BuildContext context) {
    return isListLayout ? _buildListLayout(context) : _buildGridLayout(context);
  }

  Widget _buildGridLayout(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: Card(child: _buildCardContent(context, isGrid: true)),
    );
  }

  Widget _buildListLayout(BuildContext context) {
    return _buildCardContent(context, isGrid: false);
  }

  Widget _buildCardContent(BuildContext context, {required bool isGrid}) {
    return InkWell(
      onTap: () => _navigateToDetails(context),
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
            borderRadius:
                (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius,
            child: CachedNetworkImage(
              imageUrl: getHighResImage(anime.poster),
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: theme.colorScheme.primaryContainer,
                highlightColor:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                child: Container(
                  color: theme.colorScheme.surface,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: theme.colorScheme.errorContainer,
                child: const Icon(Icons.error),
              ),
            ),
          ),
        ),
        Positioned.fill(
          bottom: -10,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.95),
                  Colors.black.withValues(alpha: 0.2),
                  Colors.transparent
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChipRow(context),
              const Spacer(),
              _buildStatusContainer(context),
              if (anime.episodeCount != null)
                Text(
                  '${anime.episodeCount} Episodes',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              const SizedBox(height: 4),
              _buildTitleText(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChipRow(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment:
          isListLayout ? MainAxisAlignment.start : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((anime.type != null && anime.rating == null) || isListLayout)
          _buildTypeContainer(theme),
        SizedBox(width: isListLayout ? 8 : 0),
        if (anime.rating != null) _buildRatingContainer(context),
      ],
    );
  }

  Widget _buildTypeContainer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        anime.type!,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer),
      ),
    );
  }

  Widget _buildRatingContainer(BuildContext context) {
    if (anime.rating == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        anime.rating!,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusContainer(BuildContext context) {
    if (anime.status == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(context, anime.status!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        anime.status!,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildTitleText() {
    return Text(
      anime.name,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black45)
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildListCardContent(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'poster-${anime.id}-$tag',
              child: Card(
                child: CachedNetworkImage(
                  imageUrl: getHighResImage(anime.poster),
                  width: 90,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: theme.colorScheme.primaryContainer,
                    highlightColor: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.5),
                    child: Container(
                      color: theme.colorScheme.surface,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.colorScheme.errorContainer,
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildListTitleText(theme),
                    const SizedBox(height: 12),
                    _buildChipRow(context)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTitleText(ThemeData theme) {
    return Hero(
      tag: 'title-${anime.id}-$tag',
      child: Text(
        anime.name,
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
