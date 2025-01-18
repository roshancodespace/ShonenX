import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/models/episodes_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/screens/main/stream/stream_screen.dart';

class BottomPlayerBar extends StatelessWidget {
  final String animeId;
  final List<Episode> episodes;
  final String? type;
  final ContinueWatchingItem? continueWatchingItem;

  const BottomPlayerBar({
    super.key,
    required this.animeId,
    required this.episodes,
    this.continueWatchingItem,
    this.type,
  });

  double _calculateProgress() {
    if (continueWatchingItem == null) return 0.0;

    try {
      final duration = _parseTimeToSeconds(continueWatchingItem!.duration);
      final progress = _parseTimeToSeconds(continueWatchingItem!.timestamp);
      return progress / duration;
    } catch (e) {
      debugPrint('Error calculating progress: $e');
      return 0.0;
    }
  }

  int _parseTimeToSeconds(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 3) {
      return int.parse(parts[0]) * 3600 +
          int.parse(parts[1]) * 60 +
          int.parse(parts[2].split('.')[0]);
    } else if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1].split('.')[0]);
    } else {
      throw FormatException('Invalid time format: $timeString');
    }
  }

  void _navigateToPlayer(BuildContext context, Episode episode) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => StreamScreen(
          episodes: episodes,
          anime: AnimeItem(
            name: continueWatchingItem!.name,
            poster: continueWatchingItem!.poster,
            id: continueWatchingItem!.id,
          ),
          episode: episode,
        ),
      ),
    );
  }

  Episode? _getNextEpisode() {
    if (continueWatchingItem == null) return null;

    final currentIndex = episodes.indexWhere((ep) => ep.episodeId == continueWatchingItem!.episodeId);
    return (currentIndex != -1 && currentIndex + 1 < episodes.length) ? episodes[currentIndex + 1] : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _calculateProgress();
    final nextEpisode = _getNextEpisode();

    if (episodes.isEmpty || continueWatchingItem == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 13),
        elevation: 0,
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        child: SizedBox(
          height: 100,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.7),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                    minHeight: 5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(continueWatchingItem!.poster),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              continueWatchingItem!.title,
                              maxLines: 1,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Episode ${continueWatchingItem!.episode} • ${continueWatchingItem!.timestamp.split(':')[1]}:${continueWatchingItem!.timestamp.split(':')[2].split('.')[0]}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedPlay,
                              color: theme.colorScheme.onSurface,
                              size: 30,
                            ),
                            onPressed: () => _navigateToPlayer(context, Episode(
                              title: continueWatchingItem!.title,
                              episodeId: continueWatchingItem!.episodeId,
                              number: continueWatchingItem!.episode,
                              isFiller: false,
                            )),
                          ),
                          if (nextEpisode != null)
                            IconButton(
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowRight01,
                                color: theme.colorScheme.onSurface,
                                size: 30,
                              ),
                              onPressed: () => _navigateToPlayer(context, nextEpisode),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
