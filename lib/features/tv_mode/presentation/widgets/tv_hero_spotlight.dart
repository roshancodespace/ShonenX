import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class TvHeroSpotlight extends StatelessWidget {
  final UnifiedMedia? media;
  final List<UnifiedMedia>? items;
  final VoidCallback? onPlay;
  final ValueChanged<UnifiedMedia>? onPlayMedia;
  final VoidCallback? onDetails;
  final ValueChanged<UnifiedMedia>? onDetailsMedia;
  final VoidCallback? onBookmark;
  final ValueChanged<UnifiedMedia>? onBookmarkMedia;
  final bool isBookmarked;
  final bool autoPlay;
  final Duration autoPlayDuration;

  const TvHeroSpotlight({
    super.key,
    this.media,
    this.items,
    this.onPlay,
    this.onPlayMedia,
    this.onDetails,
    this.onDetailsMedia,
    this.onBookmark,
    this.onBookmarkMedia,
    this.isBookmarked = false,
    this.autoPlay = true,
    this.autoPlayDuration = const Duration(seconds: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      color: Colors.white10,
      child: const Center(child: Text('TV Hero Spotlight Placeholder')),
    );
  }
}
