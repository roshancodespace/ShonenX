import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:intl/intl.dart';

class AdditionalInfoWidget extends StatelessWidget {
  final Media anime;

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
  final List<Tag> tags;

  const AnimeTagsWidget({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Limit tags to show initially? Or just show all?
    // Let's show all but formatted nicely.

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Text(
            tag.name ?? '',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class AnimeInformationGrid extends StatelessWidget {
  final Media anime;

  const AnimeInformationGrid({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    final items = [
      if (anime.title?.english != null)
        _InfoItemData('English Title', anime.title!.english!),
      if (anime.title?.native != null)
        _InfoItemData('Native Title', anime.title!.native!),
      if (anime.synonyms.isNotEmpty)
        _InfoItemData('Synonyms', anime.synonyms.take(2).join(', ')),
      if (anime.source != null)
        _InfoItemData('Source', _formatSource(anime.source!)),
      if (anime.startDate != null)
        _InfoItemData(
            'Aired', _formatDateRange(anime.startDate, anime.endDate)),
      if (anime.studios.isNotEmpty)
        _InfoItemData('Studios', anime.studios.map((s) => s.name).join(', ')),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    // Use a Wrap or Grid for 2-column layout
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items.map((item) {
        // Calculate width for 2 columns with spacing
        return LayoutBuilder(builder: (context, constraints) {
          // We can't use LayoutBuilder inside Wrap children easily for width.
          // Instead, use FractionallySizedBox or simplified assumption.
          // For simplicity, let's use a custom grid row approach or just full width rows where needed.
          // Actually, simplest clean UI is 50% width items.

          final screenWidth = MediaQuery.of(context).size.width;
          // approx width minus padding
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
        });
      }).toList(),
    );
  }

  String _formatSource(String source) {
    return source.replaceAll('_', ' ').toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
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
  final Media anime;

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
                  'https://www.youtube.com/watch?v=${anime.trailer!.id}'),
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
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
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
