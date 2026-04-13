import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/utils/html_parser.dart';
import 'package:shonenx/features/browse/model/search_filter.dart';
import 'package:shonenx/features/details/view/widgets/horizontal_media_list.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailsContent extends StatelessWidget {
  final UniversalMedia anime;
  final bool isLoading;
  final Function(UniversalMedia)? onMediaTap;

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
          const SizedBox(height: 16),
          if (anime.rankings.isNotEmpty) ...[
            const SizedBox(height: 24),
            AnimeRankings(rankings: anime.rankings),
          ],
          const SizedBox(height: 24),
          AdditionalInfoWidget(anime: anime),
          if (anime.staff.isNotEmpty) ...[
            const SizedBox(height: 24),
            HorizontalMediaSection<UniversalStaff>(
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
          HorizontalMediaSection<UniversalMediaRelation>(
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
          HorizontalMediaSection<UniversalMedia>(
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

/// Info widget displaying anime statistics in a sleek horizontal row
class AnimeInfoCard extends StatelessWidget {
  final UniversalMedia anime;
  final VoidCallback onShare;

  const AnimeInfoCard({super.key, required this.anime, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final mainStudio = anime.studios.firstWhere(
      (s) => s.isMain,
      orElse: () => anime.studios.isNotEmpty
          ? anime.studios.first
          : UniversalStudio(name: 'Unknown', isMain: true),
    );

    final stats = [
      if (anime.averageScore != null)
        _StatData(
          icon: Iconsax.star1,
          value: (anime.averageScore! / 10).toStringAsFixed(1),
          label: 'Rating',
          color: Colors.amber,
        ),
      if (anime.seasonYear != null)
        _StatData(
          icon: Iconsax.calendar_1,
          value: '${anime.seasonYear}',
          label: anime.season ?? 'Year',
          color: Colors.blueAccent,
        ),
      if (anime.episodes != null)
        _StatData(
          icon: Iconsax.layer,
          value: '${anime.episodes}',
          label: 'Episodes',
          color: Colors.purpleAccent,
        ),
      if (anime.format != null)
        _StatData(
          icon: Iconsax.monitor,
          value: anime.format!,
          label: 'Format',
          color: Colors.tealAccent,
        ),
      if (anime.duration != null)
        _StatData(
          icon: Iconsax.timer_1,
          value: '${anime.duration}m',
          label: 'Duration',
          color: Colors.orangeAccent,
        ),
      _StatData(
        icon: Iconsax.building_3,
        value: mainStudio.name.length > 20
            ? '${mainStudio.name.substring(0, 18)}...'
            : mainStudio.name,
        label: 'Studio',
        color: Colors.pinkAccent,
      ),
    ];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _StatItem(stat: stat);
        },
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}

class _StatItem extends StatelessWidget {
  final _StatData stat;

  const _StatItem({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(stat.icon, size: 16, color: stat.color),
              const SizedBox(width: 8),
              Text(
                stat.value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stat.label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display next episode countdown
class NextEpisodeWidget extends StatelessWidget {
  final UniversalMedia anime;

  const NextEpisodeWidget({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    final nextEp = anime.nextAiringEpisode;
    if (nextEp == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final timeUntil = Duration(seconds: nextEp.timeUntilAiring ?? 0);
    final days = timeUntil.inDays;
    final hours = timeUntil.inHours % 24;
    final minutes = timeUntil.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.clock, color: colorScheme.onPrimary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EPISODE ${nextEp.episode}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    children: [
                      const TextSpan(text: 'Airing in '),
                      TextSpan(
                        text: '${days}d ${hours}h ${minutes}m',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimeSynopsis extends StatefulWidget {
  final String description;
  final double collapsedHeight;
  final bool isLoading;

  const AnimeSynopsis({
    super.key,
    required this.description,
    this.collapsedHeight = 150,
    this.isLoading = false,
  });

  @override
  State<AnimeSynopsis> createState() => _AnimeSynopsisState();
}

class _AnimeSynopsisState extends State<AnimeSynopsis>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Synopsis',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.isLoading)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 14,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          )
        else ...[
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: _isExpanded
                  ? const BoxConstraints() // no height limit
                  : BoxConstraints(maxHeight: widget.collapsedHeight),
              child: Text(
                parseHtmlToString(widget.description),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                softWrap: true,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
          if (widget.description.length > 200)
            TextButton(
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(_isExpanded ? 'Show Less' : 'Read More'),
            ),
        ],
      ],
    );
  }
}

/// Rankings widget for displaying anime rankings horizontally
class AnimeRankings extends StatelessWidget {
  final List<UniversalMediaRanking> rankings;

  const AnimeRankings({super.key, required this.rankings});

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Text(
            'Achievements', // Renamed from Rankings for flair
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rankings.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                RankingPill(ranking: rankings[index]),
          ),
        ),
      ],
    );
  }
}

class RankingPill extends StatelessWidget {
  final UniversalMediaRanking ranking;

  const RankingPill({super.key, required this.ranking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTop100 = (ranking.rank ?? 999) <= 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isTop100
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTop100
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTop100 ? Iconsax.cup : Iconsax.ranking_1,
            size: 16,
            color: isTop100
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '#${ranking.rank} ${ranking.context} ${ranking.year ?? ''}'.trim(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTop100
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class AdditionalInfoWidget extends StatelessWidget {
  final UniversalMedia anime;

  const AdditionalInfoWidget({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (anime.tags.isNotEmpty) ...[
          _SectionHeader(title: 'Tags', icon: Iconsax.tag),
          const SizedBox(height: 12),
          AnimeTagsWidget(tags: anime.tags),
          const SizedBox(height: 32),
        ],
        _SectionHeader(title: 'Details', icon: Iconsax.info_circle),
        const SizedBox(height: 16),
        AnimeInformationGrid(anime: anime),
        const SizedBox(height: 32),
        if (anime.trailer != null || anime.siteUrl != null) ...[
          _SectionHeader(title: 'Links', icon: Iconsax.link),
          const SizedBox(height: 16),
          ExternalLinksWidget(anime: anime),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class AnimeTagsWidget extends StatelessWidget {
  final List<String> tags;

  const AnimeTagsWidget({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              navigateToBrowse(context, filter: SearchFilter(tags: [tag]));
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                tag,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class AnimeInformationGrid extends StatelessWidget {
  final UniversalMedia anime;

  const AnimeInformationGrid({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    final items = [
      if (anime.title.english != null)
        _InfoItemData('English Title', anime.title.english!),
      if (anime.title.native != null)
        _InfoItemData('Native Title', anime.title.native!),
      if (anime.synonyms.isNotEmpty)
        _InfoItemData('Synonyms', anime.synonyms.take(2).join(', ')),
      if (anime.source != null)
        _InfoItemData('Source', _formatSource(anime.source!)),
      if (anime.startDate != null)
        _InfoItemData(
          'Aired',
          _formatDateRange(anime.startDate, anime.endDate),
        ),
      if (anime.studios.isNotEmpty)
        _InfoItemData('Studios', anime.studios.map((s) => s.name).join(', ')),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items.map((item) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final itemWidth = (screenWidth - 32 - 16) / 2;

            return SizedBox(
              width: itemWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  String _formatSource(String source) {
    return source
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _formatDateRange(dynamic start, dynamic end) {
    String format(dynamic d) {
      if (d == null) return '?';
      if (d.year == null) return '?';
      // Handle partial dates
      if (d.month == null) return '${d.year}';
      final dt = DateTime(d.year, d.month!, d.day ?? 1);
      return DateFormat.yMMM().format(dt);
    }

    final s = format(start);
    if (end == null) return s;
    final e = format(end);
    return '$s - $e';
  }
}

class _InfoItemData {
  final String label;
  final String value;
  _InfoItemData(this.label, this.value);
}

class ExternalLinksWidget extends StatelessWidget {
  final UniversalMedia anime;

  const ExternalLinksWidget({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (anime.trailer != null && (anime.trailer!.site == 'youtube'))
          Expanded(
            child: _LinkButton(
              icon: Iconsax.video_play,
              label: 'Watch Trailer',
              color: const Color(0xFFFF0000), // YouTube Red
              onTap: () => _launchUrl(
                'https://www.youtube.com/watch?v=${anime.trailer!.id}',
              ),
            ),
          ),
        if (anime.trailer != null && anime.siteUrl != null)
          const SizedBox(width: 12),
        if (anime.siteUrl != null)
          Expanded(
            child: _LinkButton(
              icon: Iconsax.global,
              label: 'AniList',
              color: const Color(0xFF02A9FF), // AniList Blue
              onTap: () => _launchUrl(anime.siteUrl!),
            ),
          ),
      ],
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LinkButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
