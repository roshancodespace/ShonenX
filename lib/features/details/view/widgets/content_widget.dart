import 'package:flutter/material.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'info_card_widget.dart';
import 'synopsis_widget.dart';
import 'rankings_widget.dart';
import 'horizontal_media_list.dart';
import 'additional_info_widget.dart';

/// Content widget that composes all the detail sections
class DetailsContent extends StatelessWidget {
  final Media anime;
  final bool isLoading;
  final Function(Media)? onMediaTap;

  const DetailsContent({
    super.key,
    required this.anime,
    this.isLoading = false,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NextEpisodeWidget(anime: anime),
          const SizedBox(height: 24),
          AnimeSynopsis(
            description: anime.description ?? '',
            isLoading: isLoading && (anime.description?.isEmpty ?? true),
          ),
          if (anime.rankings.isNotEmpty) ...[
            const SizedBox(height: 24),
            AnimeRankings(rankings: anime.rankings),
          ],
          const SizedBox(height: 24),
          AdditionalInfoWidget(anime: anime),
          if (anime.staff.isNotEmpty) ...[
            const SizedBox(height: 24),
            HorizontalMediaSection<Staff>(
              title: 'Staff',
              items: anime.staff,
              isLoading: isLoading,
              itemBuilder: (context, staff) {
                return StaffCard(
                  staff: staff,
                  onTap: () {
                    // Handle staff tap if needed
                  },
                );
              },
            ),
          ],
          const SizedBox(height: 24),
          HorizontalMediaSection<MediaRelation>(
            title: 'Related',
            items: anime.relations,
            isLoading: isLoading,
            itemBuilder: (context, relation) {
              return MediaCard(
                media: relation.media,
                badgeText: _formatRelationType(relation.relationType),
                onTap: () => onMediaTap?.call(relation.media),
              );
            },
          ),
          const SizedBox(height: 24),
          HorizontalMediaSection<Media>(
            title: 'More Like This',
            items: anime.recommendations,
            isLoading: isLoading,
            itemBuilder: (context, media) {
              return MediaCard(
                media: media,
                onTap: () => onMediaTap?.call(media),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _formatRelationType(String type) {
    if (type.isEmpty) return type;
    final formatted = type.replaceAll('_', ' ');
    return formatted[0].toUpperCase() + formatted.substring(1).toLowerCase();
  }
}
