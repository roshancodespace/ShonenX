import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/notifications/domain/models/notification_subscription.dart';
import 'package:shonenx/features/notifications/presentation/widgets/notification_subscription_sheet.dart';
import 'package:shonenx/features/notifications/providers/notification_subscriptions_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/characters_sheet.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';

class AboutTabWidget extends ConsumerWidget {
  final UnifiedMedia media;
  final VoidCallback? onEpisodesTabRequested;
  final double uiRoundness;

  const AboutTabWidget({
    super.key,
    required this.media,
    this.onEpisodesTabRequested,
    required this.uiRoundness,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final hasTags = media.tags != null && media.tags!.isNotEmpty;
    final hasGenres = media.genres != null && media.genres!.isNotEmpty;
    final hasRelations = media.relations != null && media.relations!.isNotEmpty;
    final hasRecommendations =
        media.recommendations != null && media.recommendations!.isNotEmpty;
    final hasCharacters =
        (media.characters != null && media.characters!.isNotEmpty) ||
        media.id.isNotEmpty;
    final hasLinks =
        media.externalLinks != null && media.externalLinks!.isNotEmpty;

    final items = <Widget>[];

    // Airing Banner
    if (media.airingAt != null) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _AiringBanner(
            media: media,
            onEpisodesTabRequested: onEpisodesTabRequested,
            uiRoundness: uiRoundness,
          ),
        ),
      );
    }

    // Modern Quick Stats Bar
    items.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _QuickStatsBar(media: media, uiRoundness: uiRoundness),
      ),
    );

    // Synopsis Section
    items.add(Synopsis(description: media.description ?? ''));

    // Information & Details Key-Value List
    items.add(
      Padding(
        padding: const EdgeInsets.only(top: 20),
        child: _MediaDetailsSection(media: media, uiRoundness: uiRoundness),
      ),
    );

    // Alternative Titles Tile
    if (media.title.english != null ||
        media.title.romaji != null ||
        media.title.native != null ||
        (media.synonyms != null && media.synonyms!.isNotEmpty)) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _AlternativeTitlesTile(
            title: media.title,
            synonyms: media.synonyms ?? [],
            uiRoundness: uiRoundness,
          ),
        ),
      );
    }

    // Genres & Tags Section
    if (hasGenres || hasTags) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: _GenresAndTagsSection(
            genres: media.genres ?? [],
            tags: media.tags ?? [],
            textTheme: textTheme,
          ),
        ),
      );
    }

    // Characters & Cast Section
    if (hasCharacters) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: _CharactersList(
            mediaId: media.id,
            mediaType: media.type,
            mediaTitle: media.title.availableTitle,
            characters: media.characters ?? [],
            uiRoundness: uiRoundness,
          ),
        ),
      );
    }

    // External Streaming & Links Section
    if (hasLinks) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'External Links',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _ExternalLinksList(links: media.externalLinks!),
            ],
          ),
        ),
      );
    }

    // Relations Section
    if (hasRelations) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Relations',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _RelationsList(
                relations: media.relations!,
                parentType: media.type,
              ),
            ],
          ),
        ),
      );
    }

    // Recommendations Section
    if (hasRecommendations) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommendations',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _RecommendationsList(recommendations: media.recommendations!),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return StaggeredFadeIn(index: index, child: items[index]);
      },
    );
  }
}

class _QuickStatsBar extends StatelessWidget {
  final UnifiedMedia media;
  final double uiRoundness;

  const _QuickStatsBar({required this.media, required this.uiRoundness});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final stats = <Widget>[];

    if (media.score != null && media.score! > 0) {
      stats.add(
        _StatPill(
          icon: Icons.star_rounded,
          iconColor: cs.primary,
          label: media.score!.toStringAsFixed(1),
          uiRoundness: uiRoundness,
        ),
      );
    }

    if (media.format != null && media.format!.isNotEmpty) {
      stats.add(
        _StatPill(
          icon: Icons.tv_rounded,
          label: media.format!,
          uiRoundness: uiRoundness,
        ),
      );
    }

    if (media.status != null && media.status!.isNotEmpty) {
      stats.add(
        _StatPill(
          icon: Icons.fiber_manual_record_rounded,
          iconColor: media.status!.toLowerCase() == 'releasing'
              ? Colors.greenAccent
              : cs.primary,
          label: media.status!.toUpperCase().replaceAll('_', ' '),
          uiRoundness: uiRoundness,
        ),
      );
    }

    if (media.episodes != null && media.episodes! > 0) {
      stats.add(
        _StatPill(
          icon: Icons.video_library_rounded,
          label: '${media.episodes} eps',
          uiRoundness: uiRoundness,
        ),
      );
    }

    if (media.chapters != null && media.chapters! > 0) {
      stats.add(
        _StatPill(
          icon: Icons.menu_book_rounded,
          label: '${media.chapters} chs',
          uiRoundness: uiRoundness,
        ),
      );
    }

    if (media.season != null && media.season!.isNotEmpty) {
      stats.add(
        _StatPill(
          icon: Icons.calendar_today_rounded,
          label: media.season!,
          uiRoundness: uiRoundness,
        ),
      );
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            stats[i],
            if (i < stats.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final double uiRoundness;

  const _StatPill({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.uiRoundness,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(uiRoundness * 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaDetailsSection extends StatelessWidget {
  final UnifiedMedia media;
  final double uiRoundness;

  const _MediaDetailsSection({required this.media, required this.uiRoundness});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final details = <_DetailPair>[];

    if (media.studios != null && media.studios!.isNotEmpty) {
      details.add(_DetailPair('Studio', media.studios!.join(', ')));
    }
    if (media.source != null && media.source!.isNotEmpty) {
      details.add(
        _DetailPair('Source', media.source!.toUpperCase().replaceAll('_', ' ')),
      );
    }
    if (media.duration != null && media.duration! > 0) {
      details.add(_DetailPair('Duration', '${media.duration} mins'));
    }
    if (media.volumes != null && media.volumes! > 0) {
      details.add(_DetailPair('Volumes', '${media.volumes}'));
    }
    if (media.favourites != null && media.favourites! > 0) {
      details.add(
        _DetailPair('Favorites', _formatCompactNumber(media.favourites!)),
      );
    }
    if (media.popularity != null && media.popularity! > 0) {
      details.add(_DetailPair('Popularity', '#${media.popularity}'));
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...details.map((d) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    d.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    d.value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatCompactNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}k';
    return number.toString();
  }
}

class _DetailPair {
  final String label;
  final String value;
  const _DetailPair(this.label, this.value);
}

class _AlternativeTitlesTile extends StatefulWidget {
  final MediaTitle title;
  final List<String> synonyms;
  final double uiRoundness;

  const _AlternativeTitlesTile({
    required this.title,
    required this.synonyms,
    required this.uiRoundness,
  });

  @override
  State<_AlternativeTitlesTile> createState() => _AlternativeTitlesTileState();
}

class _AlternativeTitlesTileState extends State<_AlternativeTitlesTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final rows = <Widget>[];

    if (widget.title.english != null && widget.title.english!.isNotEmpty) {
      rows.add(_buildTitleRow('English', widget.title.english!, cs, theme));
    }
    if (widget.title.romaji != null && widget.title.romaji!.isNotEmpty) {
      rows.add(_buildTitleRow('Romaji', widget.title.romaji!, cs, theme));
    }
    if (widget.title.native != null && widget.title.native!.isNotEmpty) {
      rows.add(_buildTitleRow('Native', widget.title.native!, cs, theme));
    }

    if (_expanded && widget.synonyms.isNotEmpty) {
      rows.add(
        _buildTitleRow('Synonyms', widget.synonyms.join(', '), cs, theme),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.synonyms.isNotEmpty
              ? () => setState(() => _expanded = !_expanded)
              : null,
          borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alternative Titles',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.synonyms.isNotEmpty)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        ...rows,
      ],
    );
  }

  Widget _buildTitleRow(
    String label,
    String value,
    ColorScheme cs,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenresAndTagsSection extends StatelessWidget {
  final List<String> genres;
  final List<MediaTag> tags;
  final TextTheme textTheme;

  const _GenresAndTagsSection({
    required this.genres,
    required this.tags,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (genres.isNotEmpty) ...[
          Text(
            'Genres',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: genres.map((genre) {
              return ActionChip(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.6),
                label: Text(
                  genre,
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
                onPressed: () {
                  context.go('/discover?genres=${Uri.encodeComponent(genre)}');
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
        ],
        if (tags.isNotEmpty) ...[
          Text(
            'Tags',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: tags.map((tag) => _TagChip(label: tag.name)).toList(),
          ),
        ],
      ],
    );
  }
}

class _CharactersList extends ConsumerStatefulWidget {
  final String mediaId;
  final MediaType mediaType;
  final String mediaTitle;
  final List<MediaCharacter> characters;
  final double uiRoundness;

  const _CharactersList({
    required this.mediaId,
    required this.mediaType,
    required this.mediaTitle,
    required this.characters,
    required this.uiRoundness,
  });

  @override
  ConsumerState<_CharactersList> createState() => _CharactersListState();
}

class _CharactersListState extends ConsumerState<_CharactersList> {
  List<MediaCharacter> _list = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _list = List.from(widget.characters);
    if (_list.isEmpty && widget.mediaId.isNotEmpty) {
      _fetchInitialCharacters();
    }
  }

  Future<void> _fetchInitialCharacters() async {
    setState(() => _isLoading = true);
    try {
      final tracker = ref.read(metadataSourceProvider);
      final res = await tracker.getCharacters(
        widget.mediaId,
        page: 1,
        perPage: 15,
        type: widget.mediaType,
      );
      if (mounted) {
        setState(() {
          _list = res.items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_list.isEmpty && !_isLoading) {
      return const SizedBox.shrink();
    }

    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Characters & Cast',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onPressed: () {
            CharactersSheet.show(
              context,
              mediaId: widget.mediaId,
              mediaType: widget.mediaType,
              mediaTitle: widget.mediaTitle,
              initialCharacters: widget.characters,
            );
          },
        ),
      ],
    );

    Widget content;
    if (_isLoading) {
      content = SizedBox(
        height: 102,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return Container(
              width: 195,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(widget.uiRoundness),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 90,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(
                        widget.uiRoundness * 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 12,
                          color: cs.surfaceContainerHigh,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 50,
                          height: 10,
                          color: cs.surfaceContainerHigh,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      content = SizedBox(
        height: 102,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final c = _list[index];
            return InkWell(
              onTap: () {
                CharactersSheet.showDetails(context, c);
              },
              borderRadius: BorderRadius.circular(widget.uiRoundness),
              child: Container(
                width: 195,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(widget.uiRoundness),
                ),
                child: Row(
                  children: [
                    if (c.image != null && c.image!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          widget.uiRoundness * 0.7,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: c.image!,
                          width: 52,
                          height: 90,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 52,
                            height: 90,
                            color: cs.surfaceContainerHigh,
                            child: const Icon(Icons.person_rounded, size: 22),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 52,
                        height: 90,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(
                            widget.uiRoundness * 0.7,
                          ),
                        ),
                        child: const Icon(Icons.person_rounded, size: 22),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (c.role != null && c.role!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              c.role!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                          ],
                          if (c.voiceActorName != null &&
                              c.voiceActorName!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              c.voiceActorName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [header, const SizedBox(height: 12), content],
    );
  }
}

class _ExternalLinksList extends StatelessWidget {
  final List<MediaExternalLink> links;

  const _ExternalLinksList({required this.links});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: links.map((link) {
        return ActionChip(
          visualDensity: VisualDensity.compact,
          avatar: const Icon(Icons.open_in_new_rounded, size: 13),
          side: BorderSide.none,
          backgroundColor: cs.surfaceContainerHigh.withValues(alpha: 0.5),
          label: Text(
            link.site,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
          onPressed: () async {
            final uri = Uri.tryParse(link.url);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        );
      }).toList(),
    );
  }
}

class _AiringBanner extends ConsumerWidget {
  final UnifiedMedia media;
  final double uiRoundness;
  final VoidCallback? onEpisodesTabRequested;

  const _AiringBanner({
    required this.media,
    this.onEpisodesTabRequested,
    required this.uiRoundness,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final airingAt = media.airingAt!;
    final nextEpisode = media.nextEpisode;
    final episodeNum = nextEpisode is int ? nextEpisode : (1);
    final theme = Theme.of(context);

    final subType = media.type == MediaType.MANGA
        ? SubscriptionType.mangaChapter
        : SubscriptionType.animeAiring;

    final map = ref.watch(notificationSubscriptionsProvider);
    final subscription = map['${subType.name}_${media.id}'];

    final bool isMissed =
        subscription != null &&
        subscription.isEnabled &&
        subscription.upcomingTime != null &&
        subscription.upcomingTime!.isBefore(DateTime.now());

    final isManga = media.type == MediaType.MANGA;
    final itemText = isManga ? 'Chapter' : 'Episode';
    final tabText = isManga ? 'Chapters' : 'Episodes';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(uiRoundness),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.timer_outlined,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${itemText.toUpperCase()} $episodeNum',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                if (isMissed) ...[
                  Text(
                    'You missed the notification for $itemText $episodeNum',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      if (onEpisodesTabRequested != null) {
                        onEpisodesTabRequested!();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please check the $tabText tab for the latest release.',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Open $tabText tab →',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ] else ...[
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      children: [
                        const TextSpan(text: 'Airing in '),
                        TextSpan(
                          text: formatCountdown(airingAt),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                final notifier = ref.read(
                  notificationSubscriptionsProvider.notifier,
                );
                await notifier.toggleSubscription(media);
                final sub = notifier.getSubscription(subType, media.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  if (sub != null && sub.isEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Subscribed to ${itemText} $episodeNum. You will be notified when it drops.',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications disabled.')),
                    );
                  }
                }
              },
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      NotificationSubscriptionSheet(media: media),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  subscription?.isEnabled == true
                      ? (subscription!.mode == SubscriptionMode.entireSeason
                            ? Icons.notifications_active
                            : Icons.notifications)
                      : Icons.notifications_outlined,
                  color: subscription?.isEnabled == true
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      side: BorderSide.none,
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onPressed: () {
        context.go('/discover?tags=${Uri.encodeComponent(label)}');
      },
    );
  }
}

class _RelationsList extends ConsumerWidget {
  final List<UnifiedMedia> relations;
  final MediaType parentType;

  const _RelationsList({required this.relations, required this.parentType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));
    final isWide = ref.watch(
      uiPrefsProvider.select((s) => s.isMediaCardWide(style.name)),
    );
    final cardHeight = style.getLayout(isWideMode: isWide).height;

    final Map<String, List<UnifiedMedia>> grouped = {};
    for (final relation in relations) {
      if (relation.type != parentType) continue;

      final type = relation.relationType ?? 'Other';
      final formattedType = type
          .replaceAll('_', ' ')
          .split(' ')
          .map(
            (s) => s.isEmpty
                ? ''
                : s[0].toUpperCase() + s.substring(1).toLowerCase(),
          )
          .join(' ');

      grouped.putIfAbsent(formattedType, () => []).add(relation);
    }

    if (grouped.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: entry.value.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final relation = entry.value[index];
                    return MediaCard(
                      tag: 'details-${relation.id}',
                      title: relation.title.availableTitle,
                      format: relation.format,
                      imageUrl: relation.cover ?? relation.banner ?? '',
                      onTap: () => context.pushReplacement(
                        '/details/${relation.type.id}?tag=details-${relation.id}',
                        extra: relation,
                      ),
                      style: style,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecommendationsList extends ConsumerWidget {
  final List<UnifiedMedia> recommendations;

  const _RecommendationsList({required this.recommendations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));
    final isWide = ref.watch(
      uiPrefsProvider.select((s) => s.isMediaCardWide(style.name)),
    );
    final cardHeight = style.getLayout(isWideMode: isWide).height;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: recommendations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final rec = recommendations[index];
          return MediaCard(
            tag: 'details-rec-${rec.id}',
            title: rec.title.availableTitle,
            format: rec.format,
            imageUrl: rec.cover ?? rec.banner ?? '',
            onTap: () => context.pushReplacement(
              '/details/${rec.type.id}?tag=details-rec-${rec.id}',
              extra: rec,
            ),
            style: style,
          );
        },
      ),
    );
  }
}

class Synopsis extends StatefulWidget {
  final String description;
  final double collapsedHeight;
  final bool isLoading;

  const Synopsis({
    super.key,
    required this.description,
    this.collapsedHeight = 150,
    this.isLoading = false,
  });

  @override
  State<Synopsis> createState() => _SynopsisState();
}

class _SynopsisState extends State<Synopsis>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  static final _brRegex = RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false);
  static final _bOpenRegex = RegExp(r'<\s*b\s*>', caseSensitive: false);
  static final _bCloseRegex = RegExp(r'<\s*/\s*b\s*>', caseSensitive: false);
  static final _boldTagRegex = RegExp(r'<b>(.*?)</b>', dotAll: true);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Synopsis',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (widget.isLoading)
          const _SynopsisSkeleton()
        else ...[
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  _isExpanded
                      ? Colors.transparent
                      : theme.scaffoldBackgroundColor,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5],
              ).createShader(bounds),
              blendMode: BlendMode.dstOut,
              child: ConstrainedBox(
                constraints: _isExpanded
                    ? const BoxConstraints()
                    : BoxConstraints(maxHeight: widget.collapsedHeight),
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                      overflow: TextOverflow.fade,
                    ),
                    children: _descriptionSpans(widget.description, context),
                  ),
                ),
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

  List<TextSpan> _descriptionSpans(String text, BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium!;
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);

    final spans = <TextSpan>[];

    String cleanText = text
        .replaceAll(_brRegex, '\n')
        .replaceAll(_bOpenRegex, '<b>')
        .replaceAll(_bCloseRegex, '</b>');

    int lastIndex = 0;

    for (final match in _boldTagRegex.allMatches(cleanText)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: cleanText.substring(lastIndex, match.start),
            style: baseStyle,
          ),
        );
      }

      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      lastIndex = match.end;
    }

    if (lastIndex < cleanText.length) {
      spans.add(
        TextSpan(text: cleanText.substring(lastIndex), style: baseStyle),
      );
    }

    return spans;
  }
}

class _SynopsisSkeleton extends StatelessWidget {
  const _SynopsisSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final skeletonColor = colorScheme.surfaceContainerHigh.withValues(
      alpha: 0.5,
    );

    Widget buildLine(double width) => Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: skeletonColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLine(double.infinity),
        const SizedBox(height: 8),
        buildLine(double.infinity),
        const SizedBox(height: 8),
        buildLine(MediaQuery.sizeOf(context).width * 0.6),
      ],
    );
  }
}
