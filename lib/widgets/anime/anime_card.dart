import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shonenx/api/models/anime/anime_model.dep.dart';
import 'package:uuid/uuid.dart';

enum AnimeCardMode {
  card, // Original card mode
  expanded, // Original expanded mode
  grid, // New grid mode
  list, // New list mode
  compact // New compact mode
}

class AnimeCard extends StatelessWidget {
  final Media? anime;
  final String? tag;
  final AnimeCardMode mode;
  final double? width;
  final double? height;

  const AnimeCard({
    super.key,
    required this.anime,
    this.mode = AnimeCardMode.card,
    required this.tag,
    this.width,
    this.height,
  });

  // Get responsive dimensions based on screen size
  Size _getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    switch (mode) {
      case AnimeCardMode.card:
        return Size(width ?? (screenWidth < 600 ? 140 : 160),
            height ?? (screenWidth < 600 ? 200 : 240));
      case AnimeCardMode.expanded:
        return Size(width ?? double.infinity,
            height ?? (screenWidth < 600 ? 120 : 140));
      case AnimeCardMode.grid:
        return Size(width ?? (screenWidth < 600 ? 160 : 200),
            height ?? (screenWidth < 600 ? 260 : 300));
      case AnimeCardMode.list:
        return Size(width ?? double.infinity,
            height ?? (screenWidth < 600 ? 100 : 120));
      case AnimeCardMode.compact:
        return Size(width ?? (screenWidth < 600 ? 100 : 120),
            height ?? (screenWidth < 600 ? 150 : 180));
    }
  }

  Widget _buildEpisodesInfo(
      BuildContext context, Episodes? episodes, TextStyle? baseStyle) {
    if (episodes == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final List<Widget> episodeWidgets = [];
    final bool isCompact = mode == AnimeCardMode.compact;

    // Total episodes
    if (episodes.total != null) {
      episodeWidgets.add(
        Text(
          isCompact ? '${episodes.total}ep' : '${episodes.total} eps',
          style: baseStyle,
        ),
      );
    }

    // Sub episodes
    if (episodes.sub != null && !isCompact) {
      episodeWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Sub: ${episodes.sub}',
            style: baseStyle?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: (baseStyle.fontSize ?? 12) - 1,
            ),
          ),
        ),
      );
    }

    // Dub episodes
    if (episodes.dub != null && !isCompact) {
      episodeWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Dub: ${episodes.dub}',
            style: baseStyle?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
              fontSize: (baseStyle.fontSize ?? 12) - 1,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: episodeWidgets,
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context, Size size) {
    final theme = Theme.of(context);
    return Skeletonizer.zone(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: theme.colorScheme.primaryContainer,
        highlightColor: theme.colorScheme.primary,
        duration: const Duration(seconds: 1),
      ),
      child: Container(
        width: size.width,
        height: size.height,
        color: theme.colorScheme.primary,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Bone.text(),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context, Size size) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl:
                    anime?.coverImage?.large ?? anime?.coverImage?.medium ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    _buildLoadingPlaceholder(context, size),
                errorWidget: (context, url, error) =>
                    _buildLoadingPlaceholder(context, size),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime?.title?.english ??
                        anime?.title?.romaji ??
                        anime?.title?.native ??
                        '',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  _buildEpisodesInfo(
                      context,
                      EpisodesModel(total: anime?.episodes),
                      theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListLayout(BuildContext context, Size size) {
    final theme = Theme.of(context);
    return SizedBox(
      height: size.height,
      child: Row(
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl:
                    anime?.coverImage?.large ?? anime?.coverImage?.medium ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildLoadingPlaceholder(
                    context, Size(size.height * 2 / 3, size.height)),
                errorWidget: (context, url, error) => _buildLoadingPlaceholder(
                    context, Size(size.height * 2 / 3, size.height)),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    anime?.title?.english ??
                        anime?.title?.romaji ??
                        anime?.title?.native ??
                        '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  if (anime?.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      anime!.description!,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: 4),
                  _buildEpisodesInfo(
                      context,
                      EpisodesModel(total: anime?.episodes),
                      theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, Size size) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl:
                    anime?.coverImage?.large ?? anime?.coverImage?.medium ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    _buildLoadingPlaceholder(context, size),
                errorWidget: (context, url, error) =>
                    _buildLoadingPlaceholder(context, size),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            anime?.title?.english ??
                anime?.title?.romaji ??
                anime?.title?.native ??
                '',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          _buildEpisodesInfo(context, EpisodesModel(total: anime?.episodes),
              theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildCardLayout(BuildContext context, Size size) {
    return SizedBox(
      width: size.width,
      child: Hero(
        tag: tag ?? Uuid().v4(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: CachedNetworkImage(
            imageUrl:
                anime?.coverImage?.large ?? anime?.coverImage?.medium ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                _buildLoadingPlaceholder(context, size),
            errorWidget: (context, url, error) =>
                _buildLoadingPlaceholder(context, size),
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Theme.of(context).shadowColor.withValues(alpha: 0.8),
                      Theme.of(context).colorScheme.shadow,
                    ],
                    stops: const [0.3, 0.9, 1],
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (anime?.format != null)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${anime!.format}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onTertiaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Spacer(),
                    if (anime?.averageScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${anime!.averageScore}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      anime?.title?.english ??
                          anime?.title?.romaji ??
                          anime?.title?.native ??
                          '',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    _buildEpisodesInfo(
                      context,
                      EpisodesModel(total: anime?.episodes),
                      Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = _getResponsiveDimensions(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        switch (mode) {
          case AnimeCardMode.expanded:
            return SizedBox(
              height: size.height,
              child: _buildListLayout(context, size),
            );
          case AnimeCardMode.grid:
            return _buildGridLayout(context, size);
          case AnimeCardMode.list:
            return _buildListLayout(context, size);
          case AnimeCardMode.compact:
            return _buildCompactLayout(context, size);
          case AnimeCardMode.card:
            return _buildCardLayout(context, size);
        }
      },
    );
  }
}
