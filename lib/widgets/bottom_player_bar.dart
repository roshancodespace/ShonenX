import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/screens/main/stream/stream_screen.dart';

class BottomPlayerBar extends StatelessWidget {
  final ContinueWatchingItem item;
  final String title;
  final String id;
  final String image;
  final String? type;
  final String? nextEpisode;
  final String? nextEpisodeTitle;

  const BottomPlayerBar({
    super.key,
    required this.item,
    required this.title,
    required this.id,
    required this.image,
    required this.type,
    this.nextEpisode,
    this.nextEpisodeTitle
  });

 double _calculateProgress() {
    try {
      // Parse timestamp (format: HH:mm:ss.ms)
      List<String> timestampParts = item.timestamp.split(':');
      int timestampSeconds = 0;
      
      if (timestampParts.length == 3) {
        // Handle hours if present
        timestampSeconds = int.parse(timestampParts[0]) * 3600 +
            int.parse(timestampParts[1]) * 60 +
            int.parse(timestampParts[2].split('.')[0]);
      } else if (timestampParts.length == 2) {
        // Handle mm:ss format
        timestampSeconds = int.parse(timestampParts[0]) * 60 +
            int.parse(timestampParts[1].split('.')[0]);
      }

      // Parse duration (format: HH:mm:ss or mm:ss)
      List<String> durationParts = item.duration.split(':');
      int durationSeconds = 0;
      
      if (durationParts.length == 3) {
        // Handle hours if present
        durationSeconds = int.parse(durationParts[0]) * 3600 +
            int.parse(durationParts[1]) * 60 +
            int.parse(durationParts[2].split('.')[0]);
      } else if (durationParts.length == 2) {
        // Handle mm:ss format
        durationSeconds = int.parse(durationParts[0]) * 60 +
            int.parse(durationParts[1].split('.')[0]);
      }

      // Calculate progress ratio (between 0.0 and 1.0)
      if (durationSeconds > 0) {
        double progress = timestampSeconds / durationSeconds;
        // Ensure progress is between 0 and 1
        return progress.clamp(0.0, 1.0);
      }

      return 0.0;
    } catch (e) {
      debugPrint('Error calculating progress: $e');
      return 0.0; // Return 0 progress in case of any parsing errors
    }
  }

  void _navigateToPlayer(BuildContext context, String episodeId, String episodeTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamScreen(
          name: item.name,
          title: episodeTitle,
          id: id,
          episodeId: episodeId,
          poster: image,
          episode: item.episode,
          type: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface.withOpacity(0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: Container(
            color: theme.colorScheme.primary.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                // Thumbnail/Poster
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Episode Info and Progress
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Episode Number
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'EP ${item.episode}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Progress Bar
                      LinearProgressIndicator(
                        value: _calculateProgress(), // Calculate this based on timestamp/duration
                        backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                        minHeight: 3,
                      ),
                      const SizedBox(height: 4),
                      
                      // Timestamp
                      Text(
                        '${item.timestamp.split(':')[1]}:${item.timestamp.split(':')[2].split('.')[0]}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Control Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedPlay, color: Colors.white),
                      onPressed: () => _navigateToPlayer(context, item.episodeId, item.title),
                    ),
                    if (nextEpisode != null && nextEpisodeTitle != null) IconButton(
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: Colors.white),
                      onPressed: () => _navigateToPlayer(context, nextEpisode!, nextEpisodeTitle!),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}